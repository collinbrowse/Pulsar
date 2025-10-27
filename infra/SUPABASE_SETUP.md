# Supabase Backend Setup Guide

This guide walks you through setting up the Supabase backend for Pulsar.

## Prerequisites

- **Supabase Account**: Sign up at https://supabase.com
- **Supabase CLI** (for local development): 
  ```bash
  brew install supabase/tap/supabase
  ```
- **Docker** (required for local Supabase): https://www.docker.com/get-started

## Project Configuration

**Project URL**: `https://jlyamkhkgjkktiypywkk.supabase.co`  
**Project ID**: `jlyamkhkgjkktiypywkk`

---

## Option 1: Remote Setup (Production/Staging)

### Step 1: Link to Remote Project

```bash
cd infra/supabase
supabase link --project-ref jlyamkhkgjkktiypywkk
```

You'll be prompted for your Supabase access token (get from: https://app.supabase.com/account/tokens)

### Step 2: Push Migrations

```bash
supabase db push
```

This applies all migrations in `migrations/` to your remote database.

### Step 3: Deploy Edge Functions

```bash
# Deploy all functions
supabase functions deploy ingest-activity
supabase functions deploy match-segments
supabase functions deploy leaderboard
```

### Step 4: Create Storage Bucket

In Supabase Dashboard:
1. Go to **Storage**
2. Create new bucket: `activity-files`
3. Make it **public** (or configure RLS policies)
4. Set max file size: 50MB

### Step 5: Configure Authentication

In Supabase Dashboard → **Authentication → Providers**:

1. **Enable Email/Password**
   - Enable "Email Provider"
   - Disable email confirmations for development (enable for production)

2. **Enable Apple Sign In** (optional, for production)
   - Enable "Apple"
   - Add Client ID and Secret from Apple Developer

---

## Option 2: Local Development Setup

### Step 1: Start Local Supabase

```bash
cd infra/supabase
supabase start
```

This will:
- Start Docker containers (Postgres, PostgREST, GoTrue, etc.)
- Apply all migrations automatically
- Create local database at `localhost:54322`

**Output will show**:
```
API URL: http://localhost:54321
GraphQL URL: http://localhost:54321/graphql/v1
DB URL: postgresql://postgres:postgres@localhost:54322/postgres
Studio URL: http://localhost:54323
Inbucket URL: http://localhost:54324
JWT secret: super-secret-jwt-token-with-at-least-32-characters-long
anon key: eyJhbG...
service_role key: eyJhbG...
```

**Save these keys!** You'll need them for local development.

### Step 2: View Supabase Studio

Open: http://localhost:54323

This gives you a local dashboard to:
- View tables and data
- Test SQL queries
- Manage authentication
- Test Edge Functions

### Step 3: Seed Test Data

```bash
supabase db reset --db-url postgresql://postgres:postgres@localhost:54322/postgres
```

This will:
- Reset database
- Reapply all migrations
- Run seed scripts in `seed/`

### Step 4: Deploy Edge Functions Locally

```bash
supabase functions serve
```

Functions will be available at:
- `http://localhost:54321/functions/v1/ingest-activity`
- `http://localhost:54321/functions/v1/match-segments`
- `http://localhost:54321/functions/v1/leaderboard`

---

## Database Schema Overview

### Core Tables

| Table | Description | Key Features |
|-------|-------------|--------------|
| `app.profiles` | User profiles | Linked to auth.users, auto-created on signup |
| `app.activities` | Uploaded activities | PostGIS geometry, RLS for privacy |
| `app.segments` | Known route segments | Spatial indexing for matching |
| `app.segment_efforts` | Leaderboard entries | Denormalized for performance |
| `app.follows` | Social graph | Follower/following relationships |
| `app.kudos` | Activity likes | Unique constraint per user/activity |
| `app.comments` | Activity comments | RLS respects activity visibility |

### Key Features

1. **PostGIS Extension**: Enabled for geospatial queries
2. **Row-Level Security (RLS)**: All tables have RLS policies
3. **Auto-updating timestamps**: `updated_at` updated via triggers
4. **Cascading deletes**: User deletion cascades to activities, etc.

---

## Testing the Setup

### Test 1: Database Connection

```bash
psql postgresql://postgres:postgres@localhost:54322/postgres
```

```sql
-- Check PostGIS
SELECT PostGIS_version();

-- List tables
\dt app.*

-- Count segments
SELECT COUNT(*) FROM app.segments;
```

### Test 2: Create Test User

