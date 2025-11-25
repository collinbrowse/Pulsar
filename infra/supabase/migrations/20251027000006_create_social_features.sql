-- Migration: Create social features (follows, kudos, comments)
-- Created: 2025-10-27
-- Description: Social interaction tables for feed and engagement

-- Follows table
CREATE TABLE IF NOT EXISTS public.follows (
    follow_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    follower_id UUID NOT NULL REFERENCES public.profiles(user_id) ON DELETE CASCADE,
    following_id UUID NOT NULL REFERENCES public.profiles(user_id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
    
    -- Constraints
    CONSTRAINT no_self_follow CHECK (follower_id != following_id),
    CONSTRAINT unique_follow UNIQUE(follower_id, following_id)
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_follows_follower ON public.follows(follower_id);
CREATE INDEX IF NOT EXISTS idx_follows_following ON public.follows(following_id);

-- Kudos table
CREATE TABLE IF NOT EXISTS public.kudos (
    kudos_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    activity_id UUID NOT NULL REFERENCES public.activities(activity_id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES public.profiles(user_id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
    
    -- Constraints
    CONSTRAINT unique_kudos UNIQUE(activity_id, user_id)
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_kudos_activity ON public.kudos(activity_id);
CREATE INDEX IF NOT EXISTS idx_kudos_user ON public.kudos(user_id);
CREATE INDEX IF NOT EXISTS idx_kudos_created_at ON public.kudos(created_at DESC);

-- Comments table
CREATE TABLE IF NOT EXISTS public.comments (
    comment_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    activity_id UUID NOT NULL REFERENCES public.activities(activity_id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES public.profiles(user_id) ON DELETE CASCADE,
    text TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
    
    -- Constraints
    CONSTRAINT comment_text_length CHECK (char_length(text) >= 1 AND char_length(text) <= 1000)
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_comments_activity ON public.comments(activity_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_comments_user ON public.comments(user_id);

-- Enable Row Level Security
ALTER TABLE public.follows ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.kudos ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.comments ENABLE ROW LEVEL SECURITY;

-- RLS Policies: Follows
DROP POLICY IF EXISTS "Users can view all follows" ON public.follows;
CREATE POLICY "Users can view all follows" 
    ON public.follows FOR SELECT 
    USING (true);

DROP POLICY IF EXISTS "Users can follow others" ON public.follows;
CREATE POLICY "Users can follow others" 
    ON public.follows FOR INSERT 
    WITH CHECK (auth.uid() = follower_id);

DROP POLICY IF EXISTS "Users can unfollow" ON public.follows;
CREATE POLICY "Users can unfollow" 
    ON public.follows FOR DELETE 
    USING (auth.uid() = follower_id);

-- RLS Policies: Kudos
DROP POLICY IF EXISTS "Users can view all kudos" ON public.kudos;
CREATE POLICY "Users can view all kudos" 
    ON public.kudos FOR SELECT 
    USING (true);

DROP POLICY IF EXISTS "Authenticated users can give kudos" ON public.kudos;
CREATE POLICY "Authenticated users can give kudos" 
    ON public.kudos FOR INSERT 
    WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can remove their own kudos" ON public.kudos;
CREATE POLICY "Users can remove their own kudos" 
    ON public.kudos FOR DELETE 
    USING (auth.uid() = user_id);

-- RLS Policies: Comments
DROP POLICY IF EXISTS "Users can view comments on visible activities" ON public.comments;
CREATE POLICY "Users can view comments on visible activities" 
    ON public.comments FOR SELECT 
    USING (
        EXISTS (
            SELECT 1 FROM public.activities a 
            WHERE a.activity_id = comments.activity_id 
            AND (
                a.visibility = 'public' OR
                (a.visibility = 'followers' AND auth.uid() IN (
                    SELECT following_id FROM public.follows WHERE follower_id = a.user_id
                )) OR
                a.user_id = auth.uid()
            )
        )
    );

DROP POLICY IF EXISTS "Authenticated users can comment" ON public.comments;
CREATE POLICY "Authenticated users can comment" 
    ON public.comments FOR INSERT 
    WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can update their own comments" ON public.comments;
CREATE POLICY "Users can update their own comments" 
    ON public.comments FOR UPDATE 
    USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can delete their own comments" ON public.comments;
CREATE POLICY "Users can delete their own comments" 
    ON public.comments FOR DELETE 
    USING (auth.uid() = user_id);

-- Trigger to update comments updated_at
DROP TRIGGER IF EXISTS update_comments_updated_at ON public.comments;
CREATE TRIGGER update_comments_updated_at 
    BEFORE UPDATE ON public.comments 
    FOR EACH ROW 
    EXECUTE FUNCTION public.update_updated_at_column();

-- Function to get user feed
CREATE OR REPLACE FUNCTION public.get_user_feed(
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
            SELECT 1 FROM public.kudos k2 
            WHERE k2.activity_id = a.activity_id 
            AND k2.user_id = p_user_id
        ) as user_gave_kudos
    FROM public.activities a
    JOIN public.profiles p ON p.user_id = a.user_id
    LEFT JOIN public.kudos k ON k.activity_id = a.activity_id
    LEFT JOIN public.comments c ON c.activity_id = a.activity_id
    WHERE 
        a.user_id IN (
            SELECT following_id FROM public.follows WHERE follower_id = p_user_id
        )
        AND a.visibility IN ('public', 'followers')
    GROUP BY a.activity_id, p.username, p.avatar_url
    ORDER BY a.start_time DESC
    LIMIT p_limit OFFSET p_offset;
END;
$$ LANGUAGE plpgsql;

-- Function to get follower/following counts
CREATE OR REPLACE FUNCTION public.get_user_social_stats(p_user_id UUID)
RETURNS TABLE (
    follower_count BIGINT,
    following_count BIGINT,
    activity_count BIGINT
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        (SELECT COUNT(*) FROM public.follows WHERE following_id = p_user_id) as follower_count,
        (SELECT COUNT(*) FROM public.follows WHERE follower_id = p_user_id) as following_count,
        (SELECT COUNT(*) FROM public.activities WHERE user_id = p_user_id AND visibility = 'public') as activity_count;
END;
$$ LANGUAGE plpgsql;

-- Comments
COMMENT ON TABLE public.follows IS 'User follow relationships for social features';
COMMENT ON TABLE public.kudos IS 'Kudos (likes) given to activities';
COMMENT ON TABLE public.comments IS 'Comments on activities';
COMMENT ON FUNCTION public.get_user_feed IS 'Get chronological feed of activities from followed users';
COMMENT ON FUNCTION public.get_user_social_stats IS 'Get follower/following/activity counts for a user';

