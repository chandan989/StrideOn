from datetime import datetime, timezone
from typing import Optional
from models import SessionState
from services.geo import H3GeoProcessor
from config import SESSION_TTL_SEC


class SessionManager:
    """Manages session state and lifecycle in Redis"""
    
    def __init__(self, redis_client):
        self.redis = redis_client
        self.geo_processor = H3GeoProcessor()
    
    async def create_session_state(self, session_id: str, user_id: str, city: str) -> SessionState:
        """Create new session state in Redis"""
        now = datetime.now(timezone.utc)
        state = SessionState(
            session_id=session_id,
            user_id=user_id,
            city=city,
            status='active',
            started_at=now,
            last_activity=now,
            trail_count=0,
            total_area_claimed=0.0
        )
        
        # Store in Redis
        session_key = f"session:{session_id}"
        await self.redis.hset(session_key, mapping={
            "user_id": user_id,
            "city": city,
            "status": state.status,
            "started_at": state.started_at.isoformat(),
            "last_activity": state.last_activity.isoformat(),
            "trail_count": str(state.trail_count),
            "total_area_claimed": str(state.total_area_claimed)
        })
        await self.redis.expire(session_key, SESSION_TTL_SEC)
        
        # Add to user's active sessions
        await self.redis.sadd(f"user:{user_id}:sessions", session_id)
        await self.redis.expire(f"user:{user_id}:sessions", SESSION_TTL_SEC)
        
        return state
    
    async def get_session_state(self, session_id: str) -> Optional[SessionState]:
        """Get session state from Redis"""
        session_key = f"session:{session_id}"
        data = await self.redis.hgetall(session_key)
        
        if not data:
            return None
        
        return SessionState(
            session_id=session_id,
            user_id=data.get("user_id", ""),
            city=data.get("city", ""),
            status=data.get("status", "active"),
            started_at=datetime.fromisoformat(data.get("started_at", datetime.now(timezone.utc).isoformat())),
            last_activity=datetime.fromisoformat(data.get("last_activity", datetime.now(timezone.utc).isoformat())),
            trail_count=int(data.get("trail_count", "0")),
            total_area_claimed=float(data.get("total_area_claimed", "0.0"))
        )
    
    async def update_session_activity(self, session_id: str) -> None:
        """Update last activity timestamp"""
        session_key = f"session:{session_id}"
        now = datetime.now(timezone.utc).isoformat()
        await self.redis.hset(session_key, "last_activity", now)
        await self.redis.expire(session_key, SESSION_TTL_SEC)
    
    async def end_session(self, session_id: str) -> None:
        """End session and clean up Redis state"""
        session_key = f"session:{session_id}"
        trail_key = f"trail:{session_id}"
        
        # Update status
        await self.redis.hset(session_key, "status", "ended")
        
        # Clean up trail data
        await self.redis.delete(trail_key)
        await self.redis.delete(f"gps:{session_id}:stream")
        
        # Remove from user's active sessions
        state = await self.get_session_state(session_id)
        if state:
            await self.redis.srem(f"user:{state.user_id}:sessions", session_id)