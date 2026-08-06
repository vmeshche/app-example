-- ============================================================
-- Venue Guide — Event Companion App
-- Supabase Database Schema
-- Migration: 00001_initial_schema
-- ============================================================

-- ── Extensions ──────────────────────────────────────────────
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ── Events ──────────────────────────────────────────────────
CREATE TABLE events (
  id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name        TEXT        NOT NULL,
  slug        TEXT        UNIQUE NOT NULL,
  description TEXT,
  logo_url    TEXT,
  banner_url  TEXT,
  start_date  DATE        NOT NULL,
  end_date    DATE        NOT NULL,
  location    TEXT        NOT NULL,
  city        TEXT,
  country     TEXT,
  timezone    TEXT        DEFAULT 'UTC',
  is_active   BOOLEAN     DEFAULT true,
  created_at  TIMESTAMPTZ DEFAULT now(),
  updated_at  TIMESTAMPTZ DEFAULT now()
);

-- ── Speakers ────────────────────────────────────────────────
CREATE TABLE speakers (
  id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  event_id    UUID        REFERENCES events(id) ON DELETE CASCADE,
  name        TEXT        NOT NULL,
  company     TEXT,
  role        TEXT,
  bio         TEXT,
  photo_url   TEXT,
  topics      TEXT[]      DEFAULT '{}',
  social_links JSONB      DEFAULT '{}',
  created_at  TIMESTAMPTZ DEFAULT now(),
  updated_at  TIMESTAMPTZ DEFAULT now()
);

-- ── Rooms / Stages ──────────────────────────────────────────
CREATE TABLE rooms (
  id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  event_id    UUID        REFERENCES events(id) ON DELETE CASCADE,
  name        TEXT        NOT NULL,
  type        TEXT        DEFAULT 'stage',   -- stage | workshop | booth | food | restroom | entrance | other
  capacity    INT,
  floor       TEXT,
  description TEXT,
  created_at  TIMESTAMPTZ DEFAULT now(),
  updated_at  TIMESTAMPTZ DEFAULT now()
);

-- ── Categories ──────────────────────────────────────────────
CREATE TABLE categories (
  id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  event_id    UUID        REFERENCES events(id) ON DELETE CASCADE,
  name        TEXT        NOT NULL,
  color       TEXT        DEFAULT '#007AFF',
  icon        TEXT,
  sort_order  INT         DEFAULT 0,
  created_at  TIMESTAMPTZ DEFAULT now()
);

-- ── Sessions ────────────────────────────────────────────────
CREATE TABLE sessions (
  id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  event_id    UUID        REFERENCES events(id) ON DELETE CASCADE,
  title       TEXT        NOT NULL,
  description TEXT,
  category_id UUID        REFERENCES categories(id) ON DELETE SET NULL,
  room_id     UUID        REFERENCES rooms(id) ON DELETE SET NULL,
  start_time  TIMESTAMPTZ NOT NULL,
  end_time    TIMESTAMPTZ NOT NULL,
  status      TEXT        DEFAULT 'upcoming', -- upcoming | live | recorded | cancelled
  image_url   TEXT,
  likes_count INT         DEFAULT 0,
  stream_url  TEXT,                            -- live stream URL
  recording_url TEXT,                          -- VOD URL
  materials_url TEXT,                          -- presentation / downloads
  created_at  TIMESTAMPTZ DEFAULT now(),
  updated_at  TIMESTAMPTZ DEFAULT now()
);

-- ── Session ↔ Speaker (many-to-many) ────────────────────────
CREATE TABLE session_speakers (
  session_id UUID REFERENCES sessions(id) ON DELETE CASCADE,
  speaker_id UUID REFERENCES speakers(id) ON DELETE CASCADE,
  PRIMARY KEY (session_id, speaker_id)
);

-- ── Venue Map Locations ─────────────────────────────────────
CREATE TABLE venue_locations (
  id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  event_id    UUID        REFERENCES events(id) ON DELETE CASCADE,
  room_id     UUID        REFERENCES rooms(id) ON DELETE SET NULL,
  label       TEXT        NOT NULL,
  type        TEXT        DEFAULT 'stage',   -- stage | workshop | food | restroom | registration | expo | entrance | info
  color       TEXT        DEFAULT '#007AFF',
  pos_x       FLOAT       NOT NULL DEFAULT 0,
  pos_y       FLOAT       NOT NULL DEFAULT 0,
  width       FLOAT       NOT NULL DEFAULT 100,
  height      FLOAT       NOT NULL DEFAULT 80,
  created_at  TIMESTAMPTZ DEFAULT now()
);

