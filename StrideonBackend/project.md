# StrideOn — The City Is Your Arena

A decentralized, move-to-earn game where your run becomes a strategic battle for territory on a live H3 hex grid. Built with a speed-first off-chain game loop and a trustless on-chain settlement layer on the Very Network.

---
Important: 2-Day Sprint (Aug 29–Aug 31, 2025)

We have only 2 days to deliver a demo-ready MVP slice. Scope is trimmed to essentials:
- Android app with live map + H3 overlay for one city area.
- Basic trail drawing and loop closure locally (happy path only).
- Presence stub (fake nearby runners) and minimal daily leaderboard mock.
- No on-chain integration in this sprint; simulate banked scores.

Deliverables by Day 2 (2025-08-31 EOD):
- Buildable APK with trail + loop closure demo and claim visualization.
- Prototype server (or local stub) with presence and cut detection placeholder.
- Short recording/gif of gameplay loop.
- README updated with instructions to run the demo.
---

## Vision & Goals
- Turn outdoor activity into a competitive, city-scale strategy game.
- Blend paper.io mechanics with real-world movement: draw trails, close loops, claim zones.
- Deliver a lag-free, real-time experience while ensuring verifiable, tamper-proof results on-chain.

## Core Gameplay
- Trail & Claim: As you run, you create a live trail on an H3 hex grid. Close a loop back to your existing territory to claim the enclosed area.
- Tactical Risk: Your active trail is vulnerable until you bank it. Rivals can cut it by crossing your line, invalidating the claim.
- Territory Control: Expand, defend, and outmaneuver nearby runners in real time.

## MVP Scope (Private Beta)
- Android app (Chandigarh city focus) with:
  - Live map + H3 grid overlay
  - Presence pings and nearby runners
  - Trail drawing and polygon/zonal claiming after loop closure
  - Lightweight daily leaderboard
- Closed beta; centralized ops and controlled access.

## Architecture Overview
Speed off-chain, trust on-chain.

Tech choice for this repo: Python FastAPI + Supabase (Postgres/Auth/Realtime). Prior Node/TypeScript references are deprecated for this MVP; use Python + Supabase throughout.

- Client (Android): GPS, map visualization, trail rendering, local validations, power-up UX.
- Game Server (Centralized, Python FastAPI): Real-time state, collision/cut detection, H3 grid ops, Redis-backed low-latency cache; Supabase for Postgres/Auth/Realtime.
- Very Network (On-Chain): Finalized checkpoints (banked claims), daily leaderboard settlement, reward distribution in VERY tokens.
- Storage:
  - Redis: hot game state, live sessions, proximity sets
  - Postgres: audit logs, aggregated results, player profiles, anti-cheat signals
  - IPFS (optional later): proofs and snapshots

### Data Flow
1. Client streams GPS points -> Server smooths, snaps to H3 cells.
2. Server maintains active trails, checks collisions and loop closures.
3. On loop closure: computes enclosed polygon via grid flood-fill/graph ops, proposes claim.
4. On cut event: invalidates claimant’s active trail; awards intercept bonus (off-chain tally).
5. Periodic checkpointing: Players “bank” scores; server submits Merkle root/batch to smart contract for finalization.
6. Daily at T+24h: Contract settles leaderboard and distributes rewards.

## Key Components
- Android App
  - Kotlin, Google Maps/MapLibre
  - Foreground service for location
  - WebSocket (or gRPC) for live updates
  - Offline queue for intermittent connectivity
- Game Server
  - Python (FastAPI + Uvicorn + asyncio) for low-latency API/WebSockets (preferred for this MVP)
  - WebSocket gateway, Redis Pub/Sub, geo-indexing
  - H3 library for hex ops
  - Anti-cheat heuristics (speed thresholds, teleport checks)
- Smart Contracts (Very Network)
  - Escrow & Rewards: staking/claim banking
  - Leaderboard settlement: Merkle root verification
  - Power-up marketplace: Shield, Ghost Mode, Speed Boost

## H3 Grid Mechanics
- Resolution selection: Start at res 9–10 (city-scale granularity). Tune for density.
- Trail snapping: Map GPS to H3 cells; deduplicate; maintain ordered path.
- Loop detection: Trail intersects owned boundary -> close.
- Area claim: Compute interior cells via boundary walk and fill; exclude rival territory unless enclosed.

## Real-Time Mechanics
- Presence: Server broadcasts regional channels (spatial shards by H3 ring).
- Cut Detection: Segment–segment intersection of rival paths projected onto H3 edges.
- Latency Budget: <150 ms round trip in-region; Redis for pub/sub fanout; edge nodes if needed.

## On-Chain Interactions
- Bank Score: Player signs an off-chain message; server aggregates into batch; submits Merkle root and IPFS reference.
- Distribute Rewards: Daily cron triggers contract settlement; tokens sent to top N per city.
- Verifiability: Players can prove inclusion via Merkle proofs in-app.

