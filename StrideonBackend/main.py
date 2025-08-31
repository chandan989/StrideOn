from datetime import datetime, timezone
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from config import APP_NAME, REDIS_URL, ALLOWED_ORIGINS
from models import HealthOut
from services.session import SessionManager
from services.trail import TrailProcessor
from routers.auth import router as auth_router, wepin_router
from routers.profiles import router as profiles_router
from routers.sessions import router as sessions_router
from routers.presence import router as presence_router, gps_router
from routers.trails import router as trails_router, sessions_router as trail_sessions_router, cuts_router
from routers.claims import router as claims_router, bank_router
from routers.powerups import router as powerups_router, inventory_router, leaderboard_router
from routers.verynet import router as verinet_router

try:
    import redis.asyncio as aioredis
except Exception:  # pragma: no cover
    aioredis = None  # type: ignore

# Global state
redis = None
session_manager = None
trail_processor = None

app = FastAPI(title=APP_NAME)

# CORS setup
origins = ["*"] if ALLOWED_ORIGINS.strip() == "*" else [o.strip() for o in ALLOWED_ORIGINS.split(",") if o.strip()]
app.add_middleware(
    CORSMiddleware,
    allow_origins=origins,
    allow_credentials=(ALLOWED_ORIGINS.strip() != "*"),
    allow_methods=["*"],
    allow_headers=["*"],
)

# Register routers
app.include_router(auth_router)
app.include_router(wepin_router)
app.include_router(profiles_router)
app.include_router(sessions_router)
app.include_router(trail_sessions_router)
app.include_router(presence_router)
app.include_router(gps_router)
app.include_router(trails_router)
app.include_router(cuts_router)
app.include_router(claims_router)
app.include_router(bank_router)
app.include_router(powerups_router)
app.include_router(inventory_router)
app.include_router(leaderboard_router)
app.include_router(verinet_router)


# ---------- Lifecycle ----------
@app.on_event("startup")
async def on_startup() -> None:
    global redis, session_manager, trail_processor
    # Init Supabase early
    from utils import ensure_supabase
    _ = ensure_supabase()
    # Init Redis if available
    if aioredis and REDIS_URL:
        try:
            redis = aioredis.from_url(REDIS_URL, decode_responses=True)
            await redis.ping()
            # Initialize managers
            session_manager = SessionManager(redis)
            trail_processor = TrailProcessor(redis)
        except Exception:
            redis = None


@app.on_event("shutdown")
async def on_shutdown() -> None:
    global redis
    if redis:
        try:
            await redis.aclose()
        except Exception:
            pass


# ---------- Basic Health Endpoints ----------
@app.get("/", response_model=HealthOut)
async def root() -> HealthOut:
    return HealthOut(ok=True, name=APP_NAME, time=datetime.now(timezone.utc).isoformat())


@app.get("/health", response_model=HealthOut)
async def health() -> HealthOut:
    return await root()


# Notes:
# - Run with: uvicorn main:app --reload
# - Env required: SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY, REDIS_URL (for presence/gps), SUPABASE_ANON_KEY (for JWT verify)
# - For local dev without JWT, set DEBUG_USER_ID to a valid profiles.user_id in your Supabase.