-- ============================================================
-- Venue Guide — Seed Data: TechConf 2026
-- Based on the frontend mock data from Figma design
-- ============================================================

-- ── Event ───────────────────────────────────────────────────
INSERT INTO events (id, name, slug, description, start_date, end_date, location, city, country, timezone) VALUES
(
  '00000000-0000-0000-0000-000000000001',
  'TechConf 2026',
  'techconf-2026',
  'The premier technology conference featuring world-class speakers, hands-on workshops, and cutting-edge topics in AI, spatial computing, design systems, web performance, and security.',
  '2026-09-15',
  '2026-09-17',
  'Moscone Center',
  'San Francisco',
  'USA',
  'America/Los_Angeles'
);

-- ── Categories ──────────────────────────────────────────────
INSERT INTO categories (id, event_id, name, color, icon, sort_order) VALUES
('c0000001-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000001', 'Keynote',   '#007AFF', 'star',         1),
('c0000001-0000-0000-0000-000000000002', '00000000-0000-0000-0000-000000000001', 'Workshop',  '#FF9500', 'wrench',       2),
('c0000001-0000-0000-0000-000000000003', '00000000-0000-0000-0000-000000000001', 'Talk',      '#5856D6', 'message-square', 3),
('c0000001-0000-0000-0000-000000000004', '00000000-0000-0000-0000-000000000001', 'Panel',     '#34C759', 'users',        4),
('c0000001-0000-0000-0000-000000000005', '00000000-0000-0000-0000-000000000001', 'Networking','#FF2D55', 'heart',        5);

-- ── Rooms / Stages ──────────────────────────────────────────
INSERT INTO rooms (id, event_id, name, type, capacity, floor, description) VALUES
('r0000001-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000001', 'Main Stage',       'stage',     1200, '1F', 'Main keynote hall with 4K LED wall'),
('r0000001-0000-0000-0000-000000000002', '00000000-0000-0000-0000-000000000001', 'Innovation Stage', 'stage',      400, '1F', 'Intimate stage for product demos'),
('r0000001-0000-0000-0000-000000000003', '00000000-0000-0000-0000-000000000001', 'Design Stage',     'stage',      300, '1F', 'Focused on design and UX topics'),
('r0000001-0000-0000-0000-000000000004', '00000000-0000-0000-0000-000000000001', 'Security Stage',   'stage',      250, '2F', 'Security and infrastructure talks'),
('r0000001-0000-0000-0000-000000000005', '00000000-0000-0000-0000-000000000001', 'Engineering Stage','stage',      350, '2F', 'Engineering deep dives'),
('r0000001-0000-0000-0000-000000000006', '00000000-0000-0000-0000-000000000001', 'Community Stage',  'stage',      200, '2F', 'Community and open source'),
('r0000001-0000-0000-0000-000000000007', '00000000-0000-0000-0000-000000000001', 'Workshop A',       'workshop',   60,  '1F', 'Hands-on workshop room'),
('r0000001-0000-0000-0000-000000000008', '00000000-0000-0000-0000-000000000001', 'Workshop B',       'workshop',   60,  '1F', 'Hands-on workshop room'),
('r0000001-0000-0000-0000-000000000009', '00000000-0000-0000-0000-000000000001', 'Expo Hall',        'booth',     null, '1F', 'Exhibition and sponsor booths'),
('r0000001-0000-0000-0000-000000000010', '00000000-0000-0000-0000-000000000001', 'Food Court',       'food',      null, '1F', 'Dining area with food trucks'),
('r0000001-0000-0000-0000-000000000011', '00000000-0000-0000-0000-000000000001', 'Registration',     'entrance',  null, '1F', 'Check-in and badge pickup');