## Economy & Power-Ups
- Earnings: Daily city leaderboards award VERY tokens.
- Sinks (spend):
  - Shield: Temporary invulnerability to cuts on active trail
  - Ghost Mode: Hidden from local map for a short duration
  - Speed Boost: Higher effective claim rate for limited time
- Balancing: Dynamic pricing based on demand; cooldowns; anti-abuse rules.

## Anti-Cheat & Fairness
- Client: Foreground service + motion APIs; root/jailbreak detection; obfuscation.
- Server: Velocity/acceleration bounds; improbable path filters; GPS drift smoothing; device fingerprinting.
- Audits: Randomized proof requests; replay verification using submitted GPS traces; anomaly scoring.
- On-Chain: Settlement only for server-verified, signed batches.

## Privacy & Safety
- Minimal location retention; aggregation for leaderboards.
- Opt-in anonymized handles; differential privacy for public heatmaps.

## Observability
- Metrics: active users, avg latency, cuts/minute, loop closures/hr, area claimed, DAU/WAU, retention, fraud rate.
- Tracing: Server spans for update pipeline; client logs (opt-in) with sampling.

## Rollout Plan & Milestones
1. Week 0–1: Prototype
   - Map + H3 overlay, live trail, mock server, loop closure locally.
2. Week 2–3: Real-Time Server Alpha
   - WebSocket gateway, Redis cache, presence channels, cut detection v1.
3. Week 4: MVP Beta (Chandigarh)
   - Bank score checkpoints, basic leaderboard, invite-only access.
4. Week 5–6: On-Chain Settlement
   - Merkle batch submissions, daily reward distribution.
5. Week 7+: Power-Ups & Guilds
   - Shield/Ghost/Speed marketplace; Guild formation via Verychat integrations.

Target start: 2025-08-29 (local). Adjust timelines per team capacity.

## Testing Strategy
- Unit: H3 ops, loop/area fill, cut detection.
- Simulation: Bot runners in virtual city grid; load tests (1k concurrent).
- Field: Small cohorts in Chandigarh neighborhoods.

## Risks & Mitigations
- GPS Noise: Kalman filter, map matching, min step thresholds.
- Latency Spikes: Regional shards, autoscaling, backpressure.
- Cheating: Multi-layer heuristics + audits; progressive bans.
- Token Economics: Cap daily rewards; dynamic pricing; season resets.

## Operations (Private Beta)
- Access Control: Invite codes bound to device fingerprints.
- Support: In-app report, Slack/Verychat triage.
- Incident Runbooks: Latency, data corruption, chain delays.

## Next Steps
- Stand up map + H3 overlay in Android app.
- Spin up prototype server with Redis; implement presence + live trail.
- Define contract interfaces for banking & rewards; set up testnet deployment.
- Instrument metrics and create a daily settlement job.

## 2-Day Sprint — Next Steps (Aug 29–31, 2025)

Focus: Demo-ready MVP slice in 48 hours. Keep scope tight and prioritize visible loop-closure flow.

Day 1 (Build Core Loop)
- Android: Map + H3 overlay visible in Chandigarh area. ✓
- Trail drawing from GPS or mock path; close loop and visualize claimed area. *
- Presence stub: show 2–3 fake runners nearby. *
- Minimal leaderboard mock screen with static data. *

Day 2 (Polish + Demo)
- Cut detection placeholder (UI-only event) and error-handling for GPS loss. 
- Banked score simulation: local tally when tapping "Bank".
- Record a 20–30s screen capture of the gameplay loop.
- Finalize README demo instructions and known limitations.

How to Run the Demo
- Requirements: Android Studio Hedgehog+; Android 10+ device/emulator with Google Play Services.
- Steps:
  1) Open this project in Android Studio and Sync Gradle.
  2) Run the app on a device (recommended) and allow location permissions.
  3) Toggle mock location if indoors; the app works with slow simulated movement.
  4) Use the UI to draw a short trail; return to your territory to close a loop and see the claim.
  5) Presence and leaderboard screens show stubbed data for this sprint.

Deliverables Checklist (Due 2025-08-31 EOD)
- [ ] Buildable APK demonstrating trail -> loop closure -> claim visualization.
- [ ] Presence stub and leaderboard mock accessible from the app.
- [ ] Short video/gif of the gameplay loop.
- [ ] This README reflects demo steps and limitations.

---

## Supabase + Python Integration Guide (MVP)

This project uses Supabase (Postgres + Auth + Realtime) for quick iteration. The Python service is an optional prototype for ingesting GPS points, snapping to H3, and writing to Supabase.

### Prerequisites
- Supabase account and a new project (Region close to users).
- Supabase keys from Project Settings -> API:
  - SUPABASE_URL
  - SUPABASE_ANON_KEY (client)
  - SUPABASE_SERVICE_ROLE_KEY (server, keep secret)
- Python 3.11+

### Environment variables (.env)
- Client (Android to be added later): uses ANON key.
- Server (Python): uses SERVICE ROLE key.

