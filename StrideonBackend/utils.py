from datetime import datetime, timezone
from typing import Optional
import httpx
from fastapi import HTTPException, Header
from supabase import create_client, Client
from config import SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY, SUPABASE_ANON_KEY, DEBUG_USER_ID


# Global Supabase client
sb: Optional[Client] = None


async def get_user_id(authorization: str = Header(default="")) -> str:
    """Resolve user_id from Supabase JWT. Falls back to DEBUG_USER_ID if set.
    Accepts header in formats: "Bearer <jwt>" or the raw token.
    """
    token = ""
    if authorization:
        if authorization.lower().startswith("bearer "):
            token = authorization.split(" ", 1)[1].strip()
        else:
            token = authorization.strip()
    if token and SUPABASE_URL:
        try:
            async with httpx.AsyncClient(timeout=5.0) as client:
                headers = {"Authorization": f"Bearer {token}", "apikey": SUPABASE_ANON_KEY}
                resp = await client.get(f"{SUPABASE_URL}/auth/v1/user", headers=headers)
                if resp.status_code == 200:
                    data = resp.json()
                    uid = data.get("id") or (data.get("user") or {}).get("id")
                    if uid:
                        return uid
        except Exception:
            pass
    if DEBUG_USER_ID:
        return DEBUG_USER_ID
    raise HTTPException(status_code=401, detail="Unauthorized: supply valid Supabase JWT or set DEBUG_USER_ID")


def ensure_supabase() -> Client:
    global sb
    if not sb:
        if not SUPABASE_URL or not SUPABASE_SERVICE_ROLE_KEY:
            raise HTTPException(500, "Supabase not configured: set SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY")
        try:
            sb_local = create_client(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY)
        except Exception as e:  # pragma: no cover
            raise HTTPException(500, f"Failed to init Supabase: {e}")
        # assign only on success
        globals()["sb"] = sb_local
    return sb  # type: ignore


async def ensure_profile(user_id: str) -> None:
    s = ensure_supabase()
    try:
        # Try fetch
        got = s.table("profiles").select("user_id").eq("user_id", user_id).limit(1).execute()
        if not got.data:
            s.table("profiles").upsert({"user_id": user_id}, on_conflict="user_id").execute()
    except Exception:
        # ignore; RLS/service role might differ across envs
        pass


async def set_nonce(user_id: str, nonce: str, ttl: int = 300, redis=None, app_state=None) -> None:
    if redis:
        await redis.setex(f"nonce:{user_id}", ttl, nonce)
    else:
        # fallback in-process using app state
        if app_state is not None:
            if not hasattr(app_state, 'nonces'):
                app_state.nonces = {}
            app_state.nonces[user_id] = {"nonce": nonce, "exp": datetime.now(timezone.utc).timestamp() + ttl}


async def get_nonce(user_id: str, redis=None, app_state=None) -> Optional[str]:
    if redis:
        return await redis.get(f"nonce:{user_id}")
    if app_state is not None:
        cache = getattr(app_state, "nonces", {})
        entry = cache.get(user_id)
        if entry and entry["exp"] > datetime.now(timezone.utc).timestamp():
            return entry["nonce"]
    return None