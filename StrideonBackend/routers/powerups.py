from typing import List, Dict, Any, Optional
from fastapi import APIRouter, HTTPException, Header, Query
from models import PowerupUseIn
from utils import get_user_id, ensure_supabase


router = APIRouter(prefix="/powerups", tags=["powerups"])


@router.get("")
async def list_powerups() -> List[Dict[str, Any]]:
    s = ensure_supabase()
    try:
        res = s.table("powerups").select("id,name,description,base_price,duration_seconds,enabled,updated_at").eq("enabled", True).order("id").execute()
        return res.data or []
    except Exception as e:
        raise HTTPException(400, f"DB error: {e}")


@router.post("/use")
async def use_powerup(body: PowerupUseIn, authorization: str = Header(default="")) -> Dict[str, Any]:
    user_id = await get_user_id(authorization)
    s = ensure_supabase()
    # Check inventory
    try:
        inv = s.table("user_powerups").select("id,quantity").eq("user_id", user_id).eq("powerup_id", body.powerup_id).single().execute().data
        if not inv or inv.get("quantity", 0) <= 0:
            raise HTTPException(400, "Insufficient quantity")
        # Log usage
        s.table("powerup_uses").insert({
            "user_id": user_id,
            "session_id": body.session_id,
            "powerup_id": body.powerup_id,
            "metadata": body.metadata or {},
        }).execute()
        # Decrement inventory (non-atomic; acceptable for MVP)
        new_q = max(0, int(inv.get("quantity", 0)) - 1)
        s.table("user_powerups").update({"quantity": new_q}).eq("id", inv["id"]).execute()
        return {"ok": True, "powerup_id": body.powerup_id, "remaining": new_q}
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(400, f"DB error: {e}")


# Inventory endpoints
inventory_router = APIRouter(prefix="/inventory", tags=["inventory"])


@inventory_router.get("")
async def my_inventory(authorization: str = Header(default="")) -> List[Dict[str, Any]]:
    user_id = await get_user_id(authorization)
    s = ensure_supabase()
    try:
        res = s.table("user_powerups").select("powerup_id,quantity,updated_at").eq("user_id", user_id).order("powerup_id").execute()
        return res.data or []
    except Exception as e:
        raise HTTPException(400, f"DB error: {e}")


# Leaderboard endpoints
leaderboard_router = APIRouter(prefix="/leaderboard", tags=["leaderboard"])


@leaderboard_router.get("/daily")
async def leaderboard_daily(day: Optional[str] = Query(default=None), city: Optional[str] = Query(default=None)) -> List[Dict[str, Any]]:
    s = ensure_supabase()
    try:
        q = s.table("leaderboard_daily").select("id,day,city,user_id,score,rank")
        if day:
            q = q.eq("day", day)
        if city:
            q = q.eq("city", city)
        q = q.order("score", desc=True).limit(100)
        res = q.execute()
        return res.data or []
    except Exception as e:
        raise HTTPException(400, f"DB error: {e}")