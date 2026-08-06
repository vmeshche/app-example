// ============================================================
// Venue Guide — Edge Function API
// Язык: русский. P5-решения: поиск убран, auth обязателен.
// ============================================================

import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "GET, POST, PUT, DELETE, OPTIONS",
};

serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  const url = new URL(req.url);
  const path = url.pathname.replace("/api", "");

  const supabaseAdmin = createClient(
    Deno.env.get("SUPABASE_URL") ?? "",
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "",
  );

  const authHeader = req.headers.get("Authorization") ?? "";
  const supabase = createClient(
    Deno.env.get("SUPABASE_URL") ?? "",
    Deno.env.get("SUPABASE_ANON_KEY") ?? "",
    { global: { headers: { Authorization: authHeader } } },
  );

  try {
    // ── Auth Routes (public) ────────────────────────────────

    // POST /auth/signup — Register new user
    if (req.method === "POST" && path === "/auth/signup") {
      const { email, password, display_name, company, job_title } = await req.json();
      if (!email || !password) {
        return json({ error: "Email и пароль обязательны" }, corsHeaders, 400);
      }

      const { data, error } = await supabaseAdmin.auth.admin.createUser({
        email,
        password,
        email_confirm: true,
        user_metadata: { display_name, company, job_title },
      });

      if (error) throw error;

      // Create user profile
      const { error: profileErr } = await supabaseAdmin
        .from("user_profiles")
        .insert({
          id: data.user.id,
          display_name: display_name || email.split("@")[0],
          company: company || "",
          job_title: job_title || "",
          ticket_type: "3-Day Pass",
        });

      if (profileErr) throw profileErr;

      return json({ user: data.user }, corsHeaders, 201);
    }

    // POST /auth/signin — Get JWT token
    if (req.method === "POST" && path === "/auth/signin") {
      const { email, password } = await req.json();
      if (!email || !password) {
        return json({ error: "Email и пароль обязательны" }, corsHeaders, 400);
      }

      const { data, error } = await supabase.auth.signInWithPassword({
        email,
        password,
      });

      if (error) throw error;
      return json(data, corsHeaders);
    }

    // ── Public Routes ──────────────────────────────────────

    // GET /event/:slug — Full event dashboard
    const eventMatch = path.match(/^\/event\/([a-z0-9-]+)$/);
    if (req.method === "GET" && eventMatch) {
      const slug = eventMatch[1];
      const { data: event, error: eventErr } = await supabaseAdmin
        .from("events").select("*").eq("slug", slug).single();
      if (eventErr) throw eventErr;

      const eventId = event.id;
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

    // GET /sessions?event_id=...&status=...&category=...&day=...
    if (req.method === "GET" && path === "/sessions") {
      const eventId = url.searchParams.get("event_id");
      const status = url.searchParams.get("status");
      const category = url.searchParams.get("category");
      const day = url.searchParams.get("day");

      let query = supabaseAdmin.from("session_details").select("*");
      if (eventId) query = query.eq("event_id", eventId);
      if (status) query = query.eq("status", status);
      if (category) query = query.eq("category_id", category);
      if (day) {
        query = query.gte("start_time", `${day}T00:00:00`);
        query = query.lte("start_time", `${day}T23:59:59`);
      }

      const { data, error } = await query.order("start_time", { ascending: true });
      if (error) throw error;
      return json(data, corsHeaders);
    }

    // GET /sessions/:id
    const sessionDetailMatch = path.match(/^\/sessions\/([a-f0-9-]+)$/);
    if (req.method === "GET" && sessionDetailMatch) {
      const { data, error } = await supabaseAdmin
        .from("session_details").select("*").eq("id", sessionDetailMatch[1]).single();
      if (error) throw error;
      return json(data, corsHeaders);
    }

    // GET /speakers?event_id=...
    if (req.method === "GET" && path === "/speakers") {
      const eventId = url.searchParams.get("event_id");
      let query = supabaseAdmin.from("speakers").select("*");
      if (eventId) query = query.eq("event_id", eventId);
      const { data, error } = await query.order("name");
      if (error) throw error;
      return json(data, corsHeaders);
    }

    // GET /speakers/:id
    const speakerMatch = path.match(/^\/speakers\/([a-f0-9-]+)$/);
    if (req.method === "GET" && speakerMatch) {
      const { data, error } = await supabaseAdmin
        .from("speaker_details").select("*").eq("id", speakerMatch[1]).single();
      if (error) throw error;
      return json(data, corsHeaders);
    }

    // GET /recordings?event_id=...
    if (req.method === "GET" && path === "/recordings") {
      const eventId = url.searchParams.get("event_id");
      let query = supabaseAdmin.from("recordings").select("*");
      if (eventId) query = query.eq("event_id", eventId);
      const { data, error } = await query.order("views_count", { ascending: false });
      if (error) throw error;
      return json(data, corsHeaders);
    }

    // GET /map?event_id=...
    if (req.method === "GET" && path === "/map") {
      const eventId = url.searchParams.get("event_id");
      let query = supabaseAdmin.from("venue_locations").select("*");
      if (eventId) query = query.eq("event_id", eventId);
      const { data, error } = await query.order("pos_y");
      if (error) throw error;
      return json(data, corsHeaders);
    }

    // GET /rooms?event_id=...
    if (req.method === "GET" && path === "/rooms") {
      const eventId = url.searchParams.get("event_id");
      let query = supabaseAdmin.from("rooms").select("*");
      if (eventId) query = query.eq("event_id", eventId);
      const { data, error } = await query.order("name");
      if (error) throw error;
      return json(data, corsHeaders);
    }

    // GET /categories?event_id=...
    if (req.method === "GET" && path === "/categories") {
      const eventId = url.searchParams.get("event_id");
      let query = supabaseAdmin.from("categories").select("*");
      if (eventId) query = query.eq("event_id", eventId);
      const { data, error } = await query.order("sort_order");
      if (error) throw error;
      return json(data, corsHeaders);
    }

    // ── Authenticated Routes ───────────────────────────────

    const { data: { user } } = await supabase.auth.getUser();
    const userId = user?.id;

    // GET /schedule — Личное расписание
    if (req.method === "GET" && path === "/schedule") {
      if (!userId) return unauthorized();
      const { data, error } = await supabase
        .from("user_saved_sessions")
        .select("session_id")
        .eq("user_id", userId);
      if (error) throw error;

      // Return session details for saved sessions
      const sessionIds = (data || []).map((s: { session_id: string }) => s.session_id);
      if (sessionIds.length === 0) return json([], corsHeaders);

      const { data: sessions, error: sessionsErr } = await supabaseAdmin
        .from("session_details")
        .select("*")
        .in("id", sessionIds)
        .order("start_time", { ascending: true });
      if (sessionsErr) throw sessionsErr;
      return json(sessions, corsHeaders);
    }

    // GET /likes — Мои лайки
    if (req.method === "GET" && path === "/likes") {
      if (!userId) return unauthorized();
      const { data, error } = await supabase
        .from("user_liked_sessions")
        .select("session_id")
        .eq("user_id", userId);
      if (error) throw error;
      return json((data || []).map((s: { session_id: string }) => s.session_id), corsHeaders);
    }

    // GET /follows — Мои подписки
    if (req.method === "GET" && path === "/follows") {
      if (!userId) return unauthorized();
      const { data, error } = await supabase
        .from("user_followed_speakers")
        .select("speaker_id")
        .eq("user_id", userId);
      if (error) throw error;
      return json((data || []).map((s: { speaker_id: string }) => s.speaker_id), corsHeaders);
    }

    // POST /schedule/:sessionId — Сохранить/убрать из расписания
    const scheduleMatch = path.match(/^\/schedule\/([a-f0-9-]+)$/);
    if (req.method === "POST" && scheduleMatch) {
      if (!userId) return unauthorized();
      const sessionId = scheduleMatch[1];
      const { data: existing } = await supabase
        .from("user_saved_sessions").select("*")
        .eq("user_id", userId).eq("session_id", sessionId).single();

      if (existing) {
        await supabase.from("user_saved_sessions").delete()
          .eq("user_id", userId).eq("session_id", sessionId);
        return json({ saved: false }, corsHeaders);
      } else {
        await supabase.from("user_saved_sessions")
          .insert({ user_id: userId, session_id: sessionId });
        return json({ saved: true }, corsHeaders);
      }
    }

    // POST /like/:sessionId — Лайк/анлайк
    const likeMatch = path.match(/^\/like\/([a-f0-9-]+)$/);
    if (req.method === "POST" && likeMatch) {
      if (!userId) return unauthorized();
      const sessionId = likeMatch[1];
      const { data: existing } = await supabase
        .from("user_liked_sessions").select("*")
        .eq("user_id", userId).eq("session_id", sessionId).single();

      if (existing) {
        await supabase.from("user_liked_sessions").delete()
          .eq("user_id", userId).eq("session_id", sessionId);
        return json({ liked: false }, corsHeaders);
      } else {
        await supabase.from("user_liked_sessions")
          .insert({ user_id: userId, session_id: sessionId });
        return json({ liked: true }, corsHeaders);
      }
    }

    // POST /follow/:speakerId — Подписаться/отписаться
    const followMatch = path.match(/^\/follow\/([a-f0-9-]+)$/);
    if (req.method === "POST" && followMatch) {
      if (!userId) return unauthorized();
      const speakerId = followMatch[1];
      const { data: existing } = await supabase
        .from("user_followed_speakers").select("*")
        .eq("user_id", userId).eq("speaker_id", speakerId).single();

      if (existing) {
        await supabase.from("user_followed_speakers").delete()
          .eq("user_id", userId).eq("speaker_id", speakerId);
        return json({ following: false }, corsHeaders);
      } else {
        await supabase.from("user_followed_speakers")
          .insert({ user_id: userId, speaker_id: speakerId });
        return json({ following: true }, corsHeaders);
      }
    }

    // GET /notifications
    if (req.method === "GET" && path === "/notifications") {
      if (!userId) return unauthorized();
      const { data, error } = await supabase
        .from("notifications").select("*")
        .eq("user_id", userId)
        .order("created_at", { ascending: false }).limit(50);
      if (error) throw error;
      return json(data, corsHeaders);
    }

    // POST /notifications/:id/read — Отметить прочитанным
    const notifReadMatch = path.match(/^\/notifications\/([a-f0-9-]+)\/read$/);
    if (req.method === "POST" && notifReadMatch) {
      if (!userId) return unauthorized();
      await supabase.from("notifications").update({ is_read: true })
        .eq("id", notifReadMatch[1]).eq("user_id", userId);
      return json({ success: true }, corsHeaders);
    }

    // GET /profile — Профиль пользователя
    if (req.method === "GET" && path === "/profile") {
      if (!userId) return unauthorized();
      const { data, error } = await supabase
        .from("user_profiles").select("*").eq("id", userId).single();
      if (error) {
        // Return basic profile from auth if no extended profile
        return json({
          id: userId,
          display_name: user.user_metadata?.display_name || user.email?.split("@")[0],
          email: user.email,
          ticket_type: "3-Day Pass",
        }, corsHeaders);
      }
      return json({ ...data, email: user.email }, corsHeaders);
    }

    // 404
    return json({ error: "Не найдено", path }, corsHeaders, 404);
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
  return json({ error: "Требуется авторизация" }, corsHeaders, 401);
}
