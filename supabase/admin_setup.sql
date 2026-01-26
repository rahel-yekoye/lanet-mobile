-- ============================================
-- LaNet Language Learning App - Admin Setup
-- ============================================
-- This script sets up tables, RLS policies, and triggers for:
-- 1. User preferences (onboarding data)
-- 2. Admin dashboard tables
-- 3. Content management (lessons, exercises, categories)
-- 4. Analytics and reporting

-- ============================================
-- 1. USER PREFERENCES TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS public.user_preferences (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    preferred_language TEXT NOT NULL CHECK (preferred_language IN ('Amharic', 'Tigrinya', 'Afaan Oromo')),
    proficiency_level TEXT NOT NULL CHECK (proficiency_level IN ('Beginner', 'Intermediate', 'Advanced')),
    learning_reasons TEXT[] DEFAULT '{}',
    daily_goal_minutes INTEGER NOT NULL CHECK (daily_goal_minutes > 0),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(user_id)
);

-- Index for fast lookups
CREATE INDEX IF NOT EXISTS idx_user_preferences_user_id ON public.user_preferences(user_id);

-- Ensure preferred_language column exists (in case table was created by migration)
DO $$ 
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.tables 
        WHERE table_schema = 'public' 
        AND table_name = 'user_preferences'
    ) AND NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'user_preferences'
        AND column_name = 'preferred_language'
    ) THEN
        ALTER TABLE public.user_preferences 
        ADD COLUMN preferred_language TEXT CHECK (preferred_language IN ('Amharic', 'Tigrinya', 'Afaan Oromo'));
    END IF;
END $$;

-- ============================================
-- 2. UPDATE PROFILES TABLE (add role and blocked)
-- ============================================
-- Add role column if it doesn't exist
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'profiles' 
        AND column_name = 'role'
    ) THEN
        ALTER TABLE public.profiles ADD COLUMN role TEXT DEFAULT 'user' CHECK (role IN ('user', 'admin', 'moderator'));
    END IF;
    
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'profiles' 
        AND column_name = 'blocked'
    ) THEN
        ALTER TABLE public.profiles ADD COLUMN blocked BOOLEAN DEFAULT FALSE;
    END IF;
END $$;

