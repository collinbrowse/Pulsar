-- Migration: Create social features (follows, kudos, comments)
-- Created: 2025-10-27
-- Description: Social interaction tables for feed and engagement

-- Follows table
CREATE TABLE IF NOT EXISTS app.follows (
    follow_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    follower_id UUID NOT NULL REFERENCES app.profiles(user_id) ON DELETE CASCADE,
    following_id UUID NOT NULL REFERENCES app.profiles(user_id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
    
    -- Constraints
    CONSTRAINT no_self_follow CHECK (follower_id != following_id),
    CONSTRAINT unique_follow UNIQUE(follower_id, following_id)
);

-- Indexes
CREATE INDEX idx_follows_follower ON app.follows(follower_id);
CREATE INDEX idx_follows_following ON app.follows(following_id);

-- Kudos table
CREATE TABLE IF NOT EXISTS app.kudos (
    kudos_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    activity_id UUID NOT NULL REFERENCES app.activities(activity_id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES app.profiles(user_id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
    
    -- Constraints
    CONSTRAINT unique_kudos UNIQUE(activity_id, user_id)
);

-- Indexes
CREATE INDEX idx_kudos_activity ON app.kudos(activity_id);
CREATE INDEX idx_kudos_user ON app.kudos(user_id);
CREATE INDEX idx_kudos_created_at ON app.kudos(created_at DESC);

-- Comments table
CREATE TABLE IF NOT EXISTS app.comments (
    comment_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    activity_id UUID NOT NULL REFERENCES app.activities(activity_id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES app.profiles(user_id) ON DELETE CASCADE,
    text TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
    
    -- Constraints
    CONSTRAINT comment_text_length CHECK (char_length(text) >= 1 AND char_length(text) <= 1000)
);

-- Indexes
CREATE INDEX idx_comments_activity ON app.comments(activity_id, created_at DESC);
CREATE INDEX idx_comments_user ON app.comments(user_id);

-- Enable Row Level Security
ALTER TABLE app.follows ENABLE ROW LEVEL SECURITY;
ALTER TABLE app.kudos ENABLE ROW LEVEL SECURITY;
ALTER TABLE app.comments ENABLE ROW LEVEL SECURITY;

-- RLS Policies: Follows
CREATE POLICY "Users can view all follows" 
    ON app.follows FOR SELECT 
    USING (true);

CREATE POLICY "Users can follow others" 
    ON app.follows FOR INSERT 
    WITH CHECK (auth.uid() = follower_id);

CREATE POLICY "Users can unfollow" 
    ON app.follows FOR DELETE 
    USING (auth.uid() = follower_id);

-- RLS Policies: Kudos
CREATE POLICY "Users can view all kudos" 
    ON app.kudos FOR SELECT 
    USING (true);

CREATE POLICY "Authenticated users can give kudos" 
    ON app.kudos FOR INSERT 
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can remove their own kudos" 
    ON app.kudos FOR DELETE 
    USING (auth.uid() = user_id);

-- RLS Policies: Comments
CREATE POLICY "Users can view comments on visible activities" 
    ON app.comments FOR SELECT 
    USING (
        EXISTS (
            SELECT 1 FROM app.activities a 
            WHERE a.activity_id = comments.activity_id 
            AND (
                a.visibility = 'public' OR
                (a.visibility = 'followers' AND auth.uid() IN (
                    SELECT following_id FROM app.follows WHERE follower_id = a.user_id
                )) OR
                a.user_id = auth.uid()
            )
        )
    );

CREATE POLICY "Authenticated users can comment" 
    ON app.comments FOR INSERT 
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own comments" 
    ON app.comments FOR UPDATE 
    USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own comments" 
    ON app.comments FOR DELETE 
    USING (auth.uid() = user_id);

-- Trigger to update comments updated_at
CREATE TRIGGER update_comments_updated_at 
    BEFORE UPDATE ON app.comments 
    FOR EACH ROW 
    EXECUTE FUNCTION app.update_updated_at_column();

-- Function to get user feed
CREATE OR REPLACE FUNCTION app.get_user_feed(
    p_user_id UUID,
    p_limit INTEGER DEFAULT 20,
    p_offset INTEGER DEFAULT 0
)
RETURNS TABLE (
    activity_id UUID,
    user_id UUID,
    username TEXT,
    avatar_url TEXT,
    activity_type TEXT,
    name TEXT,
    distance_m DECIMAL,
    duration_sec INTEGER,
    elevation_gain_m DECIMAL,
    start_time TIMESTAMPTZ,
    kudos_count BIGINT,
    comment_count BIGINT,
    user_gave_kudos BOOLEAN
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        a.activity_id,
        a.user_id,
        p.username,
        p.avatar_url,
        a.activity_type,
        a.name,
        a.distance_m,
        a.duration_sec,
        a.elevation_gain_m,
        a.start_time,
        COUNT(DISTINCT k.kudos_id) as kudos_count,
        COUNT(DISTINCT c.comment_id) as comment_count,
        EXISTS(
            SELECT 1 FROM app.kudos k2 
            WHERE k2.activity_id = a.activity_id 
            AND k2.user_id = p_user_id
        ) as user_gave_kudos
    FROM app.activities a
    JOIN app.profiles p ON p.user_id = a.user_id
    LEFT JOIN app.kudos k ON k.activity_id = a.activity_id
    LEFT JOIN app.comments c ON c.activity_id = a.activity_id
    WHERE 
        a.user_id IN (
            SELECT following_id FROM app.follows WHERE follower_id = p_user_id
        )
        AND a.visibility IN ('public', 'followers')
    GROUP BY a.activity_id, p.username, p.avatar_url
    ORDER BY a.start_time DESC
    LIMIT p_limit OFFSET p_offset;
END;
$$ LANGUAGE plpgsql;

-- Function to get follower/following counts
CREATE OR REPLACE FUNCTION app.get_user_social_stats(p_user_id UUID)
RETURNS TABLE (
    follower_count BIGINT,
    following_count BIGINT,
    activity_count BIGINT
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        (SELECT COUNT(*) FROM app.follows WHERE following_id = p_user_id) as follower_count,
        (SELECT COUNT(*) FROM app.follows WHERE follower_id = p_user_id) as following_count,
        (SELECT COUNT(*) FROM app.activities WHERE user_id = p_user_id AND visibility = 'public') as activity_count;
END;
$$ LANGUAGE plpgsql;

-- Comments
COMMENT ON TABLE app.follows IS 'User follow relationships for social features';
COMMENT ON TABLE app.kudos IS 'Kudos (likes) given to activities';
COMMENT ON TABLE app.comments IS 'Comments on activities';
COMMENT ON FUNCTION app.get_user_feed IS 'Get chronological feed of activities from followed users';
COMMENT ON FUNCTION app.get_user_social_stats IS 'Get follower/following/activity counts for a user';

