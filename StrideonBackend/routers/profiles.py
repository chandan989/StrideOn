from fastapi import APIRouter, HTTPException, Header
from models import ProfileOut, ProfilePatch
from utils import get_user_id, ensure_profile, ensure_supabase


router = APIRouter(prefix="/profiles", tags=["profiles"])


@router.get("/me", response_model=ProfileOut)
async def get_me(authorization: str = Header(default="")) -> ProfileOut:
    user_id = await get_user_id(authorization)
    await ensure_profile(user_id)
    s = ensure_supabase()
    try:
        res = s.table("profiles").select("user_id, username, avatar_url, city, wepin_user_id, wepin_address").eq("user_id", user_id).single().execute()
        row = res.data or {"user_id": user_id}
    except Exception:
        row = {"user_id": user_id}
    return ProfileOut(**row)


@router.patch("/me", response_model=ProfileOut)
async def patch_me(body: ProfilePatch, authorization: str = Header(default="")) -> ProfileOut:
    user_id = await get_user_id(authorization)
    await ensure_profile(user_id)
    s = ensure_supabase()
    updates = {k: v for k, v in body.model_dump().items() if v is not None}
    if not updates:
        # return current
        return await get_me(authorization)
    try:
        s.table("profiles").update(updates).eq("user_id", user_id).execute()
        return await get_me(authorization)
    except Exception as e:
        raise HTTPException(400, f"DB error: {e}")