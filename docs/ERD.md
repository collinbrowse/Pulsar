# Entity Relationship Diagram

## Core Entities

### Users & Profiles
```
profiles
├── user_id (PK, UUID, FK -> auth.users)
├── username (UNIQUE, TEXT)
├── full_name (TEXT)
├── avatar_url (TEXT)
├── gender (TEXT) - 'male', 'female', 'other', 'prefer_not_to_say'
├── weight_kg (DECIMAL)
├── birth_year (INTEGER)
├── created_at (TIMESTAMP)
└── updated_at (TIMESTAMP)
```

### Activities
```
activities
├── activity_id (PK, UUID)
├── user_id (FK -> profiles.user_id)
├── activity_type (TEXT) - 'run', 'ride', 'swim', 'hike', etc.
├── name (TEXT)
├── description (TEXT)
├── distance_m (DECIMAL)
├── duration_sec (INTEGER)
├── elevation_gain_m (DECIMAL)
├── avg_heart_rate (INTEGER)
├── max_heart_rate (INTEGER)
├── avg_power (INTEGER)
├── geom (GEOMETRY(LINESTRING, 4326)) - PostGIS
├── start_time (TIMESTAMP)
├── visibility (TEXT) - 'public', 'followers', 'private'
├── file_url (TEXT) - S3/Supabase Storage URL
├── created_at (TIMESTAMP)
└── updated_at (TIMESTAMP)

Indexes:
- geom (GIST index for spatial queries)
- user_id, start_time (for user activity list)
```

### Segments
```
segments
├── segment_id (PK, UUID)
├── name (TEXT)
├── geom (GEOMETRY(LINESTRING, 4326)) - PostGIS
├── distance_m (DECIMAL)
├── elevation_gain_m (DECIMAL)
├── activity_type (TEXT)
├── created_by (FK -> profiles.user_id)
├── created_at (TIMESTAMP)
└── updated_at (TIMESTAMP)

Indexes:
- geom (GIST index for spatial matching)
```

### Segment Efforts
```
segment_efforts
├── effort_id (PK, UUID)
├── segment_id (FK -> segments.segment_id)
├── activity_id (FK -> activities.activity_id)
├── user_id (FK -> profiles.user_id)
├── elapsed_time_sec (INTEGER)
├── avg_heart_rate (INTEGER)
├── avg_power (INTEGER)
├── effort_date (DATE)
└── created_at (TIMESTAMP)

Indexes:
- segment_id, elapsed_time_sec (for leaderboards)
- user_id, segment_id (for personal records)
```

### Routes
```
routes
├── route_id (PK, UUID)
├── name (TEXT)
├── description (TEXT)
├── geom (GEOMETRY(LINESTRING, 4326))
├── distance_m (DECIMAL)
├── elevation_gain_m (DECIMAL)
├── activity_type (TEXT)
├── created_by (FK -> profiles.user_id)
├── popularity_count (INTEGER)
├── is_public (BOOLEAN)
├── created_at (TIMESTAMP)
└── updated_at (TIMESTAMP)

Indexes:
- geom (GIST index)
- popularity_count (for sorting)
```

### Social Graph
```
follows
├── follow_id (PK, UUID)
├── follower_id (FK -> profiles.user_id)
├── following_id (FK -> profiles.user_id)
├── created_at (TIMESTAMP)
└── UNIQUE(follower_id, following_id)

Indexes:
- follower_id (for "following" list)
- following_id (for "followers" list)
```

### Social Interactions
```
kudos
├── kudos_id (PK, UUID)
├── activity_id (FK -> activities.activity_id)
├── user_id (FK -> profiles.user_id)
├── created_at (TIMESTAMP)
└── UNIQUE(activity_id, user_id)

comments
├── comment_id (PK, UUID)
├── activity_id (FK -> activities.activity_id)
├── user_id (FK -> profiles.user_id)
├── text (TEXT)
├── created_at (TIMESTAMP)
└── updated_at (TIMESTAMP)

Indexes:
- activity_id, created_at (for comment lists)
```

