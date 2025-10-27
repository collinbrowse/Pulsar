-- Seed Script: Test data for development
-- Created: 2025-10-27
-- Description: Sample profiles, activities, segments for local testing

-- Insert test profiles (linked to auth.users that would be created via signup)
-- Note: In actual usage, profiles are created via trigger on auth.users insert

-- Insert sample segments for testing
INSERT INTO app.segments (segment_id, name, description, geom, distance_m, elevation_gain_m, activity_type, created_by, is_public, city, state, country) VALUES
(
    '550e8400-e29b-41d4-a716-446655440001'::uuid,
    'Golden Gate Bridge Run',
    'Iconic run across the Golden Gate Bridge',
    ST_GeomFromText('LINESTRING(-122.4783 37.8199, -122.4700 37.8185, -122.4620 37.8170)', 4326),
    2500.0,
    50.0,
    'run',
    -- Note: created_by would need a real user_id from auth.users
    '00000000-0000-0000-0000-000000000000'::uuid,
    true,
    'San Francisco',
    'CA',
    'USA'
) ON CONFLICT (segment_id) DO NOTHING;

INSERT INTO app.segments (segment_id, name, description, geom, distance_m, elevation_gain_m, activity_type, created_by, is_public, city, state, country) VALUES
(
    '550e8400-e29b-41d4-a716-446655440002'::uuid,
    'Central Park Loop',
    'Full loop around Central Park',
    ST_GeomFromText('LINESTRING(-73.9680 40.7829, -73.9580 40.7680, -73.9520 40.7640, -73.9580 40.7650, -73.9680 40.7829)', 4326),
    10000.0,
    100.0,
    'run',
    '00000000-0000-0000-0000-000000000000'::uuid,
    true,
    'New York',
    'NY',
    'USA'
) ON CONFLICT (segment_id) DO NOTHING;

INSERT INTO app.segments (segment_id, name, description, geom, distance_m, elevation_gain_m, activity_type, created_by, is_public, city, state, country) VALUES
(
    '550e8400-e29b-41d4-a716-446655440003'::uuid,
    'Mulholland Drive Climb',
    'Challenging climb with amazing views',
    ST_GeomFromText('LINESTRING(-118.4300 34.1000, -118.4250 34.1050, -118.4200 34.1100)', 4326),
    5000.0,
    300.0,
    'ride',
    '00000000-0000-0000-0000-000000000000'::uuid,
    true,
    'Los Angeles',
    'CA',
    'USA'
) ON CONFLICT (segment_id) DO NOTHING;

-- Add comments
COMMENT ON TABLE app.segments IS 'Seeded with sample segments for testing';

-- Note: Sample activities and efforts would be created via API after user signup
-- This seed file focuses on segments which are more static

