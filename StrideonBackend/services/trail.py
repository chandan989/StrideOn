import json
import math
from datetime import datetime, timezone
from typing import Optional, Dict, Any, List, Set
from models import H3Point, TrailState
from services.geo import H3GeoProcessor
from config import MAX_TRAIL_POINTS, MIN_LOOP_AREA_M2, TRAIL_TTL_SEC


class TrailProcessor:
    """Processes trails, detects loops and cuts"""
    
    def __init__(self, redis_client):
        self.redis = redis_client
        self.geo_processor = H3GeoProcessor()
    
    async def add_point_to_trail(self, session_id: str, user_id: str, point: H3Point) -> Dict[str, Any]:
        """Add point to active trail and check for events"""
        trail_key = f"trail:{session_id}"
        
        # Get current trail state
        trail_data = await self.redis.hgetall(trail_key)
        
        if not trail_data:
            # Initialize new trail
            claimed_territory = await self.get_user_claimed_territory(user_id)
            trail_state = TrailState(
                session_id=session_id,
                user_id=user_id,
                points=[point],
                h3_cells={point.h3_index},
                status='active',
                last_updated=point.timestamp,
                total_length_m=0.0,
                claimed_territory=claimed_territory
            )
        else:
            # Update existing trail
            points_json = trail_data.get("points", "[]")
            points_data = json.loads(points_json)
            points = [H3Point(**p) for p in points_data]
            points.append(point)
            
            # Limit trail length
            if len(points) > MAX_TRAIL_POINTS:
                points = points[-MAX_TRAIL_POINTS:]
            
            h3_cells = {p.h3_index for p in points}
            
            # Calculate length
            total_length = self._calculate_trail_length(points)
            
            claimed_territory_json = trail_data.get("claimed_territory", "[]")
            claimed_territory = set(json.loads(claimed_territory_json))
            
            trail_state = TrailState(
                session_id=session_id,
                user_id=user_id,
                points=points,
                h3_cells=h3_cells,
                status=trail_data.get("status", "active"),
                last_updated=point.timestamp,
                total_length_m=total_length,
                claimed_territory=claimed_territory
            )
        
        # Check for loop closure
        loop_area = None
        if len(trail_state.points) >= 3:
            enclosed_cells = self.geo_processor.detect_loop_closure(
                list(trail_state.h3_cells), 
                trail_state.claimed_territory
            )
            if enclosed_cells and len(enclosed_cells) > 0:
                area_m2 = self.geo_processor.calculate_area_m2(enclosed_cells)
                if area_m2 >= MIN_LOOP_AREA_M2:
                    loop_area = {"cells": list(enclosed_cells), "area_m2": area_m2}
        
        # Check for cuts from other active trails
        cut_detected = await self._check_trail_cuts(trail_state)
        
        # Update Redis
        await self._save_trail_state(trail_state)
        
        result = {
            "ok": True,
            "h3_index": point.h3_index,
            "trail_length_m": trail_state.total_length_m,
            "points_count": len(trail_state.points)
        }
        
        if loop_area:
            result["loop_closure"] = loop_area
        
        if cut_detected:
            result["cut_detected"] = cut_detected
            trail_state.status = 'cut'
            await self._save_trail_state(trail_state)
        
        return result
    
    async def get_trail_state(self, session_id: str) -> Optional[TrailState]:
        """Get current trail state"""
        trail_key = f"trail:{session_id}"
        trail_data = await self.redis.hgetall(trail_key)
        
        if not trail_data:
            return None
        
        points_json = trail_data.get("points", "[]")
        points_data = json.loads(points_json)
        points = [H3Point(**p) for p in points_data]
        
        claimed_territory_json = trail_data.get("claimed_territory", "[]")
        claimed_territory = set(json.loads(claimed_territory_json))
        
        return TrailState(
            session_id=session_id,
            user_id=trail_data.get("user_id", ""),
            points=points,
            h3_cells=set(trail_data.get("h3_cells", "").split(",")) if trail_data.get("h3_cells") else set(),
            status=trail_data.get("status", "active"),
            last_updated=datetime.fromisoformat(trail_data.get("last_updated", datetime.now(timezone.utc).isoformat())),
            total_length_m=float(trail_data.get("total_length_m", "0.0")),
            claimed_territory=claimed_territory
        )
    
    async def get_user_claimed_territory(self, user_id: str) -> Set[str]:
        """Get user's claimed H3 cells from previous claims"""
        # Get from Redis cache first
        territory_key = f"territory:{user_id}"
        cached = await self.redis.smembers(territory_key)
        if cached:
            return set(cached)
        
        # Fallback: query from Postgres claims
        try:
            from utils import ensure_supabase
            s = ensure_supabase()
            res = s.table("claims").select("h3_cells").eq("user_id", user_id).execute()
            all_cells = set()
            for row in res.data or []:
                all_cells.update(row.get("h3_cells", []))
            
            # Cache in Redis
            if all_cells:
                await self.redis.sadd(territory_key, *all_cells)
                await self.redis.expire(territory_key, 3600)  # 1 hour cache
            
            return all_cells
        except Exception:
            return set()
    
    def _calculate_trail_length(self, points: List[H3Point]) -> float:
        """Calculate trail length in meters"""
        if len(points) < 2:
            return 0.0
        
        total_length = 0.0
        for i in range(1, len(points)):
            # Use Haversine distance
            lat1, lng1 = points[i-1].lat, points[i-1].lng
            lat2, lng2 = points[i].lat, points[i].lng
            
            # Convert to radians
            lat1, lng1, lat2, lng2 = map(math.radians, [lat1, lng1, lat2, lng2])
            
            # Haversine formula
            dlat = lat2 - lat1
            dlng = lng2 - lng1
            a = math.sin(dlat/2)**2 + math.cos(lat1) * math.cos(lat2) * math.sin(dlng/2)**2
            c = 2 * math.asin(math.sqrt(a))
            r = 6371000  # Earth radius in meters
            total_length += c * r
        
        return total_length
    
    async def _save_trail_state(self, trail_state: TrailState) -> None:
        """Save trail state to Redis"""
        trail_key = f"trail:{trail_state.session_id}"
        
        # Serialize points
        points_data = []
        for p in trail_state.points:
            points_data.append({
                "lat": p.lat,
                "lng": p.lng,
                "h3_index": p.h3_index,
                "timestamp": p.timestamp.isoformat(),
                "session_id": p.session_id
            })
        
        await self.redis.hset(trail_key, mapping={
            "user_id": trail_state.user_id,
            "status": trail_state.status,
            "points": json.dumps(points_data),
            "h3_cells": ",".join(trail_state.h3_cells),
            "last_updated": trail_state.last_updated.isoformat(),
            "total_length_m": str(trail_state.total_length_m),
            "claimed_territory": json.dumps(list(trail_state.claimed_territory))
        })
        await self.redis.expire(trail_key, TRAIL_TTL_SEC)
    
    async def _check_trail_cuts(self, trail_state: TrailState) -> Optional[Dict[str, Any]]:
        """Check if current trail intersects with other active trails"""
        if len(trail_state.points) < 2:
            return None
        
        # Get all active trails that might intersect
        active_trails_pattern = "trail:*"
        try:
            trail_keys = await self.redis.keys(active_trails_pattern)
            
            current_trail_cells = trail_state.h3_cells
            latest_point = trail_state.points[-1]
            
            for trail_key in trail_keys:
                if trail_key == f"trail:{trail_state.session_id}":
                    continue  # Skip own trail
                
                other_trail_data = await self.redis.hgetall(trail_key)
                if not other_trail_data or other_trail_data.get("status") != "active":
                    continue
                
                other_user_id = other_trail_data.get("user_id")
                if other_user_id == trail_state.user_id:
                    continue  # Skip own trails
                
                other_h3_cells = set(other_trail_data.get("h3_cells", "").split(","))
                if not other_h3_cells:
                    continue
                
                # Check for intersection
                intersection = current_trail_cells.intersection(other_h3_cells)
                if intersection:
                    # Record cut event
                    cut_id = await self._record_cut_event(
                        attacker_id=trail_state.user_id,
                        victim_id=other_user_id,
                        session_id=trail_state.session_id,
                        cut_location=latest_point.h3_index
                    )
                    
                    # Invalidate the victim's trail
                    await self.redis.hset(trail_key.replace("trail:", "trail:"), "status", "cut")
                    
                    return {
                        "cut_id": cut_id,
                        "victim_id": other_user_id,
                        "intersection_cells": list(intersection),
                        "cut_location": {
                            "lat": latest_point.lat,
                            "lng": latest_point.lng,
                            "h3_index": latest_point.h3_index
                        }
                    }
            
            return None
            
        except Exception as e:
            # Log error but don't fail the trail update
            print(f"Cut detection error: {e}")
            return None
    
    async def _record_cut_event(self, attacker_id: str, victim_id: str, session_id: str, cut_location: str) -> str:
        """Record cut event in Redis stream"""
        cut_stream = f"cuts:events:stream"
        cut_id = f"cut_{int(datetime.now(timezone.utc).timestamp() * 1000)}"
        
        fields = {
            "cut_id": cut_id,
            "attacker_id": attacker_id,
            "victim_id": victim_id,
            "session_id": session_id,
            "cut_location": cut_location,
            "occurred_at": datetime.now(timezone.utc).isoformat()
        }
        
        await self.redis.xadd(cut_stream, fields, maxlen=1000, approximate=True)
        
        # Also store in user-specific cut lists for quick access
        await self.redis.lpush(f"cuts:user:{attacker_id}", cut_id)
        await self.redis.lpush(f"cuts:user:{victim_id}", cut_id)
        await self.redis.expire(f"cuts:user:{attacker_id}", 86400)  # 24 hours
        await self.redis.expire(f"cuts:user:{victim_id}", 86400)
        
        return cut_id