-- ── Recordings (Library) ────────────────────────────────────
CREATE TABLE recordings (
  id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  event_id    UUID        REFERENCES events(id) ON DELETE CASCADE,
  session_id  UUID        REFERENCES sessions(id) ON DELETE SET NULL,
  title       TEXT        NOT NULL,
  speaker_name TEXT,
  speaker_photo_url TEXT,
  duration    TEXT,        -- e.g. "1h 12m"
  views_count INT         DEFAULT 0,
  category    TEXT,
  thumbnail_url TEXT,
  video_url   TEXT,
  created_at  TIMESTAMPTZ DEFAULT now()
);

-- ── User Profile (extends Supabase auth.users) ──────────────
CREATE TABLE user_profiles (
  id          UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  display_name TEXT,
  company     TEXT,
  job_title   TEXT,
  avatar_url  TEXT,
  ticket_type TEXT        DEFAULT 'General Admission',
  qr_code_data TEXT,      -- encoded QR ticket data
  created_at  TIMESTAMPTZ DEFAULT now(),
  updated_at  TIMESTAMPTZ DEFAULT now()
);

-- ── User Saved Sessions (My Schedule) ───────────────────────
CREATE TABLE user_saved_sessions (
  user_id    UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  session_id UUID REFERENCES sessions(id) ON DELETE CASCADE,
  saved_at   TIMESTAMPTZ DEFAULT now(),
  PRIMARY KEY (user_id, session_id)
);

-- ── User Liked Sessions ─────────────────────────────────────
CREATE TABLE user_liked_sessions (
  user_id    UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  session_id UUID REFERENCES sessions(id) ON DELETE CASCADE,
  liked_at   TIMESTAMPTZ DEFAULT now(),
  PRIMARY KEY (user_id, session_id)
);

-- ── User Followed Speakers ──────────────────────────────────
CREATE TABLE user_followed_speakers (
  user_id    UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  speaker_id UUID REFERENCES speakers(id) ON DELETE CASCADE,
  followed_at TIMESTAMPTZ DEFAULT now(),
  PRIMARY KEY (user_id, speaker_id)
);

-- ── Notifications ───────────────────────────────────────────
CREATE TABLE notifications (
  id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id     UUID        REFERENCES auth.users(id) ON DELETE CASCADE,
  type        TEXT        NOT NULL,         -- reminder | announcement | change | recording | session_start
  title       TEXT        NOT NULL,
  body        TEXT,
  session_id  UUID        REFERENCES sessions(id) ON DELETE SET NULL,
  is_read     BOOLEAN     DEFAULT false,
  created_at  TIMESTAMPTZ DEFAULT now()
);

-- ── Event Photos (User Gallery) ─────────────────────────────
CREATE TABLE event_photos (
  id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id     UUID        REFERENCES auth.users(id) ON DELETE CASCADE,
  event_id    UUID        REFERENCES events(id) ON DELETE CASCADE,
  image_url   TEXT        NOT NULL,
  caption     TEXT,
  taken_at    TIMESTAMPTZ DEFAULT now(),
  created_at  TIMESTAMPTZ DEFAULT now()
);

-- ── Indexes ─────────────────────────────────────────────────
CREATE INDEX idx_sessions_event      ON sessions(event_id);
CREATE INDEX idx_sessions_status     ON sessions(status);
CREATE INDEX idx_sessions_start_time ON sessions(start_time);
CREATE INDEX idx_speakers_event      ON speakers(event_id);
CREATE INDEX idx_rooms_event         ON rooms(event_id);
CREATE INDEX idx_recordings_event    ON recordings(event_id);
CREATE INDEX idx_notifications_user  ON notifications(user_id);
CREATE INDEX idx_event_photos_user   ON event_photos(user_id);

-- ── Updated-At Triggers ─────────────────────────────────────
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DO $$
DECLARE
  t TEXT;
