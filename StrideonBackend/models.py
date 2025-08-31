from datetime import datetime
from typing import Optional, List, Any, Dict, Set
from dataclasses import dataclass
from pydantic import BaseModel, Field


# ---------- Core Data Structures ----------
@dataclass
class H3Point:
    """Represents a GPS point with H3 indexing"""
    lat: float
    lng: float
    h3_index: str
    timestamp: datetime
    session_id: str

@dataclass 
class TrailState:
    """Active trail state in Redis"""
    session_id: str
    user_id: str
    points: List[H3Point]
    h3_cells: Set[str]
    status: str  # 'active', 'completed', 'cut'
    last_updated: datetime
    total_length_m: float
    claimed_territory: Set[str]  # H3 cells already owned

@dataclass
class SessionState:
    """Session state management"""
    session_id: str
    user_id: str
    city: str
    status: str  # 'active', 'paused', 'ended'
    started_at: datetime
    last_activity: datetime
    trail_count: int
    total_area_claimed: float


# ---------- API Models ----------
class HealthOut(BaseModel):
    ok: bool
    name: str
    time: str


class NonceOut(BaseModel):
    nonce: str
    ttl: int


class LinkReq(BaseModel):
    address: str
    wepinUserId: str
    signature: str
    nonce: str


class ProfileOut(BaseModel):
    user_id: str
    username: Optional[str] = None
    avatar_url: Optional[str] = None
    city: Optional[str] = None
    wepin_user_id: Optional[str] = None
    wepin_address: Optional[str] = None


class ProfilePatch(BaseModel):
    username: Optional[str] = Field(default=None)
    avatar_url: Optional[str] = Field(default=None)
    city: Optional[str] = Field(default=None)


class SessionCreate(BaseModel):
    city: Optional[str] = None


class SessionOut(BaseModel):
    id: str
    user_id: str
    city: Optional[str] = None
    started_at: str
    ended_at: Optional[str] = None
    status: str


class SessionEndOut(BaseModel):
    ok: bool
    session_id: str
    ended_at: str


class PointIn(BaseModel):
    session_id: str
    lat: float = Field(ge=-90, le=90)
    lng: float = Field(ge=-180, le=180)
    ts: Optional[datetime] = None
    h3_res: int = Field(default=9, ge=0, le=15)
    city: Optional[str] = None


class PresenceIn(BaseModel):
    lat: float = Field(ge=-90, le=90)
    lng: float = Field(ge=-180, le=180)
    h3_res: int = Field(default=9, ge=0, le=15)
    city: str


class NearbyOut(BaseModel):
    user_id: str
    dist_m: Optional[float] = None
    lat: Optional[float] = None
    lng: Optional[float] = None
    h3_index: Optional[str] = None
    updated_at: Optional[str] = None


class ClaimIn(BaseModel):
    session_id: str
    area_m2: float = Field(ge=0)
    h3_cells: List[str] = Field(min_items=1)


class ClaimOut(BaseModel):
    id: str
    session_id: str
    user_id: str
    area_m2: float
    h3_cells: List[str]
    created_at: str


class BankIn(BaseModel):
    session_id: str
    city: Optional[str] = None
    area_m2: float = 0
    score: int = 0
    ipfs_cid: Optional[str] = None
    signature: Optional[str] = None


class BankOut(BaseModel):
    id: str
    user_id: str
    session_id: str
    city: Optional[str]
    ts: str
    day: str
    area_m2: float
    score: int
    ipfs_cid: Optional[str]
    signature: Optional[str]


class PowerupUseIn(BaseModel):
    powerup_id: str
    session_id: Optional[str] = None
    metadata: Optional[Dict[str, Any]] = None


class TrailStateOut(BaseModel):
    session_id: str
    user_id: str
    status: str
    points_count: int
    h3_cells_count: int
    total_length_m: float
    last_updated: str
    claimed_territory_count: int


class SessionStateOut(BaseModel):
    session_id: str
    user_id: str
    city: str
    status: str
    started_at: str
    last_activity: str
    trail_count: int
    total_area_claimed: float


class CutEventOut(BaseModel):
    id: str
    attacker_id: str
    victim_id: str
    session_id: str
    occurred_at: str
    cut_location: Dict[str, Any]