-- ── Speakers ────────────────────────────────────────────────
INSERT INTO speakers (id, event_id, name, company, role, bio, photo_url, topics) VALUES
(
  '00000000-0000-0000-0000-000000000101',
  '00000000-0000-0000-0000-000000000001',
  'Sarah Chen', 'Apple', 'VP of Platform Engineering',
  'Sarah leads platform engineering at Apple with a focus on developer experience for Vision Pro. Previously at Google Brain and Stanford AI Lab, she has spent 15 years at the intersection of research and shipping.',
  'https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?w=400',
  ARRAY['Spatial Computing', 'AR/VR', 'Developer Tools']
),
(
  '00000000-0000-0000-0000-000000000102',
  '00000000-0000-0000-0000-000000000001',
  'Marcus Williams', 'OpenAI', 'Head of Product',
  'Marcus drives product strategy at OpenAI, focusing on developer APIs and enterprise integrations. Former PM at Stripe and GitHub, and an early contributor to the GraphQL specification.',
  'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=400',
  ARRAY['AI Products', 'LLMs', 'Product Strategy']
),
(
  '00000000-0000-0000-0000-000000000103',
  '00000000-0000-0000-0000-000000000001',
  'Yuki Tanaka', 'Figma', 'Principal Designer',
  'Yuki has been building Figma''s design system since 2019, growing it from a handful of components to a full-scale system used by over 4 million designers. Speaker at Config, Schema, and SmashingConf.',
  'https://images.unsplash.com/photo-1580489944761-15a19d654956?w=400',
  ARRAY['Design Systems', 'Tokens', 'Design at Scale']
),
(
  '00000000-0000-0000-0000-000000000104',
  '00000000-0000-0000-0000-000000000001',
  'Alex Rodriguez', 'Vercel', 'Developer Advocate',
  'Alex evangelizes modern web performance patterns at Vercel and created several widely-adopted open source benchmarking tools. Previously on the Chrome DevRel team at Google.',
  'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=400',
  ARRAY['Web Performance', 'Next.js', 'Edge Computing']
),
(
  '00000000-0000-0000-0000-000000000105',
  '00000000-0000-0000-0000-000000000001',
  'Priya Patel', 'Cloudflare', 'Director of Security Research',
  'Priya leads security research at Cloudflare, where her team protects millions of websites from emerging threats. She has testified before Congress on AI safety and co-authored the NIST AI Risk Framework.',
  'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=400',
  ARRAY['Zero Trust', 'AI Security', 'Network Defense']
),
(
  '00000000-0000-0000-0000-000000000106',
  '00000000-0000-0000-0000-000000000001',
  'Tom Occhino', 'Meta', 'Engineering Director',
  'Tom co-created React and led the team that open-sourced it in 2013. He now leads Meta''s open source strategy and chairs the OpenJS Foundation board of directors.',
  'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=400',
  ARRAY['Open Source', 'React', 'Developer Community']
),
(
  '00000000-0000-0000-0000-000000000107',
  '00000000-0000-0000-0000-000000000001',
  'David Kim', 'Anthropic', 'Research Scientist',
  'David leads research on language model alignment and safety at Anthropic. His work focuses on making AI systems more reliable, interpretable, and aligned with human values.',
  'https://images.unsplash.com/photo-1519085360753-af0119f7cbe7?w=400',
  ARRAY['AI Safety', 'Alignment', 'Interpretability']
),
(
  '00000000-0000-0000-0000-000000000108',
  '00000000-0000-0000-0000-000000000001',
  'Emma Davis', 'Stripe', 'Staff Engineer',
  'Emma leads the developer infrastructure team at Stripe, building tools that power millions of API requests per second. She is a core contributor to several open source Node.js projects.',
  'https://images.unsplash.com/photo-1438761681033-6461ffad8d80?w=400',
  ARRAY['Node.js', 'API Design', 'Developer Infrastructure']
),
(
  '00000000-0000-0000-0000-000000000109',
  '00000000-0000-0000-0000-000000000001',
  'James Park', 'Netflix', 'Principal Engineer',
  'James architects the streaming infrastructure that delivers content to over 260 million subscribers worldwide. His team focuses on ultra-low-latency video delivery at global scale.',
  'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?w=400',
  ARRAY['Streaming', 'Distributed Systems', 'Video Technology']
);

