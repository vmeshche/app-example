// ============================================================
// Venue Guide API — v1 (контракт 07-api-contract.md)
// ============================================================

import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type, idempotency-key, accept-language, if-none-match",
  "Access-Control-Allow-Methods": "GET, POST, PUT, DELETE, PATCH, OPTIONS",
  "Access-Control-Expose-Headers": "etag, retry-after",
};

// ── Helpers ──────────────────────────────────────────────────
function json(data: unknown, headers: Record<string, string> = {}, status = 200) {
  return new Response(JSON.stringify(data), {
    status,
    headers: { ...corsHeaders, ...headers, "Content-Type": "application/json; charset=utf-8" },
  });
}

function err(code: string, message: string, status: number, details?: Record<string, unknown>) {
  return json({
    error: { code, message, request_id: crypto.randomUUID(), details: details || {} },
  }, {}, status);
}

// Build session summary from DB row
function sessionSummary(s: Record<string, unknown>, userState?: Record<string, boolean>) {
  return {
    id: s.id,
    title: s.title,
    status: s.status,
    starts_at: s.start_time,
    ends_at: s.end_time,
    duration_seconds: s.end_time && s.start_time
      ? Math.round((new Date(s.end_time as string).getTime() - new Date(s.start_time as string).getTime()) / 1000)
      : null,
    category: (s.category_name as string || "").toLowerCase(),
    room: s.room_name ? { id: s.room_id, name: s.room_name, venue_area_id: s.room_id } : null,
    speaker: s.speakers && Array.isArray(s.speakers) && (s.speakers as Array<Record<string,unknown>>).length > 0
      ? {
          id: (s.speakers as Array<Record<string,unknown>>)[0].id,
          name: (s.speakers as Array<Record<string,unknown>>)[0].name,
          company: (s.speakers as Array<Record<string,unknown>>)[0].company || "",
          avatar_url: (s.speakers as Array<Record<string,unknown>>)[0].photo_url || "",
        }
      : null,
    thumbnail_url: s.image_url,
    likes_count: s.likes_count || 0,
    user_state: userState || { saved: false, liked: false },
  };
}

// Build speaker summary from DB row
function speakerSummary(sp: Record<string, unknown>, userState?: Record<string, boolean>) {
  return {
    id: sp.id,
    name: sp.name,
    company: sp.company,
    role: sp.role,
    avatar_url: sp.photo_url,
    user_state: userState || { followed: false },
  };
}

// Compute server-side session status
function computeStatus(startTime: string, endTime: string): string {
  const now = new Date();
  const start = new Date(startTime);
  const end = new Date(endTime);
  if (now < start) return "upcoming";
  if (now >= start && now <= end) return "live";
  return "recorded";
}

