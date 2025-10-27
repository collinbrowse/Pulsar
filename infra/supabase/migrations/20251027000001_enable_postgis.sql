-- Migration: Enable PostGIS for geospatial features
-- Created: 2025-10-27
-- Description: Enable PostGIS extension for storing and querying geographic data

-- Enable PostGIS extension
CREATE EXTENSION IF NOT EXISTS postgis;
CREATE EXTENSION IF NOT EXISTS postgis_topology;

-- Verify PostGIS is installed
SELECT PostGIS_version();

-- Create app schema for our tables
CREATE SCHEMA IF NOT EXISTS app;

-- Grant usage on app schema
GRANT USAGE ON SCHEMA app TO postgres, anon, authenticated, service_role;
GRANT ALL ON ALL TABLES IN SCHEMA app TO postgres, anon, authenticated, service_role;
GRANT ALL ON ALL SEQUENCES IN SCHEMA app TO postgres, anon, authenticated, service_role;
GRANT ALL ON ALL FUNCTIONS IN SCHEMA app TO postgres, anon, authenticated, service_role;

-- Set default privileges for future tables
ALTER DEFAULT PRIVILEGES IN SCHEMA app GRANT ALL ON TABLES TO postgres, anon, authenticated, service_role;
ALTER DEFAULT PRIVILEGES IN SCHEMA app GRANT ALL ON SEQUENCES TO postgres, anon, authenticated, service_role;
ALTER DEFAULT PRIVILEGES IN SCHEMA app GRANT ALL ON FUNCTIONS TO postgres, anon, authenticated, service_role;

-- Add comment
COMMENT ON SCHEMA app IS 'Application schema for Pulsar activity tracking';

