-- StrideOn Database Schema (Supabase/Postgres)
-- Canonical schema file: StrideonBackend/schema.sql (run this in Supabase). This copy is kept in sync for convenience.
-- Usage:
-- - Run this in Supabase SQL Editor (recommended) or any PostgreSQL 14+ compatible environment.
-- - Supabase notes: auth.users exists; RLS is enabled by default on new tables.
-- - Adjust policies to your security model if running outside Supabase.

-- ===== Extensions =====
create extension if not exists vector;
create extension if not exists pgcrypto;

-- ===== Enum types =====
DO $$ BEGIN
  CREATE TYPE trail_status AS ENUM ('active','banked','cut');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

-- ===== profiles (1:1 auth.users) =====
CREATE TABLE IF NOT EXISTS public.profiles (
  user_id uuid PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  username text UNIQUE,
  avatar_url text,
  city text,
  wepin_user_id text UNIQUE,
  wepin_address text,
  created_at timestamptz NOT NULL DEFAULT now()
);
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
CREATE INDEX IF NOT EXISTS idx_profiles_wepin_address ON public.profiles(wepin_address);

-- ===== sessions (per run) =====
CREATE TABLE IF NOT EXISTS public.sessions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES public.profiles(user_id) ON DELETE CASCADE,
  city text,
  started_at timestamptz NOT NULL DEFAULT now(),
  ended_at timestamptz,
  status text CHECK (status IN ('active','ended')) DEFAULT 'active'
);
ALTER TABLE public.sessions ENABLE ROW LEVEL SECURITY;
CREATE INDEX IF NOT EXISTS idx_sessions_user ON public.sessions(user_id);
CREATE INDEX IF NOT EXISTS idx_sessions_city ON public.sessions(city);

-- ===== gps_points (raw stream with H3) =====
-- MOVED TO REDIS: High-frequency stream should not be persisted in SQL.
-- Suggested Redis structures:
--   XADD gps:{session_id}:stream MAXLEN ~ 1000 ts=... lat=... lng=... h3_res=... h3_index=...
--   SETEX last_gps:{user_id} <ttl_seconds> { lat, lng, h3_index, ts }
-- Persist only aggregated outcomes to SQL (see banked_results).

-- ===== trails (logical grouping) =====
-- MOVED TO REDIS: Do not persist trails in SQL.
-- Suggested Redis structures:
--   HSET trail:{session_id} user_id {user_id} status active points_count 0 length_m 0
--   SADD trails_by_user:{user_id} {session_id}
--   EXPIRE trail:{session_id} <ttl_seconds>
-- Persist only banked results to SQL.

-- ===== claims (area after loop closure) =====
CREATE TABLE IF NOT EXISTS public.claims (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  session_id uuid NOT NULL REFERENCES public.sessions(id) ON DELETE CASCADE,
  user_id uuid NOT NULL REFERENCES public.profiles(user_id) ON DELETE CASCADE,
  area_m2 numeric NOT NULL,
  h3_cells text[] NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now()
);
ALTER TABLE public.claims ENABLE ROW LEVEL SECURITY;
CREATE INDEX IF NOT EXISTS idx_claims_user ON public.claims(user_id);
CREATE INDEX IF NOT EXISTS idx_claims_session ON public.claims(session_id);

-- ===== cuts (intercepts) =====
-- MOVED TO REDIS: Do not persist cuts in SQL.
-- Suggested Redis structures:
--   XADD cuts:city:{city}:stream MAXLEN ~ 500 occurred_at=... attacker={attacker_id} victim={victim_id} session={session_id}
--   SADD cuts_by_user:{user_id} {cut_id}
-- Persist only adjudicated outcomes to SQL if needed (e.g., banked_results adjustments).

-- ===== presence (latest ping per user) =====
-- MOVED TO REDIS: Do not persist presence in SQL.
-- Suggested Redis structures:
--   SETEX presence:{user_id} <ttl_seconds> { lat, lng, h3_index, updated_at }
--   GEOADD presence:city:{city} lng lat {user_id} with periodic cleanup via TTL

-- ===== daily leaderboard snapshot (denormalized for speed) =====
CREATE TABLE IF NOT EXISTS public.leaderboard_daily (
  id bigserial PRIMARY KEY,
  day date NOT NULL,
  city text,
  user_id uuid NOT NULL REFERENCES public.profiles(user_id) ON DELETE CASCADE,
  score integer NOT NULL DEFAULT 0,
  rank integer,
  UNIQUE(day, city, user_id)
);
ALTER TABLE public.leaderboard_daily ENABLE ROW LEVEL SECURITY;
CREATE INDEX IF NOT EXISTS idx_lb_day_city_score ON public.leaderboard_daily(day, city, score DESC);

-- ===== Basic owner RLS policies =====
-- profiles: user can read all, upsert own row
DROP POLICY IF EXISTS profiles_read_all ON public.profiles;
CREATE POLICY profiles_read_all ON public.profiles
  FOR SELECT USING (true);
DROP POLICY IF EXISTS profiles_upsert_own ON public.profiles;
CREATE POLICY profiles_upsert_own ON public.profiles
  FOR INSERT WITH CHECK (user_id = auth.uid());
DROP POLICY IF EXISTS profiles_update_own ON public.profiles;
CREATE POLICY profiles_update_own ON public.profiles
  FOR UPDATE USING (user_id = auth.uid());

-- sessions: user can CRUD their own
DROP POLICY IF EXISTS sessions_rw_own ON public.sessions;
CREATE POLICY sessions_rw_own ON public.sessions
  FOR ALL USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());

-- gps_points: MOVED TO REDIS; no SQL policies required

-- claims: owner-based
DROP POLICY IF EXISTS claims_rw_own ON public.claims;
CREATE POLICY claims_rw_own ON public.claims
  FOR ALL USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());

