# StrideOn — Hackathon MVP (End-to-End Guide)

![StrideOn Home](Screenshots/Home.png)

StrideOn is a decentralized running game where real-world joggers conquer and defend territories by moving through them, powered by GPS + H3 grids and optionally settled on-chain (Very Network). This README is a complete hackathon guide to run the entire stack locally and demo the MVP.

Date: 2025-08-31

## Project Modules
- Android app: StrideonApp/
- Python FastAPI backend: StrideonBackend/
- Very Network integration (contracts + scripts): very-network-integration/
- Landing page (static): index.html

## Architecture (High-Level)
- Android client: map, trail drawing, loop closure visualization, presence/leaderboard screens (mock-first for reliability).
- Backend (FastAPI): health, profiles, presence, sessions, trails/claims, optional on-chain reads; Redis for hot path; Supabase/Postgres for durable data.
- Verychain: StrideonScores contract and utilities for future settlement and read-only endpoints during the hackathon.

![Architecture Diagram](Screenshots/architecture.png)

ASCII Diagram
- Android <-> FastAPI (HTTP/WebSocket planned)
- FastAPI <-> Redis (presence, hot state)
- FastAPI <-> Supabase/Postgres (results, profiles)
- FastAPI -> Verychain (read-only for now)

## Quick Start (10 minutes)

1) Start the backend
- Prerequisites: Docker + Docker Compose
- cd StrideonBackend
- Optional: create .env with your settings; not required for basic /health
- docker compose up --build
- Backend: http://127.0.0.1:8000
- Health: curl http://127.0.0.1:8000/health

Notes:
- CORS via ALLOWED_ORIGINS (default "*").
- Redis auto-started in compose for presence features.

2) Configure the Android app
- Emulator: uses http://10.0.2.2:8000 to reach your host.
- Physical device on LAN: set base URL to your host IP, e.g. http://192.168.1.50:8000
- How to change:
  - Open StrideonApp/app/build.gradle.kts and update:
    buildConfigField("String", "API_BASE_URL", '"http://10.0.2.2:8000"')

3) Run the Android app
- Open StrideonApp/ in Android Studio
- Build and run on an emulator or device
- Splash checks /health and shows a toast (Connected/Unavailable) then navigates to Welcome

4) Manual API testing (optional)
- Use StrideonBackend/test_main.http (JetBrains/VS Code HTTP client)
- Set variables at the top (host, jwt, city) and try /health, /profiles/me, etc.

## Configuration Reference
Backend env (StrideonBackend/.env):
- SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY, SUPABASE_ANON_KEY — needed for authenticated flows
- REDIS_URL — default redis://redis:6379/0 (docker-compose)
- DEBUG_USER_ID — bypass JWT locally for dev-protected routes
- ALLOWED_ORIGINS — comma-separated CORS list (default "*")
- VERY_RPC_URL — default http://127.0.0.1:8545
- VERY_CHAIN_ID — default 1337
- VERY_CONTRACT_ADDR — contract address if you deploy locally

Android app:
- INTERNET permission is enabled; cleartext HTTP allowed for local dev
- BuildConfig.API_BASE_URL controls backend URL

## Troubleshooting
- Emulator cannot reach backend — ensure Docker is running and app uses 10.0.2.2, not localhost
- Physical device cannot reach backend — use your host LAN IP; open port 8000 in firewall
- 401/403 API — some routes need Supabase JWT; use DEBUG_USER_ID for local only or provide a valid JWT
- CORS — set ALLOWED_ORIGINS appropriately

## Very Network Integration (optional on-chain)
Read-only endpoints allow fetching an on-chain leaderboard and scores.

Backend env:
- VERY_RPC_URL — RPC of Very/Hardhat (default http://127.0.0.1:8545)
- VERY_CHAIN_ID — default 1337
- VERY_CONTRACT_ADDR — StrideonScores address (from your deployment)

How to run locally:
- cd very-network-integration
- npm install
- npx hardhat node
- In another terminal: node deploy-hackathon.js
- Export the printed contract address as VERY_CONTRACT_ADDR

Endpoints:
- GET /verynet/health -> connection + latest block
- GET /verynet/leaderboard?count=10 -> [{rank,address,score}]
- GET /verynet/score/{address} -> {address,score}

Android:
- LeaderboardActivity currently uses mock UI for stability; network responses are logged for validation.

## Screenshots

- Welcome screen

![Welcome](Screenshots/welcome.png)

- Login and Register

![Login](Screenshots/login.png)

![Register](Screenshots/Register.png)

- Home and Map

![Home](Screenshots/Home.png)

![Map](Screenshots/Map.png)

- Power-ups UI

![Power-ups](Screenshots/Powerups.png)

![Power-ups 2](Screenshots/Powerups2.png)

## Subproject READMEs
- Backend: StrideonBackend/README.md (detailed setup, env, endpoints)
- Android: StrideonApp/README.md (architecture, demo steps, Supabase, Wepin notes)
- Verychain: very-network-integration/README.md (contracts, deploy, backend/mobile integration)

## Hackathon Checklist
- Demo flow: trail -> loop closure -> claim visualization (Android)
- Backend /health OK, presence stubs responding
- Optional: Verychain node + deploy script with contract address wired to backend
- Short screen recording (20–30s) of the gameplay loop
- All READMEs up-to-date with exact run steps and envs

## License
MIT unless otherwise specified. See subproject folders for details if present.



## Smoke Test (Automated)
A quick automated smoke test is included to verify that the backend is up and core endpoints respond.

Run:
- Ensure the backend is running (see Quick Start above).
- From the StrideonBackend directory:

```
cd StrideonBackend
python3 smoke_test.py --host http://127.0.0.1:8000
```

Optional JWT:
- Provide a Supabase JWT to also test an authenticated endpoint (/profiles/me):

```
python3 smoke_test.py --host http://127.0.0.1:8000 --jwt YOUR_SUPABASE_JWT
```

Notes:
- The script uses httpx if available; otherwise it automatically falls back to Python's urllib, so no extra installs are required to run basic checks.
- Exit code is 0 when all checks pass; non-zero otherwise, making it suitable for CI.