Example .env
- SUPABASE_URL=https://YOUR-PROJECT.supabase.co
- SUPABASE_SERVICE_ROLE_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...

### Supabase project setup
1) Create project -> note URL and keys.
2) Run the SQL below (Database -> SQL Editor) to create tables and policies.
3) Verify RLS policies allow users to read public data and write only their own rows.
4) Enable Realtime on tables you want to stream (presence, sessions, gps_points if needed).

---

## Database Design (ERD)

High-level entities and relationships:
- profiles (1:1 auth.users): user profile and public handle
- sessions (1:N to users): a running activity session
- gps_points (N:1 to sessions): recorded GPS samples with H3 index
- trails (N:1 to sessions, N:1 to users): logical trail aggregation for a session
- claims (N:1 to sessions, N:1 to users): area claims from loop closures
- cuts (N:1 to sessions): records cut events between users
- runners_presence (1:1 per user): latest location for presence channels
- leaderboard_daily (N:1 to users): daily score snapshots by city

ERD (textual):
- auth.users (Supabase managed)
  - profiles.user_id PK, FK -> auth.users.id (1:1)
- profiles.user_id (PK) ──< sessions.user_id
- sessions.id (PK) ──< gps_points.session_id
- sessions.id (PK) ──< trails.session_id
- sessions.id (PK) ──< claims.session_id
- sessions.id (PK) ──< cuts.session_id
- profiles.user_id (PK) ──< trails.user_id, claims.user_id, leaderboard_daily.user_id
- profiles.user_id (PK) ── runners_presence.user_id (1:1)

Notes:
- H3 storage: keep h3_index at chosen res (9–10), and optionally h3_parent (coarser) for aggregation.
- Index frequently filtered columns: user_id, session_id, occurred_at/ts, city.
- RLS: owner-based policies on user_id; public read on some aggregates.

---

## Supabase SQL Schema (run in SQL Editor)

-- Extensions
create extension if not exists vector;
create extension if not exists pgcrypto;

-- Enum types
do $$ begin
  create type trail_status as enum ('active','banked','cut');
exception when duplicate_object then null; end $$;

-- profiles (1:1 auth.users)
create table if not exists public.profiles (
  user_id uuid primary key references auth.users(id) on delete cascade,
  username text unique,
  avatar_url text,
  city text,
  created_at timestamptz not null default now()
);
alter table public.profiles enable row level security;

-- sessions (per run)
create table if not exists public.sessions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(user_id) on delete cascade,
  city text,
  started_at timestamptz not null default now(),
  ended_at timestamptz,
  status text check (status in ('active','ended')) default 'active'
);
alter table public.sessions enable row level security;
create index if not exists idx_sessions_user on public.sessions(user_id);
create index if not exists idx_sessions_city on public.sessions(city);

-- gps_points (raw stream with H3)
create table if not exists public.gps_points (
  id bigserial primary key,
  session_id uuid not null references public.sessions(id) on delete cascade,
  ts timestamptz not null,
  lat double precision not null,
  lng double precision not null,
  h3_res int not null,
  h3_index text not null
);
alter table public.gps_points enable row level security;
create index if not exists idx_gps_session_ts on public.gps_points(session_id, ts);
create index if not exists idx_gps_h3 on public.gps_points(h3_index);

-- trails (logical grouping)
create table if not exists public.trails (
  id uuid primary key default gen_random_uuid(),
  session_id uuid not null references public.sessions(id) on delete cascade,
  user_id uuid not null references public.profiles(user_id) on delete cascade,
  status trail_status not null default 'active',
  points_count int default 0,
  length_m double precision default 0,
  updated_at timestamptz not null default now()
);
alter table public.trails enable row level security;
create index if not exists idx_trails_user on public.trails(user_id);
create index if not exists idx_trails_session on public.trails(session_id);

-- claims (area after loop closure)
create table if not exists public.claims (
  id uuid primary key default gen_random_uuid(),
  session_id uuid not null references public.sessions(id) on delete cascade,
  user_id uuid not null references public.profiles(user_id) on delete cascade,
  area_m2 numeric not null,
  h3_cells text[] not null,
  created_at timestamptz not null default now()
);
alter table public.claims enable row level security;
create index if not exists idx_claims_user on public.claims(user_id);
create index if not exists idx_claims_session on public.claims(session_id);

-- cuts (intercepts)
create table if not exists public.cuts (
  id uuid primary key default gen_random_uuid(),
  session_id uuid not null references public.sessions(id) on delete cascade,
  attacker_id uuid not null references public.profiles(user_id) on delete cascade,
  victim_id uuid not null references public.profiles(user_id) on delete cascade,
  occurred_at timestamptz not null default now()
);
alter table public.cuts enable row level security;
create index if not exists idx_cuts_session on public.cuts(session_id);
create index if not exists idx_cuts_attacker on public.cuts(attacker_id);

