-- ============================================================
-- Fix: Rewrite functions using subqueries to avoid GROUP BY errors
-- ============================================================

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
      SELECT COALESCE(json_agg(row_to_json(t)), '[]'::json)
      FROM (
        SELECT * FROM session_details sd
        JOIN events e ON e.id = sd.event_id
        WHERE e.slug = event_slug AND sd.status = 'live'
        ORDER BY sd.start_time
      ) t
    ),
    'upcoming_sessions', (
      SELECT COALESCE(json_agg(row_to_json(t)), '[]'::json)
      FROM (
        SELECT * FROM session_details sd
        JOIN events e ON e.id = sd.event_id
        WHERE e.slug = event_slug AND sd.status = 'upcoming'
        ORDER BY sd.start_time
        LIMIT 10
      ) t
    ),
    'featured_speakers', (
      SELECT COALESCE(json_agg(row_to_json(t)), '[]'::json)
      FROM (
        SELECT * FROM speaker_details sd
        JOIN events e ON e.id = sd.event_id
        WHERE e.slug = event_slug
        LIMIT 6
      ) t
    ),
    'venue_map', (
      SELECT COALESCE(json_agg(row_to_json(t)), '[]'::json)
      FROM (
        SELECT * FROM venue_locations vl
        JOIN events e ON e.id = vl.event_id
        WHERE e.slug = event_slug
        ORDER BY vl.pos_y, vl.pos_x
      ) t
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
    SELECT COALESCE(json_agg(row_to_json(t)), '[]'::json)
    FROM (
      SELECT * FROM user_schedule us
      WHERE us.user_id = get_my_schedule.user_id
      ORDER BY us.start_time
    ) t
  );
END;
$$ LANGUAGE plpgsql STABLE;