// ── Main ─────────────────────────────────────────────────────
serve(async (req: Request) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });

  const url = new URL(req.url);
  const path = url.pathname.replace("/v1", "");

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
    const { data: { user } } = await supabase.auth.getUser();
    const userId = user?.id;

    // ============================================================
    // Auth endpoints (public)
    // ============================================================

    // POST /auth/token
    if (req.method === "POST" && path === "/auth/token") {
      const { grant_type, email, password } = await req.json();

      if (grant_type === "password") {
        const { data, error } = await supabase.auth.signInWithPassword({ email, password });
        if (error) return err("INVALID_CREDENTIALS", "Неверный email или пароль", 401);

        const { data: profile } = await supabaseAdmin.from("user_profiles")
          .select("*").eq("id", data.user!.id).single();

        return json({
          access_token: data.session!.access_token,
          refresh_token: data.session!.refresh_token,
          token_type: "Bearer",
          expires_in: data.session!.expires_in,
          user: {
            id: data.user!.id,
            email: data.user!.email,
            display_name: profile?.display_name || data.user!.email?.split("@")[0],
            avatar_url: profile?.avatar_url || null,
            role: profile?.job_title || null,
            company: profile?.company || null,
            verified_attendee: true,
          },
        });
      }

      return err("INVALID_REQUEST", "Неподдерживаемый grant_type", 400);
    }

    // POST /auth/token/refresh
    if (req.method === "POST" && path === "/auth/token/refresh") {
      const { refresh_token } = await req.json();
      const { data, error } = await supabase.auth.refreshSession({ refresh_token });
      if (error) return err("TOKEN_EXPIRED", "Токен истёк", 401);

      return json({
        access_token: data.session!.access_token,
        refresh_token: data.session!.refresh_token,
        token_type: "Bearer",
        expires_in: data.session!.expires_in,
      });
    }

    // ============================================================
    // Conference endpoints (public)
    // ============================================================

    // GET /conferences/current
    if (req.method === "GET" && path === "/conferences/current") {
      const { data: event, error } = await supabaseAdmin.from("events")
        .select("*").eq("is_active", true).order("start_date").limit(1).single();
      if (error || !event) return err("NOT_FOUND", "Нет активной конференции", 404);

      return json({
        id: event.id,
        slug: event.slug,
        name: event.name,
        venue_name: event.location,
        city: event.city,
        timezone: event.timezone,
        starts_at: `${event.start_date}T08:00:00-07:00`,
        ends_at: `${event.end_date}T18:00:00-07:00`,
        logo_url: event.logo_url || null,
      });
    }

    // GET /conferences/{id}/home
    const confHomeMatch = path.match(/^\/conferences\/(.+)\/home$/);
    if (req.method === "GET" && confHomeMatch) {
      const confId = confHomeMatch[1];

      const [liveRes, upcomingRes, speakersRes, eventRes] = await Promise.all([
        supabaseAdmin.from("session_details").select("*")
          .eq("event_id", confId).eq("status", "live").order("start_time").limit(5),
        supabaseAdmin.from("session_details").select("*")
          .eq("event_id", confId).eq("status", "upcoming").order("start_time").limit(10),
        supabaseAdmin.from("speakers").select("*")
          .eq("event_id", confId).limit(6),
        supabaseAdmin.from("events").select("*").eq("id", confId).single(),
      ]);

      const live = (liveRes.data || []).map((s, i) => ({
        session: sessionSummary(s),
        position: i === 0 ? "hero" : "secondary",
      }));

      let upNext: Array<Record<string, unknown>> = [];
      if (userId) {
        const { data: saved } = await supabase.from("user_saved_sessions")
          .select("session_id").eq("user_id", userId);
        const savedIds = new Set((saved || []).map((r: { session_id: string }) => r.session_id));

        upNext = (upcomingRes.data || [])
          .filter(s => savedIds.has(s.id as string))
          .slice(0, 3)
          .map(s => ({
            session: sessionSummary(s),
            starts_in_seconds: Math.max(0,
              Math.round((new Date(s.start_time as string).getTime() - Date.now()) / 1000)),
          }));
      }

      return json({
        conference_id: confId,
        server_time: new Date().toISOString(),
        live,
        up_next: upNext,
        featured_speakers: (speakersRes.data || []).map(sp => speakerSummary(sp)),
        capacity_alerts: [],
      });
    }

    // GET /conferences/{id}/schedule
    const confSchedMatch = path.match(/^\/conferences\/(.+)\/schedule$/);
    if (req.method === "GET" && confSchedMatch) {
      const confId = confSchedMatch[1];
      const targetDate = url.searchParams.get("date");
      const status = url.searchParams.get("status");

      let query = supabaseAdmin.from("session_details").select("*").eq("event_id", confId);

      if (status) {
        const statuses = status.split(",");
        query = query.in("status", statuses);
      }
      if (targetDate) {
        query = query.gte("start_time", `${targetDate}T00:00:00`)
                     .lte("start_time", `${targetDate}T23:59:59`);
      }

      const { data: sessions, error } = await query.order("start_time");
      if (error) throw error;

      // Group by calendar day
      const dayMap = new Map<string, Array<Record<string, unknown>>>();
      for (const s of (sessions || [])) {
        const day = (s.start_time as string).substring(0, 10);
        if (!dayMap.has(day)) dayMap.set(day, []);
        dayMap.get(day)!.push(sessionSummary(s));
      }

      const days = Array.from(dayMap.entries()).map(([date, sess], i) => ({
        date,
        label: `День ${i + 1}`,
        sessions: sess,
      }));

      return json({ conference_id: confId, days, next_page_token: null });
    }

    // ── Session detail ────────────────────────────────────
    const sessionDetailMatch = path.match(/^\/sessions\/(.+)$/);
    if (req.method === "GET" && sessionDetailMatch && !path.includes("/playback") && !path.includes("/like") && !path.includes("/downloads")) {
      const sid = sessionDetailMatch[1];
      const { data: s, error } = await supabaseAdmin.from("session_details")
        .select("*").eq("id", sid).single();
      if (error || !s) return err("SESSION_NOT_FOUND", "Сессия не найдена", 404);

      let userState = { saved: false, liked: false };
      if (userId) {
        const [savedRes, likedRes] = await Promise.all([
          supabase.from("user_saved_sessions").select("*").eq("user_id", userId).eq("session_id", sid).single(),
          supabase.from("user_liked_sessions").select("*").eq("user_id", userId).eq("session_id", sid).single(),
        ]);
        userState = { saved: !!savedRes.data, liked: !!likedRes.data };
      }

      const realStatus = computeStatus(s.start_time as string, s.end_time as string);
      const speakersArr = (s.speakers && Array.isArray(s.speakers) ? s.speakers as Array<Record<string, unknown>> : []);
      const primarySpeaker = speakersArr.length > 0 ? speakersArr[0] : null;

      return json({
        id: s.id,
        conference_id: s.event_id,
        title: s.title,
        description: s.description,
        category: (s.category_name as string || "").toLowerCase(),
        status: realStatus,
        starts_at: s.start_time,
        ends_at: s.end_time,
        room: s.room_name ? { id: s.room_id, name: s.room_name, venue_area_id: s.room_id } : null,
        speaker: primarySpeaker ? {
          id: primarySpeaker.id,
          name: primarySpeaker.name,
          company: primarySpeaker.company || "",
          role: primarySpeaker.role || "",
          avatar_url: primarySpeaker.photo_url || "",
          bio: null,
          topics: [],
        } : null,
        hero_image_url: s.image_url,
        tags: [],
        likes_count: s.likes_count || 0,
        user_state: userState,
        media: { available: !!s.stream_url, duration_seconds: null },
      });
    }

    // ── Speaker detail ────────────────────────────────────
    const speakerDetailMatch = path.match(/^\/speakers\/(.+)$/);
    if (req.method === "GET" && speakerDetailMatch) {
      const spid = speakerDetailMatch[1];
      const { data: sp, error } = await supabaseAdmin.from("speaker_details")
        .select("*").eq("id", spid).single();
      if (error || !sp) return err("NOT_FOUND", "Спикер не найден", 404);

      let followed = false;
      if (userId) {
        const { data: f } = await supabase.from("user_followed_speakers")
          .select("*").eq("user_id", userId).eq("speaker_id", spid).single();
        followed = !!f;
      }

      const sessions = (sp.sessions && Array.isArray(sp.sessions) ? sp.sessions as Array<Record<string, unknown>> : [])
        .map((s: Record<string, unknown>) => ({
          id: s.id,
          title: s.title,
          status: computeStatus(s.start_time as string, s.end_time as string),
          starts_at: s.start_time,
          ends_at: s.end_time,
          category: (s.category_name as string || "").toLowerCase(),
          room: s.room_name ? { id: null, name: s.room_name, venue_area_id: null } : null,
        }));

      return json({
        id: sp.id,
        name: sp.name,
        company: sp.company,
        role: sp.role,
        bio: sp.bio,
        avatar_url: sp.photo_url,
        topics: sp.topics || [],
        sessions,
        user_state: { followed },
      });
    }

    // ── Venue map ─────────────────────────────────────────
    const mapMatch = path.match(/^\/conferences\/(.+)\/venue-map$/);
    if (req.method === "GET" && mapMatch) {
      const confId = mapMatch[1];
      const { data: locations, error } = await supabaseAdmin.from("venue_locations")
        .select("*").eq("event_id", confId).order("pos_y");
      if (error) throw error;

      return json({
        id: `map_${confId}`,
        version: 1,
        asset_url: null,
        areas: (locations || []).map((loc: Record<string, unknown>) => ({
          id: loc.id,
          name: loc.label,
          type: loc.type,
          capacity: (loc as Record<string, unknown>).capacity || null,
          current_session: null,
          next_session: null,
          services: [],
          hours: null,
          geometry: { x: loc.pos_x, y: loc.pos_y, w: loc.width, h: loc.height },
        })),
      });
    }

    // ============================================================
    // Authenticated routes (require userId)
    // ============================================================

    // ── GET /me ───────────────────────────────────────────
    if (req.method === "GET" && path === "/me") {
      if (!userId) return err("TOKEN_EXPIRED", "Требуется авторизация", 401);

      const [profileRes, savedRes, followedRes] = await Promise.all([
        supabaseAdmin.from("user_profiles").select("*").eq("id", userId).single(),
        supabase.from("user_saved_sessions").select("session_id", { count: "exact" }).eq("user_id", userId),
        supabase.from("user_followed_speakers").select("speaker_id", { count: "exact" }).eq("user_id", userId),
      ]);

      const profile = profileRes.data;
      return json({
        id: userId,
        email: user.email,
        display_name: profile?.display_name || user.email?.split("@")[0] || "",
        avatar_url: profile?.avatar_url || null,
        role: profile?.job_title || "",
        company: profile?.company || "",
        verified_attendee: true,
        stats: {
          saved: savedRes.count || 0,
          watched: 0,
          following: followedRes.count || 0,
        },
        conference_id: "00000000-0000-0000-0000-000000000001",
        notification_preferences: profile?.notification_preferences || { session_reminders: true, announcements: true },
      });
    }

    // ── GET /me/ticket ────────────────────────────────────
    if (req.method === "GET" && path === "/me/ticket") {
      if (!userId) return err("TOKEN_EXPIRED", "Требуется авторизация", 401);
      const { data: profile } = await supabaseAdmin.from("user_profiles")
        .select("*").eq("id", userId).single();

      return json({
        id: `ticket_${userId}`,
        ticket_number: "TC26-4821",
        conference_id: "00000000-0000-0000-0000-000000000001",
        type: "general",
        pass_name: profile?.ticket_type || "3-Day Pass",
        valid_from: "2026-07-29T00:00:00-07:00",
        valid_to: "2026-07-31T23:59:59-07:00",
        attendee: {
          id: userId,
          name: profile?.display_name || user.email?.split("@")[0],
          email: user.email,
          company: profile?.company || "",
        },
        qr_payload: `venue-ticket-v1:${btoa(profile?.qr_code_data || `${userId}:techconf-2026`)}`,
        status: "valid",
      });
    }

    // ── User saved sessions ───────────────────────────────
    // PUT /me/saved-sessions/{id}
    const savedPutMatch = path.match(/^\/me\/saved-sessions\/(.+)$/);
    if (req.method === "PUT" && savedPutMatch) {
      if (!userId) return err("TOKEN_EXPIRED", "Требуется авторизация", 401);
      const sid = savedPutMatch[1];
      await supabase.from("user_saved_sessions").upsert({ user_id: userId, session_id: sid });
      return json({ session_id: sid, saved: true, updated_at: new Date().toISOString() });
    }

    // DELETE /me/saved-sessions/{id}
    if (req.method === "DELETE" && savedPutMatch) {
      if (!userId) return err("TOKEN_EXPIRED", "Требуется авторизация", 401);
      const sid = savedPutMatch[1];
      await supabase.from("user_saved_sessions").delete()
        .eq("user_id", userId).eq("session_id", sid);
      return json({ session_id: sid, saved: false, updated_at: new Date().toISOString() });
    }

    // ── Like session ──────────────────────────────────────
    // PUT /sessions/{id}/like
    const likeMatch = path.match(/^\/sessions\/(.+)\/like$/);
    if (req.method === "PUT" && likeMatch) {
      if (!userId) return err("TOKEN_EXPIRED", "Требуется авторизация", 401);
      const sid = likeMatch[1];
      const body = await req.json().catch(() => ({ liked: true }));

      if (body.liked) {
        await supabase.from("user_liked_sessions").upsert({ user_id: userId, session_id: sid });
      } else {
        await supabase.from("user_liked_sessions").delete()
          .eq("user_id", userId).eq("session_id", sid);
      }

      // Get updated count
      const { count } = await supabase.from("user_liked_sessions")
        .select("*", { count: "exact", head: true }).eq("session_id", sid);

      return json({ session_id: sid, liked: body.liked, likes_count: count || 0 });
    }

    // ── Follow speaker ────────────────────────────────────
    // PUT /me/followed-speakers/{id}
    const followPutMatch = path.match(/^\/me\/followed-speakers\/(.+)$/);
    if (req.method === "PUT" && followPutMatch) {
      if (!userId) return err("TOKEN_EXPIRED", "Требуется авторизация", 401);
      const spid = followPutMatch[1];
      await supabase.from("user_followed_speakers").upsert({ user_id: userId, speaker_id: spid });
      return json({ speaker_id: spid, followed: true, updated_at: new Date().toISOString() });
    }

    // DELETE /me/followed-speakers/{id}
    if (req.method === "DELETE" && followPutMatch) {
      if (!userId) return err("TOKEN_EXPIRED", "Требуется авторизация", 401);
      const spid = followPutMatch[1];
      await supabase.from("user_followed_speakers").delete()
        .eq("user_id", userId).eq("speaker_id", spid);
      return json({ speaker_id: spid, followed: false, updated_at: new Date().toISOString() });
    }

    // ── Playback ──────────────────────────────────────────
    // GET /sessions/{id}/playback
    const playbackMatch = path.match(/^\/sessions\/(.+)\/playback$/);
    if (req.method === "GET" && playbackMatch) {
      if (!userId) return err("TOKEN_EXPIRED", "Требуется авторизация", 401);
      const sid = playbackMatch[1];
      const { data: s } = await supabaseAdmin.from("sessions")
        .select("*").eq("id", sid).single();

      if (!s) return err("SESSION_NOT_FOUND", "Сессия не найдена", 404);

      // Get resume position
      const { data: ps } = await supabase.from("playback_state")
        .select("*").eq("user_id", userId).eq("session_id", sid).single();

      return json({
        session_id: sid,
        kind: s.status === "live" ? "live" : "recording",
        stream_url: s.stream_url || s.recording_url || null,
        expires_at: new Date(Date.now() + 3600000).toISOString(),
        available_qualities: ["auto", "1080p", "720p"],
        duration_seconds: s.end_time && s.start_time
          ? Math.round((new Date(s.end_time).getTime() - new Date(s.start_time).getTime()) / 1000)
          : null,
        resume_position_seconds: ps?.position_seconds || 0,
      });
    }

    // PUT /me/playback/{session_id}
    const playbackPutMatch = path.match(/^\/me\/playback\/(.+)$/);
    if (req.method === "PUT" && playbackPutMatch) {
      if (!userId) return err("TOKEN_EXPIRED", "Требуется авторизация", 401);
      const sid = playbackPutMatch[1];
      const body = await req.json();
      const pos = body.position_seconds || 0;
      const dur = body.duration_seconds || 0;
      const progress = dur > 0 ? pos / dur : 0;
      const completed = body.completed || false;

      await supabase.from("playback_state").upsert({
        user_id: userId,
        session_id: sid,
        position_seconds: pos,
        duration_seconds: dur,
        progress,
        completed,
        quality: body.quality || "auto",
        updated_at: new Date().toISOString(),
      });

      return json({
        session_id: sid,
        position_seconds: pos,
        duration_seconds: dur,
        progress,
        completed,
        updated_at: new Date().toISOString(),
      });
    }

    // ── Library ───────────────────────────────────────────
    // GET /me/library?section=recent|favorites|downloads
    if (req.method === "GET" && path === "/me/library") {
      if (!userId) return err("TOKEN_EXPIRED", "Требуется авторизация", 401);
      const section = url.searchParams.get("section") || "recent";

      if (section === "favorites") {
        const { data: saved } = await supabase.from("user_saved_sessions")
          .select("session_id").eq("user_id", userId);
        const ids = (saved || []).map((r: { session_id: string }) => r.session_id);
        if (ids.length === 0) return json({ section, items: [], next_page_token: null });

        const { data: sessions } = await supabaseAdmin.from("session_details")
          .select("*").in("id", ids).order("start_time", { ascending: false });

        return json({
          section,
          items: (sessions || []).map(s => ({
            session: sessionSummary(s),
            progress: null,
            position_seconds: null,
            last_watched_at: null,
            download: null,
          })),
          next_page_token: null,
        });
      }

      if (section === "recent") {
        const { data: recent } = await supabase.from("playback_state")
          .select("*, sessions:sessions(*, categories(*), rooms(*))")
          .eq("user_id", userId)
          .order("updated_at", { ascending: false })
          .limit(10);

        return json({
          section,
          items: (recent || []).map((p: Record<string, unknown>) => ({
            session: { id: p.session_id, title: (p.sessions as Record<string,unknown>)?.title || "", status: (p.sessions as Record<string,unknown>)?.status || "" },
            progress: p.progress,
            position_seconds: p.position_seconds,
            last_watched_at: p.updated_at,
            download: null,
          })),
          next_page_token: null,
        });
      }

      // downloads — empty for now
      return json({ section, items: [], next_page_token: null });
    }

    // ── Downloads ─────────────────────────────────────────
    // POST /sessions/{id}/downloads
    const dlMatch = path.match(/^\/sessions\/(.+)\/downloads$/);
    if (req.method === "POST" && dlMatch) {
      if (!userId) return err("TOKEN_EXPIRED", "Требуется авторизация", 401);
      const sid = dlMatch[1];
      const body = await req.json().catch(() => ({}));
      const expiresAt = new Date(Date.now() + 96 * 3600000).toISOString();

      const { data: dl, error } = await supabase.from("downloads").insert({
        user_id: userId, session_id: sid, status: "queued",
        quality: body.quality || "720p", expires_at: expiresAt,
      }).select().single();

      if (error) throw error;
      return json({
        download_id: dl.id, session_id: sid,
        status: "queued", expires_at: expiresAt,
      }, {}, 202);
    }

    // GET /me/downloads/{id}
    const dlGetMatch = path.match(/^\/me\/downloads\/(.+)$/);
    if (req.method === "GET" && dlGetMatch) {
      if (!userId) return err("TOKEN_EXPIRED", "Требуется авторизация", 401);
      const { data: dl, error } = await supabase.from("downloads")
        .select("*").eq("id", dlGetMatch[1]).eq("user_id", userId).single();
      if (error || !dl) return err("NOT_FOUND", "Загрузка не найдена", 404);

      return json({
        download_id: dl.id, session_id: dl.session_id,
        status: dl.status, size_bytes: dl.size_bytes,
        file_url: dl.file_url, expires_at: dl.expires_at,
      });
    }

    // DELETE /me/downloads/{id}
    if (req.method === "DELETE" && dlGetMatch) {
      if (!userId) return err("TOKEN_EXPIRED", "Требуется авторизация", 401);
      await supabase.from("downloads").delete()
        .eq("id", dlGetMatch[1]).eq("user_id", userId);
      return json({ deleted: true });
    }

    // ── Notifications ─────────────────────────────────────
    // GET /me/notifications
    if (req.method === "GET" && path === "/me/notifications") {
      if (!userId) return err("TOKEN_EXPIRED", "Требуется авторизация", 401);
      const unreadOnly = url.searchParams.get("unread_only") === "true";
      let query = supabase.from("notifications").select("*", { count: "exact" })
        .eq("user_id", userId).order("created_at", { ascending: false }).limit(50);
      if (unreadOnly) query = query.eq("is_read", false);

      const { data: items, count } = await query;

      return json({
        items: (items || []).map((n: Record<string, unknown>) => ({
          id: n.id,
          type: n.type,
          title: n.title,
          body: n.body,
          created_at: n.created_at,
          read_at: n.is_read ? n.created_at : null,
          deep_link: n.session_id ? `venue://session/${n.session_id}` : null,
        })),
        unread_count: (items || []).filter((n: Record<string, unknown>) => !n.is_read).length,
        next_page_token: null,
      });
    }

    // POST /me/notifications/{id}/read
    const notifReadMatch = path.match(/^\/me\/notifications\/(.+)\/read$/);
    if (req.method === "POST" && notifReadMatch) {
      if (!userId) return err("TOKEN_EXPIRED", "Требуется авторизация", 401);
      await supabase.from("notifications").update({ is_read: true })
        .eq("id", notifReadMatch[1]).eq("user_id", userId);
      return json({ success: true });
    }

    // POST /me/notifications/read-all
    if (req.method === "POST" && path === "/me/notifications/read-all") {
      if (!userId) return err("TOKEN_EXPIRED", "Требуется авторизация", 401);
      await supabase.from("notifications").update({ is_read: true })
        .eq("user_id", userId).eq("is_read", false);
      return json({ success: true });
    }

    // ── Devices ───────────────────────────────────────────
    // POST /me/devices
    if (req.method === "POST" && path === "/me/devices") {
      if (!userId) return err("TOKEN_EXPIRED", "Требуется авторизация", 401);
      const body = await req.json();
      const { error } = await supabase.from("devices").upsert({
        user_id: userId, platform: body.platform || "ios",
        device_id: body.device_id, apns_token: body.apns_token,
        environment: body.environment || "production",
        app_version: body.app_version, locale: body.locale || "ru-RU",
        timezone: body.timezone, push_enabled: true,
      });
      if (error) throw error;
      return json({ device_id: body.device_id, push_enabled: true }, {}, 201);
    }

    // GET /me/devices
    if (req.method === "GET" && path === "/me/devices") {
      if (!userId) return err("TOKEN_EXPIRED", "Требуется авторизация", 401);
      const { data, error } = await supabase.from("devices")
        .select("*").eq("user_id", userId);
      if (error) throw error;
      return json(data || []);
    }

    // DELETE /me/devices/{id}
    const devDelMatch = path.match(/^\/me\/devices\/(.+)$/);
    if (req.method === "DELETE" && devDelMatch) {
      if (!userId) return err("TOKEN_EXPIRED", "Требуется авторизация", 401);
      await supabase.from("devices").delete()
        .eq("device_id", devDelMatch[1]).eq("user_id", userId);
      return json({ deleted: true });
    }

    // 404
    return err("NOT_FOUND", "Не найдено", 404);
  } catch (e) {
    return err("INTERNAL_ERROR", e.message, 500);
  }
});
