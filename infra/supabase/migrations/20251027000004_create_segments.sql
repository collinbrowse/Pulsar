-- Migration: Create segments table
-- Created: 2025-10-27
-- Description: Known route segments for leaderboards and PRs

CREATE TABLE IF NOT EXISTS app.segments (
    segment_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    description TEXT,
    
    -- Geospatial data
    geom GEOMETRY(LINESTRING, 4326) NOT NULL,
    distance_m DECIMAL(10, 2) NOT NULL CHECK (distance_m > 0),
    elevation_gain_m DECIMAL(8, 2),
    elevation_loss_m DECIMAL(8, 2),
    
    -- Segment properties
    activity_type TEXT NOT NULL CHECK (activity_type IN ('run', 'ride', 'swim', 'hike', 'walk', 'ski', 'other')),
    difficulty TEXT CHECK (difficulty IN ('easy', 'moderate', 'hard', 'expert')),
    surface_type TEXT CHECK (surface_type IN ('paved', 'trail', 'mixed', 'other')),
    
    -- Metadata
    created_by UUID NOT NULL REFERENCES app.profiles(user_id) ON DELETE CASCADE,
    is_public BOOLEAN DEFAULT true NOT NULL,
    is_hazardous BOOLEAN DEFAULT false,
    
    -- Statistics
    effort_count INTEGER DEFAULT 0 NOT NULL,
    star_count INTEGER DEFAULT 0 NOT NULL,
    
    -- Location for searching
    city TEXT,
    state TEXT,
    country TEXT,
    
    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
    
    -- Constraints
    CONSTRAINT segment_name_length CHECK (char_length(name) >= 3 AND char_length(name) <= 100)
);

-- Indexes
CREATE INDEX idx_segments_activity_type ON app.segments(activity_type);
CREATE INDEX idx_segments_created_by ON app.segments(created_by);
CREATE INDEX idx_segments_is_public ON app.segments(is_public);
CREATE INDEX idx_segments_effort_count ON app.segments(effort_count DESC);
CREATE INDEX idx_segments_star_count ON app.segments(star_count DESC);

-- Spatial index for segment matching
CREATE INDEX idx_segments_geom ON app.segments USING GIST(geom);

-- Composite indexes
CREATE INDEX idx_segments_type_public ON app.segments(activity_type, is_public);

-- Enable Row Level Security
ALTER TABLE app.segments ENABLE ROW LEVEL SECURITY;

-- RLS Policies
-- Public segments viewable by everyone
CREATE POLICY "Public segments are viewable by everyone" 
    ON app.segments FOR SELECT 
    USING (is_public = true);

-- Private segments viewable by creator
CREATE POLICY "Private segments viewable by creator" 
    ON app.segments FOR SELECT 
    USING (is_public = false AND auth.uid() = created_by);

-- Authenticated users can create segments
CREATE POLICY "Authenticated users can create segments" 
    ON app.segments FOR INSERT 
    WITH CHECK (auth.uid() = created_by);

-- Users can update their own segments
CREATE POLICY "Users can update their own segments" 
    ON app.segments FOR UPDATE 
    USING (auth.uid() = created_by);

-- Users can delete their own segments
CREATE POLICY "Users can delete their own segments" 
    ON app.segments FOR DELETE 
    USING (auth.uid() = created_by);

-- Trigger to update updated_at
CREATE TRIGGER update_segments_updated_at 
    BEFORE UPDATE ON app.segments 
    FOR EACH ROW 
    EXECUTE FUNCTION app.update_updated_at_column();

-- Function to find intersecting segments for an activity
CREATE OR REPLACE FUNCTION app.find_matching_segments(
    p_activity_geom GEOMETRY,
    p_activity_type TEXT,
    p_tolerance DECIMAL DEFAULT 50.0
)
RETURNS TABLE (
    segment_id UUID,
    segment_name TEXT,
    match_percentage DECIMAL
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        s.segment_id,
        s.name as segment_name,
        (ST_Length(ST_Intersection(s.geom, p_activity_geom)::geography) / 
         ST_Length(s.geom::geography) * 100)::DECIMAL(5, 2) as match_percentage
    FROM app.segments s
    WHERE 
        s.is_public = true
        AND s.activity_type = p_activity_type
        AND ST_DWithin(s.geom::geography, p_activity_geom::geography, p_tolerance)
        AND ST_Intersects(s.geom, p_activity_geom)
    ORDER BY match_percentage DESC
    LIMIT 10;
END;
$$ LANGUAGE plpgsql;

-- Comments
COMMENT ON TABLE app.segments IS 'Known route segments for leaderboards and personal records';
COMMENT ON COLUMN app.segments.geom IS 'PostGIS LineString geometry of the segment path';
COMMENT ON COLUMN app.segments.effort_count IS 'Number of recorded efforts on this segment';
COMMENT ON COLUMN app.segments.star_count IS 'Number of users who starred this segment';
COMMENT ON FUNCTION app.find_matching_segments IS 'Find segments that intersect with an activity route';

