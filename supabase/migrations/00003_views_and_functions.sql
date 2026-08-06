-- ============================================================
-- Venue Guide — Useful API Views & Functions
-- ============================================================

-- ── View: Full session info with speaker and room ───────────
CREATE OR REPLACE VIEW session_details AS
SELECT
  s.id,
  s.event_id,
  s.title,
  s.description,
  s.category_id,
  s.room_id,
  s.start_time,
  s.end_time,
  s.status,
  s.image_url,
  s.likes_count,
  s.stream_url,
  s.recording_url,
  s.materials_url,
  s.created_at,
  s.updated_at,
  c.name  AS category_name,
  c.color AS category_color,
  r.name  AS room_name,
  r.type  AS room_type,
  r.floor AS room_floor,
  COALESCE(
    (
      SELECT json_agg(json_build_object(
        'id', sp.id,
        'name', sp.name,
        'company', sp.company,
        'role', sp.role,
        'photo_url', sp.photo_url
      ))
      FROM session_speakers ss
      JOIN speakers sp ON sp.id = ss.speaker_id
      WHERE ss.session_id = s.id
    ),
    '[]'::json
  ) AS speakers
FROM sessions s
LEFT JOIN categories c ON c.id = s.category_id
LEFT JOIN rooms r ON r.id = s.room_id;

-- ── View: Speaker with their sessions ───────────────────────
CREATE OR REPLACE VIEW speaker_details AS
SELECT
  sp.id,
  sp.event_id,
  sp.name,
  sp.company,
  sp.role,
  sp.bio,
  sp.photo_url,
  sp.topics,
  sp.social_links,
  sp.created_at,
  sp.updated_at,
  COALESCE(sess.sessions, '[]'::json) AS sessions
FROM speakers sp
LEFT JOIN LATERAL (
  SELECT json_agg(json_build_object(
    'id', s.id,
    'title', s.title,
    'start_time', s.start_time,
    'end_time', s.end_time,
    'status', s.status,
    'room_name', r.name,
    'category_name', c.name
  ) ORDER BY s.start_time) AS sessions
  FROM session_speakers ss
  JOIN sessions s ON s.id = ss.session_id
  LEFT JOIN rooms r ON r.id = s.room_id
  LEFT JOIN categories c ON c.id = s.category_id
  WHERE ss.speaker_id = sp.id
) sess ON true;

-- ── View: User schedule with session details ─────────────────
CREATE OR REPLACE VIEW user_schedule AS
SELECT
  uss.user_id,
  uss.saved_at,
  sd.id AS session_id,
  sd.event_id,
  sd.title AS session_title,
  sd.description AS session_description,
  sd.category_id,
  sd.room_id,
  sd.start_time,
  sd.end_time,
  sd.status AS session_status,
  sd.image_url,
  sd.likes_count,
  sd.stream_url,
  sd.recording_url,
  sd.materials_url,
  sd.category_name,
  sd.category_color,
  sd.room_name,
  sd.room_type,
  sd.room_floor,
  sd.speakers AS session_speakers
FROM user_saved_sessions uss
JOIN session_details sd ON sd.id = uss.session_id;

-- ── Function: Get event dashboard ───────────────────────────
CREATE OR REPLACE FUNCTION get_event_dashboard(event_slug TEXT)
RETURNS JSONB AS $$
DECLARE
  result JSONB;
BEGIN
  SELECT json_build_object(
    'event', (
      SELECT row_to_json(e.*) FROM events e WHERE e.slug = event_slug
    ),
    'live_sessions', (
      SELECT json_agg(to_jsonb(sd) ORDER BY sd.start_time)
      FROM session_details sd
      JOIN events e ON e.id = sd.event_id
      WHERE e.slug = event_slug AND sd.status = 'live'
    ),
    'upcoming_sessions', (
      SELECT json_agg(to_jsonb(sd) ORDER BY sd.start_time)
      FROM session_details sd
      JOIN events e ON e.id = sd.event_id
      WHERE e.slug = event_slug AND sd.status = 'upcoming'
      LIMIT 10
    ),
    'featured_speakers', (
      SELECT json_agg(to_jsonb(sd))
      FROM speaker_details sd
      JOIN events e ON e.id = sd.event_id
      WHERE e.slug = event_slug
      LIMIT 6
    ),
    'venue_map', (
      SELECT json_agg(to_jsonb(vl) ORDER BY vl.pos_y, vl.pos_x)
      FROM venue_locations vl
      JOIN events e ON e.id = vl.event_id
      WHERE e.slug = event_slug
    )
  ) INTO result;

  RETURN result;
END;
$$ LANGUAGE plpgsql STABLE;

-- ── Function: Get user's personal schedule ──────────────────
CREATE OR REPLACE FUNCTION get_my_schedule(user_id UUID)
RETURNS JSONB AS $$
BEGIN
  RETURN (
    SELECT json_agg(to_jsonb(us) ORDER BY us.start_time)
    FROM user_schedule us
    WHERE us.user_id = get_my_schedule.user_id
  );
END;
$$ LANGUAGE plpgsql STABLE;

-- ── Function: Search sessions ───────────────────────────────
CREATE OR REPLACE FUNCTION search_sessions(
  event_id UUID,
  query TEXT
)
RETURNS SETOF session_details AS $$
BEGIN
  RETURN QUERY
    SELECT sd.*
    FROM session_details sd
    WHERE sd.event_id = search_sessions.event_id
      AND (
        sd.title ILIKE '%' || query || '%'
        OR sd.description ILIKE '%' || query || '%'
        OR sd.speakers::TEXT ILIKE '%' || query || '%'
      )
    ORDER BY sd.start_time;
END;
$$ LANGUAGE plpgsql STABLE;

-- ── Function: Get event schedule by day ─────────────────────
CREATE OR REPLACE FUNCTION get_schedule_by_day(
  event_id UUID,
  target_date DATE DEFAULT NULL
)
RETURNS SETOF session_details AS $$
BEGIN
  IF target_date IS NULL THEN
    target_date := CURRENT_DATE;
  END IF;

  RETURN QUERY
    SELECT sd.*
    FROM session_details sd
    WHERE sd.event_id = get_schedule_by_day.event_id
      AND sd.start_time::DATE = target_date
    ORDER BY sd.start_time;
END;
$$ LANGUAGE plpgsql STABLE;