BEGIN
  FOR t IN
    SELECT table_name FROM information_schema.columns
    WHERE column_name = 'updated_at' AND table_schema = 'public'
  LOOP
    EXECUTE format(
      'DROP TRIGGER IF EXISTS trg_%I_updated_at ON %I;
       CREATE TRIGGER trg_%I_updated_at BEFORE UPDATE ON %I
       FOR EACH ROW EXECUTE FUNCTION update_updated_at();',
      t, t, t, t
    );
  END LOOP;
END;
$$;

-- ── Increment Likes Count Trigger ───────────────────────────
CREATE OR REPLACE FUNCTION update_session_likes_count()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    UPDATE sessions SET likes_count = likes_count + 1 WHERE id = NEW.session_id;
  ELSIF TG_OP = 'DELETE' THEN
    UPDATE sessions SET likes_count = GREATEST(likes_count - 1, 0) WHERE id = OLD.session_id;
  END IF;
  RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_user_liked_sessions_count
  AFTER INSERT OR DELETE ON user_liked_sessions
  FOR EACH ROW EXECUTE FUNCTION update_session_likes_count();

-- ── Row Level Security (RLS) ────────────────────────────────
ALTER TABLE events              ENABLE ROW LEVEL SECURITY;
ALTER TABLE speakers            ENABLE ROW LEVEL SECURITY;
ALTER TABLE rooms               ENABLE ROW LEVEL SECURITY;
ALTER TABLE categories          ENABLE ROW LEVEL SECURITY;
ALTER TABLE sessions            ENABLE ROW LEVEL SECURITY;
ALTER TABLE session_speakers    ENABLE ROW LEVEL SECURITY;
ALTER TABLE venue_locations     ENABLE ROW LEVEL SECURITY;
ALTER TABLE recordings          ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_profiles       ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_saved_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_liked_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_followed_speakers ENABLE ROW LEVEL SECURITY;
ALTER TABLE notifications       ENABLE ROW LEVEL SECURITY;
ALTER TABLE event_photos        ENABLE ROW LEVEL SECURITY;

-- Public read access for event data
CREATE POLICY "Public read events"          ON events          FOR SELECT USING (true);
CREATE POLICY "Public read speakers"        ON speakers        FOR SELECT USING (true);
CREATE POLICY "Public read rooms"           ON rooms           FOR SELECT USING (true);
CREATE POLICY "Public read categories"      ON categories      FOR SELECT USING (true);
CREATE POLICY "Public read sessions"        ON sessions        FOR SELECT USING (true);
CREATE POLICY "Public read session_speakers" ON session_speakers FOR SELECT USING (true);
CREATE POLICY "Public read venue_locations" ON venue_locations FOR SELECT USING (true);
CREATE POLICY "Public read recordings"      ON recordings      FOR SELECT USING (true);

-- Authenticated user access for user-specific data
CREATE POLICY "User manage own profile"     ON user_profiles   USING (auth.uid() = id);
CREATE POLICY "User manage own schedule"    ON user_saved_sessions USING (auth.uid() = user_id);
CREATE POLICY "User manage own likes"       ON user_liked_sessions USING (auth.uid() = user_id);
CREATE POLICY "User manage own follows"     ON user_followed_speakers USING (auth.uid() = user_id);
CREATE POLICY "User manage own photos"      ON event_photos    USING (auth.uid() = user_id);

-- Notifications: user can read own, insert for self
CREATE POLICY "User read own notifications" ON notifications FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "User insert own notifications" ON notifications FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "User update own notifications" ON notifications FOR UPDATE USING (auth.uid() = user_id);

-- Insert policies for user data
CREATE POLICY "User insert profile"         ON user_profiles   FOR INSERT WITH CHECK (auth.uid() = id);
CREATE POLICY "User insert schedule"        ON user_saved_sessions FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "User insert likes"           ON user_liked_sessions FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "User insert follows"         ON user_followed_speakers FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "User insert photos"          ON event_photos    FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Delete policies
CREATE POLICY "User delete schedule"        ON user_saved_sessions FOR DELETE USING (auth.uid() = user_id);
CREATE POLICY "User delete likes"           ON user_liked_sessions FOR DELETE USING (auth.uid() = user_id);
CREATE POLICY "User delete follows"         ON user_followed_speakers FOR DELETE USING (auth.uid() = user_id);
CREATE POLICY "User delete photos"          ON event_photos    FOR DELETE USING (auth.uid() = user_id);