-- presence (latest ping per user)
create table if not exists public.runners_presence (
  user_id uuid primary key references public.profiles(user_id) on delete cascade,
  lat double precision,
  lng double precision,
  h3_index text,
  updated_at timestamptz not null default now()
);
alter table public.runners_presence enable row level security;

-- daily leaderboard snapshot (denormalized for speed)
create table if not exists public.leaderboard_daily (
  id bigserial primary key,
  day date not null,
  city text,
  user_id uuid not null references public.profiles(user_id) on delete cascade,
  score integer not null default 0,
  rank integer,
  unique(day, city, user_id)
);
alter table public.leaderboard_daily enable row level security;
create index if not exists idx_lb_day_city_score on public.leaderboard_daily(day, city, score desc);

-- Basic owner RLS policies
-- profiles: user can read all, upsert own row
drop policy if exists profiles_read_all on public.profiles;
create policy profiles_read_all on public.profiles
  for select using (true);
drop policy if exists profiles_upsert_own on public.profiles;
create policy profiles_upsert_own on public.profiles
  for insert with check (user_id = auth.uid());
drop policy if exists profiles_update_own on public.profiles;
create policy profiles_update_own on public.profiles
  for update using (user_id = auth.uid());

-- sessions: user can CRUD their own
drop policy if exists sessions_rw_own on public.sessions;
create policy sessions_rw_own on public.sessions
  for all using (user_id = auth.uid()) with check (user_id = auth.uid());

-- gps_points: write if session belongs to user; read own and recent public for debug
drop policy if exists gps_points_insert_own on public.gps_points;
create policy gps_points_insert_own on public.gps_points
  for insert with check (
    exists (select 1 from public.sessions s where s.id = session_id and s.user_id = auth.uid())
  );
drop policy if exists gps_points_read_own on public.gps_points;
create policy gps_points_read_own on public.gps_points
  for select using (
    exists (select 1 from public.sessions s where s.id = session_id and s.user_id = auth.uid())
  );

-- trails, claims, cuts: owner-based
drop policy if exists trails_rw_own on public.trails;
create policy trails_rw_own on public.trails
  for all using (user_id = auth.uid()) with check (user_id = auth.uid());
drop policy if exists claims_rw_own on public.claims;
create policy claims_rw_own on public.claims
  for all using (user_id = auth.uid()) with check (user_id = auth.uid());
drop policy if exists cuts_read_own on public.cuts;
create policy cuts_read_own on public.cuts
  for select using (
    attacker_id = auth.uid() or victim_id = auth.uid()
  );

-- presence: upsert own, read all
drop policy if exists presence_read_all on public.runners_presence;
create policy presence_read_all on public.runners_presence
  for select using (true);
drop policy if exists presence_upsert_own on public.runners_presence;
create policy presence_upsert_own on public.runners_presence
  for insert with check (user_id = auth.uid());
drop policy if exists presence_update_own on public.runners_presence;
create policy presence_update_own on public.runners_presence
  for update using (user_id = auth.uid());

-- leaderboard_daily: read all, write service role only
drop policy if exists lb_read_all on public.leaderboard_daily;
create policy lb_read_all on public.leaderboard_daily
  for select using (true);

-- Ensure RLS is enabled (it is by default on new tables above)

---

## Python Backend Quickstart (Prototype)

This example ingests GPS points, computes H3 indices, and writes to Supabase. Use SERVICE ROLE key for server-side writes.

### Install
- python -m venv .venv && source .venv/bin/activate
- pip install fastapi uvicorn supabase==2.* h3==4.* python-dotenv

### Run
- export $(grep -v '^#' .env | xargs)  # or set env manually
- uvicorn app:app --reload

### app.py (minimal example)
```python
import os
from datetime import datetime, timezone
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel, Field
from supabase import create_client
import h3

SUPABASE_URL = os.environ["SUPABASE_URL"]
SUPABASE_KEY = os.environ["SUPABASE_SERVICE_ROLE_KEY"]
sb = create_client(SUPABASE_URL, SUPABASE_KEY)

app = FastAPI()

class PointIn(BaseModel):
    session_id: str
    lat: float = Field(ge=-90, le=90)
    lng: float = Field(ge=-180, le=180)
    ts: datetime | None = None
    h3_res: int = 9

@app.post("/ingest")
def ingest(p: PointIn):
    ts = p.ts or datetime.now(timezone.utc)
    h3_index = h3.latlng_to_cell(p.lat, p.lng, p.h3_res)
    data = {
        "session_id": p.session_id,
        "ts": ts.isoformat(),
        "lat": p.lat,
        "lng": p.lng,
        "h3_res": p.h3_res,
        "h3_index": h3_index,
    }
    try:
        res = sb.table("gps_points").insert(data).execute()
        return {"ok": True, "inserted": len(res.data)}
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))

@app.post("/presence")
def presence(p: PointIn):
    h3_index = h3.latlng_to_cell(p.lat, p.lng, p.h3_res)
    user_id = os.environ.get("DEBUG_USER_ID")  # for local testing
    if not user_id:
        raise HTTPException(status_code=400, detail="Set DEBUG_USER_ID for local testing")
    upsert = {
        "user_id": user_id,
        "lat": p.lat,
        "lng": p.lng,
        "h3_index": h3_index,
        "updated_at": datetime.now(timezone.utc).isoformat(),
    }
    try:
        sb.table("runners_presence").upsert(upsert, on_conflict="user_id").execute()
        return {"ok": True}
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))
```