-- ── Sessions ────────────────────────────────────────────────
INSERT INTO sessions (id, event_id, title, description, category_id, room_id, start_time, end_time, status, image_url, stream_url) VALUES
(
  '00000000-0000-0000-0000-000000000201',
  '00000000-0000-0000-0000-000000000001',
  'The Future of Spatial Computing',
  'An in-depth exploration of how spatial computing is reshaping human-computer interaction. From Apple Vision Pro to the next decade of immersive experiences built for everyday life.',
  'c0000001-0000-0000-0000-000000000001',
  'r0000001-0000-0000-0000-000000000001',
  '2026-09-15 10:00:00-07', '2026-09-15 10:45:00-07',
  'live',
  'https://images.unsplash.com/photo-1540575467063-178a50c2df87?w=800',
  'https://stream.techconf.example/live/main-stage'
),
(
  '00000000-0000-0000-0000-000000000202',
  '00000000-0000-0000-0000-000000000001',
  'Building AI-Native Products at Scale',
  'Practical frameworks for integrating large language models into product workflows. Real-world case studies and patterns from production AI systems serving millions of users.',
  'c0000001-0000-0000-0000-000000000002',
  'r0000001-0000-0000-0000-000000000002',
  '2026-09-15 11:30:00-07', '2026-09-15 12:00:00-07',
  'live',
  'https://images.unsplash.com/photo-1620712943543-bcc4688e7485?w=800',
  'https://stream.techconf.example/live/innovation-stage'
),
(
  '00000000-0000-0000-0000-000000000203',
  '00000000-0000-0000-0000-000000000001',
  'Design Systems at Scale',
  'How Figma''s design team built and maintains a system used by millions of designers. Token architecture, governance, and the human side of scaling design systems.',
  'c0000001-0000-0000-0000-000000000003',
  'r0000001-0000-0000-0000-000000000003',
  '2026-09-15 13:00:00-07', '2026-09-15 13:40:00-07',
  'upcoming',
  'https://images.unsplash.com/photo-1558618666-fcd25c85cd64?w=800',
  NULL
),
(
  '00000000-0000-0000-0000-000000000204',
  '00000000-0000-0000-0000-000000000001',
  'Web Performance in 2026',
  'Core Web Vitals evolution, edge rendering patterns, and the performance-budget mindset that makes shipping fast the default rather than an afterthought.',
  'c0000001-0000-0000-0000-000000000003',
  'r0000001-0000-0000-0000-000000000005',
  '2026-09-15 14:30:00-07', '2026-09-15 15:05:00-07',
  'upcoming',
  'https://images.unsplash.com/photo-1461749280684-dccba630e2f6?w=800',
  NULL
),
(
  '00000000-0000-0000-0000-000000000205',
  '00000000-0000-0000-0000-000000000001',
  'Security in the Age of AI',
  'How AI is changing the threat landscape and how we build defenses that adapt. From prompt injection to model poisoning to zero-trust at the edge.',
  'c0000001-0000-0000-0000-000000000001',
  'r0000001-0000-0000-0000-000000000004',
  '2026-09-15 15:45:00-07', '2026-09-15 16:30:00-07',
  'upcoming',
  'https://images.unsplash.com/photo-1555949963-aa79dcee981c?w=800',
  NULL
),
(
  '00000000-0000-0000-0000-000000000206',
  '00000000-0000-0000-0000-000000000001',
  'Open Source Sustainability',
  'The state of open source software: maintainer burnout, corporate contributions, and what healthy community-driven ecosystems actually look like in practice.',
  'c0000001-0000-0000-0000-000000000003',
  'r0000001-0000-0000-0000-000000000006',
  '2026-09-15 09:00:00-07', '2026-09-15 09:30:00-07',
  'recorded',
  'https://images.unsplash.com/photo-1510915361894-db8b60106cb1?w=800',
  NULL
),
-- Day 2 sessions
(
  '00000000-0000-0000-0000-000000000207',
  '00000000-0000-0000-0000-000000000001',
  'The AI Alignment Problem: Progress and Challenges',
  'A deep dive into the technical challenges of aligning AI systems with human values. Recent breakthroughs and unsolved problems in the field.',
  'c0000001-0000-0000-0000-000000000001',
  'r0000001-0000-0000-0000-000000000001',
  '2026-09-16 10:00:00-07', '2026-09-16 11:00:00-07',
  'upcoming',
  'https://images.unsplash.com/photo-1677442135703-1787eea5ce01?w=800',
  NULL
),
(
  '00000000-0000-0000-0000-000000000208',
  '00000000-0000-0000-0000-000000000001',
  'React Server Components: A Year in Production',
  'Lessons learned from deploying React Server Components at scale. Performance gains, developer experience improvements, and migration strategies.',
  'c0000001-0000-0000-0000-000000000002',
  'r0000001-0000-0000-0000-000000000007',
  '2026-09-16 11:30:00-07', '2026-09-16 12:30:00-07',
  'upcoming',
  'https://images.unsplash.com/photo-1587825140708-dfaf72ae4b04?w=800',
  NULL
),
(
  '00000000-0000-0000-0000-000000000209',
  '00000000-0000-0000-0000-000000000001',
  'Streaming at Planet Scale',
  'How Netflix delivers seamless video to 260M+ subscribers. The architecture, the failures, and the innovations that make global streaming possible.',
  'c0000001-0000-0000-0000-000000000003',
  'r0000001-0000-0000-0000-000000000005',
  '2026-09-16 14:00:00-07', '2026-09-16 14:45:00-07',
  'upcoming',
  'https://images.unsplash.com/photo-1461749280684-dccba630e2f6?w=800',
  NULL
),
(
  '00000000-0000-0000-0000-000000000210',
  '00000000-0000-0000-0000-000000000001',
  'Building Accessible Developer Tools',
  'Practical patterns for making developer tools accessible. From CLI to IDE to web dashboards — inclusive design for the tools that build the internet.',
  'c0000001-0000-0000-0000-000000000002',
  'r0000001-0000-0000-0000-000000000008',
  '2026-09-16 16:00:00-07', '2026-09-16 16:30:00-07',
  'upcoming',
  'https://images.unsplash.com/photo-1517245386807-bb43f82c33c4?w=800',
  NULL
),
-- Day 3 sessions
(
  '00000000-0000-0000-0000-000000000211',
  '00000000-0000-0000-0000-000000000001',
  'The New CSS: Container Queries & Beyond',
  'Modern CSS features that are transforming web design. Container queries, cascade layers, :has(), view transitions, and what is coming next.',
  'c0000001-0000-0000-0000-000000000003',
  'r0000001-0000-0000-0000-000000000003',
  '2026-09-17 10:00:00-07', '2026-09-17 10:35:00-07',
  'upcoming',
  'https://images.unsplash.com/photo-1504639725590-34d0984388bd?w=800',
  NULL
),
(
  '00000000-0000-0000-0000-000000000212',
  '00000000-0000-0000-0000-000000000001',
  'Distributed Systems War Stories',
  'A panel of senior engineers sharing real stories of distributed systems failures, near-misses, and hard-won lessons from operating at scale.',
  'c0000001-0000-0000-0000-000000000004',
  'r0000001-0000-0000-0000-000000000001',
  '2026-09-17 13:00:00-07', '2026-09-17 14:00:00-07',
  'upcoming',
  'https://images.unsplash.com/photo-1556761175-b413da4baf72?w=800',
  NULL
),
(
  '00000000-0000-0000-0000-000000000213',
  '00000000-0000-0000-0000-000000000001',
  'Closing Party & Networking',
  'Join us for drinks, music, and conversation. Meet the speakers, connect with fellow attendees, and celebrate three amazing days of learning.',
  'c0000001-0000-0000-0000-000000000005',
  'r0000001-0000-0000-0000-000000000010',
  '2026-09-17 17:00:00-07', '2026-09-17 20:00:00-07',
  'upcoming',
  'https://images.unsplash.com/photo-1540575467063-178a50c2df87?w=800',
  NULL
);

