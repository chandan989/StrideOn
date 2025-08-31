from typing import Dict, Any, List, Optional
from fastapi import APIRouter, HTTPException, Header, Path, Query
from models import TrailStateOut, SessionStateOut
from utils import get_user_id


router = APIRouter(prefix="/trails", tags=["trails"])


@router.get("/{session_id}", response_model=TrailStateOut)
async def get_trail_state(session_id: str = Path(...), authorization: str = Header(default="")) -> TrailStateOut:
    user_id = await get_user_id(authorization)
    from main import trail_processor
    if not trail_processor:
        raise HTTPException(500, "TrailProcessor not configured")
    
    trail_state = await trail_processor.get_trail_state(session_id)
    if not trail_state:
        raise HTTPException(404, "Trail not found")
    
    # Verify ownership
    if trail_state.user_id != user_id:
        raise HTTPException(403, "Access denied")
    
    return TrailStateOut(
        session_id=trail_state.session_id,
        user_id=trail_state.user_id,
        status=trail_state.status,
        points_count=len(trail_state.points),
        h3_cells_count=len(trail_state.h3_cells),
        total_length_m=trail_state.total_length_m,
        last_updated=trail_state.last_updated.isoformat(),
        claimed_territory_count=len(trail_state.claimed_territory)
    )


@router.get("/{session_id}/cells")
async def get_trail_cells(session_id: str = Path(...), authorization: str = Header(default="")) -> Dict[str, Any]:
    user_id = await get_user_id(authorization)
    from main import trail_processor
    if not trail_processor:
        raise HTTPException(500, "TrailProcessor not configured")
    
    trail_state = await trail_processor.get_trail_state(session_id)
    if not trail_state or trail_state.user_id != user_id:
        raise HTTPException(404, "Trail not found")
    
    # Convert H3 cells to polygon for visualization
    polygon_coords = trail_processor.geo_processor.cells_to_polygon(trail_state.h3_cells)
    
    return {
        "session_id": session_id,
        "h3_cells": list(trail_state.h3_cells),
        "polygon_coords": polygon_coords,
        "status": trail_state.status,
        "area_m2": trail_processor.geo_processor.calculate_area_m2(trail_state.h3_cells)
    }


# Session state endpoints (related to trails)
sessions_router = APIRouter(prefix="/sessions", tags=["sessions"])


@sessions_router.get("/{session_id}/state", response_model=SessionStateOut)
async def get_session_state(session_id: str = Path(...), authorization: str = Header(default="")) -> SessionStateOut:
    user_id = await get_user_id(authorization)
    from main import session_manager
    if not session_manager:
        raise HTTPException(500, "SessionManager not configured")
    
    session_state = await session_manager.get_session_state(session_id)
    if not session_state:
        raise HTTPException(404, "Session state not found")
    
    # Verify ownership
    if session_state.user_id != user_id:
        raise HTTPException(403, "Access denied")
    
    return SessionStateOut(
        session_id=session_state.session_id,
        user_id=session_state.user_id,
        city=session_state.city,
        status=session_state.status,
        started_at=session_state.started_at.isoformat(),
        last_activity=session_state.last_activity.isoformat(),
        trail_count=session_state.trail_count,
        total_area_claimed=session_state.total_area_claimed
    )


# Cut events endpoints
cuts_router = APIRouter(prefix="/cuts", tags=["cuts"])


@cuts_router.get("/mine")
async def get_my_cuts(authorization: str = Header(default=""), limit: int = Query(50, ge=1, le=100)) -> List[Dict[str, Any]]:
    user_id = await get_user_id(authorization)
    from main import redis
    if not redis:
        raise HTTPException(500, "Redis not configured")
    
    try:
        # Get recent cuts for user
        cut_ids = await redis.lrange(f"cuts:user:{user_id}", 0, limit - 1)
        if not cut_ids:
            return []
        
        # Fetch cut details from the events stream
        cuts = []
        for cut_id in cut_ids:
            # Search for the cut event in the stream
            cut_stream = "cuts:events:stream"
            try:
                # Get recent entries from stream
                entries = await redis.xrevrange(cut_stream, count=1000)
                for entry_id, fields in entries:
                    if fields.get("cut_id") == cut_id:
                        cuts.append({
                            "cut_id": cut_id,
                            "attacker_id": fields.get("attacker_id"),
                            "victim_id": fields.get("victim_id"),
                            "session_id": fields.get("session_id"),
                            "cut_location": fields.get("cut_location"),
                            "occurred_at": fields.get("occurred_at"),
                            "role": "attacker" if fields.get("attacker_id") == user_id else "victim"
                        })
                        break
            except Exception:
                continue
        
        return cuts
        
    except Exception as e:
        raise HTTPException(500, f"Redis error: {e}")


@cuts_router.get("/recent")
async def get_recent_cuts(city: Optional[str] = Query(None), limit: int = Query(20, ge=1, le=100)) -> List[Dict[str, Any]]:
    from main import redis
    if not redis:
        raise HTTPException(500, "Redis not configured")
    
    try:
        cut_stream = "cuts:events:stream"
        entries = await redis.xrevrange(cut_stream, count=limit)
        
        cuts = []
        for entry_id, fields in entries:
            # Filter by city if specified (would need to store city in cut events)
            cuts.append({
                "cut_id": fields.get("cut_id"),
                "attacker_id": fields.get("attacker_id"),
                "victim_id": fields.get("victim_id"), 
                "session_id": fields.get("session_id"),
                "cut_location": fields.get("cut_location"),
                "occurred_at": fields.get("occurred_at")
            })
        
        return cuts
        
    except Exception as e:
        raise HTTPException(500, f"Redis error: {e}")