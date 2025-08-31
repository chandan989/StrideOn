from datetime import datetime, timezone
from typing import List
from fastapi import APIRouter, HTTPException, Header, Path
from models import SessionCreate, SessionOut, SessionEndOut
from utils import get_user_id, ensure_profile, ensure_supabase


router = APIRouter(prefix="/sessions", tags=["sessions"])


@router.post("", response_model=SessionOut)
async def create_session(body: SessionCreate, authorization: str = Header(default="")) -> SessionOut:
    user_id = await get_user_id(authorization)
    await ensure_profile(user_id)
    s = ensure_supabase()
    payload = {"user_id": user_id, "city": body.city}
    try:
        res = s.table("sessions").insert(payload).execute()
        row = (res.data or [])[0]
        
        # Create enhanced session state in Redis
        from main import session_manager
        if session_manager and row:
            session_id = row.get("id")
            city = body.city or "unknown"
            await session_manager.create_session_state(session_id, user_id, city)
            
    except Exception as e:
        raise HTTPException(400, f"DB error: {e}")
    return SessionOut(**row)


@router.get("/mine", response_model=List[SessionOut])
async def list_sessions(authorization: str = Header(default="")) -> List[SessionOut]:
    user_id = await get_user_id(authorization)
    s = ensure_supabase()
    try:
        res = s.table("sessions").select("id,user_id,city,started_at,ended_at,status").eq("user_id", user_id).order("started_at", desc=True).limit(50).execute()
        rows = res.data or []
    except Exception as e:
        raise HTTPException(400, f"DB error: {e}")
    return [SessionOut(**r) for r in rows]


@router.patch("/{session_id}/end", response_model=SessionEndOut)
async def end_session(session_id: str = Path(...), authorization: str = Header(default="")) -> SessionEndOut:
    user_id = await get_user_id(authorization)
    s = ensure_supabase()
    ended_at = datetime.now(timezone.utc).isoformat()
    try:
        # enforce ownership in app layer
        own = s.table("sessions").select("id,user_id").eq("id", session_id).single().execute().data
        if not own or own.get("user_id") != user_id:
            raise HTTPException(404, "Session not found")
        s.table("sessions").update({"ended_at": ended_at, "status": "ended"}).eq("id", session_id).execute()
        
        # Clean up Redis session state
        from main import session_manager
        if session_manager:
            await session_manager.end_session(session_id)
            
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(400, f"DB error: {e}")
    return SessionEndOut(ok=True, session_id=session_id, ended_at=ended_at)