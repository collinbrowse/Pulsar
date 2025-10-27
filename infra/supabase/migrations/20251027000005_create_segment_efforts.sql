-- Migration: Create segment_efforts table
-- Created: 2025-10-27
-- Description: Individual efforts on segments for leaderboards

CREATE TABLE IF NOT EXISTS app.segment_efforts (
    effort_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    segment_id UUID NOT NULL REFERENCES app.segments(segment_id) ON DELETE CASCADE,
    activity_id UUID NOT NULL REFERENCES app.activities(activity_id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES app.profiles(user_id) ON DELETE CASCADE,
    
    -- Effort stats
    elapsed_time_sec INTEGER NOT NULL CHECK (elapsed_time_sec > 0),
    distance_m DECIMAL(10, 2) NOT NULL,
    
    -- Optional metrics
    avg_heart_rate INTEGER CHECK (avg_heart_rate > 0 AND avg_heart_rate < 300),
    max_heart_rate INTEGER CHECK (max_heart_rate > 0 AND max_heart_rate < 300),
    avg_power INTEGER CHECK (avg_power >= 0),
    max_power INTEGER CHECK (max_power >= 0),
    avg_cadence INTEGER CHECK (avg_cadence >= 0),
    
    -- Computed performance metrics
    avg_speed_mps DECIMAL(6, 2) GENERATED ALWAYS AS (
        CASE 
            WHEN elapsed_time_sec > 0 THEN distance_m / elapsed_time_sec 
            ELSE 0 
        END
    ) STORED,
    
    -- For leaderboard context (denormalized for performance)
    user_gender TEXT,
    user_birth_year INTEGER,
    user_weight_kg DECIMAL(5, 2),
    
    -- Metadata
    effort_date DATE NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
    
    -- Constraints
    CONSTRAINT unique_activity_segment UNIQUE(activity_id, segment_id)
);

-- Indexes for leaderboards (critical for performance)
CREATE INDEX idx_segment_efforts_segment_time ON app.segment_efforts(segment_id, elapsed_time_sec ASC);
CREATE INDEX idx_segment_efforts_user_segment ON app.segment_efforts(user_id, segment_id, elapsed_time_sec ASC);
CREATE INDEX idx_segment_efforts_date ON app.segment_efforts(effort_date DESC);
CREATE INDEX idx_segment_efforts_activity ON app.segment_efforts(activity_id);

-- Composite indexes for filtered leaderboards
CREATE INDEX idx_segment_efforts_gender ON app.segment_efforts(segment_id, user_gender, elapsed_time_sec);
CREATE INDEX idx_segment_efforts_age ON app.segment_efforts(segment_id, user_birth_year, elapsed_time_sec);

-- Enable Row Level Security
ALTER TABLE app.segment_efforts ENABLE ROW LEVEL SECURITY;

-- RLS Policies
-- Efforts on public segments are viewable by everyone
CREATE POLICY "Public segment efforts are viewable by everyone" 
    ON app.segment_efforts FOR SELECT 
    USING (
        EXISTS (
            SELECT 1 FROM app.segments s 
            WHERE s.segment_id = segment_efforts.segment_id 
            AND s.is_public = true
        )
    );

-- System can insert efforts (via Edge Function)
CREATE POLICY "System can insert efforts" 
    ON app.segment_efforts FOR INSERT 
    WITH CHECK (true);

-- Function to get segment leaderboard
CREATE OR REPLACE FUNCTION app.get_segment_leaderboard(
    p_segment_id UUID,
    p_gender TEXT DEFAULT NULL,
    p_min_birth_year INTEGER DEFAULT NULL,
    p_max_birth_year INTEGER DEFAULT NULL,
    p_limit INTEGER DEFAULT 50
)
RETURNS TABLE (
    rank BIGINT,
    effort_id UUID,
    user_id UUID,
    username TEXT,
    elapsed_time_sec INTEGER,
    avg_speed_mps DECIMAL,
    effort_date DATE,
    is_pr BOOLEAN
) AS $$
BEGIN
    RETURN QUERY
    WITH ranked_efforts AS (
        SELECT
            ROW_NUMBER() OVER (ORDER BY se.elapsed_time_sec ASC) as rank,
            ROW_NUMBER() OVER (PARTITION BY se.user_id ORDER BY se.elapsed_time_sec ASC) as user_rank,
            se.effort_id,
            se.user_id,
            se.elapsed_time_sec,
            se.avg_speed_mps,
            se.effort_date
        FROM app.segment_efforts se
        WHERE 
            se.segment_id = p_segment_id
            AND (p_gender IS NULL OR se.user_gender = p_gender)
            AND (p_min_birth_year IS NULL OR se.user_birth_year >= p_min_birth_year)
            AND (p_max_birth_year IS NULL OR se.user_birth_year <= p_max_birth_year)
    )
    SELECT
        re.rank,
        re.effort_id,
        re.user_id,
        p.username,
        re.elapsed_time_sec,
        re.avg_speed_mps,
        re.effort_date,
        (re.user_rank = 1) as is_pr
    FROM ranked_efforts re
    JOIN app.profiles p ON p.user_id = re.user_id
    WHERE re.rank <= p_limit
    ORDER BY re.rank;
END;
$$ LANGUAGE plpgsql;

-- Function to get user's personal record on a segment
CREATE OR REPLACE FUNCTION app.get_user_segment_pr(
    p_user_id UUID,
    p_segment_id UUID
)
RETURNS TABLE (
    effort_id UUID,
    elapsed_time_sec INTEGER,
    effort_date DATE,
    rank BIGINT
) AS $$
BEGIN
    RETURN QUERY
    WITH user_pr AS (
        SELECT
            se.effort_id,
            se.elapsed_time_sec,
            se.effort_date
        FROM app.segment_efforts se
        WHERE 
            se.user_id = p_user_id
            AND se.segment_id = p_segment_id
        ORDER BY se.elapsed_time_sec ASC
        LIMIT 1
    ),
    overall_rank AS (
        SELECT COUNT(*) + 1 as rank
        FROM app.segment_efforts se
        WHERE 
            se.segment_id = p_segment_id
            AND se.elapsed_time_sec < (SELECT elapsed_time_sec FROM user_pr)
    )
    SELECT
        up.effort_id,
        up.elapsed_time_sec,
        up.effort_date,
        COALESCE(ork.rank, 999999) as rank
    FROM user_pr up
    CROSS JOIN overall_rank ork;
END;
$$ LANGUAGE plpgsql;

-- Trigger to update segment effort_count
CREATE OR REPLACE FUNCTION app.update_segment_effort_count()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        UPDATE app.segments 
        SET effort_count = effort_count + 1 
        WHERE segment_id = NEW.segment_id;
    ELSIF TG_OP = 'DELETE' THEN
        UPDATE app.segments 
        SET effort_count = GREATEST(0, effort_count - 1)
        WHERE segment_id = OLD.segment_id;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_segment_effort_count_trigger
    AFTER INSERT OR DELETE ON app.segment_efforts
    FOR EACH ROW
    EXECUTE FUNCTION app.update_segment_effort_count();

-- Comments
COMMENT ON TABLE app.segment_efforts IS 'Individual efforts on segments, used for leaderboards and PRs';
COMMENT ON COLUMN app.segment_efforts.elapsed_time_sec IS 'Time taken to complete the segment (faster is better)';
COMMENT ON FUNCTION app.get_segment_leaderboard IS 'Get ranked leaderboard for a segment with optional filters';
COMMENT ON FUNCTION app.get_user_segment_pr IS 'Get user''s personal record on a segment with overall rank';

