# Venue Guide — Supabase Backend

## What is this?

Backend for the **Venue Guide** iOS event companion app.  
Built on [Supabase](https://supabase.com) — PostgreSQL + Auth + Edge Functions.

## Quick Start

```bash
# 1. Install Supabase CLI
brew install supabase/tap/supabase

# 2. Start local Supabase
supabase start

# 3. Run migrations
supabase db reset

# 4. Deploy to production
supabase link --project-ref <your-project-ref>
supabase db push
supabase functions deploy api
```

## Project Structure

```
supabase/
├── migrations/
│   ├── 00001_initial_schema.sql      # Database schema
│   ├── 00002_seed_data.sql           # Test data (TechConf 2026)
│   └── 00003_views_and_functions.sql # API views + Postgres functions
├── functions/
│   └── api/
│       └── index.ts                  # Edge Function — REST API
├── config.toml                       # Supabase project config
└── seed.sql                          # (generated) local dev seed

.github/
└── workflows/
    └── deploy.yml                    # CI/CD: deploy to Supabase on push to main
```

## API Reference

Base URL: `https://<project-ref>.supabase.co/functions/v1/api`

### Public Endpoints

| Method | Path | Description |
|--------|------|-------------|
| GET | `/event/:slug` | Full event dashboard |
| GET | `/sessions` | List sessions (?event_id=&status=&day=&q=) |
| GET | `/sessions/:id` | Session detail with speakers |
| GET | `/speakers` | List speakers (?event_id=) |
| GET | `/speakers/:id` | Speaker profile with sessions |
| GET | `/recordings` | Library content (?event_id=) |
| GET | `/map` | Venue map locations (?event_id=) |
| GET | `/rooms` | Rooms & stages (?event_id=) |
| GET | `/categories` | Session categories (?event_id=) |

### Authenticated Endpoints

| Method | Path | Description |
|--------|------|-------------|
| GET | `/schedule` | My saved sessions |
| POST | `/schedule/:id` | Toggle save/unsave session |
| POST | `/like/:id` | Toggle like/unlike session |
| POST | `/follow/:id` | Toggle follow/unfollow speaker |
| GET | `/notifications` | My notifications |
| POST | `/notifications/:id/read` | Mark notification as read |
| GET | `/profile` | My user profile |

## Database Schema

### Event Data (public read)
- **events** — Main event info
- **categories** — Session categories (Keynote, Workshop, Talk…)
- **sessions** — Individual talks with times, rooms, status
- **speakers** — Speaker profiles
- **session_speakers** — Many-to-many link
- **rooms** — Venue rooms & stages
- **venue_locations** — Map coordinates
- **recordings** — Video archive / library

### User Data (auth-required)
- **user_profiles** — Extends Supabase auth
- **user_saved_sessions** — Personal schedule
- **user_liked_sessions** — Liked sessions
- **user_followed_speakers** — Followed speakers
- **notifications** — In-app notifications
- **event_photos** — User photo gallery

## GitHub Actions Deployment

1. Get your access token from [Supabase Dashboard → Account → Tokens](https://supabase.com/dashboard/account/tokens)
2. Find your project ref in Supabase Dashboard → Settings → General
3. Add these secrets to your GitHub repo:
   - `SUPABASE_ACCESS_TOKEN`
   - `SUPABASE_PROJECT_ID`
   - `SUPABASE_DB_PASSWORD`
4. Push to `main` — the workflow runs automatically

## Local Development

The seed data creates a complete **TechConf 2026** event with:
- 13 sessions across 3 days
- 9 speakers from Apple, OpenAI, Figma, Vercel, Cloudflare, Meta, Anthropic, Stripe, Netflix
- 6 rooms/stages
- 10 venue map locations
- 4 library recordings
- Demo user: `demo@venueguide.app` / `demopass123`
