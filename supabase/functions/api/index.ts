// ============================================================
// Venue Guide — Edge Function API
// Deployed to Supabase Edge Functions
// ============================================================

import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "GET, POST, PUT, DELETE, OPTIONS",
};

serve(async (req: Request) => {
  // Handle CORS preflight
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  const url = new URL(req.url);
  const path = url.pathname.replace("/api", "");

  // Create Supabase client with service role key for full DB access
  const supabaseAdmin = createClient(
    Deno.env.get("SUPABASE_URL") ?? "",
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "",
  );

  // Create authenticated client from request
  const authHeader = req.headers.get("Authorization") ?? "";
  const supabase = createClient(
    Deno.env.get("SUPABASE_URL") ?? "",
    Deno.env.get("SUPABASE_ANON_KEY") ?? "",
    { global: { headers: { Authorization: authHeader } } },
  );

  try {
    // ── Public Routes ──────────────────────────────────────

    // GET /event/:slug — Full event dashboard
    const eventMatch = path.match(/^\/event\/([a-z0-9-]+)$/);
    if (req.method === "GET" && eventMatch) {
      const slug = eventMatch[1];

      // Fetch event
      const { data: event, error: eventErr } = await supabaseAdmin
        .from("events").select("*").eq("slug", slug).single();
      if (eventErr) throw eventErr;

      const eventId = event.id;

      // Fetch all dashboard data in parallel
      const [
        { data: live },
        { data: upcoming },
        { data: speakers },
        { data: map },
      ] = await Promise.all([
        supabaseAdmin.from("session_details").select("*")
          .eq("event_id", eventId).eq("status", "live")
          .order("start_time", { ascending: true }),
        supabaseAdmin.from("session_details").select("*")
          .eq("event_id", eventId).eq("status", "upcoming")
          .order("start_time", { ascending: true }).limit(10),
        supabaseAdmin.from("speaker_details").select("*")
          .eq("event_id", eventId).limit(6),
        supabaseAdmin.from("venue_locations").select("*")
          .eq("event_id", eventId).order("pos_y", { ascending: true }),
      ]);

      return json({
        event,
        live_sessions: live || [],
        upcoming_sessions: upcoming || [],
        featured_speakers: speakers || [],
        venue_map: map || [],
      }, corsHeaders);
    }

    // GET /sessions?event_id=...&status=...&category=...&q=...
    if (req.method === "GET" && path === "/sessions") {
      const eventId = url.searchParams.get("event_id");
      const status = url.searchParams.get("status");
      const category = url.searchParams.get("category");
      const query = url.searchParams.get("q");
      const day = url.searchParams.get("day");

      let req = supabaseAdmin.from("session_details").select("*");

      if (eventId) req = req.eq("event_id", eventId);
      if (status) req = req.eq("status", status);
      if (category) req = req.eq("category_id", category);
      if (query) req = req.or(`title.ilike.%${query}%,description.ilike.%${query}%`);
      if (day) {
        req = req.gte("start_time", `${day}T00:00:00`);
        req = req.lte("start_time", `${day}T23:59:59`);
      }

      const { data, error } = await req.order("start_time", { ascending: true });
      if (error) throw error;
      return json(data, corsHeaders);
    }

    // GET /sessions/:id
    const sessionDetailMatch = path.match(/^\/sessions\/([a-f0-9-]+)$/);
    if (req.method === "GET" && sessionDetailMatch) {
      const { data, error } = await supabaseAdmin
        .from("session_details")
        .select("*")
        .eq("id", sessionDetailMatch[1])
        .single();
      if (error) throw error;
      return json(data, corsHeaders);
    }

    // GET /speakers?event_id=...
    if (req.method === "GET" && path === "/speakers") {
      const eventId = url.searchParams.get("event_id");
      let req = supabaseAdmin.from("speakers").select("*");
      if (eventId) req = req.eq("event_id", eventId);
      const { data, error } = await req.order("name");
      if (error) throw error;
      return json(data, corsHeaders);
    }

    // GET /speakers/:id
    const speakerMatch = path.match(/^\/speakers\/([a-f0-9-]+)$/);
    if (req.method === "GET" && speakerMatch) {
      const { data, error } = await supabaseAdmin
        .from("speaker_details")
        .select("*")
        .eq("id", speakerMatch[1])
        .single();
      if (error) throw error;
      return json(data, corsHeaders);
    }

    // GET /recordings?event_id=...
    if (req.method === "GET" && path === "/recordings") {
      const eventId = url.searchParams.get("event_id");
      let req = supabaseAdmin.from("recordings").select("*");
      if (eventId) req = req.eq("event_id", eventId);
      const { data, error } = await req.order("views_count", { ascending: false });
      if (error) throw error;
      return json(data, corsHeaders);
    }

    // GET /map?event_id=...
    if (req.method === "GET" && path === "/map") {
      const eventId = url.searchParams.get("event_id");
      let req = supabaseAdmin.from("venue_locations").select("*");
      if (eventId) req = req.eq("event_id", eventId);
      const { data, error } = await req.order("pos_y");
      if (error) throw error;
      return json(data, corsHeaders);
    }

    // GET /rooms?event_id=...
    if (req.method === "GET" && path === "/rooms") {
      const eventId = url.searchParams.get("event_id");
      let req = supabaseAdmin.from("rooms").select("*");
      if (eventId) req = req.eq("event_id", eventId);
      const { data, error } = await req.order("name");
      if (error) throw error;
      return json(data, corsHeaders);
    }

    // GET /categories?event_id=...
    if (req.method === "GET" && path === "/categories") {
      const eventId = url.searchParams.get("event_id");
      let req = supabaseAdmin.from("categories").select("*");
      if (eventId) req = req.eq("event_id", eventId);
      const { data, error } = await req.order("sort_order");
      if (error) throw error;
      return json(data, corsHeaders);
    }

    // ── Authenticated Routes ───────────────────────────────

    // Get current user
    const { data: { user } } = await supabase.auth.getUser();
    const userId = user?.id;

    // GET /schedule — User's personal schedule
    if (req.method === "GET" && path === "/schedule") {
      if (!userId) return unauthorized();
      const { data, error } = await supabase.rpc("get_my_schedule", {
        user_id: userId,
      });
      if (error) throw error;
      return json(data, corsHeaders);
    }

    // POST /schedule/:sessionId — Toggle save session
    const scheduleMatch = path.match(/^\/schedule\/([a-f0-9-]+)$/);
    if (req.method === "POST" && scheduleMatch) {
      if (!userId) return unauthorized();
      const sessionId = scheduleMatch[1];

      // Check if already saved
      const { data: existing } = await supabase
        .from("user_saved_sessions")
        .select("*")
        .eq("user_id", userId)
        .eq("session_id", sessionId)
        .single();

      if (existing) {
        const { error } = await supabase
          .from("user_saved_sessions")
          .delete()
          .eq("user_id", userId)
          .eq("session_id", sessionId);
        if (error) throw error;
        return json({ saved: false }, corsHeaders);
      } else {
        const { error } = await supabase
          .from("user_saved_sessions")
          .insert({ user_id: userId, session_id: sessionId });
        if (error) throw error;
        return json({ saved: true }, corsHeaders);
      }
    }

    // POST /like/:sessionId — Toggle like
    const likeMatch = path.match(/^\/like\/([a-f0-9-]+)$/);
    if (req.method === "POST" && likeMatch) {
      if (!userId) return unauthorized();
      const sessionId = likeMatch[1];

      const { data: existing } = await supabase
        .from("user_liked_sessions")
        .select("*")
        .eq("user_id", userId)
        .eq("session_id", sessionId)
        .single();

      if (existing) {
        const { error } = await supabase
          .from("user_liked_sessions")
          .delete()
          .eq("user_id", userId)
          .eq("session_id", sessionId);
        if (error) throw error;
        return json({ liked: false }, corsHeaders);
      } else {
        const { error } = await supabase
          .from("user_liked_sessions")
          .insert({ user_id: userId, session_id: sessionId });
        if (error) throw error;
        return json({ liked: true }, corsHeaders);
      }
    }

    // POST /follow/:speakerId — Toggle follow speaker
    const followMatch = path.match(/^\/follow\/([a-f0-9-]+)$/);
    if (req.method === "POST" && followMatch) {
      if (!userId) return unauthorized();
      const speakerId = followMatch[1];

      const { data: existing } = await supabase
        .from("user_followed_speakers")
        .select("*")
        .eq("user_id", userId)
        .eq("speaker_id", speakerId)
        .single();

      if (existing) {
        const { error } = await supabase
          .from("user_followed_speakers")
          .delete()
          .eq("user_id", userId)
          .eq("speaker_id", speakerId);
        if (error) throw error;
        return json({ following: false }, corsHeaders);
      } else {
        const { error } = await supabase
          .from("user_followed_speakers")
          .insert({ user_id: userId, speaker_id: speakerId });
        if (error) throw error;
        return json({ following: true }, corsHeaders);
      }
    }

    // GET /notifications
    if (req.method === "GET" && path === "/notifications") {
      if (!userId) return unauthorized();
      const { data, error } = await supabase
        .from("notifications")
        .select("*")
        .eq("user_id", userId)
        .order("created_at", { ascending: false })
        .limit(50);
      if (error) throw error;
      return json(data, corsHeaders);
    }

    // POST /notifications/:id/read — Mark as read
    const notifReadMatch = path.match(/^\/notifications\/([a-f0-9-]+)\/read$/);
    if (req.method === "POST" && notifReadMatch) {
      if (!userId) return unauthorized();
      const { error } = await supabase
        .from("notifications")
        .update({ is_read: true })
        .eq("id", notifReadMatch[1])
        .eq("user_id", userId);
      if (error) throw error;
      return json({ success: true }, corsHeaders);
    }

    // GET /profile
    if (req.method === "GET" && path === "/profile") {
      if (!userId) return unauthorized();
      const { data, error } = await supabase
        .from("user_profiles")
        .select("*")
        .eq("id", userId)
        .single();
      if (error) throw error;
      return json(data, corsHeaders);
    }

    // 404
    return json({ error: "Not found", path }, corsHeaders, 404);
  } catch (err) {
    return json({ error: err.message }, corsHeaders, 500);
  }
});

function json(data: unknown, headers: Record<string, string>, status = 200) {
  return new Response(JSON.stringify(data), {
    status,
    headers: { ...headers, "Content-Type": "application/json" },
  });
}

function unauthorized() {
  return json({ error: "Unauthorized" }, corsHeaders, 401);
}