### Testing locally
- Create a session row manually in Supabase (sessions with your user_id) or adjust the RLS temporarily while testing.
- Then POST to localhost:8000/ingest with JSON:
```json
{ "session_id":"<uuid>", "lat":30.7333, "lng":76.7794, "h3_res":9 }
```

### Notes
- In production, authenticate requests and map auth.uid() to user_id; the Python service should verify JWTs from the Android client or operate with service role behind a trusted gateway.
- Keep SERVICE ROLE key on server only.
- You can use Supabase Realtime to watch runners_presence changes for presence channels in the app.

---

## Redis-First Game State (Performance Plan)

Goal: Keep the hot loop entirely in memory for sub-150 ms latency. Persist only finalized outcomes and aggregates.

What lives in Redis (hot, low-latency):
- active:session:{sessionId}:point_seq -> compacted polyline or H3 path
- active:user:{userId}:trail -> current trail edges/cells
- active:cells:claimed -> set/hash for quick claim checks
- geo:presence -> GEOSET of (lng,lat,userId) for proximity queries
- cuts:events -> recent cut events (ring buffer with TTL)
- channels:region:{h3} -> pub/sub fanout for presence and events

TTLs and eviction:
- active session/trail keys: TTL 10–30 minutes after last update
- cuts and transient events: TTL 2–5 minutes
- presence GEO entries: TTL 30–90 seconds

Persistence contract (Postgres):
- Only write finalized, banked results, daily leaderboard snapshots, and audit logs as needed.
- gps_points, trails, cuts tables are optional archives, not used in hot path. Keep disabled by default or write asynchronously via background jobs if needed.

Client-to-server loop:
- Client streams GPS -> server updates Redis path, checks loop closure/cuts entirely in memory -> when user taps "Bank", server computes result and writes a single row to Postgres.

Recommended Redis structures:
- Use Redis Streams for audit of ingested GPS if needed (stream:gps), capped length.
- Use SET/JSON for user power-up state during a session (active effects with expiries), mirrored to DB on use.

## Web3 Data Storage Plan

What goes on-chain vs off-chain:
- On-chain (later phases): Merkle-rooted settlement of banked results and reward distribution.
- Off-chain (now): Wallet linking, power-up catalog/inventory/usage, banked_results rows, daily leaderboard.

Wallet connection (Wepin-only):
- No off-chain wallets table. Link Wepin and store only profiles.wepin_user_id and profiles.wepin_address after signature verification.
- Address lifecycle is managed by Wepin; if it changes, the user re-links and we overwrite profiles.wepin_address.

Power-ups:
- Catalog is static/configurable (powerups table) with ids: shield, ghost, speed.
- User inventory (user_powerups) tracks quantities; decremented on use.
- Usage logs (powerup_uses) record in-session activation along with metadata; these logs are off-chain proofs if needed later.

Results persistence:
- banked_results table stores the score/area claimed for a checkpoint with optional IPFS CID and signature. These are inputs for Merkle batching later.

Security notes:
- RLS enforces owner access. Service role performs settlements and leaderboard writes.
- Keep SERVICE ROLE key server-side only; mobile uses JWT from Supabase Auth.

## Android Integration Stubs (Future Work)
- Add supabase-kt or HTTP client with Supabase REST for presence and session writes.
- Use Realtime channels to subscribe to runners_presence by H3 ring around the player.
- Keep within sprint scope: for now these are stubs; presence/leaderboard can be mocked on-device.


---

## Wepin Wallet Integration (Login, Linking, Rewards)

Note: Wepin-only mode is authoritative for this MVP — no off-chain wallets table. We store only profiles.wepin_user_id and profiles.wepin_address (see the “Wepin-only Mode” section below). Any earlier mention of a public.wallets table is deprecated for this MVP and kept only for historical context.

Goal: Let players log in with Supabase Auth, link or create a Wepin wallet, and receive VERY rewards to that wallet. We keep the hot game loop off-chain/Redis-first; only finalized results and wallet links are in Postgres.

Key Concepts
- Identity: Supabase Auth (email/OTP/social) for app sessions; profiles.wepin_user_id optionally binds to Wepin.
- Wepin linkage only: No off-chain wallets table. Store profiles.wepin_user_id and profiles.wepin_address; Wepin holds keys.
- Rewards: Players accrue off-chain “VERY points” via gameplay; daily job settles to token transfers (Very Network later). For now, simulate transfer or record intents.

