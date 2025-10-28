# Pulsar Backend API Documentation

Base URL: `https://your-project.supabase.co`

All endpoints require authentication via Supabase Auth token in `Authorization` header:
```
Authorization: Bearer <token>
```

## Authentication

### Sign Up
```http
POST /auth/v1/signup
Content-Type: application/json

{
  "email": "user@example.com",
  "password": "secure_password"
}
```

### Sign In
```http
POST /auth/v1/token?grant_type=password
Content-Type: application/json

{
  "email": "user@example.com",
  "password": "secure_password"
}
```

### Sign in with Apple
```http
POST /auth/v1/token?grant_type=id_token
Content-Type: application/json

{
  "provider": "apple",
  "id_token": "<apple_id_token>"
}
```

## Profiles

### Get User Profile
```http
GET /rest/v1/profiles?user_id=eq.{user_id}
```

Response:
```json
{
  "user_id": "uuid",
  "username": "athlete123",
  "full_name": "John Doe",
  "avatar_url": "https://...",
  "gender": "male",
  "weight_kg": 70.5,
  "birth_year": 1990,
  "created_at": "2025-01-01T00:00:00Z"
}
```

### Update Profile
```http
PATCH /rest/v1/profiles?user_id=eq.{user_id}
Content-Type: application/json

{
  "full_name": "John Doe",
  "weight_kg": 72.0
}
```

## Activities

### Ingest Activity
```http
POST /functions/v1/ingest-activity
Content-Type: multipart/form-data

file: <gpx/tcx/fit file>
activity_type: "run" | "ride" | "swim" | "hike"
```

Response:
```json
{
  "activity_id": "uuid",
  "status": "success",
  "stats": {
    "distance_m": 5000,
    "duration_sec": 1800,
    "elevation_gain_m": 150
  }
}
```

### Get Activity
```http
GET /rest/v1/activities?activity_id=eq.{activity_id}
```

### Update Activity Visibility
```http
PATCH /rest/v1/activities?activity_id=eq.{activity_id}
Content-Type: application/json

{
  "visibility": "public" | "followers" | "private"
}
```

## Feed

### Get Feed
```http
GET /rest/v1/feed?user_id={user_id}&page={page}&limit={limit}
```

Response:
```json
[
  {
    "activity_id": "uuid",
    "user_id": "uuid",
    "username": "athlete123",
    "avatar_url": "https://...",
    "activity_type": "run",
    "distance_m": 5000,
    "duration_sec": 1800,
    "elevation_gain_m": 150,
    "created_at": "2025-01-01T12:00:00Z",
    "kudos_count": 12,
    "comment_count": 3
  }
]
```

## Social Interactions

### Give Kudos
```http
POST /rest/v1/kudos
Content-Type: application/json

{
  "activity_id": "uuid",
  "user_id": "uuid"
}
```

### Add Comment
```http
POST /rest/v1/comments
Content-Type: application/json

{
  "activity_id": "uuid",
  "user_id": "uuid",
  "text": "Great run!"
}
```

### Follow User
```http
POST /rest/v1/follows
Content-Type: application/json

{
  "follower_id": "uuid",
  "following_id": "uuid"
}
```

## Segments

### Get Segment
```http
GET /rest/v1/segments?segment_id=eq.{segment_id}
```

### Get Segment Leaderboard
```http
GET /functions/v1/leaderboard?segment_id={segment_id}&age_min={age}&age_max={age}&gender={gender}
```

Response:
```json
{
  "segment_id": "uuid",
  "entries": [
    {
      "rank": 1,
      "user_id": "uuid",
      "username": "athlete123",
      "elapsed_time_sec": 300,
      "date": "2025-01-01"
    }
  ]
}
```

## Analytics

### Get User Analytics
```http
GET /functions/v1/analytics?user_id={user_id}&period=week|month|year
```

Response:
```json
{
  "period": "week",
  "total_distance_m": 25000,
  "total_duration_sec": 9000,
  "total_elevation_gain_m": 500,
  "activity_count": 5,
  "trend_data": [
    { "date": "2025-01-01", "distance_m": 5000 }
  ]
}
```

## Goals

### Create Goal
```http
POST /rest/v1/goals
Content-Type: application/json

{
  "user_id": "uuid",
  "metric": "distance" | "duration" | "elevation",
  "period": "week" | "month" | "year",
  "target_value": 100000,
  "start_date": "2025-01-01",
  "end_date": "2025-12-31"
}
```

### Get User Goals
```http
GET /rest/v1/goals?user_id=eq.{user_id}
```

## Routes

### Search Routes
```http
GET /functions/v1/routes?location={lat},{lon}&distance_min={m}&distance_max={m}&sort=popularity
```

### Save Route
```http
POST /rest/v1/routes
Content-Type: application/json

{
  "name": "Morning Loop",
  "geom": "<GeoJSON LineString>",
  "distance_m": 5000,
  "elevation_gain_m": 100
}
```

### Export Route
```http
GET /functions/v1/routes/{route_id}/export?format=gpx
```

## Clubs

### Create Club
```http
POST /rest/v1/clubs
Content-Type: application/json

{
  "name": "Weekend Warriors",
  "description": "A club for casual runners"
}
```

### Get Club Members
```http
GET /rest/v1/club_members?club_id=eq.{club_id}
```

### Join Club
```http
POST /rest/v1/club_members
Content-Type: application/json

{
  "club_id": "uuid",
  "user_id": "uuid"
}
```

## Challenges

### Create Challenge
```http
POST /rest/v1/challenges
Content-Type: application/json

{
  "club_id": "uuid",
  "name": "January Distance Challenge",
  "metric": "distance",
  "target_value": 100000,
  "start_date": "2025-01-01",
  "end_date": "2025-01-31"
}
```

### Get Challenge Leaderboard
```http
GET /functions/v1/challenges/{challenge_id}/leaderboard
```

## Premium

### Check Entitlements
```http
GET /rest/v1/entitlements?user_id=eq.{user_id}
```

Response:
```json
[
  {
    "user_id": "uuid",
    "feature_key": "premium_analytics",
    "start_date": "2025-01-01",
    "end_date": "2026-01-01"
  }
]
```

### Subscribe (Receipt Validation)
```http
POST /functions/v1/subscribe
Content-Type: application/json

{
  "user_id": "uuid",
  "receipt_data": "<base64_encoded_receipt>",
  "product_id": "com.pulsar.premium.yearly"
}
```

## Error Responses

All endpoints may return standard HTTP error codes:

### 400 Bad Request
```json
{
  "error": "Invalid request parameters",
  "details": "..."
}
```

### 401 Unauthorized
```json
{
  "error": "Authentication required"
}
```

### 403 Forbidden
```json
{
  "error": "Insufficient permissions"
}
```

### 404 Not Found
```json
{
  "error": "Resource not found"
}
```

### 500 Internal Server Error
```json
{
  "error": "Internal server error",
  "request_id": "uuid"
}
```

## Rate Limiting

- **Authenticated requests**: 1000 requests per hour
- **Anonymous requests**: 100 requests per hour

Rate limit headers:
```
X-RateLimit-Limit: 1000
X-RateLimit-Remaining: 999
X-RateLimit-Reset: 1672531200
```

