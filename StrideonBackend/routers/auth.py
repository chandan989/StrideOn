from datetime import datetime, timezone
from typing import Dict, Any
from fastapi import APIRouter, HTTPException, Header
from models import NonceOut, LinkReq
from utils import get_user_id, ensure_profile, ensure_supabase, set_nonce, get_nonce

try:
    from eth_account.messages import encode_defunct
    from eth_account import Account
except Exception:  # pragma: no cover
    encode_defunct = None  # type: ignore
    Account = None  # type: ignore


router = APIRouter(prefix="/auth", tags=["authentication"])


@router.post("/nonce", response_model=NonceOut)
async def create_nonce(authorization: str = Header(default="")) -> NonceOut:
    user_id = await get_user_id(authorization)
    await ensure_profile(user_id)
    nonce = f"strideon:{user_id}:{int(datetime.now(timezone.utc).timestamp())}"
    ttl = 300
    # Import at runtime to avoid circular imports
    from main import redis, app
    await set_nonce(user_id, nonce, ttl, redis=redis, app_state=app.state)
    return NonceOut(nonce=nonce, ttl=ttl)


# Wepin endpoints
wepin_router = APIRouter(prefix="/wepin", tags=["wepin"])


@wepin_router.post("/link")
async def link_wepin(req: LinkReq, authorization: str = Header(default="")) -> Dict[str, Any]:
    user_id = await get_user_id(authorization)
    await ensure_profile(user_id)
    # Import at runtime to avoid circular imports
    from main import redis, app
    expect = await get_nonce(user_id, redis=redis, app_state=app.state)
    if not expect or expect != req.nonce:
        raise HTTPException(400, "Invalid or expired nonce")
    if encode_defunct is None or Account is None:
        raise HTTPException(500, "eth_account not installed on server")
    # Verify EVM signature
    msg = encode_defunct(text=req.nonce)
    try:
        recovered = Account.recover_message(msg, signature=req.signature)
    except Exception as e:
        raise HTTPException(400, f"Invalid signature: {e}")
    if recovered.lower() != req.address.lower():
        raise HTTPException(400, "Signature address mismatch")
    # Update profile with Wepin linkage
    s = ensure_supabase()
    try:
        s.table("profiles").upsert({
            "user_id": user_id,
            "wepin_user_id": req.wepinUserId,
            "wepin_address": req.address,
        }, on_conflict="user_id").execute()
    except Exception as e:
        raise HTTPException(400, f"DB error: {e}")
    return {"ok": True}