Login and Linking Flows
1) First-time user
   - Step A: Supabase Auth sign-in on Android (email OTP, phone, or social).
   - Step B: Offer "Create Wepin Wallet" or "Link Existing".
     - Create: Initialize Wepin SDK, create wallet, obtain wepin_user_id and wallet address.
     - Link existing: Use Wepin SDK authentication to fetch account and primary address.
   - Step C: Server-side verification challenge (Prevents spoofing):
     - App requests a nonce from backend.
     - App asks Wepin SDK to sign the nonce with the selected address.
     - Backend verifies signature and updates profiles.wepin_user_id and profiles.wepin_address.

2) Returning user
   - App signs in with Supabase Auth.
   - If profiles.wepin_user_id exists, initialize Wepin SDK session and fetch wallet(s); otherwise prompt linking.

3) Multiple wallets
   - Allow multiple rows in wallets per user_id; use is_primary to select reward destination.

Android Client Sketch (Kotlin)
- Pseudocode outline of the flow; exact Wepin SDK API names may differ.

```kotlin
class WalletLinker(
    private val supabaseJwtProvider: () -> String,
    private val backend: BackendApi,
    private val wepin: WepinSdk
) {
    suspend fun ensureLinked(): WalletInfo {
        val session = backend.getSessionProfile(auth = supabaseJwtProvider())
        if (session.wepinUserId != null) {
            return wepin.currentWallet() ?: wepin.restore(session.wepinUserId)
        }
        // Create or select wallet in Wepin
        val wallet = wepin.createOrSelectWallet() // returns address + wepinUserId
        // Server challenge -> sign -> verify
        val nonce = backend.createNonce(auth = supabaseJwtProvider())
        val signature = wepin.signMessage(wallet.address, nonce)
        backend.linkWepinWallet(
            auth = supabaseJwtProvider(),
            body = LinkReq(
                address = wallet.address,
                chain = "evm",
                wepinUserId = wallet.wepinUserId,
                signature = signature,
                nonce = nonce
            )
        )
        return wallet
    }
}
```

Backend (Python FastAPI) Sketch
- Reuse Supabase service role for DB writes. Verify client JWT for user_id. Verify EVM signature of the nonce.

```python
from fastapi import FastAPI, Depends, HTTPException
from supabase import create_client
from pydantic import BaseModel
import os, time
from eth_account.messages import encode_defunct
from eth_account import Account

sb = create_client(os.environ["SUPABASE_URL"], os.environ["SUPABASE_SERVICE_ROLE_KEY"])

NONCES = {}  # in-memory; use Redis in prod

def get_user_id_from_jwt(jwt: str) -> str:
    # Validate Supabase JWT (call /auth/v1/user or verify locally). Return user id.
    # Placeholder for brevity
    return "<decoded-user-id>"

class NonceOut(BaseModel):
    nonce: str
    ttl: int

@app.post("/auth/nonce", response_model=NonceOut)
def create_nonce(authorization: str = ""):
    user_id = get_user_id_from_jwt(authorization)
    nonce = f"strideon:{user_id}:{int(time.time())}"
    NONCES[user_id] = nonce
    return {"nonce": nonce, "ttl": 300}

class LinkReq(BaseModel):
    address: str
    wepinUserId: str
    signature: str
    nonce: str

@app.post("/wepin/link")
def link_wallet(req: LinkReq, authorization: str = ""):
    user_id = get_user_id_from_jwt(authorization)
    if NONCES.get(user_id) != req.nonce:
        raise HTTPException(400, "Invalid nonce")
    # Verify EVM-style signature
    msg = encode_defunct(text=req.nonce)
    recovered = Account.recover_message(msg, signature=req.signature)
    if recovered.lower() != req.address.lower():
        raise HTTPException(400, "Signature mismatch")
    # Update profile only (Wepin-only)
    sb.table("profiles").upsert({
        "user_id": user_id,
        "wepin_user_id": req.wepinUserId,
        "wepin_address": req.address
    }, on_conflict="user_id").execute()
    return {"ok": True}
```

Rewarding VERY Points
- Accrual (off-chain):
  - During a session, keep live state in Redis; when user taps Bank, compute area/score and insert a public.banked_results row tied to user_id and session_id.
- Daily settlement (cron):
  - Aggregate yesterday’s results into leaderboard_daily.
  - Determine top-N per city and their reward amounts.
  - Create transfer intents to the primary wallet address for each winner.
  - Phase 1 (MVP): Store intents in DB (e.g., a transfers_intent table or metadata on leaderboard rows) and simulate transfer in-app.
  - Phase 2: Execute real token transfers on the Very Network to the stored EVM address (Wepin wallet). Record tx hash back in DB.

How login and rewards connect
- Supabase Auth -> user_id
- Wallet link -> wallets row (address, verified_at) + profiles.wepin_user_id
- Bank results -> banked_results rows per user
- Daily job -> leaderboard_daily + token transfer to wallets.is_primary = true address

Database Touchpoints
- profiles.wepin_user_id: present when Wepin is linked.
- wallets.metadata: stores provider info and Wepin-specific identifiers.
- banked_results, leaderboard_daily: input and outputs for rewards.