### Clubs & Challenges
```
clubs
├── club_id (PK, UUID)
├── name (TEXT)
├── description (TEXT)
├── avatar_url (TEXT)
├── created_by (FK -> profiles.user_id)
├── created_at (TIMESTAMP)
└── updated_at (TIMESTAMP)

club_members
├── membership_id (PK, UUID)
├── club_id (FK -> clubs.club_id)
├── user_id (FK -> profiles.user_id)
├── role (TEXT) - 'owner', 'admin', 'member'
├── joined_at (TIMESTAMP)
└── UNIQUE(club_id, user_id)

challenges
├── challenge_id (PK, UUID)
├── club_id (FK -> clubs.club_id)
├── name (TEXT)
├── description (TEXT)
├── metric (TEXT) - 'distance', 'duration', 'elevation'
├── target_value (DECIMAL)
├── start_date (DATE)
├── end_date (DATE)
├── created_at (TIMESTAMP)
└── updated_at (TIMESTAMP)
```

### Goals
```
goals
├── goal_id (PK, UUID)
├── user_id (FK -> profiles.user_id)
├── metric (TEXT) - 'distance', 'duration', 'elevation', 'activity_count'
├── period (TEXT) - 'week', 'month', 'year', 'custom'
├── target_value (DECIMAL)
├── current_value (DECIMAL)
├── start_date (DATE)
├── end_date (DATE)
├── is_repeating (BOOLEAN)
├── created_at (TIMESTAMP)
└── updated_at (TIMESTAMP)
```

### Premium & Entitlements
```
entitlements
├── entitlement_id (PK, UUID)
├── user_id (FK -> profiles.user_id)
├── feature_key (TEXT) - 'premium_analytics', 'full_leaderboards', etc.
├── start_date (DATE)
├── end_date (DATE)
├── subscription_id (TEXT) - App Store subscription ID
├── created_at (TIMESTAMP)
└── updated_at (TIMESTAMP)

Indexes:
- user_id, feature_key, end_date (for access checks)
```

## Relationships

```
profiles 1---* activities
profiles 1---* segment_efforts
profiles 1---* routes
profiles 1---* goals
profiles 1---* kudos
profiles 1---* comments
profiles 1---* club_members
profiles 1---* entitlements

segments 1---* segment_efforts
activities 1---* segment_efforts
activities 1---* kudos
activities 1---* comments

clubs 1---* club_members
clubs 1---* challenges

profiles *---* profiles (follows - self-referential)
```

## PostGIS Spatial Queries

### Segment Matching
```sql
SELECT s.segment_id, s.name
FROM segments s
WHERE ST_Intersects(
  s.geom, 
  (SELECT geom FROM activities WHERE activity_id = $1)
)
AND s.activity_type = (SELECT activity_type FROM activities WHERE activity_id = $1);
```

### Nearby Routes
```sql
SELECT r.route_id, r.name, r.distance_m,
       ST_Distance(r.geom::geography, ST_SetSRID(ST_MakePoint($1, $2), 4326)::geography) as distance
FROM routes r
WHERE r.is_public = true
  AND r.distance_m BETWEEN $3 AND $4
ORDER BY distance
LIMIT 20;
```

### Privacy Zone Blurring
```sql
UPDATE activities
SET geom = ST_RemovePoint(
  ST_RemovePoint(geom, 0), -- Remove first point
  ST_NPoints(geom) - 1     -- Remove last point
)
WHERE activity_id = $1;
```

## Row-Level Security (RLS) Policies

### Activities
- `SELECT`: Users can see public activities, or follower-only from followed users, or their own
- `INSERT`: Users can insert their own activities
- `UPDATE`: Users can update only their own activities
- `DELETE`: Users can delete only their own activities

### Profiles
- `SELECT`: Public (all users can view)
- `UPDATE`: Users can update only their own profile

### Kudos/Comments
- `INSERT`: Authenticated users
- `DELETE`: Only comment/kudos author can delete

### Segments/Routes
- `SELECT`: Public (filtered by `is_public`)
- `INSERT`: Authenticated users
- `UPDATE/DELETE`: Only creator

## Notes

- All `user_id` fields reference `auth.users.id` from Supabase Auth
- PostGIS is enabled for geospatial queries
- GIST indexes on geometry columns for performance
- Use materialized views for leaderboards and analytics aggregates
- Consider partitioning `activities` and `segment_efforts` by date for large datasets

