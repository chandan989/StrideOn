from datetime import datetime, timezone
from typing import List, Optional
from fastapi import APIRouter, HTTPException, Header, Query
from models import ClaimIn, ClaimOut, BankIn, BankOut
from utils import get_user_id, ensure_supabase


router = APIRouter(prefix="/claims", tags=["claims"])


@router.post("", response_model=ClaimOut)
async def create_claim(body: ClaimIn, authorization: str = Header(default="")) -> ClaimOut:
    user_id = await get_user_id(authorization)
    s = ensure_supabase()
    payload = {
        "session_id": body.session_id,
        "user_id": user_id,
        "area_m2": body.area_m2,
        "h3_cells": body.h3_cells,
    }
    try:
        res = s.table("claims").insert(payload).execute()
        row = (res.data or [])[0]
        return ClaimOut(**row)
    except Exception as e:
        raise HTTPException(400, f"DB error: {e}")


@router.get("/mine", response_model=List[ClaimOut])
async def list_claims(authorization: str = Header(default="")) -> List[ClaimOut]:
    user_id = await get_user_id(authorization)
    s = ensure_supabase()
    try:
        res = s.table("claims").select("id,session_id,user_id,area_m2,h3_cells,created_at").eq("user_id", user_id).order("created_at", desc=True).limit(100).execute()
        rows = res.data or []
        return [ClaimOut(**r) for r in rows]
    except Exception as e:
        raise HTTPException(400, f"DB error: {e}")


# Banking endpoints
bank_router = APIRouter(prefix="/bank", tags=["banking"])


@bank_router.post("", response_model=BankOut)
async def bank_result(body: BankIn, authorization: str = Header(default="")) -> BankOut:
    user_id = await get_user_id(authorization)
    s = ensure_supabase()
    now = datetime.now(timezone.utc).isoformat()
    payload = {
        "user_id": user_id,
        "session_id": body.session_id,
        "city": body.city,
        "ts": now,
        # day computed by trigger
        "area_m2": body.area_m2,
        "score": body.score,
        "ipfs_cid": body.ipfs_cid,
        "signature": body.signature,
    }
    try:
        res = s.table("banked_results").insert(payload).execute()
        row = (res.data or [])[0]
        # We may not have day populated in returning if trigger runs before return; best-effort cast
        day = row.get("day") or datetime.now(timezone.utc).date().isoformat()
        return BankOut(
            id=row.get("id"), user_id=row.get("user_id"), session_id=row.get("session_id"), city=row.get("city"), ts=row.get("ts"), day=day, area_m2=row.get("area_m2", 0), score=row.get("score", 0), ipfs_cid=row.get("ipfs_cid"), signature=row.get("signature"),
        )
    except Exception as e:
        raise HTTPException(400, f"DB error: {e}")


@bank_router.get("/mine", response_model=List[BankOut])
async def list_banked(authorization: str = Header(default=""), day: Optional[str] = Query(default=None)) -> List[BankOut]:
    user_id = await get_user_id(authorization)
    s = ensure_supabase()
    try:
        q = s.table("banked_results").select("id,user_id,session_id,city,ts,day,area_m2,score,ipfs_cid,signature").eq("user_id", user_id)
        if day:
            q = q.eq("day", day)
        res = q.order("ts", desc=True).limit(100).execute()
        rows = res.data or []
        return [BankOut(**r) for r in rows]
    except Exception as e:
        raise HTTPException(400, f"DB error: {e}")