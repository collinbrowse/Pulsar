-- Migration: Create profiles table
-- Created: 2025-10-27
-- Description: User profiles with authentication integration

CREATE TABLE IF NOT EXISTS app.profiles (
    user_id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    username TEXT UNIQUE NOT NULL,
    full_name TEXT,
    avatar_url TEXT,
    gender TEXT CHECK (gender IN ('male', 'female', 'other', 'prefer_not_to_say')),
    weight_kg DECIMAL(5, 2),
    birth_year INTEGER CHECK (birth_year >= 1900 AND birth_year <= EXTRACT(YEAR FROM CURRENT_DATE)),
    created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
    
    -- Constraints
    CONSTRAINT username_length CHECK (char_length(username) >= 3 AND char_length(username) <= 30),
    CONSTRAINT username_format CHECK (username ~ '^[a-zA-Z0-9_-]+$')
);

-- Indexes
CREATE INDEX idx_profiles_username ON app.profiles(username);
CREATE INDEX idx_profiles_created_at ON app.profiles(created_at DESC);

-- Enable Row Level Security
ALTER TABLE app.profiles ENABLE ROW LEVEL SECURITY;

-- RLS Policies
-- Anyone can view profiles (public data)
CREATE POLICY "Profiles are viewable by everyone" 
    ON app.profiles FOR SELECT 
    USING (true);

-- Users can insert their own profile
CREATE POLICY "Users can insert their own profile" 
    ON app.profiles FOR INSERT 
    WITH CHECK (auth.uid() = user_id);

-- Users can update their own profile
CREATE POLICY "Users can update their own profile" 
    ON app.profiles FOR UPDATE 
    USING (auth.uid() = user_id);

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION app.update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to automatically update updated_at
CREATE TRIGGER update_profiles_updated_at 
    BEFORE UPDATE ON app.profiles 
    FOR EACH ROW 
    EXECUTE FUNCTION app.update_updated_at_column();

-- Function to handle new user signup
CREATE OR REPLACE FUNCTION app.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO app.profiles (user_id, username, full_name)
    VALUES (
        NEW.id,
        COALESCE(NEW.raw_user_meta_data->>'username', 'user_' || substring(NEW.id::text from 1 for 8)),
        COALESCE(NEW.raw_user_meta_data->>'full_name', NULL)
    );
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger to create profile on signup
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW
    EXECUTE FUNCTION app.handle_new_user();

-- Comments
COMMENT ON TABLE app.profiles IS 'User profiles linked to authentication';
COMMENT ON COLUMN app.profiles.username IS 'Unique username for the user (3-30 chars, alphanumeric, underscore, hyphen)';
COMMENT ON COLUMN app.profiles.gender IS 'User gender for leaderboard filtering';
COMMENT ON COLUMN app.profiles.weight_kg IS 'User weight in kilograms for power calculations';
COMMENT ON COLUMN app.profiles.birth_year IS 'Birth year for age-based leaderboard filtering';

