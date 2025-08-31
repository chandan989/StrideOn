# StrideonBackend — FastAPI Game Server (Hackathon Edition)

A lightweight Python FastAPI backend that powers the StrideOn MVP: health checks, auth stubs, profiles, presence, sessions, trails/claims, and optional Very Network (Verychain) on-chain reads. Designed for a 2–day hackathon sprint: simple to run locally via Docker Compose with Redis.

Project root overview and mobile app instructions live in the repository README.md. This document focuses on the backend service only.

## Features
- FastAPI + Uvicorn async API server
- Redis for hot path (presence, active sessions) via docker-compose
- Supabase (Postgres/Auth) integration via service-role key
- CORS with configurable allowed origins
- Optional Very Network integration for leaderboard/score reads
- Smoke tests and HTTP request collection for manual testing

## Repository Layout
- main.py — FastAPI app entrypoint (includes routers and health)
- routers/ — Feature routers
  - auth.py — JWT decode helper and dev stubs
  - profiles.py — Basic profile endpoints
  - presence.py — Presence publishing and queries
  - sessions.py — Session lifecycle endpoints
  - trails.py — Trails and claims (MVP stubs)
  - powerups.py — Power-up catalog/inventory (MVP)
  - verynet.py — Verychain read-only endpoints
  - claims.py — Claims endpoints
- services/ — Services layer (geo, sessions, trails)
- utils.py — Shared helpers
- schema.sql — DB schema for local/testing
- docker-compose.yml — API + Redis for local dev
- Dockerfile — Container build for the API
- requirements.txt — Python dependencies
- test_main.http — HTTP requests for manual testing
- smoke_test.py — Simple script to validate a dev environment
- project.md — Extended architecture notes (in-depth; optional reading)

## Quickstart (Recommended: Docker Compose)
Prerequisites: Docker and Docker Compose installed.

1) From repo root:
- cd StrideonBackend
- docker compose up --build

2) Verify health:
- curl http://127.0.0.1:8000/health

3) Default services started by compose:
- API at http://127.0.0.1:8000
- Redis at redis://redis:6379/0

## Environment Variables
Create a .env file in StrideonBackend/ (optional—compose has sensible defaults):

- SUPABASE_URL: Supabase project URL
- SUPABASE_SERVICE_ROLE_KEY: Service role key (server-side only)
- SUPABASE_ANON_KEY: Client anon key (used rarely on server)
- DEBUG_USER_ID: Convenience user id for local testing of protected endpoints
- REDIS_URL: Defaults to redis://redis:6379/0 (compose service name)
- ALLOWED_ORIGINS: Comma-separated list for CORS (default "*")
- VERY_RPC_URL: Verychain RPC (default http://127.0.0.1:8545)
- VERY_CHAIN_ID: Chain ID (default 1337)
- VERY_CONTRACT_ADDR: StrideonScores address if deployed locally

Note: Keep service keys out of version control. .env is optional; you can export env vars in your shell.

## Local Development (Python venv)
If you prefer to run without Docker:

- cd StrideonBackend
- python -m venv .venv && source .venv/bin/activate
- pip install -r requirements.txt
- export $(grep -v '^#' .env 2>/dev/null | xargs) # optional
- uvicorn main:app --reload --host 127.0.0.1 --port 8000

Health check:
- curl http://127.0.0.1:8000/health

## API Overview
Core routes (see routers/* for full list):
- GET /health — service & deps health
- GET /profiles/me — current user profile (uses Supabase JWT or DEBUG_USER_ID)
- POST /presence/ping — upsert current location (uses Redis and/or DB)
- GET /presence/nearby?lat=..&lng=.. — nearby runners (mock/redis-backed)
- POST /sessions/start — begin a running session
- POST /sessions/end — end current session
- POST /trails/point — submit a GPS point (MVP path/h3 logic in services/geo.py)
- POST /trails/bank — finalize current claim/score (writes DB row)
- GET /verynet/leaderboard?count=10 — optional Verychain read-only sample

Use StrideonBackend/test_main.http with an HTTP client to exercise endpoints.

## Database Schema
Two options:
- Quick demo: rely on Redis+minimal DB. Use schema.sql if you want relational tables for claims, profiles, etc. Run it in your Supabase SQL editor or local Postgres.
- Full plan and SQL examples: see project.md for detailed schema and policies.

## Very Network (Verychain) Setup (Optional)
For local blockchain tests:
- cd very-network-integration
- npm install
- npx hardhat node
- node deploy-hackathon.js
- Export the deployed StrideonScores address as VERY_CONTRACT_ADDR
- Start backend with VERY_RPC_URL=http://127.0.0.1:8545 and updated VERY_CONTRACT_ADDR

Now verify:
- curl http://127.0.0.1:8000/verynet/health
- curl "http://127.0.0.1:8000/verynet/leaderboard?count=5"

## CORS and Android Emulator
- The Android app uses http://10.0.2.2:8000 to reach your localhost from the emulator.
- If running the backend on another host, set BuildConfig.API_BASE_URL in the Android app accordingly and set ALLOWED_ORIGINS to include your app origin if needed.

## Testing and Tools
- Manual API tests: test_main.http
- Quick smoke test: python smoke_test.py (checks health and basic wiring)

## Troubleshooting
- 401/403: Use a valid Supabase JWT on protected endpoints, or set DEBUG_USER_ID for local testing.
- Emulator cannot connect: Use 10.0.2.2 from Android, ensure Docker is up, and port 8000 is open.
- Redis errors: Ensure docker-compose launched the redis service; verify REDIS_URL.
- Verychain errors: Ensure local node is running and contract address is set.

## Hackathon Notes
- This backend is intentionally minimal and optimized for demo reliability.
- Prefer mocks for risky paths; wire the real components behind feature flags.
- Document all assumptions in PRs to help judges and teammates reproduce the demo.

## License
MIT (or as per root license).