Using Supabase Studio (http://localhost:54323):

1. Go to **Authentication → Users**
2. Click **Add User**
3. Enter email: `test@example.com`
4. Password: `password123`
5. Check database:

```sql
SELECT * FROM app.profiles WHERE username LIKE 'user_%';
```

Profile should be auto-created via trigger.

### Test 3: Test Edge Function

```bash
curl -X POST http://localhost:54321/functions/v1/leaderboard \
  -H "Content-Type: application/json" \
  -d '{"segment_id": "550e8400-e29b-41d4-a716-446655440001"}'
```

Expected: JSON response with empty leaderboard.

---

## Common Tasks

### Reset Database

```bash
supabase db reset
```

### View Logs

```bash
supabase logs --db postgres
supabase logs --function ingest-activity
```

### Stop Local Supabase

```bash
supabase stop
```

### Generate Migration

```bash
supabase migration new add_new_feature
```

Edit the generated file in `migrations/`, then:

```bash
supabase db reset  # Apply locally
supabase db push   # Push to remote
```

---

## Edge Functions Details

### 1. `ingest-activity`

**Purpose**: Upload and parse activity files (GPX/TCX/FIT)

**Authentication**: Required (JWT)

**Request**:
```bash
curl -X POST http://localhost:54321/functions/v1/ingest-activity \
  -H "Authorization: Bearer <jwt_token>" \
  -F "file=@activity.gpx" \
  -F "activity_type=run" \
  -F "name=Morning Run" \
  -F "visibility=public"
```

**Response**:
```json
{
  "success": true,
  "activity_id": "uuid",
  "stats": {
    "distance_m": 5000,
    "duration_sec": 1800,
    "elevation_gain_m": 150
  }
}
```

### 2. `match-segments`

**Purpose**: Find intersecting segments and create efforts

**Authentication**: Service role (called internally)

**Triggered**: Automatically after activity ingestion

### 3. `leaderboard`

**Purpose**: Get segment leaderboard with filters

**Authentication**: None (public endpoint)

**Request**:
```bash
curl "http://localhost:54321/functions/v1/leaderboard?segment_id=<uuid>&gender=male&age_min=20&age_max=30&limit=50"
```

**Response**:
```json
{
  "segment": {
    "segment_id": "uuid",
    "name": "Golden Gate Bridge Run",
    "distance_km": "2.50"
  },
  "leaderboard": [
    {
      "rank": 1,
      "username": "athlete123",
      "elapsed_time_sec": 420,
      "elapsed_time_formatted": "7:00",
      "is_pr": true
    }
  ]
}
```

---

## Troubleshooting

### "Docker is not running"

**Solution**: Start Docker Desktop

### "Port already in use"

**Solution**: 
```bash
supabase stop
docker ps -a
docker rm -f $(docker ps -aq)
```

### "Migration failed"

**Solution**:
```bash
supabase db reset --debug
```

Check error output for SQL syntax issues.

### "PostGIS function not found"

**Solution**: Ensure PostGIS migration ran:
```sql
SELECT * FROM pg_extension WHERE extname = 'postgis';
```

If missing:
```sql
CREATE EXTENSION postgis;
```

### "RLS policy prevents access"

**Solution**: Check RLS policies:
```sql
SELECT * FROM pg_policies WHERE schemaname = 'app';
```

Temporarily disable RLS for debugging:
```sql
ALTER TABLE app.activities DISABLE ROW LEVEL SECURITY;
```

---

## Security Considerations

1. **Never commit**:
   - Service role keys
   - Database passwords
   - JWT secrets

2. **Enable RLS**: All tables must have RLS enabled

3. **Use service role carefully**: Only in backend Edge Functions

4. **Validate input**: All Edge Functions validate input

5. **CORS**: Configure allowed origins for production

---

## Production Checklist

- [ ] Enable email confirmations
- [ ] Configure Apple Sign In with real credentials
- [ ] Set up proper CORS origins
- [ ] Enable database backups (automatic with Supabase)
- [ ] Monitor function logs
- [ ] Set up alerts for errors
- [ ] Test RLS policies thoroughly
- [ ] Add rate limiting to Edge Functions
- [ ] Configure storage policies
- [ ] Set up staging environment

---

## Useful Commands Cheat Sheet

```bash
# Start local Supabase
supabase start

# Stop local Supabase
supabase stop

# Reset database (reapply migrations)
supabase db reset

# Push migrations to remote
supabase db push

# Pull remote schema changes
supabase db pull

# Generate TypeScript types
supabase gen types typescript --local > types/supabase.ts

# Deploy function
supabase functions deploy <function-name>

# View function logs
supabase functions logs <function-name>

# Link to remote project
supabase link --project-ref <project-ref>

# Run migrations
supabase migration up

# Create new migration
supabase migration new <name>
```

---

## Next Steps

After setup is complete:

1. ✅ Test user signup flow
2. ✅ Test activity upload via Edge Function
3. ✅ Verify segment matching works
4. ✅ Check leaderboards populate correctly
5. ✅ Test iOS app integration
6. ✅ Deploy to production Supabase

---

**Questions?** Check:
- [Supabase Docs](https://supabase.com/docs)
- [PostGIS Reference](https://postgis.net/docs/)
- [Deno Deploy Docs](https://deno.com/deploy/docs)

