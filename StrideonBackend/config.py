import os

# Application
APP_NAME = "StrideOn Game Server"

# Supabase
SUPABASE_URL = os.environ.get("SUPABASE_URL", "")
SUPABASE_SERVICE_ROLE_KEY = os.environ.get("SUPABASE_SERVICE_ROLE_KEY", "")
SUPABASE_ANON_KEY = os.environ.get("SUPABASE_ANON_KEY", SUPABASE_SERVICE_ROLE_KEY)

# Redis
REDIS_URL = os.environ.get("REDIS_URL", "")

# CORS
# Comma-separated list of origins, e.g. "http://localhost:3000,http://10.0.2.2:8000"
ALLOWED_ORIGINS = os.environ.get("ALLOWED_ORIGINS", "*")

# Debug
DEBUG_USER_ID = os.environ.get("DEBUG_USER_ID", "")

# Game Configuration
PRESENCE_TTL_SEC = int(os.environ.get("PRESENCE_TTL_SEC", "90"))
GPS_STREAM_MAXLEN = int(os.environ.get("GPS_STREAM_MAXLEN", "1000"))
SESSION_TTL_SEC = int(os.environ.get("SESSION_TTL_SEC", "3600"))  # 1 hour
TRAIL_TTL_SEC = int(os.environ.get("TRAIL_TTL_SEC", "7200"))  # 2 hours
H3_RESOLUTION = int(os.environ.get("H3_RESOLUTION", "9"))
MIN_LOOP_AREA_M2 = float(os.environ.get("MIN_LOOP_AREA_M2", "100.0"))
MAX_TRAIL_POINTS = int(os.environ.get("MAX_TRAIL_POINTS", "10000"))