-- trails: MOVED TO REDIS; no SQL policies required
-- cuts: MOVED TO REDIS; no SQL policies required
-- presence: MOVED TO REDIS; no SQL policies required

-- leaderboard_daily: read all (writes via service role only)
DROP POLICY IF EXISTS lb_read_all ON public.leaderboard_daily;
CREATE POLICY lb_read_all ON public.leaderboard_daily
  FOR SELECT USING (true);

-- End of schema


-- ===== Web3 and Results (persistent, off hot path) =====

-- Wepin-only mode: No wallets table. Store Wepin linkage on profiles (wepin_user_id, wepin_address). Route rewards to profiles.wepin_address

-- powerups: catalog (public read)
CREATE TABLE IF NOT EXISTS public.powerups (
  id text PRIMARY KEY,
  name text NOT NULL,
  description text,
  base_price numeric,
  duration_seconds integer,
  enabled boolean NOT NULL DEFAULT true,
  updated_at timestamptz NOT NULL DEFAULT now()
);
ALTER TABLE public.powerups ENABLE ROW LEVEL SECURITY;

-- user_powerups: inventory per user
CREATE TABLE IF NOT EXISTS public.user_powerups (
  id bigserial PRIMARY KEY,
  user_id uuid NOT NULL REFERENCES public.profiles(user_id) ON DELETE CASCADE,
  powerup_id text NOT NULL REFERENCES public.powerups(id) ON DELETE RESTRICT,
  quantity integer NOT NULL DEFAULT 0,
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE(user_id, powerup_id)
);
ALTER TABLE public.user_powerups ENABLE ROW LEVEL SECURITY;
CREATE INDEX IF NOT EXISTS idx_user_powerups_user ON public.user_powerups(user_id);

-- powerup_uses: usage logs during sessions
CREATE TABLE IF NOT EXISTS public.powerup_uses (
  id bigserial PRIMARY KEY,
  user_id uuid NOT NULL REFERENCES public.profiles(user_id) ON DELETE CASCADE,
  session_id uuid REFERENCES public.sessions(id) ON DELETE SET NULL,
  powerup_id text NOT NULL REFERENCES public.powerups(id) ON DELETE RESTRICT,
  used_at timestamptz NOT NULL DEFAULT now(),
  metadata jsonb
);
ALTER TABLE public.powerup_uses ENABLE ROW LEVEL SECURITY;
CREATE INDEX IF NOT EXISTS idx_powerup_uses_user ON public.powerup_uses(user_id);
CREATE INDEX IF NOT EXISTS idx_powerup_uses_session ON public.powerup_uses(session_id);

-- banked_results: finalized outcomes ready for settlement/batching
CREATE TABLE IF NOT EXISTS public.banked_results (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES public.profiles(user_id) ON DELETE CASCADE,
  session_id uuid NOT NULL REFERENCES public.sessions(id) ON DELETE CASCADE,
  city text,
  ts timestamptz NOT NULL DEFAULT now(),
  -- day derived from ts (UTC) computed via trigger to avoid GENERATED expression immutability issues
  day date NOT NULL,
  area_m2 numeric NOT NULL DEFAULT 0,
  score integer NOT NULL DEFAULT 0,
  ipfs_cid text,
  signature text
);
ALTER TABLE public.banked_results ENABLE ROW LEVEL SECURITY;
CREATE INDEX IF NOT EXISTS idx_banked_day_city_user ON public.banked_results(day, city, user_id);
CREATE INDEX IF NOT EXISTS idx_banked_session ON public.banked_results(session_id);

-- Trigger to compute day from ts in UTC
CREATE OR REPLACE FUNCTION public.set_banked_results_day()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
  -- Compute UTC date from timestamptz ts
  NEW.day := (NEW.ts AT TIME ZONE 'UTC')::date;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_set_banked_results_day ON public.banked_results;
CREATE TRIGGER trg_set_banked_results_day
BEFORE INSERT OR UPDATE OF ts ON public.banked_results
FOR EACH ROW
EXECUTE FUNCTION public.set_banked_results_day();

-- ===== RLS for new tables =====
-- wallets: owner-only

-- powerups: public read (writes via service role only)
DROP POLICY IF EXISTS powerups_read_all ON public.powerups;
CREATE POLICY powerups_read_all ON public.powerups
  FOR SELECT USING (true);

-- user_powerups: owner-only
DROP POLICY IF EXISTS user_powerups_select_own ON public.user_powerups;
CREATE POLICY user_powerups_select_own ON public.user_powerups
  FOR SELECT USING (user_id = auth.uid());
DROP POLICY IF EXISTS user_powerups_modify_own ON public.user_powerups;
CREATE POLICY user_powerups_modify_own ON public.user_powerups
  FOR ALL USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());

-- powerup_uses: owner-only
DROP POLICY IF EXISTS powerup_uses_select_own ON public.powerup_uses;
CREATE POLICY powerup_uses_select_own ON public.powerup_uses
  FOR SELECT USING (user_id = auth.uid());
DROP POLICY IF EXISTS powerup_uses_insert_own ON public.powerup_uses;
CREATE POLICY powerup_uses_insert_own ON public.powerup_uses
  FOR INSERT WITH CHECK (user_id = auth.uid());

-- banked_results: owner-only read/insert (service role may aggregate)
DROP POLICY IF EXISTS banked_results_select_own ON public.banked_results;
CREATE POLICY banked_results_select_own ON public.banked_results
  FOR SELECT USING (user_id = auth.uid());
DROP POLICY IF EXISTS banked_results_insert_own ON public.banked_results;
CREATE POLICY banked_results_insert_own ON public.banked_results
  FOR INSERT WITH CHECK (user_id = auth.uid());
