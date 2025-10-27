-- Migration: Create activities table
-- Created: 2025-10-27
-- Description: Store uploaded/imported activities with geospatial data

CREATE TABLE IF NOT EXISTS app.activities (
    activity_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES app.profiles(user_id) ON DELETE CASCADE,
    activity_type TEXT NOT NULL CHECK (activity_type IN ('run', 'ride', 'swim', 'hike', 'walk', 'ski', 'other')),
    name TEXT NOT NULL,
    description TEXT,
    
    -- Stats
    distance_m DECIMAL(10, 2) NOT NULL CHECK (distance_m >= 0),
    duration_sec INTEGER NOT NULL CHECK (duration_sec >= 0),
    elevation_gain_m DECIMAL(8, 2) CHECK (elevation_gain_m >= 0),
    elevation_loss_m DECIMAL(8, 2) CHECK (elevation_loss_m >= 0),
    
    -- Heart rate & power
    avg_heart_rate INTEGER CHECK (avg_heart_rate > 0 AND avg_heart_rate < 300),
    max_heart_rate INTEGER CHECK (max_heart_rate > 0 AND max_heart_rate < 300),
    avg_power INTEGER CHECK (avg_power >= 0),
    max_power INTEGER CHECK (max_power >= 0),
    avg_cadence INTEGER CHECK (avg_cadence >= 0),
    
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
CREATE INDEX idx_activities_user_id ON app.activities(user_id);
CREATE INDEX idx_activities_activity_type ON app.activities(activity_type);
CREATE INDEX idx_activities_start_time ON app.activities(start_time DESC);
CREATE INDEX idx_activities_created_at ON app.activities(created_at DESC);
CREATE INDEX idx_activities_visibility ON app.activities(visibility);

-- Spatial index for geospatial queries (GIST)
CREATE INDEX idx_activities_geom ON app.activities USING GIST(geom);

-- Composite indexes for common queries
CREATE INDEX idx_activities_user_type_time ON app.activities(user_id, activity_type, start_time DESC);

-- Enable Row Level Security
ALTER TABLE app.activities ENABLE ROW LEVEL SECURITY;

-- RLS Policies
-- Public activities are viewable by everyone
CREATE POLICY "Public activities are viewable by everyone" 
    ON app.activities FOR SELECT 
    USING (visibility = 'public');

-- Followers-only activities viewable by followers (to be implemented with follows table)
CREATE POLICY "Followers activities viewable by followers" 
    ON app.activities FOR SELECT 
    USING (
        visibility = 'followers' AND (
            auth.uid() = user_id OR
            EXISTS (
                SELECT 1 FROM app.follows 
                WHERE follower_id = auth.uid() AND following_id = user_id
            )
        )
    );

-- Private activities only viewable by owner
CREATE POLICY "Private activities viewable by owner" 
    ON app.activities FOR SELECT 
    USING (visibility = 'private' AND auth.uid() = user_id);

-- Users can insert their own activities
CREATE POLICY "Users can insert their own activities" 
    ON app.activities FOR INSERT 
    WITH CHECK (auth.uid() = user_id);

-- Users can update their own activities
CREATE POLICY "Users can update their own activities" 
    ON app.activities FOR UPDATE 
    USING (auth.uid() = user_id);

-- Users can delete their own activities
CREATE POLICY "Users can delete their own activities" 
    ON app.activities FOR DELETE 
    USING (auth.uid() = user_id);

-- Trigger to update updated_at
CREATE TRIGGER update_activities_updated_at 
    BEFORE UPDATE ON app.activities 
    FOR EACH ROW 
    EXECUTE FUNCTION app.update_updated_at_column();

-- Function to calculate activity statistics
CREATE OR REPLACE FUNCTION app.calculate_activity_stats(
    p_geom GEOMETRY,
    p_start_time TIMESTAMPTZ,
    p_end_time TIMESTAMPTZ
)
RETURNS TABLE (
    distance DECIMAL,
    duration INTEGER,
    elevation_gain DECIMAL,
    elevation_loss DECIMAL
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        ST_Length(p_geom::geography)::DECIMAL(10, 2) as distance,
        EXTRACT(EPOCH FROM (p_end_time - p_start_time))::INTEGER as duration,
        0::DECIMAL(8, 2) as elevation_gain,  -- Would need elevation data
        0::DECIMAL(8, 2) as elevation_loss;
END;
$$ LANGUAGE plpgsql;

-- Comments
COMMENT ON TABLE app.activities IS 'User activities (runs, rides, etc.) with geospatial data';
COMMENT ON COLUMN app.activities.geom IS 'PostGIS LineString geometry of the activity route';
COMMENT ON COLUMN app.activities.visibility IS 'Who can see this activity: public, followers, or private';
COMMENT ON COLUMN app.activities.file_url IS 'URL to original uploaded file (GPX/TCX/FIT) in Supabase Storage';
COMMENT ON COLUMN app.activities.media_url IS 'Optional photo/media attachment URL';