-- ── Session ↔ Speaker Links ─────────────────────────────────
INSERT INTO session_speakers (session_id, speaker_id) VALUES
('00000000-0000-0000-0000-000000000201', '00000000-0000-0000-0000-000000000101'), -- Spatial Computing → Sarah Chen
('00000000-0000-0000-0000-000000000202', '00000000-0000-0000-0000-000000000102'), -- AI-Native → Marcus Williams
('00000000-0000-0000-0000-000000000203', '00000000-0000-0000-0000-000000000103'), -- Design Systems → Yuki Tanaka
('00000000-0000-0000-0000-000000000204', '00000000-0000-0000-0000-000000000104'), -- Web Perf → Alex Rodriguez
('00000000-0000-0000-0000-000000000205', '00000000-0000-0000-0000-000000000105'), -- Security → Priya Patel
('00000000-0000-0000-0000-000000000206', '00000000-0000-0000-0000-000000000106'), -- Open Source → Tom Occhino
('00000000-0000-0000-0000-000000000207', '00000000-0000-0000-0000-000000000107'), -- AI Alignment → David Kim
('00000000-0000-0000-0000-000000000208', '00000000-0000-0000-0000-000000000104'), -- RSC → Alex Rodriguez
('00000000-0000-0000-0000-000000000208', '00000000-0000-0000-0000-000000000106'), -- RSC → Tom Occhino (co-speaker)
('00000000-0000-0000-0000-000000000209', '00000000-0000-0000-0000-000000000109'), -- Streaming → James Park
('00000000-0000-0000-0000-000000000210', '00000000-0000-0000-0000-000000000108'), -- Accessible Tools → Emma Davis
('00000000-0000-0000-0000-000000000211', '00000000-0000-0000-0000-000000000103'), -- CSS → Yuki Tanaka
('00000000-0000-0000-0000-000000000212', '00000000-0000-0000-0000-000000000106'), -- Panel → Tom Occhino
('00000000-0000-0000-0000-000000000212', '00000000-0000-0000-0000-000000000108'), -- Panel → Emma Davis
('00000000-0000-0000-0000-000000000212', '00000000-0000-0000-0000-000000000109'), -- Panel → James Park
('00000000-0000-0000-0000-000000000213', '00000000-0000-0000-0000-000000000101'), -- Closing → Sarah Chen
('00000000-0000-0000-0000-000000000213', '00000000-0000-0000-0000-000000000102'); -- Closing → Marcus Williams