-- ============================================
-- 3. CATEGORIES TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS public.categories (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL UNIQUE,
    description TEXT,
    icon TEXT,
    color TEXT,
    order_index INTEGER DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- 4. LESSONS TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS public.lessons (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title TEXT NOT NULL,
    description TEXT,
    language TEXT NOT NULL CHECK (language IN ('Amharic', 'Tigrinya', 'Afaan Oromo')),
    category_id UUID REFERENCES public.categories(id) ON DELETE SET NULL,
    category TEXT, -- Denormalized for easier querying
    difficulty INTEGER NOT NULL CHECK (difficulty BETWEEN 1 AND 3), -- 1=Beginner, 2=Intermediate, 3=Advanced
    status TEXT NOT NULL DEFAULT 'draft' CHECK (status IN ('draft', 'published', 'archived')),
    estimated_minutes INTEGER DEFAULT 5,
    order_index INTEGER DEFAULT 0,
    created_by UUID REFERENCES auth.users(id),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_lessons_language ON public.lessons(language);
CREATE INDEX IF NOT EXISTS idx_lessons_difficulty ON public.lessons(difficulty);
CREATE INDEX IF NOT EXISTS idx_lessons_status ON public.lessons(status);
CREATE INDEX IF NOT EXISTS idx_lessons_category ON public.lessons(category_id);

-- ============================================
-- 5. EXERCISES TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS public.exercises (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    lesson_id UUID NOT NULL REFERENCES public.lessons(id) ON DELETE CASCADE,
    type TEXT NOT NULL CHECK (type IN ('multiple-choice', 'listen-repeat', 'translate', 'fill-blank', 'matching', 'reorder')),
    prompt TEXT NOT NULL,
    options JSONB, -- For multiple choice options, matching pairs, etc.
    correct_answer TEXT NOT NULL,
    points INTEGER DEFAULT 1,
    media_url TEXT, -- Reference to storage bucket
    order_index INTEGER DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_exercises_lesson_id ON public.exercises(lesson_id);

-- ============================================
-- 6. MEDIA ASSETS TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS public.media_assets (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    storage_path TEXT NOT NULL UNIQUE,
    bucket_name TEXT NOT NULL,
    file_name TEXT NOT NULL,
    file_type TEXT NOT NULL,
    file_size BIGINT,
    mime_type TEXT,
    signed_url TEXT, -- Cached signed URL (expires, but useful for quick access)
    url_expires_at TIMESTAMPTZ,
    uploaded_by UUID REFERENCES auth.users(id),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_media_assets_storage_path ON public.media_assets(storage_path);

-- ============================================
-- 7. NOTIFICATIONS TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS public.notifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE, -- NULL = broadcast to all
    title TEXT NOT NULL,
    message TEXT NOT NULL,
    type TEXT DEFAULT 'info' CHECK (type IN ('info', 'warning', 'success', 'error')),
    read BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_notifications_user_id ON public.notifications(user_id);
CREATE INDEX IF NOT EXISTS idx_notifications_read ON public.notifications(read);

-- ============================================
-- 8. APP SETTINGS TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS public.app_settings (
    key TEXT PRIMARY KEY,
    value JSONB NOT NULL,
    description TEXT,
    updated_by UUID REFERENCES auth.users(id),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Insert default settings
INSERT INTO public.app_settings (key, value, description) VALUES
    ('maintenance_mode', '{"enabled": false}', 'Enable/disable maintenance mode'),
    ('welcome_message', '{"enabled": true, "message": "Welcome to LaNet! Start your language learning journey today."}', 'Welcome message for new users'),
    ('max_daily_lessons', '{"value": 20}', 'Maximum lessons per day')
ON CONFLICT (key) DO NOTHING;

-- ============================================
-- 9. USER PROGRESS TRACKING (for analytics)
-- ============================================
CREATE TABLE IF NOT EXISTS public.user_lesson_progress (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    lesson_id UUID NOT NULL REFERENCES public.lessons(id) ON DELETE CASCADE,
    completed BOOLEAN DEFAULT FALSE,
    score INTEGER DEFAULT 0,
    time_spent_seconds INTEGER DEFAULT 0,
    completed_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(user_id, lesson_id)
);

CREATE INDEX IF NOT EXISTS idx_user_lesson_progress_user_id ON public.user_lesson_progress(user_id);
CREATE INDEX IF NOT EXISTS idx_user_lesson_progress_lesson_id ON public.user_lesson_progress(lesson_id);

-- ============================================
-- 10. TRIGGERS FOR UPDATED_AT
-- ============================================
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply to all tables with updated_at
CREATE TRIGGER update_user_preferences_updated_at BEFORE UPDATE ON public.user_preferences
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_categories_updated_at BEFORE UPDATE ON public.categories
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_lessons_updated_at BEFORE UPDATE ON public.lessons
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_exercises_updated_at BEFORE UPDATE ON public.exercises
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_user_lesson_progress_updated_at BEFORE UPDATE ON public.user_lesson_progress
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ============================================
-- 11. ROW LEVEL SECURITY (RLS) POLICIES
-- ============================================

-- Enable RLS on all tables
ALTER TABLE public.user_preferences ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.lessons ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.exercises ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.media_assets ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.app_settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_lesson_progress ENABLE ROW LEVEL SECURITY;

-- Helper function to check if user is admin
CREATE OR REPLACE FUNCTION is_admin(user_uuid UUID)
RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 FROM public.profiles
        WHERE id = user_uuid AND role = 'admin'
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- USER_PREFERENCES policies
-- Users can read/write their own preferences
CREATE POLICY "Users can view own preferences" ON public.user_preferences
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own preferences" ON public.user_preferences
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own preferences" ON public.user_preferences
    FOR UPDATE USING (auth.uid() = user_id);

-- Admins can view all preferences
CREATE POLICY "Admins can view all preferences" ON public.user_preferences
    FOR SELECT USING (is_admin(auth.uid()));

-- CATEGORIES policies
-- Everyone can read published categories
CREATE POLICY "Anyone can view categories" ON public.categories
    FOR SELECT USING (true);

-- Only admins can modify
CREATE POLICY "Admins can manage categories" ON public.categories
    FOR ALL USING (is_admin(auth.uid()));

-- LESSONS policies
-- Users can view published lessons
CREATE POLICY "Users can view published lessons" ON public.lessons
    FOR SELECT USING (status = 'published' OR is_admin(auth.uid()));

-- Only admins can modify
CREATE POLICY "Admins can manage lessons" ON public.lessons
    FOR ALL USING (is_admin(auth.uid()));

-- EXERCISES policies
-- Users can view exercises for published lessons
CREATE POLICY "Users can view exercises for published lessons" ON public.exercises
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM public.lessons
            WHERE lessons.id = exercises.lesson_id
            AND (lessons.status = 'published' OR is_admin(auth.uid()))
        )
    );

-- Only admins can modify
CREATE POLICY "Admins can manage exercises" ON public.exercises
    FOR ALL USING (is_admin(auth.uid()));

-- MEDIA_ASSETS policies
-- Users can view media assets
CREATE POLICY "Anyone can view media assets" ON public.media_assets
    FOR SELECT USING (true);

-- Only admins can upload/manage
CREATE POLICY "Admins can manage media assets" ON public.media_assets
    FOR ALL USING (is_admin(auth.uid()));

-- NOTIFICATIONS policies
-- Users can view their own notifications
CREATE POLICY "Users can view own notifications" ON public.notifications
    FOR SELECT USING (user_id = auth.uid() OR user_id IS NULL OR is_admin(auth.uid()));

-- Users can update their own notifications (mark as read)
CREATE POLICY "Users can update own notifications" ON public.notifications
    FOR UPDATE USING (user_id = auth.uid());

-- Only admins can create notifications
CREATE POLICY "Admins can create notifications" ON public.notifications
    FOR INSERT WITH CHECK (is_admin(auth.uid()));

-- APP_SETTINGS policies
-- Everyone can read settings
CREATE POLICY "Anyone can view app settings" ON public.app_settings
    FOR SELECT USING (true);

-- Only admins can modify
CREATE POLICY "Admins can manage app settings" ON public.app_settings
    FOR ALL USING (is_admin(auth.uid()));

-- USER_LESSON_PROGRESS policies
-- Users can view/update their own progress
CREATE POLICY "Users can manage own progress" ON public.user_lesson_progress
    FOR ALL USING (user_id = auth.uid());

-- Admins can view all progress
CREATE POLICY "Admins can view all progress" ON public.user_lesson_progress
    FOR SELECT USING (is_admin(auth.uid()));

-- ============================================
-- 12. STORAGE BUCKETS SETUP
-- ============================================
-- Note: These need to be created via Supabase Dashboard or API
-- Buckets: 'audio', 'images', 'videos'
-- Policies: Public read, Admin write

-- ============================================
-- 13. HELPER VIEWS FOR ANALYTICS
-- ============================================
-- Drop view if it exists to avoid conflicts
DROP VIEW IF EXISTS public.user_stats;

-- Create user_stats view
-- Check if preferred_language column exists in user_preferences table
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'user_preferences'
        AND column_name = 'preferred_language'
    ) THEN
        -- Column exists, create view with preferred_language
        EXECUTE '
        CREATE VIEW public.user_stats AS
        SELECT 
            u.id,
            u.email,
            COALESCE(p.full_name, '''') as name,
            COALESCE(p.role, ''user'') as role,
            COALESCE(p.blocked, false) as blocked,
            COALESCE(up.preferred_language, ''Not set'') as language,
            COUNT(DISTINCT ulp.lesson_id) FILTER (WHERE ulp.completed = true) as lessons_completed,
            COALESCE(SUM(ulp.time_spent_seconds), 0) as total_time_seconds,
            MAX(ulp.updated_at) as last_activity,
            u.created_at as joined_at
        FROM auth.users u
        LEFT JOIN public.profiles p ON p.id = u.id
        LEFT JOIN public.user_preferences up ON up.user_id = u.id
        LEFT JOIN public.user_lesson_progress ulp ON ulp.user_id = u.id
        GROUP BY u.id, u.email, p.full_name, p.role, p.blocked, up.preferred_language, u.created_at';
    ELSE
        -- Column doesn't exist, create view without preferred_language
        EXECUTE '
        CREATE VIEW public.user_stats AS
        SELECT 
            u.id,
            u.email,
            COALESCE(p.full_name, '''') as name,
            COALESCE(p.role, ''user'') as role,
            COALESCE(p.blocked, false) as blocked,
            ''Not set'' as language,
            COUNT(DISTINCT ulp.lesson_id) FILTER (WHERE ulp.completed = true) as lessons_completed,
            COALESCE(SUM(ulp.time_spent_seconds), 0) as total_time_seconds,
            MAX(ulp.updated_at) as last_activity,
            u.created_at as joined_at
        FROM auth.users u
        LEFT JOIN public.profiles p ON p.id = u.id
        LEFT JOIN public.user_lesson_progress ulp ON ulp.user_id = u.id
        GROUP BY u.id, u.email, p.full_name, p.role, p.blocked, u.created_at';
    END IF;
END $$;

-- Lesson popularity view
DROP VIEW IF EXISTS public.lesson_popularity;

CREATE VIEW public.lesson_popularity AS
SELECT 
    l.id,
    l.title,
    COALESCE(l.category, 'Uncategorized') as category,
    l.language,
    COUNT(DISTINCT ulp.user_id) FILTER (WHERE ulp.completed = true) as completions,
    COALESCE(AVG(ulp.score) FILTER (WHERE ulp.completed = true), 0) as avg_score,
    COALESCE(AVG(ulp.time_spent_seconds) FILTER (WHERE ulp.completed = true), 0) as avg_time_seconds
FROM public.lessons l
LEFT JOIN public.user_lesson_progress ulp ON ulp.lesson_id = l.id
WHERE l.status = 'published'
GROUP BY l.id, l.title, l.category, l.language;

-- ============================================
-- END OF SETUP
-- ============================================

