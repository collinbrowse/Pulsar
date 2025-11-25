-- Quick Fix: Create activities table in public schema
-- Run this in Supabase SQL Editor: https://supabase.com/dashboard/project/jlyamkhkgjkktiypywkk/sql
-- This creates the activities table that the app needs

-- Create activities table in public schema
CREATE TABLE IF NOT EXISTS public.activities (
    activity_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.profiles(user_id) ON DELETE CASCADE,
    activity_type TEXT NOT NULL CHECK (activity_type IN ('run', 'ride', 'swim', 'hike', 'walk', 'ski', 'other')),
    name TEXT NOT NULL,
    description TEXT,
    
    -- Stats
    distance_m DECIMAL(10, 2) NOT NULL CHECK (distance_m >= 0),
    duration_sec INTEGER NOT NULL CHECK (duration_sec >= 0),
    elevation_gain_m DECIMAL(8, 2) CHECK (elevation_gain_m >= 0),
    elevation_loss_m DECIMAL(8, 2) CHECK (elevation_loss_m >= 0),
    max_elevation DECIMAL(8, 2),
    min_elevation DECIMAL(8, 2),
    
    -- Heart rate & power
    avg_heart_rate INTEGER CHECK (avg_heart_rate > 0 AND avg_heart_rate < 300),
    max_heart_rate INTEGER CHECK (max_heart_rate > 0 AND max_heart_rate < 300),
    avg_power INTEGER CHECK (avg_power >= 0),
    max_power INTEGER CHECK (max_power >= 0),
    avg_cadence INTEGER CHECK (avg_cadence >= 0),
    max_cadence INTEGER CHECK (max_cadence >= 0),
    
    -- Geospatial data (PostGIS)
    geom GEOMETRY(LINESTRING, 4326),
    start_lat DECIMAL(10, 8),
    start_lon DECIMAL(11, 8),
    end_lat DECIMAL(10, 8),
    end_lon DECIMAL(11, 8),
    
    -- Metadata
    start_time TIMESTAMPTZ NOT NULL,
    end_time TIMESTAMPTZ,
    visibility TEXT NOT NULL DEFAULT 'public' CHECK (visibility IN ('public', 'followers', 'private')),
    file_url TEXT,
    original_file_name TEXT,
    media_url TEXT,
    device_name TEXT,
    
    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
    
    -- Computed fields
    avg_speed_mps DECIMAL(6, 2) GENERATED ALWAYS AS (
        CASE 
            WHEN duration_sec > 0 THEN distance_m / duration_sec 
            ELSE 0 
        END
    ) STORED,
    
    -- Constraints
    CONSTRAINT valid_times CHECK (end_time IS NULL OR end_time >= start_time),
    CONSTRAINT valid_coordinates CHECK (
        (start_lat IS NULL AND start_lon IS NULL) OR 
        (start_lat BETWEEN -90 AND 90 AND start_lon BETWEEN -180 AND 180)
    )
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_activities_user_id ON public.activities(user_id);
CREATE INDEX IF NOT EXISTS idx_activities_activity_type ON public.activities(activity_type);
CREATE INDEX IF NOT EXISTS idx_activities_start_time ON public.activities(start_time DESC);
CREATE INDEX IF NOT EXISTS idx_activities_created_at ON public.activities(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_activities_visibility ON public.activities(visibility);

-- Spatial index for geospatial queries (GIST)
CREATE INDEX IF NOT EXISTS idx_activities_geom ON public.activities USING GIST(geom);

-- Composite indexes for common queries
CREATE INDEX IF NOT EXISTS idx_activities_user_type_time ON public.activities(user_id, activity_type, start_time DESC);

-- Enable Row Level Security
ALTER TABLE public.activities ENABLE ROW LEVEL SECURITY;

-- RLS Policies
-- Public activities are viewable by everyone
CREATE POLICY "Public activities are viewable by everyone" 
    ON public.activities FOR SELECT 
    USING (visibility = 'public');

-- Private activities only viewable by owner
CREATE POLICY "Private activities viewable by owner" 
    ON public.activities FOR SELECT 
    USING (visibility = 'private' AND auth.uid() = user_id);

-- Users can insert their own activities
CREATE POLICY "Users can insert their own activities" 
    ON public.activities FOR INSERT 
    WITH CHECK (auth.uid() = user_id);

-- Users can update their own activities
CREATE POLICY "Users can update their own activities" 
    ON public.activities FOR UPDATE 
    USING (auth.uid() = user_id);

-- Users can delete their own activities
CREATE POLICY "Users can delete their own activities" 
    ON public.activities FOR DELETE 
    USING (auth.uid() = user_id);

-- Trigger to update updated_at
CREATE TRIGGER update_activities_updated_at 
    BEFORE UPDATE ON public.activities 
    FOR EACH ROW 
    EXECUTE FUNCTION public.update_updated_at_column();

-- Comments
COMMENT ON TABLE public.activities IS 'User activities (runs, rides, etc.) with geospatial data';
COMMENT ON COLUMN public.activities.geom IS 'PostGIS LineString geometry of the activity route';
COMMENT ON COLUMN public.activities.visibility IS 'Who can see this activity: public, followers, or private';
COMMENT ON COLUMN public.activities.file_url IS 'URL to original uploaded file (GPX/TCX/FIT) in Supabase Storage';
COMMENT ON COLUMN public.activities.original_file_name IS 'Original filename of uploaded activity file';

