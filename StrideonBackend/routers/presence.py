import json
from datetime import datetime, timezone
from typing import Dict, Any, List
import h3
from fastapi import APIRouter, HTTPException, Header, Query
from models import PresenceIn, NearbyOut, PointIn, H3Point
from utils import get_user_id
from config import PRESENCE_TTL_SEC, GPS_STREAM_MAXLEN, H3_RESOLUTION


router = APIRouter(tags=["presence"])


@router.post("/presence")
async def update_presence(p: PresenceIn, authorization: str = Header(default="")) -> Dict[str, Any]:
    user_id = await get_user_id(authorization)
    from main import redis
    if not redis:
        raise HTTPException(500, "Redis not configured; set REDIS_URL")
    h3_index = h3.latlng_to_cell(p.lat, p.lng, p.h3_res)
    now_iso = datetime.now(timezone.utc).isoformat()
    # KV for latest presence
    val = {"user_id": user_id, "lat": p.lat, "lng": p.lng, "h3_index": h3_index, "updated_at": now_iso, "city": p.city}
    await redis.setex(f"presence:{user_id}", PRESENCE_TTL_SEC, json.dumps(val))
    # GEO per city
    if p.city:
        await redis.execute_command("GEOADD", f"presence:city:{p.city}", p.lng, p.lat, user_id)
    return {"ok": True, "h3_index": h3_index}


@router.get("/presence/nearby", response_model=List[NearbyOut])
async def presence_nearby(
    city: str = Query(...),
    lat: float = Query(..., ge=-90, le=90),
    lng: float = Query(..., ge=-180, le=180),
    radius_m: int = Query(1000, ge=10, le=10000),
) -> List[NearbyOut]:
    from main import redis
    if not redis:
        raise HTTPException(500, "Redis not configured; set REDIS_URL")
    key = f"presence:city:{city}"
    try:
        # Use GEOSEARCH for metric radius
        res = await redis.execute_command(
            "GEOSEARCH", key, "FROMLONLAT", lng, lat, "BYRADIUS", radius_m, "m", "WITHDIST", "COUNT", 50
        )
    except Exception as e:
        raise HTTPException(500, f"Redis error: {e}")
    out: List[NearbyOut] = []
    for item in res or []:
        uid = item[0]
        dist = float(item[1]) if len(item) > 1 else None
        # Fetch presence payload
        payload = await redis.get(f"presence:{uid}")
        data = json.loads(payload) if payload else {}
        out.append(NearbyOut(user_id=uid, dist_m=dist, lat=data.get("lat"), lng=data.get("lng"), h3_index=data.get("h3_index"), updated_at=data.get("updated_at")))
    return out


# GPS endpoints
gps_router = APIRouter(prefix="/gps", tags=["gps"])


@gps_router.post("/ingest")
async def gps_ingest(p: PointIn, authorization: str = Header(default="")) -> Dict[str, Any]:
    user_id = await get_user_id(authorization)
    from main import redis, trail_processor, session_manager
    if not redis or not trail_processor:
        raise HTTPException(500, "Redis or TrailProcessor not configured")
    
    # Update session activity
    if session_manager:
        await session_manager.update_session_activity(p.session_id)
    
    ts = p.ts or datetime.now(timezone.utc)
    h3_index = h3.latlng_to_cell(p.lat, p.lng, p.h3_res or H3_RESOLUTION)
    
    # Create H3Point for enhanced processing
    point = H3Point(
        lat=p.lat,
        lng=p.lng,
        h3_index=h3_index,
        timestamp=ts,
        session_id=p.session_id
    )
    
    try:
        # Store in GPS stream for audit trail
        stream_key = f"gps:{p.session_id}:stream"
        fields = {
            "ts": ts.isoformat(),
            "lat": str(p.lat),
            "lng": str(p.lng),
            "h3_res": str(p.h3_res or H3_RESOLUTION),
            "h3_index": h3_index,
        }
        msgid = await redis.xadd(stream_key, fields, maxlen=GPS_STREAM_MAXLEN, approximate=True)
        
        # Enhanced trail processing
        result = await trail_processor.add_point_to_trail(p.session_id, user_id, point)
        result["stream_id"] = msgid
        
        return result
        
    except Exception as e:
        raise HTTPException(500, f"Processing error: {e}")