-- ── Venue Map Locations ─────────────────────────────────────
INSERT INTO venue_locations (id, event_id, room_id, label, type, color, pos_x, pos_y, width, height) VALUES
('m0000001-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000001', 'r0000001-0000-0000-0000-000000000001', 'Main Stage',     'stage',        '#007AFF', 28,  18,  200, 108),
('m0000001-0000-0000-0000-000000000002', '00000000-0000-0000-0000-000000000001', 'r0000001-0000-0000-0000-000000000002', 'Innovation Stage','stage',      '#5856D6', 246, 18,  120, 78),
('m0000001-0000-0000-0000-000000000003', '00000000-0000-0000-0000-000000000001', 'r0000001-0000-0000-0000-000000000003', 'Design Stage',   'stage',        '#FF2D55', 246, 112, 120, 78),
('m0000001-0000-0000-0000-000000000004', '00000000-0000-0000-0000-000000000001', 'r0000001-0000-0000-0000-000000000007', 'Workshop A',     'workshop',     '#FF9500', 28,  148, 90,  68),
('m0000001-0000-0000-0000-000000000005', '00000000-0000-0000-0000-000000000001', 'r0000001-0000-0000-0000-000000000008', 'Workshop B',     'workshop',     '#FF9500', 128, 148, 90,  68),
('m0000001-0000-0000-0000-000000000006', '00000000-0000-0000-0000-000000000001', 'r0000001-0000-0000-0000-000000000009', 'Expo Hall',      'expo',         '#8E8E93', 200, 210, 170, 90),
('m0000001-0000-0000-0000-000000000007', '00000000-0000-0000-0000-000000000001', 'r0000001-0000-0000-0000-000000000010', 'Food Court',     'food',         '#34C759', 28,  240, 150, 60),
('m0000001-0000-0000-0000-000000000008', '00000000-0000-0000-0000-000000000001', 'r0000001-0000-0000-0000-000000000011', 'Registration',   'registration', '#5AC8FA', 28,  320, 340, 40),
('m0000001-0000-0000-0000-000000000009', '00000000-0000-0000-0000-000000000001', 'r0000001-0000-0000-0000-000000000004', 'Security Stage', 'stage',        '#FF3B30', 28,  360, 170, 50),
('m0000001-0000-0000-0000-000000000010', '00000000-0000-0000-0000-000000000001', 'r0000001-0000-0000-0000-000000000006', 'Community Stage','stage',        '#AF52DE', 210, 360, 158, 50);

-- ── Recordings (Library) ────────────────────────────────────
INSERT INTO recordings (id, event_id, session_id, title, speaker_name, speaker_photo_url, duration, views_count, category, thumbnail_url) VALUES
(
  'l0000001-0000-0000-0000-000000000001',
  '00000000-0000-0000-0000-000000000001',
  NULL,
  'Opening Keynote 2025',
  'David Kim',
  'https://images.unsplash.com/photo-1519085360753-af0119f7cbe7?w=200',
  '1h 12m', 24300, 'Keynote',
  'https://images.unsplash.com/photo-1540575467063-178a50c2df87?w=600'
),
(
  'l0000001-0000-0000-0000-000000000002',
  '00000000-0000-0000-0000-000000000001',
  '00000000-0000-0000-0000-000000000206',
  'Open Source Sustainability',
  'Tom Occhino',
  'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=200',
  '30m', 18700, 'Talk',
  'https://images.unsplash.com/photo-1510915361894-db8b60106cb1?w=600'
),
(
  'l0000001-0000-0000-0000-000000000003',
  '00000000-0000-0000-0000-000000000001',
  NULL,
  'The New CSS: Container Queries & Beyond',
  'Yuki Tanaka',
  'https://images.unsplash.com/photo-1580489944761-15a19d654956?w=200',
  '35m', 11200, 'Talk',
  'https://images.unsplash.com/photo-1504639725590-34d0984388bd?w=600'
),
(
  'l0000001-0000-0000-0000-000000000004',
  '00000000-0000-0000-0000-000000000001',
  NULL,
  'React Server Components Deep Dive',
  'Alex Rodriguez',
  'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=200',
  '48m', 9200, 'Workshop',
  'https://images.unsplash.com/photo-1587825140708-dfaf72ae4b04?w=600'
);

