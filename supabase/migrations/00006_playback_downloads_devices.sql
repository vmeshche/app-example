-- ============================================================
-- Add playback, downloads, devices, notification preferences
-- Migration: 00006_playback_downloads_devices
-- ============================================================

-- ── Playback State ──────────────────────────────────────────
CREATE TABLE playback_state (
  user_id           UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  session_id        UUID REFERENCES sessions(id) ON DELETE CASCADE,
  position_seconds  INT         DEFAULT 0,
  duration_seconds  INT         DEFAULT 0,
  progress          FLOAT       DEFAULT 0,
  completed         BOOLEAN     DEFAULT false,
  quality           TEXT        DEFAULT 'auto',
  updated_at        TIMESTAMPTZ DEFAULT now(),
  PRIMARY KEY (user_id, session_id)
);

CREATE INDEX idx_playback_user ON playback_state(user_id);

-- ── Downloads ───────────────────────────────────────────────
CREATE TABLE downloads (
  id            UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id       UUID        REFERENCES auth.users(id) ON DELETE CASCADE,
  session_id    UUID        REFERENCES sessions(id) ON DELETE CASCADE,
  status        TEXT        DEFAULT 'queued',   -- queued | downloading | ready | failed | expired
  quality       TEXT        DEFAULT '720p',
  size_bytes    BIGINT,
  file_url      TEXT,
  expires_at    TIMESTAMPTZ,
  created_at    TIMESTAMPTZ DEFAULT now(),
  updated_at    TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX idx_downloads_user ON downloads(user_id);

-- ── Devices (APNs) ──────────────────────────────────────────
CREATE TABLE devices (
  id            UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id       UUID        REFERENCES auth.users(id) ON DELETE CASCADE,
  platform      TEXT        DEFAULT 'ios',
  device_id     TEXT        NOT NULL,
  apns_token    TEXT,
  environment   TEXT        DEFAULT 'production',
  app_version   TEXT,
  locale        TEXT        DEFAULT 'ru-RU',
  timezone      TEXT,
  push_enabled  BOOLEAN     DEFAULT true,
  created_at    TIMESTAMPTZ DEFAULT now(),
  updated_at    TIMESTAMPTZ DEFAULT now(),
  UNIQUE(user_id, device_id)
);

-- ── Notification Preferences ────────────────────────────────
ALTER TABLE user_profiles
  ADD COLUMN IF NOT EXISTS notification_preferences JSONB DEFAULT '{"session_reminders": true, "announcements": true}';