Edge Cases & Security
- Signature replay: Nonces are single-use and expire quickly (store in Redis with TTL).
- Multiple devices: Linking is per user_id; Wepin SDK session should be restored via wepin_user_id.
- Wallet changes: Changing primary wallet requires re-verification (flip is_primary flags transactionally).
- Account recovery: Handled by Wepin SDK; upon recovery, address might change; require re-link and set as primary.
- RLS: Owner-only policies already enforce that users can only read/modify their wallets and results.
- Webhooks: If Wepin provides webhooks for account changes, process them server-side (service role) to update wallets.

Operational Notes
- Keep service role keys server-side only.
- Use environment flags to simulate transfers during MVP.
- Log reward decisions with reproducible inputs for audits.


---

## FAQ

Q: If we use Wepin, why is there a wallets table?
- Identity vs. payout: Supabase Auth gives us the in‑app identity (auth.users/profile). Wepin manages keys and signing. The wallets table is our app’s off‑chain linkage for where to send rewards and to record verification state.
- Multiple wallets: A player can have more than one address (e.g., recovered/new). We store them all and mark one as is_primary for reward routing.
- Provider metadata: We keep metadata like provider=wepin and wepin_user_id for restoration and audits; we never store private keys.
- Audits and history: We record when an address was verified (verified_at) and can show an audit trail of reward destinations over time.
- Future‑proofing: If we ever support another wallet provider, the same table works (chain column, metadata), keeping the app provider‑agnostic.

Implementation notes
- profiles.wepin_user_id binds a Supabase user to their Wepin account for quick restore.
- public.wallets enforces owner‑only access via RLS; only service role can perform administrative operations.
- We enforce exactly one primary wallet per user via a partial unique index (idx_wallets_one_primary_per_user).
- Rewards jobs target the address where is_primary=true.


---

# Wepin-only Mode (No off-chain wallets)

Important change: We removed the off-chain wallets table from the schema and will rely solely on Wepin for key custody. Our database only stores the Wepin linkage on the user profile for payout/routing.

What we store
- profiles.wepin_user_id: The user identifier from Wepin (for restore on new devices).
- profiles.wepin_address: The current payout EVM address provided by Wepin.

What we do NOT store
- No public.wallets table, no multiple addresses, no primary-flag logic off-chain.
- No off-chain custody or key material.

Login + Linking flow (updated)
1) User signs in via Supabase Auth.
2) App initializes Wepin SDK.
3) App requests a backend nonce and signs it with the Wepin wallet to prove control.
4) Backend verifies signature and updates only the profiles row: wepin_user_id + wepin_address.

Updated backend sketch (Python FastAPI)
```python
from fastapi import FastAPI, HTTPException, Header
from pydantic import BaseModel
from supabase import create_client
from eth_account.messages import encode_defunct
from eth_account import Account
import os, time

app = FastAPI()
sb = create_client(os.environ["SUPABASE_URL"], os.environ["SUPABASE_SERVICE_ROLE_KEY"])
NONCES = {}

def get_user_id_from_jwt(jwt: str) -> str:
    # Validate Supabase JWT (call /auth/v1/user). Return user id.
    return "<decoded-user-id>"

class NonceOut(BaseModel):
    nonce: str
    ttl: int

@app.post("/auth/nonce", response_model=NonceOut)
def create_nonce(authorization: str = Header("")):
    user_id = get_user_id_from_jwt(authorization)
    nonce = f"strideon:{user_id}:{int(time.time())}"
    NONCES[user_id] = nonce
    return {"nonce": nonce, "ttl": 300}

class LinkReq(BaseModel):
    address: str
    wepinUserId: str
    signature: str
    nonce: str

@app.post("/wepin/link")
def link_wepin(req: LinkReq, authorization: str = Header("")):
    user_id = get_user_id_from_jwt(authorization)
    if NONCES.get(user_id) != req.nonce:
        raise HTTPException(400, "Invalid nonce")
    msg = encode_defunct(text=req.nonce)
    recovered = Account.recover_message(msg, signature=req.signature)
    if recovered.lower() != req.address.lower():
        raise HTTPException(400, "Signature mismatch")
    # Update profile only
    sb.table("profiles").upsert({
        "user_id": user_id,
        "wepin_user_id": req.wepinUserId,
        "wepin_address": req.address
    }, on_conflict="user_id").execute()
    return {"ok": True}
```

Rewards routing (updated)
- Daily settlement sends rewards to profiles.wepin_address.
- If a user changes Wepin address (e.g., recovery), they must re-link. The new address overwrites profiles.wepin_address after verification.

Doc note
- Any mentions of a public.wallets table earlier in this README are deprecated for this MVP. Use profiles.wepin_user_id and profiles.wepin_address only.


---

## Android: Wepin Login Library Setup (Kotlin)

Official docs: https://docs.wepin.io/en/widget-integration/android-java-and-kotlin-sdk/login-library/installation