-- ── Demo User & Data ────────────────────────────────────────
-- Note: Create a real user through Supabase Auth first, then run this.
-- This section is an example for local development seeding.

DO $$
DECLARE
  demo_user_id UUID;
BEGIN
  -- Create a demo user in auth.users (only works in local/dev Supabase)
  -- For production, users are created via Supabase Auth
  IF current_setting('app.settings.environment', true) = 'development' THEN
    INSERT INTO auth.users (
      id, instance_id, email, encrypted_password, email_confirmed_at,
      raw_app_meta_data, raw_user_meta_data, created_at, updated_at
    ) VALUES (
      '00000000-0000-0000-0000-000000000999',
      '00000000-0000-0000-0000-000000000000',
      'demo@venueguide.app',
      crypt('demopass123', gen_salt('bf')),
      now(),
      '{"provider":"email"}',
      '{"display_name":"Alex Attendee","company":"TechStart Inc.","job_title":"Senior Developer"}',
      now(), now()
    ) ON CONFLICT (id) DO NOTHING;

    demo_user_id := '00000000-0000-0000-0000-000000000999';

    -- User profile
    INSERT INTO user_profiles (id, display_name, company, job_title, ticket_type, qr_code_data)
    VALUES (
      demo_user_id,
      'Alex Attendee',
      'TechStart Inc.',
      'Senior Developer',
      'VIP Pass',
      'VENUE-TECHCONF2026-VIP-A1B2C3'
    ) ON CONFLICT (id) DO NOTHING;

    -- Save some sessions to schedule
    INSERT INTO user_saved_sessions (user_id, session_id) VALUES
    (demo_user_id, '00000000-0000-0000-0000-000000000201'), -- Spatial Computing
    (demo_user_id, '00000000-0000-0000-0000-000000000203'), -- Design Systems
    (demo_user_id, '00000000-0000-0000-0000-000000000208'), -- RSC Deep Dive
    (demo_user_id, '00000000-0000-0000-0000-000000000212')  -- Distributed Systems Panel
    ON CONFLICT DO NOTHING;

    -- Like some sessions
    INSERT INTO user_liked_sessions (user_id, session_id) VALUES
    (demo_user_id, '00000000-0000-0000-0000-000000000201'),
    (demo_user_id, '00000000-0000-0000-0000-000000000202'),
    (demo_user_id, '00000000-0000-0000-0000-000000000203')
    ON CONFLICT DO NOTHING;

    -- Follow speakers
    INSERT INTO user_followed_speakers (user_id, speaker_id) VALUES
    (demo_user_id, '00000000-0000-0000-0000-000000000101'), -- Sarah Chen
    (demo_user_id, '00000000-0000-0000-0000-000000000103'), -- Yuki Tanaka
    (demo_user_id, '00000000-0000-0000-0000-000000000107')  -- David Kim
    ON CONFLICT DO NOTHING;

    -- Demo notifications
    INSERT INTO notifications (id, user_id, type, title, body, session_id, is_read) VALUES
    (gen_random_uuid(), demo_user_id, 'reminder',     'Session starting soon',       'The Future of Spatial Computing starts in 15 minutes',         '00000000-0000-0000-0000-000000000201', false),
    (gen_random_uuid(), demo_user_id, 'announcement', 'Keynote speaker announced',    'David Kim will present the opening keynote on Day 2',          NULL,                                   false),
    (gen_random_uuid(), demo_user_id, 'change',       'Room change: Design Systems',  'Moved from Studio 2 to Design Stage',                          '00000000-0000-0000-0000-000000000203', true),
    (gen_random_uuid(), demo_user_id, 'recording',    'Recording available',          'Open Source Sustainability is now available to watch',          '00000000-0000-0000-0000-000000000206', false),
    (gen_random_uuid(), demo_user_id, 'announcement', 'Welcome to TechConf 2026!',    'Check in at Registration to pick up your badge and welcome kit', NULL,                                  false);

    RAISE NOTICE 'Demo user seeded: demo@venueguide.app / demopass123';
  END IF;
END;
$$;