Summary steps (follow the official guide for exact coordinates and API names):
- Get your Wepin credentials from the Wepin Developer Console (e.g., appId / projectId).
- Gradle setup (project/app): add the repositories and dependency per the docs; use the latest version from the link above.
- Initialize the Wepin Login Library in your Application or first Activity with your credentials.
- Implement the login/link flow:
  - Sign in to Supabase Auth.
  - Acquire a nonce from your backend.
  - Ask the Wepin SDK to sign the nonce with the selected wallet address.
  - POST the signature, address, and wepin_user_id to the backend to verify and store on the profile.

Notes:
- Keep any Wepin keys and IDs out of the repo; parameterize via BuildConfig or remote config.
- For this MVP, we use Wepin-only mode (no wallets table). The backend stores profiles.wepin_user_id and profiles.wepin_address.

## Verychain (Very Network) Integration

Official intro: https://wp.verylabs.io/verychain/introduce-verychain

How we use Verychain:
- MVP (now): simulate reward distribution off-chain. Write intents/snapshots to Postgres and show them in the UI.
- Phase 2 (later): on daily settlement, send VERY token transfers on Verychain to profiles.wepin_address. Store tx hash back in DB.

Implementation outline:
- Off-chain accrual: write banked_results at “Bank” events; aggregate to leaderboard_daily.
- Settlement job: compute rewards; in MVP, create simulated transfer intents. Later, call Verychain contracts and persist tx metadata.
- Address source: profiles.wepin_address (from Wepin link flow). No off-chain wallets table.
- Auditing: log inputs/outputs for reproducibility; secure service keys server-side only.



## Data storage policy: Redis for hot-path, Postgres for results (Do not store unnecessary data)
To keep gameplay snappy and costs low, we do not persist high-frequency game state in SQL. Only results and essential Web3/account data are stored in Postgres.

What lives in Redis (ephemeral, low-latency):
- GPS stream per session: XADD gps:{session_id}:stream MAXLEN ~ 1000 ts=... lat=... lng=... h3_res=... h3_index=...
- Presence: SETEX presence:{user_id} <ttl_seconds> { lat, lng, h3_index, ts }; GEOADD presence:city:{city} lng lat {user_id}
- Active trails: HSET trail:{session_id} user_id {user_id} status active points_count ... length_m ...; SADD trails_by_user:{user_id} {session_id}; EXPIRE trail:{session_id} <ttl>
- Cuts/intercepts: XADD cuts:city:{city}:stream MAXLEN ~ 500 occurred_at=... attacker=... victim=... session=...
- Pub/Sub fanout to interested shards (nearby H3 rings) for live updates

What is persisted in Postgres (auditable, durable):
- profiles: includes wallet linkage (wepin_user_id, wepin_address)
- sessions: session metadata (start/end/status)
- claims: finalized loop-closure claims (area, cells)
- banked_results: finalized outcomes used for rewards settlement
- leaderboard_daily: denormalized daily rankings
- powerups, user_powerups, powerup_uses: catalog, inventory, and usage logs

Explicitly NOT stored in Postgres:
- gps_points, trails, cuts, runners_presence (moved to Redis)

Wallet/Web3 data:
- Wepin-only mode: no wallets table. Store wallet linkage on profiles (wepin_user_id, wepin_address). Rewards are routed to profiles.wepin_address.
- Indexes: schema.sql creates idx_profiles_wepin_address to support fast lookups by address.

Redis TTL recommendations (tune as needed):
- presence:{user_id}: 60–120s
- trail:{session_id}: match expected max session inactivity window (e.g., 10–30 min)
- streams (gps, cuts): use MAXLEN trimming and/or periodic cleanup workers

Migration notes (if you previously created SQL tables for hot-path data):
- Drop tables gps_points, trails, cuts, runners_presence and related policies. The current schema.sql already omits them and documents Redis alternatives.

Env setup
- REDIS_URL=redis://<host>:<port>/<db>
- Postgres/Supabase as per your environment; run db/schema.sql in Supabase SQL editor.


## Running with Docker

You can run the API in Docker. Make sure you have Docker installed.

1) Build the image

   docker build -t strideon-backend:latest .

2) Run the container (set your envs accordingly)

   docker run --rm -p 8000:8000 \
     -e SUPABASE_URL=... \
     -e SUPABASE_SERVICE_ROLE_KEY=... \
     -e SUPABASE_ANON_KEY=... \
     -e DEBUG_USER_ID=... \
     -e REDIS_URL=redis://host.docker.internal:6379/0 \
     strideon-backend:latest

3) Or use docker-compose (spins up Redis too)

   # create a .env file (optional) with your secrets
   # SUPABASE_URL=...
   # SUPABASE_SERVICE_ROLE_KEY=...
   # SUPABASE_ANON_KEY=...
   # DEBUG_USER_ID=...

   docker compose up --build

The API will be available at http://localhost:8000 and a health check at /health.
