-- ====================================================================
-- CRAFTAI STUDIO — COMPLETE CONSOLIDATED SUPABASE DATABASE SETUP
-- Run this ONCE in Supabase SQL Editor:
-- Dashboard -> Project (txiuwtrmfvceddqsjvhk) -> SQL Editor -> New Query -> Run
-- ====================================================================

-- Enable Required Extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ====================================================================
-- 1. CHARACTERS TABLE (InstantID AI Avatars & Face-Lock)
-- ====================================================================
CREATE TABLE IF NOT EXISTS public.characters (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    gender TEXT,
    reference_photo_urls TEXT[] NOT NULL DEFAULT '{}',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE public.characters ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Users manage own characters" ON public.characters;
CREATE POLICY "Users manage own characters" ON public.characters
    FOR ALL USING ((SELECT auth.uid()) = user_id);

GRANT ALL ON public.characters TO anon, authenticated, service_role;

-- ====================================================================
-- 2. EXPLORE PROMPTS (Marketplace, Likes RPC, & Uniform Aliases)
-- ====================================================================
CREATE TABLE IF NOT EXISTS public.explore_prompts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    author_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    prompt TEXT,
    author_handle TEXT DEFAULT '@creator',
    category TEXT DEFAULT 'General',
    model_used TEXT DEFAULT 'FLUX.1 Schnell',
    aspect_ratio VARCHAR(10) DEFAULT '1:1',
    preview_url TEXT,
    preview_image_url TEXT,
    image_url TEXT,
    master_image_url TEXT,
    masked_prompt_summary TEXT,
    masked_summary TEXT,
    base_remix_fee NUMERIC(10, 2) DEFAULT 4.00,
    author_royalty_cut NUMERIC(10, 2) DEFAULT 1.60,
    total_remixes INT DEFAULT 0,
    remixes_count INT DEFAULT 0,
    likes_count INT DEFAULT 0,
    is_marketplace_public BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE public.explore_prompts 
    ADD COLUMN IF NOT EXISTS author_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    ADD COLUMN IF NOT EXISTS user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    ADD COLUMN IF NOT EXISTS prompt TEXT,
    ADD COLUMN IF NOT EXISTS image_url TEXT,
    ADD COLUMN IF NOT EXISTS model TEXT,
    ADD COLUMN IF NOT EXISTS remixes_count INT DEFAULT 0,
    ADD COLUMN IF NOT EXISTS author_name TEXT DEFAULT 'Creator',
    ADD COLUMN IF NOT EXISTS author_avatar TEXT DEFAULT 'AR',
    ADD COLUMN IF NOT EXISTS masked_summary TEXT,
    ADD COLUMN IF NOT EXISTS preview_image_url TEXT,
    ADD COLUMN IF NOT EXISTS master_image_url TEXT,
    ADD COLUMN IF NOT EXISTS tool_applied TEXT NOT NULL DEFAULT 'text_to_image',
    ADD COLUMN IF NOT EXISTS aspect_ratio VARCHAR(10) NOT NULL DEFAULT '1:1',
    ADD COLUMN IF NOT EXISTS model_used VARCHAR(50) NOT NULL DEFAULT 'flux',
    ADD COLUMN IF NOT EXISTS dimensions VARCHAR(20) DEFAULT '1024x1024',
    ADD COLUMN IF NOT EXISTS seed BIGINT DEFAULT 42,
    ADD COLUMN IF NOT EXISTS is_marketplace_public BOOLEAN NOT NULL DEFAULT TRUE,
    ADD COLUMN IF NOT EXISTS base_remix_fee NUMERIC(10, 2) DEFAULT 4.00,
    ADD COLUMN IF NOT EXISTS remix_fee NUMERIC(10, 2) DEFAULT 4.00,
    ADD COLUMN IF NOT EXISTS author_royalty_cut NUMERIC(10, 2) DEFAULT 1.60,
    ADD COLUMN IF NOT EXISTS creator_royalty_cut NUMERIC(10, 2) DEFAULT 1.60,
    ADD COLUMN IF NOT EXISTS metadata JSONB NOT NULL DEFAULT '{}'::jsonb;

-- CRITICAL: Allow system/curated starter templates (author_id & user_id may be null for platform templates)
ALTER TABLE public.explore_prompts ALTER COLUMN author_id DROP NOT NULL;
ALTER TABLE public.explore_prompts ALTER COLUMN user_id DROP NOT NULL;

-- Harmonize dual-platform aliases
UPDATE public.explore_prompts SET user_id = author_id WHERE user_id IS NULL AND author_id IS NOT NULL;
UPDATE public.explore_prompts SET author_id = user_id WHERE author_id IS NULL AND user_id IS NOT NULL;
UPDATE public.explore_prompts SET prompt = masked_prompt_summary WHERE prompt IS NULL AND masked_prompt_summary IS NOT NULL;
UPDATE public.explore_prompts SET masked_summary = masked_prompt_summary WHERE masked_summary IS NULL AND masked_prompt_summary IS NOT NULL;
UPDATE public.explore_prompts SET image_url = preview_url WHERE image_url IS NULL AND preview_url IS NOT NULL;
UPDATE public.explore_prompts SET preview_image_url = preview_url WHERE preview_image_url IS NULL AND preview_url IS NOT NULL;
UPDATE public.explore_prompts SET model = model_used WHERE model IS NULL AND model_used IS NOT NULL;
UPDATE public.explore_prompts SET remixes_count = total_remixes WHERE remixes_count IS NULL AND total_remixes IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_explore_category_created ON public.explore_prompts (category, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_explore_user ON public.explore_prompts (user_id, created_at DESC);

-- GIN Universal Search Index for instant keyword filtering
DROP INDEX IF EXISTS public.idx_explore_prompts_fts;
CREATE INDEX idx_explore_prompts_fts ON public.explore_prompts 
USING gin (to_tsvector('english', 
    COALESCE(title, '') || ' ' || 
    COALESCE(masked_summary, '') || ' ' || 
    COALESCE(masked_prompt_summary, '') || ' ' || 
    COALESCE(category, '') || ' ' ||
    COALESCE(model_used, '')
));

ALTER TABLE public.explore_prompts ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Users publish own prompts" ON public.explore_prompts;
CREATE POLICY "Users publish own prompts" ON public.explore_prompts 
    FOR INSERT WITH CHECK ((SELECT auth.uid()) = author_id OR (SELECT auth.uid()) = user_id);

DROP POLICY IF EXISTS "Users update own prompts" ON public.explore_prompts;
CREATE POLICY "Users update own prompts" ON public.explore_prompts 
    FOR UPDATE USING ((SELECT auth.uid()) = author_id OR (SELECT auth.uid()) = user_id);

DROP POLICY IF EXISTS "Public prompts viewable by all" ON public.explore_prompts;
CREATE POLICY "Public prompts viewable by all" ON public.explore_prompts 
    FOR SELECT USING (is_marketplace_public = TRUE OR (SELECT auth.uid()) = author_id OR (SELECT auth.uid()) = user_id);

GRANT ALL ON public.explore_prompts TO anon, authenticated, service_role;

-- Atomic like counter toggle RPC function (prevents overwriting like counts with 1/0)
CREATE OR REPLACE FUNCTION public.toggle_prompt_like(prompt_id UUID, is_liked BOOLEAN)
RETURNS INT AS $$
DECLARE
    new_count INT;
BEGIN
    UPDATE public.explore_prompts
    SET likes_count = GREATEST(0, COALESCE(likes_count, 0) + (CASE WHEN is_liked THEN 1 ELSE -1 END))
    WHERE id = prompt_id
    RETURNING likes_count INTO new_count;
    RETURN COALESCE(new_count, 0);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
GRANT EXECUTE ON FUNCTION public.toggle_prompt_like TO anon, authenticated, service_role;

-- ====================================================================
-- 3. JOBS TABLE (Generations, Pay-to-Download, & Cloud Library Ledger)
-- ====================================================================
CREATE TABLE IF NOT EXISTS public.jobs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    job_id TEXT,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    character_id UUID REFERENCES public.characters(id) ON DELETE SET NULL,
    remixed_from_prompt_id UUID REFERENCES public.explore_prompts(id) ON DELETE SET NULL,
    type TEXT NOT NULL DEFAULT 'IMAGE_GEN',
    status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'processing', 'completed', 'failed')),
    prompt TEXT,
    prompt_text TEXT,
    preview_url TEXT,
    preview_image_url TEXT,
    image_url TEXT,
    master_url TEXT,
    master_image_url TEXT,
    output_url TEXT,
    tool_applied TEXT NOT NULL DEFAULT 'text_to_image',
    aspect_ratio VARCHAR(10) NOT NULL DEFAULT '1:1',
    dimensions VARCHAR(20) DEFAULT '1024x1024',
    seed BIGINT DEFAULT 42,
    model_used VARCHAR(50) DEFAULT 'flux',
    tokens_analyzed INT NOT NULL DEFAULT 0,
    credits_deducted NUMERIC(10, 2) NOT NULL DEFAULT 2.00,
    is_download_unlocked BOOLEAN NOT NULL DEFAULT FALSE,
    download_unlocked_at TIMESTAMPTZ,
    download_cost NUMERIC(10, 2) NOT NULL DEFAULT 2.00,
    generation_time_ms INT DEFAULT 0,
    metadata JSONB NOT NULL DEFAULT '{}'::jsonb,
    deleted_at TIMESTAMPTZ DEFAULT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE public.jobs 
    ADD COLUMN IF NOT EXISTS job_id TEXT,
    ADD COLUMN IF NOT EXISTS prompt TEXT,
    ADD COLUMN IF NOT EXISTS prompt_text TEXT,
    ADD COLUMN IF NOT EXISTS preview_url TEXT,
    ADD COLUMN IF NOT EXISTS preview_image_url TEXT,
    ADD COLUMN IF NOT EXISTS image_url TEXT,
    ADD COLUMN IF NOT EXISTS master_image_url TEXT,
    ADD COLUMN IF NOT EXISTS master_url TEXT,
    ADD COLUMN IF NOT EXISTS output_url TEXT,
    ADD COLUMN IF NOT EXISTS is_download_unlocked BOOLEAN NOT NULL DEFAULT FALSE,
    ADD COLUMN IF NOT EXISTS download_cost NUMERIC(10, 2) NOT NULL DEFAULT 2.00,
    ADD COLUMN IF NOT EXISTS credits_deducted NUMERIC(10, 2) NOT NULL DEFAULT 2.00,
    ADD COLUMN IF NOT EXISTS model_used VARCHAR(50) DEFAULT 'flux',
    ADD COLUMN IF NOT EXISTS tool_applied TEXT NOT NULL DEFAULT 'text_to_image',
    ADD COLUMN IF NOT EXISTS aspect_ratio VARCHAR(10) NOT NULL DEFAULT '1:1',
    ADD COLUMN IF NOT EXISTS dimensions VARCHAR(20) DEFAULT '1024x1024',
    ADD COLUMN IF NOT EXISTS seed BIGINT DEFAULT 42,
    ADD COLUMN IF NOT EXISTS generation_time_ms INT DEFAULT 0,
    ADD COLUMN IF NOT EXISTS deleted_at TIMESTAMPTZ DEFAULT NULL,
    ADD COLUMN IF NOT EXISTS metadata JSONB NOT NULL DEFAULT '{}'::jsonb;

-- Populate aliases seamlessly
UPDATE public.jobs SET job_id = id::text WHERE job_id IS NULL;
UPDATE public.jobs SET prompt = prompt_text WHERE prompt IS NULL AND prompt_text IS NOT NULL;
UPDATE public.jobs SET prompt_text = prompt WHERE prompt_text IS NULL AND prompt IS NOT NULL;
UPDATE public.jobs SET preview_url = preview_image_url WHERE preview_url IS NULL AND preview_image_url IS NOT NULL;
UPDATE public.jobs SET preview_image_url = preview_url WHERE preview_image_url IS NULL AND preview_url IS NOT NULL;
UPDATE public.jobs SET image_url = preview_url WHERE image_url IS NULL AND preview_url IS NOT NULL;
UPDATE public.jobs SET output_url = preview_url WHERE output_url IS NULL AND preview_url IS NOT NULL;

CREATE UNIQUE INDEX IF NOT EXISTS uq_jobs_job_id ON public.jobs (job_id) WHERE job_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_jobs_user_created ON public.jobs (user_id, created_at DESC);

ALTER TABLE public.jobs ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Users insert own jobs" ON public.jobs;
CREATE POLICY "Users insert own jobs" ON public.jobs 
    FOR INSERT WITH CHECK ((SELECT auth.uid()) = user_id);

DROP POLICY IF EXISTS "Users view own jobs" ON public.jobs;
CREATE POLICY "Users view own jobs" ON public.jobs 
    FOR SELECT USING ((SELECT auth.uid()) = user_id);

DROP POLICY IF EXISTS "Users update own jobs" ON public.jobs;
CREATE POLICY "Users update own jobs" ON public.jobs 
    FOR UPDATE USING ((SELECT auth.uid()) = user_id);

DROP POLICY IF EXISTS "Users delete own jobs" ON public.jobs;
CREATE POLICY "Users delete own jobs" ON public.jobs 
    FOR DELETE USING ((SELECT auth.uid()) = user_id);

GRANT ALL ON public.jobs TO anon, authenticated, service_role;

-- Full text search GIN index for jobs
DROP INDEX IF EXISTS public.idx_jobs_prompt_fts;
CREATE INDEX idx_jobs_prompt_fts ON public.jobs 
USING gin (to_tsvector('english', COALESCE(prompt_text, '') || ' ' || COALESCE(prompt, '')));

-- ====================================================================
-- 4. COLLECTIONS TABLE (Folders / Bookmarks)
-- ====================================================================
CREATE TABLE IF NOT EXISTS public.collections (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    name TEXT NOT NULL CHECK (char_length(trim(name)) > 0),
    description TEXT,
    cover_image_url TEXT,
    item_count INT NOT NULL DEFAULT 0,
    is_default BOOLEAN NOT NULL DEFAULT FALSE,
    is_private BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE public.collections 
    ADD COLUMN IF NOT EXISTS item_count INT NOT NULL DEFAULT 0,
    ADD COLUMN IF NOT EXISTS is_default BOOLEAN NOT NULL DEFAULT FALSE,
    ADD COLUMN IF NOT EXISTS is_private BOOLEAN NOT NULL DEFAULT TRUE,
    ADD COLUMN IF NOT EXISTS cover_image_url TEXT,
    ADD COLUMN IF NOT EXISTS description TEXT;

CREATE INDEX IF NOT EXISTS idx_collections_user ON public.collections (user_id, updated_at DESC);
ALTER TABLE public.collections ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Users manage own collections" ON public.collections;
CREATE POLICY "Users manage own collections" ON public.collections
    FOR ALL USING ((SELECT auth.uid()) = user_id);

-- Auto-provision 'All Saved' default collection on new user signup
CREATE OR REPLACE FUNCTION public.handle_new_user_default_collection()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.collections (user_id, name, is_default, is_private)
    VALUES (NEW.id, 'All Saved', TRUE, TRUE)
    ON CONFLICT DO NOTHING;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS trg_new_user_default_collection ON auth.users;
CREATE TRIGGER trg_new_user_default_collection
AFTER INSERT ON auth.users
FOR EACH ROW EXECUTE FUNCTION public.handle_new_user_default_collection();

GRANT ALL ON public.collections TO anon, authenticated, service_role;

-- ====================================================================
-- 5. COLLECTION ITEMS (Polymorphic Bookmark Junction Table)
-- ====================================================================
CREATE TABLE IF NOT EXISTS public.collection_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    collection_id UUID NOT NULL REFERENCES public.collections(id) ON DELETE CASCADE,
    job_id UUID REFERENCES public.jobs(id) ON DELETE CASCADE,
    explore_prompt_id UUID REFERENCES public.explore_prompts(id) ON DELETE CASCADE,
    artwork_id TEXT,
    item_id TEXT,
    image_url TEXT NOT NULL,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT chk_item_target CHECK (job_id IS NOT NULL OR explore_prompt_id IS NOT NULL OR item_id IS NOT NULL OR artwork_id IS NOT NULL)
);

CREATE UNIQUE INDEX IF NOT EXISTS uq_collection_job 
    ON public.collection_items (collection_id, job_id) 
    WHERE job_id IS NOT NULL;

CREATE UNIQUE INDEX IF NOT EXISTS uq_collection_explore 
    ON public.collection_items (collection_id, explore_prompt_id) 
    WHERE explore_prompt_id IS NOT NULL;

CREATE UNIQUE INDEX IF NOT EXISTS uq_collection_artwork 
    ON public.collection_items (collection_id, artwork_id) 
    WHERE artwork_id IS NOT NULL;

CREATE UNIQUE INDEX IF NOT EXISTS uq_collection_item_generic 
    ON public.collection_items (collection_id, item_id) 
    WHERE item_id IS NOT NULL;

ALTER TABLE public.collection_items 
    ADD COLUMN IF NOT EXISTS collection_id UUID REFERENCES public.collections(id) ON DELETE CASCADE,
    ADD COLUMN IF NOT EXISTS job_id UUID REFERENCES public.jobs(id) ON DELETE CASCADE,
    ADD COLUMN IF NOT EXISTS explore_prompt_id UUID REFERENCES public.explore_prompts(id) ON DELETE CASCADE,
    ADD COLUMN IF NOT EXISTS artwork_id TEXT,
    ADD COLUMN IF NOT EXISTS item_id TEXT,
    ADD COLUMN IF NOT EXISTS image_url TEXT,
    ADD COLUMN IF NOT EXISTS user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE;

CREATE INDEX IF NOT EXISTS idx_collection_items_col ON public.collection_items (collection_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_collection_items_user ON public.collection_items (user_id, created_at DESC);
ALTER TABLE public.collection_items ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Users manage own collection items" ON public.collection_items;
CREATE POLICY "Users manage own collection items" ON public.collection_items
    FOR ALL USING ((SELECT auth.uid()) = user_id);

-- O(1) Counter cache trigger functions for collection item counts
CREATE OR REPLACE FUNCTION public.increment_collection_count()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE public.collections 
    SET item_count = item_count + 1, updated_at = NOW()
    WHERE id = NEW.collection_id;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS trg_collection_item_added ON public.collection_items;
CREATE TRIGGER trg_collection_item_added
AFTER INSERT ON public.collection_items
FOR EACH ROW EXECUTE FUNCTION public.increment_collection_count();

CREATE OR REPLACE FUNCTION public.decrement_collection_count()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE public.collections 
    SET item_count = GREATEST(item_count - 1, 0), updated_at = NOW()
    WHERE id = OLD.collection_id;
    RETURN OLD;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS trg_collection_item_removed ON public.collection_items;
CREATE TRIGGER trg_collection_item_removed
AFTER DELETE ON public.collection_items
FOR EACH ROW EXECUTE FUNCTION public.decrement_collection_count();

-- ====================================================================
-- 5. WALLET & USER_WALLETS VIEW COMPATIBILITY
-- ====================================================================
CREATE TABLE IF NOT EXISTS public.wallets (
    user_id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    credits NUMERIC(10, 2) NOT NULL DEFAULT 500.00,
    free_daily_balance NUMERIC(10, 2) NOT NULL DEFAULT 500.00,
    purchased_balance NUMERIC(10, 2) NOT NULL DEFAULT 0.00,
    earned_royalty_balance NUMERIC(10, 2) NOT NULL DEFAULT 0.00,
    total_generations INT NOT NULL DEFAULT 0,
    total_royalties_earned NUMERIC(10, 2) NOT NULL DEFAULT 0.00,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE public.wallets 
    ADD COLUMN IF NOT EXISTS credits NUMERIC(10, 2) NOT NULL DEFAULT 500.00,
    ADD COLUMN IF NOT EXISTS free_daily_balance NUMERIC(10, 2) NOT NULL DEFAULT 500.00,
    ADD COLUMN IF NOT EXISTS purchased_balance NUMERIC(10, 2) NOT NULL DEFAULT 0.00,
    ADD COLUMN IF NOT EXISTS earned_royalty_balance NUMERIC(10, 2) NOT NULL DEFAULT 0.00,
    ADD COLUMN IF NOT EXISTS total_generations INT NOT NULL DEFAULT 0,
    ADD COLUMN IF NOT EXISTS total_royalties_earned NUMERIC(10, 2) NOT NULL DEFAULT 0.00,
    ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW();

ALTER TABLE public.wallets ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Users view own wallet" ON public.wallets;
CREATE POLICY "Users view own wallet" ON public.wallets
    FOR SELECT USING ((SELECT auth.uid()) = user_id);

DROP POLICY IF EXISTS "Users update own wallet" ON public.wallets;
CREATE POLICY "Users update own wallet" ON public.wallets
    FOR UPDATE USING ((SELECT auth.uid()) = user_id);

DROP POLICY IF EXISTS "Users insert own wallet" ON public.wallets;
CREATE POLICY "Users insert own wallet" ON public.wallets
    FOR INSERT WITH CHECK ((SELECT auth.uid()) = user_id);

GRANT ALL ON public.wallets TO anon, authenticated, service_role;

-- Auto-provision wallet on user signup trigger
CREATE OR REPLACE FUNCTION public.handle_new_user_wallet()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.wallets (user_id, free_daily_balance, purchased_balance, credits)
    VALUES (NEW.id, 500.00, 0.00, 500.00)
    ON CONFLICT (user_id) DO NOTHING;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS trg_new_user_wallet ON auth.users;
CREATE TRIGGER trg_new_user_wallet
AFTER INSERT ON auth.users
FOR EACH ROW EXECUTE FUNCTION public.handle_new_user_wallet();

-- Create a view so both 'wallets' and 'user_wallets' queries resolve seamlessly
CREATE OR REPLACE VIEW public.user_wallets AS 
SELECT * FROM public.wallets;

-- Atomic RPC: deduct_user_credits
CREATE OR REPLACE FUNCTION public.deduct_user_credits(
    p_user_id UUID,
    p_amount NUMERIC(10, 2),
    p_task_id TEXT DEFAULT NULL,
    p_reason TEXT DEFAULT 'generation'
)
RETURNS JSONB AS $$
DECLARE
    v_wallet RECORD;
    v_free_deduct NUMERIC(10, 2) := 0.00;
    v_purchased_deduct NUMERIC(10, 2) := 0.00;
    v_remaining_needed NUMERIC(10, 2) := p_amount;
    v_total_balance NUMERIC(10, 2);
    v_new_total NUMERIC(10, 2);
BEGIN
    SELECT * INTO v_wallet 
    FROM public.wallets 
    WHERE user_id = p_user_id 
    FOR UPDATE;

    IF NOT FOUND THEN
        INSERT INTO public.wallets (user_id, free_daily_balance, purchased_balance)
        VALUES (p_user_id, 500.00, 0.00)
        RETURNING * INTO v_wallet;
    END IF;

    v_total_balance := COALESCE(v_wallet.free_daily_balance, 0.00) + COALESCE(v_wallet.purchased_balance, 0.00);

    IF v_total_balance < p_amount THEN
        RETURN jsonb_build_object(
            'success', FALSE,
            'error', 'Insufficient credit balance',
            'current_balance', v_total_balance,
            'required', p_amount
        );
    END IF;

    IF v_wallet.free_daily_balance >= v_remaining_needed THEN
        v_free_deduct := v_remaining_needed;
        v_remaining_needed := 0.00;
    ELSE
        v_free_deduct := v_wallet.free_daily_balance;
        v_remaining_needed := v_remaining_needed - v_wallet.free_daily_balance;
        v_purchased_deduct := v_remaining_needed;
    END IF;

    UPDATE public.wallets 
    SET 
        free_daily_balance = free_daily_balance - v_free_deduct,
        purchased_balance = purchased_balance - v_purchased_deduct,
        total_generations = total_generations + 1,
        updated_at = NOW()
    WHERE user_id = p_user_id;

    v_new_total := v_total_balance - p_amount;

    RETURN jsonb_build_object(
        'success', TRUE,
        'deducted', p_amount,
        'remaining_balance', v_new_total,
        'free_daily_balance', v_wallet.free_daily_balance - v_free_deduct,
        'purchased_balance', v_wallet.purchased_balance - v_purchased_deduct,
        'task_id', p_task_id
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Atomic RPC: refund_user_credits
CREATE OR REPLACE FUNCTION public.refund_user_credits(
    p_user_id UUID,
    p_amount NUMERIC(10, 2),
    p_task_id TEXT DEFAULT NULL,
    p_reason TEXT DEFAULT 'generation_failed'
)
RETURNS JSONB AS $$
DECLARE
    v_wallet RECORD;
    v_new_balance NUMERIC(10, 2);
BEGIN
    SELECT * INTO v_wallet 
    FROM public.wallets 
    WHERE user_id = p_user_id 
    FOR UPDATE;

    IF NOT FOUND THEN
        INSERT INTO public.wallets (user_id, free_daily_balance, purchased_balance)
        VALUES (p_user_id, p_amount, 0.00)
        RETURNING * INTO v_wallet;
    ELSE
        UPDATE public.wallets 
        SET 
            free_daily_balance = free_daily_balance + p_amount,
            updated_at = NOW()
        WHERE user_id = p_user_id;
    END IF;

    SELECT (COALESCE(free_daily_balance, 0.00) + COALESCE(purchased_balance, 0.00)) INTO v_new_balance
    FROM public.wallets 
    WHERE user_id = p_user_id;

    RETURN jsonb_build_object(
        'success', TRUE,
        'refunded', p_amount,
        'new_balance', v_new_balance,
        'task_id', p_task_id
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ====================================================================
-- 6. ENSURE DEFAULT COLLECTIONS FOR EXISTING USERS (Zero Conflicts)
-- ====================================================================
INSERT INTO public.collections (user_id, name, is_default, is_private)
SELECT u.id, 'All Saved', TRUE, TRUE
FROM auth.users u
WHERE NOT EXISTS (
    SELECT 1 FROM public.collections c 
    WHERE c.user_id = u.id AND (c.name = 'All Saved' OR c.is_default = TRUE)
);

-- ====================================================================
-- 7. SEED EXPLORE COMMUNITY PROMPTS (Initial Styles & Categories)
-- ====================================================================
DO $$
DECLARE
    v_admin_id UUID;
BEGIN
    -- Dynamically use earliest registered user ID if available, else NULL
    SELECT id INTO v_admin_id FROM auth.users ORDER BY created_at ASC LIMIT 1;

    INSERT INTO public.explore_prompts (
        id, author_id, user_id, title, author_handle, category, model_used, aspect_ratio, preview_url, preview_image_url,
        image_url, masked_prompt_summary, masked_summary, prompt, base_remix_fee, author_royalty_cut,
        total_remixes, remixes_count, likes_count, is_marketplace_public
    ) VALUES
        ('00000000-0000-4000-8000-000000000001', v_admin_id, v_admin_id, 'Cyber Ronin in Rain', '@neo_akira', 'Cyberpunk', 'FLUX.1 Schnell', '16:9', 'https://images.unsplash.com/photo-1578632767115-351597cf2477?w=600&auto=format&fit=crop', 'https://images.unsplash.com/photo-1578632767115-351597cf2477?w=600&auto=format&fit=crop', 'https://images.unsplash.com/photo-1578632767115-351597cf2477?w=600&auto=format&fit=crop', 'Cyber Ronin • Wet Neon Street • 85mm Bokeh • [Secret Recipe Encrypted]', 'Cyber Ronin • Wet Neon Street • 85mm Bokeh • [Secret Recipe Encrypted]', 'Cyber Ronin • Wet Neon Street • 85mm Bokeh • [Secret Recipe Encrypted]', 4.0, 1.6, 342, 342, 890, TRUE),
        ('00000000-0000-4000-8000-000000000002', v_admin_id, v_admin_id, 'Ethereal Studio Portrait', '@elena_art', 'Photorealism', 'RealVisXL v4.0', '1:1', 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=600&auto=format&fit=crop', 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=600&auto=format&fit=crop', 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=600&auto=format&fit=crop', 'Natural Beauty • Hasselblad 100c • Soft Golden Hour • [Secret Recipe Encrypted]', 'Natural Beauty • Hasselblad 100c • Soft Golden Hour • [Secret Recipe Encrypted]', 'Natural Beauty • Hasselblad 100c • Soft Golden Hour • [Secret Recipe Encrypted]', 5.0, 2.0, 512, 512, 1420, TRUE),
        ('00000000-0000-4000-8000-000000000003', v_admin_id, v_admin_id, 'Mecha Angel Guardian', '@kaito_anime', 'Anime', 'SDXL-Lightning', '9:16', 'https://images.unsplash.com/photo-1607604276583-eef5d076aa5f?w=600&auto=format&fit=crop', 'https://images.unsplash.com/photo-1607604276583-eef5d076aa5f?w=600&auto=format&fit=crop', 'https://images.unsplash.com/photo-1607604276583-eef5d076aa5f?w=600&auto=format&fit=crop', 'Mecha Armor • Celestial Glow • Makoto Shinkai Style • [Secret Recipe Encrypted]', 'Mecha Armor • Celestial Glow • Makoto Shinkai Style • [Secret Recipe Encrypted]', 'Mecha Armor • Celestial Glow • Makoto Shinkai Style • [Secret Recipe Encrypted]', 4.0, 1.6, 219, 219, 654, TRUE),
        ('00000000-0000-4000-8000-000000000004', v_admin_id, v_admin_id, 'Obsidian Minimalist Watch', '@voxel_craft', 'Product', 'FLUX.1 Schnell', '1:1', 'https://images.unsplash.com/photo-1523275335684-37898b6baf30?w=600&auto=format&fit=crop', 'https://images.unsplash.com/photo-1523275335684-37898b6baf30?w=600&auto=format&fit=crop', 'https://images.unsplash.com/photo-1523275335684-37898b6baf30?w=600&auto=format&fit=crop', 'Matte Black • Volumetric Rim Lighting • Studio Pedestal • [Secret Recipe Encrypted]', 'Matte Black • Volumetric Rim Lighting • Studio Pedestal • [Secret Recipe Encrypted]', 'Matte Black • Volumetric Rim Lighting • Studio Pedestal • [Secret Recipe Encrypted]', 3.0, 1.2, 184, 184, 420, TRUE),
        ('00000000-0000-4000-8000-000000000005', v_admin_id, v_admin_id, 'Neon Valkyrie 2099', '@sora_cg', 'Character', 'RealVisXL v4.0', '9:16', 'https://images.unsplash.com/photo-1563089145-599997674d42?w=600&auto=format&fit=crop', 'https://images.unsplash.com/photo-1563089145-599997674d42?w=600&auto=format&fit=crop', 'https://images.unsplash.com/photo-1563089145-599997674d42?w=600&auto=format&fit=crop', 'Valkyrie Armor • Electric Wings • Hyper-detailed Face • [Secret Recipe Encrypted]', 'Valkyrie Armor • Electric Wings • Hyper-detailed Face • [Secret Recipe Encrypted]', 'Valkyrie Armor • Electric Wings • Hyper-detailed Face • [Secret Recipe Encrypted]', 4.0, 1.6, 412, 412, 975, TRUE),
        ('00000000-0000-4000-8000-000000000006', v_admin_id, v_admin_id, 'Nordic Cliffside Villa', '@arch_design', 'Architecture', 'FLUX.1 Schnell', '16:9', 'https://images.unsplash.com/photo-1600585154340-be6161a56a0c?w=600&auto=format&fit=crop', 'https://images.unsplash.com/photo-1600585154340-be6161a56a0c?w=600&auto=format&fit=crop', 'https://images.unsplash.com/photo-1600585154340-be6161a56a0c?w=600&auto=format&fit=crop', 'Modern Concrete • Floor-to-ceiling Glass • Mist Valley • [Secret Recipe Encrypted]', 'Modern Concrete • Floor-to-ceiling Glass • Mist Valley • [Secret Recipe Encrypted]', 'Modern Concrete • Floor-to-ceiling Glass • Mist Valley • [Secret Recipe Encrypted]', 3.0, 1.2, 156, 156, 388, TRUE),
        ('00000000-0000-4000-8000-000000000007', v_admin_id, v_admin_id, 'Winter Fox Adventurer', '@pixar_craft', '3D Render', 'SDXL-Lightning', '1:1', 'https://images.unsplash.com/photo-1474511320723-9a56873867b5?w=600&auto=format&fit=crop', 'https://images.unsplash.com/photo-1474511320723-9a56873867b5?w=600&auto=format&fit=crop', 'https://images.unsplash.com/photo-1474511320723-9a56873867b5?w=600&auto=format&fit=crop', 'Fluffy Red Fox • Knitted Beanie • Snow Sparkle • [Secret Recipe Encrypted]', 'Fluffy Red Fox • Knitted Beanie • Snow Sparkle • [Secret Recipe Encrypted]', 'Fluffy Red Fox • Knitted Beanie • Snow Sparkle • [Secret Recipe Encrypted]', 3.0, 1.2, 680, 680, 1890, TRUE),
        ('00000000-0000-4000-8000-000000000008', v_admin_id, v_admin_id, 'Haute Couture Liquid Silk', '@zara_fashion', 'Photorealism', 'RealVisXL v4.0', '4:5', 'https://images.unsplash.com/photo-1496747611176-843222e1e57c?w=600&auto=format&fit=crop', 'https://images.unsplash.com/photo-1496747611176-843222e1e57c?w=600&auto=format&fit=crop', 'https://images.unsplash.com/photo-1496747611176-843222e1e57c?w=600&auto=format&fit=crop', 'Floating Emerald Silk • Dramatic Studio Shadows • 8K Textures • [Secret Recipe Encrypted]', 'Floating Emerald Silk • Dramatic Studio Shadows • 8K Textures • [Secret Recipe Encrypted]', 'Floating Emerald Silk • Dramatic Studio Shadows • 8K Textures • [Secret Recipe Encrypted]', 5.0, 2.0, 390, 390, 1120, TRUE),
        ('00000000-0000-4000-8000-000000000009', v_admin_id, v_admin_id, 'Analog 1985 Street Rider', '@retro_1985', 'Photorealism', 'SDXL-Lightning', '16:9', 'https://images.unsplash.com/photo-1558981806-ec527fa84c39?w=600&auto=format&fit=crop', 'https://images.unsplash.com/photo-1558981806-ec527fa84c39?w=600&auto=format&fit=crop', 'https://images.unsplash.com/photo-1558981806-ec527fa84c39?w=600&auto=format&fit=crop', 'Leather Jacket • 35mm Kodachrome Grain • Direct Flash • [Secret Recipe Encrypted]', 'Leather Jacket • 35mm Kodachrome Grain • Direct Flash • [Secret Recipe Encrypted]', 'Leather Jacket • 35mm Kodachrome Grain • Direct Flash • [Secret Recipe Encrypted]', 4.0, 1.6, 845, 845, 2310, TRUE),
        ('00000000-0000-4000-8000-000000000010', v_admin_id, v_admin_id, 'Cyberpunk Bio-Dome', '@nexus_3d', 'Cyberpunk', 'FLUX.1 Schnell', '16:9', 'https://images.unsplash.com/photo-1518709268805-4e9042af9f23?w=600&auto=format&fit=crop', 'https://images.unsplash.com/photo-1518709268805-4e9042af9f23?w=600&auto=format&fit=crop', 'https://images.unsplash.com/photo-1518709268805-4e9042af9f23?w=600&auto=format&fit=crop', 'Bioluminescent Flora • Neon Glass Habitat • Unreal Engine 5 • [Secret Recipe Encrypted]', 'Bioluminescent Flora • Neon Glass Habitat • Unreal Engine 5 • [Secret Recipe Encrypted]', 'Bioluminescent Flora • Neon Glass Habitat • Unreal Engine 5 • [Secret Recipe Encrypted]', 4.0, 1.6, 290, 290, 740, TRUE),
        ('00000000-0000-4000-8000-000000000011', v_admin_id, v_admin_id, 'Samurai Spirit In Blossom', '@manga_blade', 'Anime', 'RealVisXL v4.0', '9:16', 'https://images.unsplash.com/photo-1524413840807-0c3cb6fa808d?w=600&auto=format&fit=crop', 'https://images.unsplash.com/photo-1524413840807-0c3cb6fa808d?w=600&auto=format&fit=crop', 'https://images.unsplash.com/photo-1524413840807-0c3cb6fa808d?w=600&auto=format&fit=crop', 'Katana Stance • Cherry Blossom Storm • Ukiyo-e Modern Blend • [Secret Recipe Encrypted]', 'Katana Stance • Cherry Blossom Storm • Ukiyo-e Modern Blend • [Secret Recipe Encrypted]', 'Katana Stance • Cherry Blossom Storm • Ukiyo-e Modern Blend • [Secret Recipe Encrypted]', 4.0, 1.6, 530, 530, 1470, TRUE),
        ('00000000-0000-4000-8000-000000000012', v_admin_id, v_admin_id, 'Matte Iridescent Sphere', '@prism_3d', '3D Render', 'SDXL-Lightning', '1:1', 'https://images.unsplash.com/photo-1618005182384-a83a8bd57fbe?w=600&auto=format&fit=crop', 'https://images.unsplash.com/photo-1618005182384-a83a8bd57fbe?w=600&auto=format&fit=crop', 'https://images.unsplash.com/photo-1618005182384-a83a8bd57fbe?w=600&auto=format&fit=crop', 'Fluid Chrome • Holographic Caustics • Octane Render 8K • [Secret Recipe Encrypted]', 'Fluid Chrome • Holographic Caustics • Octane Render 8K • [Secret Recipe Encrypted]', 'Fluid Chrome • Holographic Caustics • Octane Render 8K • [Secret Recipe Encrypted]', 3.0, 1.2, 310, 310, 820, TRUE)
    ON CONFLICT (id) DO UPDATE SET
        author_id = COALESCE(explore_prompts.author_id, EXCLUDED.author_id),
        user_id = COALESCE(explore_prompts.user_id, EXCLUDED.user_id),
        title = EXCLUDED.title,
        preview_url = EXCLUDED.preview_url,
        preview_image_url = EXCLUDED.preview_image_url;
END $$;

-- ====================================================================
-- 8. WEB TEAM COMPATIBILITY: ARTWORKS TABLE & 2-WAY CROSS-SYNC
-- ====================================================================
CREATE TABLE IF NOT EXISTS public.artworks (
    id TEXT PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE DEFAULT auth.uid(),
    author_id UUID REFERENCES auth.users(id) ON DELETE CASCADE DEFAULT auth.uid(),
    title TEXT NOT NULL,
    prompt TEXT NOT NULL,
    masked_summary TEXT,
    image_url TEXT NOT NULL,
    preview_url TEXT,
    category TEXT NOT NULL DEFAULT 'portrait',
    model TEXT NOT NULL DEFAULT 'FLUX.1 Schnell',
    model_used TEXT DEFAULT 'FLUX.1 Schnell',
    remixes_count INT NOT NULL DEFAULT 0,
    total_remixes INT NOT NULL DEFAULT 0,
    likes_count INT NOT NULL DEFAULT 0,
    author_name TEXT NOT NULL DEFAULT 'Creator',
    author_handle TEXT NOT NULL DEFAULT '@creator',
    author_avatar TEXT NOT NULL DEFAULT 'AR',
    aspect_ratio VARCHAR(10) NOT NULL DEFAULT '1:1',
    base_remix_fee NUMERIC(10, 2) DEFAULT 4.00,
    author_royalty_cut NUMERIC(10, 2) DEFAULT 1.60,
    seed INT NOT NULL DEFAULT 42,
    width INT NOT NULL DEFAULT 512,
    height INT NOT NULL DEFAULT 512,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE public.artworks 
    ADD COLUMN IF NOT EXISTS user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE DEFAULT auth.uid(),
    ADD COLUMN IF NOT EXISTS author_id UUID REFERENCES auth.users(id) ON DELETE CASCADE DEFAULT auth.uid(),
    ADD COLUMN IF NOT EXISTS masked_summary TEXT,
    ADD COLUMN IF NOT EXISTS preview_url TEXT,
    ADD COLUMN IF NOT EXISTS model_used TEXT DEFAULT 'FLUX.1 Schnell',
    ADD COLUMN IF NOT EXISTS total_remixes INT DEFAULT 0,
    ADD COLUMN IF NOT EXISTS aspect_ratio VARCHAR(10) DEFAULT '1:1',
    ADD COLUMN IF NOT EXISTS tool_applied TEXT NOT NULL DEFAULT 'text_to_image',
    ADD COLUMN IF NOT EXISTS dimensions VARCHAR(20) DEFAULT '1024x1024',
    ADD COLUMN IF NOT EXISTS base_remix_fee NUMERIC(10, 2) DEFAULT 4.00,
    ADD COLUMN IF NOT EXISTS remix_fee NUMERIC(10, 2) DEFAULT 4.00,
    ADD COLUMN IF NOT EXISTS author_royalty_cut NUMERIC(10, 2) DEFAULT 1.60,
    ADD COLUMN IF NOT EXISTS creator_royalty_cut NUMERIC(10, 2) DEFAULT 1.60;

ALTER TABLE public.artworks ALTER COLUMN user_id DROP NOT NULL;
ALTER TABLE public.artworks ALTER COLUMN author_id DROP NOT NULL;

-- Sync uniform field values in artworks
UPDATE public.artworks SET user_id = author_id WHERE user_id IS NULL AND author_id IS NOT NULL;
UPDATE public.artworks SET author_id = user_id WHERE author_id IS NULL AND user_id IS NOT NULL;
UPDATE public.artworks SET preview_url = image_url WHERE preview_url IS NULL AND image_url IS NOT NULL;
UPDATE public.artworks SET image_url = preview_url WHERE image_url IS NULL AND preview_url IS NOT NULL;
UPDATE public.artworks SET model_used = model WHERE model_used IS NULL AND model IS NOT NULL;
UPDATE public.artworks SET model = model_used WHERE model IS NULL AND model_used IS NOT NULL;
UPDATE public.artworks SET total_remixes = remixes_count WHERE total_remixes IS NULL AND remixes_count IS NOT NULL;
UPDATE public.artworks SET remixes_count = total_remixes WHERE remixes_count IS NULL AND total_remixes IS NOT NULL;
UPDATE public.artworks SET masked_summary = prompt WHERE masked_summary IS NULL AND prompt IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_artworks_user ON public.artworks (user_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_artworks_author ON public.artworks (author_id, created_at DESC);

ALTER TABLE public.artworks ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Anyone can view artworks" ON public.artworks;
CREATE POLICY "Anyone can view artworks" ON public.artworks FOR SELECT USING (true);
DROP POLICY IF EXISTS "Anyone can insert artworks" ON public.artworks;
CREATE POLICY "Anyone can insert artworks" ON public.artworks FOR INSERT WITH CHECK (true);
DROP POLICY IF EXISTS "Users update own artworks" ON public.artworks;
CREATE POLICY "Users update own artworks" ON public.artworks FOR UPDATE USING (auth.uid() = user_id OR auth.uid() = author_id);
DROP POLICY IF EXISTS "Users delete own artworks" ON public.artworks;
CREATE POLICY "Users delete own artworks" ON public.artworks FOR DELETE USING (auth.uid() = user_id OR auth.uid() = author_id);
GRANT ALL ON public.artworks TO anon, authenticated, service_role;

-- Populate initial artworks from explore_prompts so Web and Mobile show same community feed
INSERT INTO public.artworks (
    id, user_id, author_id, title, prompt, masked_summary, image_url, preview_url,
    category, model, model_used, remixes_count, total_remixes, likes_count,
    author_name, author_handle, created_at
)
SELECT 
    ep.id::text,
    COALESCE(ep.user_id, ep.author_id),
    COALESCE(ep.author_id, ep.user_id),
    ep.title,
    COALESCE(ep.masked_prompt_summary, ep.prompt, ep.title, 'Artwork'),
    COALESCE(ep.masked_summary, ep.masked_prompt_summary, ep.title, 'Artwork'),
    COALESCE(ep.preview_url, ep.preview_image_url, ep.image_url, ''),
    COALESCE(ep.preview_url, ep.preview_image_url, ep.image_url, ''),
    COALESCE(ep.category, 'portrait'),
    COALESCE(ep.model_used, 'FLUX.1 Schnell'),
    COALESCE(ep.model_used, 'FLUX.1 Schnell'),
    COALESCE(ep.total_remixes, ep.remixes_count, 0),
    COALESCE(ep.total_remixes, ep.remixes_count, 0),
    COALESCE(ep.likes_count, 0),
    COALESCE(ep.author_name, 'Creator'),
    COALESCE(ep.author_handle, '@creator'),
    COALESCE(ep.created_at, NOW())
FROM public.explore_prompts ep
ON CONFLICT (id) DO NOTHING;

-- Two-Way Sync Trigger 1: When Web user publishes to artworks -> auto-mirror to explore_prompts with user_id
CREATE OR REPLACE FUNCTION public.sync_artwork_to_explore_prompts()
RETURNS TRIGGER AS $$
BEGIN
    IF pg_trigger_depth() > 1 THEN
        RETURN NEW;
    END IF;

    INSERT INTO public.explore_prompts (
        id, author_id, user_id, title, author_handle, category, model_used, aspect_ratio, preview_url, preview_image_url,
        image_url, masked_prompt_summary, masked_summary, prompt, tool_applied, dimensions, base_remix_fee, remix_fee,
        author_royalty_cut, creator_royalty_cut, total_remixes, remixes_count, likes_count, is_marketplace_public, created_at
    ) VALUES (
        CASE 
            WHEN NEW.id ~ '^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$' 
            THEN NEW.id::uuid 
            ELSE gen_random_uuid() 
        END,
        COALESCE(NEW.author_id, NEW.user_id, auth.uid()),
        COALESCE(NEW.user_id, NEW.author_id, auth.uid()),
        NEW.title,
        COALESCE(NEW.author_handle, '@creator'),
        COALESCE(NEW.category, 'General'),
        COALESCE(NEW.model, NEW.model_used, 'FLUX.1 Schnell'),
        COALESCE(NEW.aspect_ratio, '1:1'),
        COALESCE(NEW.preview_url, NEW.image_url, ''),
        COALESCE(NEW.preview_url, NEW.image_url, ''),
        COALESCE(NEW.image_url, NEW.preview_url, ''),
        COALESCE(NEW.masked_summary, NEW.prompt, NEW.title),
        COALESCE(NEW.masked_summary, NEW.prompt, NEW.title),
        NEW.prompt,
        COALESCE(NEW.tool_applied, 'text_to_image'),
        COALESCE(NEW.dimensions, '1024x1024'),
        COALESCE(NEW.base_remix_fee, 4.0),
        COALESCE(NEW.remix_fee, NEW.base_remix_fee, 4.0),
        COALESCE(NEW.author_royalty_cut, 1.6),
        COALESCE(NEW.creator_royalty_cut, NEW.author_royalty_cut, 1.6),
        COALESCE(NEW.total_remixes, NEW.remixes_count, 0),
        COALESCE(NEW.remixes_count, NEW.total_remixes, 0),
        COALESCE(NEW.likes_count, 0),
        TRUE,
        COALESCE(NEW.created_at, NOW())
    )
    ON CONFLICT (id) DO UPDATE SET
        author_id = EXCLUDED.author_id,
        user_id = EXCLUDED.user_id,
        title = EXCLUDED.title,
        prompt = EXCLUDED.prompt,
        image_url = EXCLUDED.image_url,
        preview_url = EXCLUDED.preview_url,
        preview_image_url = EXCLUDED.preview_image_url,
        tool_applied = EXCLUDED.tool_applied,
        dimensions = EXCLUDED.dimensions;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS trg_sync_artwork_to_explore ON public.artworks;
CREATE TRIGGER trg_sync_artwork_to_explore
AFTER INSERT OR UPDATE ON public.artworks
FOR EACH ROW EXECUTE FUNCTION public.sync_artwork_to_explore_prompts();

-- Two-Way Sync Trigger 2: When Mobile user publishes to explore_prompts -> auto-mirror to artworks with user_id
CREATE OR REPLACE FUNCTION public.sync_explore_prompt_to_artworks()
RETURNS TRIGGER AS $$
BEGIN
    IF pg_trigger_depth() > 1 THEN
        RETURN NEW;
    END IF;

    INSERT INTO public.artworks (
        id, user_id, author_id, title, prompt, masked_summary, image_url, preview_url,
        category, model, model_used, remixes_count, total_remixes, likes_count,
        author_name, author_handle, aspect_ratio, tool_applied, dimensions,
        base_remix_fee, remix_fee, author_royalty_cut, creator_royalty_cut, created_at
    ) VALUES (
        NEW.id::text,
        COALESCE(NEW.user_id, NEW.author_id),
        COALESCE(NEW.author_id, NEW.user_id),
        NEW.title,
        COALESCE(NEW.prompt, NEW.masked_summary, NEW.masked_prompt_summary, NEW.title),
        COALESCE(NEW.masked_summary, NEW.masked_prompt_summary, NEW.title),
        COALESCE(NEW.image_url, NEW.preview_url, NEW.preview_image_url, ''),
        COALESCE(NEW.preview_url, NEW.preview_image_url, NEW.image_url, ''),
        COALESCE(NEW.category, 'portrait'),
        COALESCE(NEW.model, NEW.model_used, 'FLUX.1 Schnell'),
        COALESCE(NEW.model_used, NEW.model, 'FLUX.1 Schnell'),
        COALESCE(NEW.remixes_count, NEW.total_remixes, 0),
        COALESCE(NEW.total_remixes, NEW.remixes_count, 0),
        COALESCE(NEW.likes_count, 0),
        COALESCE(NEW.author_name, 'Creator'),
        COALESCE(NEW.author_handle, '@creator'),
        COALESCE(NEW.aspect_ratio, '1:1'),
        COALESCE(NEW.tool_applied, 'text_to_image'),
        COALESCE(NEW.dimensions, '1024x1024'),
        COALESCE(NEW.base_remix_fee, 4.0),
        COALESCE(NEW.remix_fee, NEW.base_remix_fee, 4.0),
        COALESCE(NEW.author_royalty_cut, 1.6),
        COALESCE(NEW.creator_royalty_cut, NEW.author_royalty_cut, 1.6),
        COALESCE(NEW.created_at, NOW())
    )
    ON CONFLICT (id) DO UPDATE SET
        user_id = EXCLUDED.user_id,
        author_id = EXCLUDED.author_id,
        title = EXCLUDED.title,
        prompt = EXCLUDED.prompt,
        image_url = EXCLUDED.image_url,
        preview_url = EXCLUDED.preview_url,
        tool_applied = EXCLUDED.tool_applied,
        dimensions = EXCLUDED.dimensions;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS trg_sync_explore_to_artworks ON public.explore_prompts;
CREATE TRIGGER trg_sync_explore_to_artworks
AFTER INSERT OR UPDATE ON public.explore_prompts
FOR EACH ROW EXECUTE FUNCTION public.sync_explore_prompt_to_artworks();

-- ====================================================================
-- 9. STORAGE BUCKETS & POLICIES (user_generations & reference-images)
-- ====================================================================
INSERT INTO storage.buckets (id, name, public)
VALUES ('user_generations', 'user_generations', true)
ON CONFLICT (id) DO UPDATE SET public = true;

INSERT INTO storage.buckets (id, name, public)
VALUES ('reference-images', 'reference-images', true)
ON CONFLICT (id) DO UPDATE SET public = true;

DROP POLICY IF EXISTS "Public view user_generations" ON storage.objects;
CREATE POLICY "Public view user_generations" ON storage.objects
    FOR SELECT USING (bucket_id = 'user_generations');

DROP POLICY IF EXISTS "Authenticated upload user_generations" ON storage.objects;
CREATE POLICY "Authenticated upload user_generations" ON storage.objects
    FOR INSERT WITH CHECK (bucket_id = 'user_generations');

DROP POLICY IF EXISTS "Authenticated delete user_generations" ON storage.objects;
CREATE POLICY "Authenticated delete user_generations" ON storage.objects
    FOR DELETE USING (bucket_id = 'user_generations');

DROP POLICY IF EXISTS "Public view reference_images" ON storage.objects;
CREATE POLICY "Public view reference_images" ON storage.objects
    FOR SELECT USING (bucket_id = 'reference-images');

DROP POLICY IF EXISTS "Authenticated upload reference_images" ON storage.objects;
CREATE POLICY "Authenticated upload reference_images" ON storage.objects
    FOR INSERT WITH CHECK (bucket_id = 'reference-images');

-- ====================================================================
-- 15. DYNAMIC CATEGORIES & IMAGE AUTO-CLASSIFICATION SYSTEM
-- ====================================================================

-- 1. Create Master Categories Table
CREATE TABLE IF NOT EXISTS public.categories (
    id TEXT PRIMARY KEY DEFAULT gen_random_uuid()::text,
    slug VARCHAR(50) UNIQUE NOT NULL,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    icon_name VARCHAR(50) NOT NULL DEFAULT 'auto_awesome',
    keywords TEXT[] NOT NULL DEFAULT '{}',
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    sort_order INT NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Ensure all columns exist even if categories table was created in an earlier migration
ALTER TABLE public.categories 
    ADD COLUMN IF NOT EXISTS slug VARCHAR(50),
    ADD COLUMN IF NOT EXISTS name VARCHAR(100),
    ADD COLUMN IF NOT EXISTS description TEXT,
    ADD COLUMN IF NOT EXISTS icon_name VARCHAR(50) NOT NULL DEFAULT 'auto_awesome',
    ADD COLUMN IF NOT EXISTS keywords TEXT[] NOT NULL DEFAULT '{}',
    ADD COLUMN IF NOT EXISTS is_active BOOLEAN NOT NULL DEFAULT TRUE,
    ADD COLUMN IF NOT EXISTS sort_order INT NOT NULL DEFAULT 0,
    ADD COLUMN IF NOT EXISTS created_at TIMESTAMPTZ NOT NULL DEFAULT NOW();

CREATE UNIQUE INDEX IF NOT EXISTS uq_categories_slug ON public.categories (slug);

-- 2. Populate Standard Starter Categories with Smart Keyword Rules
INSERT INTO public.categories (slug, name, icon_name, keywords, sort_order) VALUES
('photorealism', 'Photorealism', 'camera_alt', ARRAY['photo', 'photograph', '85mm', 'portrait', 'realistic', 'dslr', 'raw photo', 'kodak', 'hyperrealistic', 'film grain', 'cinematic photo'], 1),
('anime', 'Anime', 'palette', ARRAY['anime', 'manga', 'ghibli', 'makoto shinkai', 'cel shaded', 'waifu', 'kawaii', 'chibi', 'otaku', 'japanese animation'], 2),
('cyberpunk', 'Cyberpunk', 'electric_bolt', ARRAY['cyberpunk', 'neon', 'futuristic', 'cyborg', 'synthwave', 'sci-fi', 'hologram', 'mecha', 'blade runner', 'matrix'], 3),
('3d-render', '3D Render', 'view_in_ar', ARRAY['3d', 'render', 'octane', 'blender', 'unreal engine', 'cgi', 'isometric', 'pixar', 'claymation', 'digital 3d'], 4),
('character', 'Character', 'person', ARRAY['character', 'portrait', 'warrior', 'knight', 'woman', 'man', 'hero', 'villain', 'avatar', 'ethereal noblewoman', 'samurai'], 5),
('architecture', 'Architecture', 'apartment', ARRAY['architecture', 'building', 'house', 'interior', 'facade', 'modern villa', 'skyscraper', 'room design', 'urban'], 6),
('product', 'Product', 'inventory_2', ARRAY['product', 'mockup', 'bottle', 'packaging', 'watch', 'sneakers', 'commercial', 'cosmetics', 'gadget', 'merchandise'], 7),
('general', 'General', 'auto_awesome', ARRAY['art', 'illustration', 'creative', 'concept', 'abstract'], 99)
ON CONFLICT (slug) DO UPDATE SET 
    name = EXCLUDED.name,
    icon_name = EXCLUDED.icon_name,
    keywords = EXCLUDED.keywords,
    sort_order = EXCLUDED.sort_order;

-- 3. Enhance public.jobs & explore_prompts Tables
ALTER TABLE public.jobs 
    ADD COLUMN IF NOT EXISTS category VARCHAR(50) DEFAULT 'General',
    ADD COLUMN IF NOT EXISTS category_id TEXT REFERENCES public.categories(id) ON DELETE SET NULL;

ALTER TABLE public.explore_prompts 
    ADD COLUMN IF NOT EXISTS category_id TEXT REFERENCES public.categories(id) ON DELETE SET NULL;

CREATE INDEX IF NOT EXISTS idx_jobs_user_category ON public.jobs (user_id, category, created_at DESC);

-- 5. Data Normalization & Backfill
UPDATE public.explore_prompts SET category = 'Photorealism' 
WHERE LOWER(category) IN ('photoreal', 'photorealism', 'photo', 'cinematic art', 'hollywood');

UPDATE public.explore_prompts SET category = 'Anime' 
WHERE LOWER(category) IN ('anime', 'anime cel', 'manga', 'japanese animation');

UPDATE public.explore_prompts SET category = 'Cyberpunk' 
WHERE LOWER(category) IN ('cyberpunk', 'cyberpunk neon', 'sci-fi neon', 'neon');

UPDATE public.explore_prompts SET category = '3D Render' 
WHERE LOWER(category) IN ('3d render', '3d', 'pixar 3d', '3d cartoon', 'render');

UPDATE public.explore_prompts SET category = 'Character' 
WHERE LOWER(category) IN ('character', 'portrait', 'person', 'avatar');

UPDATE public.explore_prompts SET category = 'General' 
WHERE category IS NULL OR category = '' OR LOWER(category) = 'portrait';

-- Connect category_id foreign keys automatically
UPDATE public.explore_prompts ep
SET category_id = c.id
FROM public.categories c
WHERE LOWER(ep.category) = LOWER(c.name) OR LOWER(ep.category) = LOWER(c.slug);

-- 6. Performance & Case-Insensitive Functional Indexes
CREATE INDEX IF NOT EXISTS idx_explore_prompts_cat_lower ON public.explore_prompts (LOWER(category), created_at DESC);
CREATE INDEX IF NOT EXISTS idx_explore_prompts_category_id ON public.explore_prompts (category_id);

-- Also index and backfill artworks table if used by Web team
DO $$
BEGIN
    IF EXISTS (SELECT FROM pg_tables WHERE schemaname = 'public' AND tablename = 'artworks') THEN
        CREATE INDEX IF NOT EXISTS idx_artworks_cat_lower ON public.artworks (LOWER(category), created_at DESC);
        UPDATE public.artworks SET category = 'Photorealism' WHERE LOWER(category) IN ('photoreal', 'photorealism', 'photo', 'cinematic art', 'hollywood');
        UPDATE public.artworks SET category = 'Anime' WHERE LOWER(category) IN ('anime', 'anime cel', 'manga', 'japanese animation');
        UPDATE public.artworks SET category = 'Cyberpunk' WHERE LOWER(category) IN ('cyberpunk', 'cyberpunk neon', 'sci-fi neon', 'neon');
        UPDATE public.artworks SET category = '3D Render' WHERE LOWER(category) IN ('3d render', '3d', 'pixar 3d', '3d cartoon', 'render');
        UPDATE public.artworks SET category = 'Character' WHERE LOWER(category) IN ('character', 'portrait', 'person', 'avatar');
        UPDATE public.artworks SET category = 'General' WHERE category IS NULL OR category = '';
    END IF;
END $$;

-- 7. RLS Governance
ALTER TABLE public.categories ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Public can view active categories" ON public.categories;
CREATE POLICY "Public can view active categories" ON public.categories
    FOR SELECT USING (is_active = true);
GRANT SELECT ON public.categories TO anon, authenticated;
GRANT ALL ON public.categories TO service_role;

-- ============================================================================
-- 8. RAZORPAY PAYMENT GATEWAY & CREDIT LEDGER SYSTEM
-- ============================================================================

-- A. DYNAMIC CREDIT PACKAGES TABLE (Admin controlled via Supabase Dashboard)
CREATE TABLE IF NOT EXISTS public.credit_packages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    package_id TEXT UNIQUE NOT NULL,                  -- e.g. 'pack_starter_99', 'pack_creator_249'
    name TEXT NOT NULL,                               -- e.g. 'Creator Pack'
    badge TEXT,                                       -- e.g. 'Most Popular', 'Diwali 50% Extra'
    price_inr NUMERIC(10, 2) NOT NULL,                -- e.g. 249.00
    price_usd NUMERIC(10, 2) NOT NULL,                -- e.g. 2.99
    credits INT NOT NULL,                             -- Base credits: 250
    bonus_credits INT NOT NULL DEFAULT 0,             -- Bonus credits: 50
    features JSONB NOT NULL DEFAULT '[]'::jsonb,      -- Feature bullets
    is_active BOOLEAN NOT NULL DEFAULT TRUE,          -- Toggle visibility
    is_popular BOOLEAN NOT NULL DEFAULT FALSE,        -- Visual highlight
    sort_order INT NOT NULL DEFAULT 1,                -- UI sort order
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Ensure all columns exist even if table was created in an earlier partial run
ALTER TABLE public.credit_packages 
    ADD COLUMN IF NOT EXISTS package_id TEXT,
    ADD COLUMN IF NOT EXISTS name TEXT,
    ADD COLUMN IF NOT EXISTS badge TEXT,
    ADD COLUMN IF NOT EXISTS price_inr NUMERIC(10, 2),
    ADD COLUMN IF NOT EXISTS price_usd NUMERIC(10, 2),
    ADD COLUMN IF NOT EXISTS credits INT,
    ADD COLUMN IF NOT EXISTS bonus_credits INT DEFAULT 0,
    ADD COLUMN IF NOT EXISTS features JSONB DEFAULT '[]'::jsonb,
    ADD COLUMN IF NOT EXISTS is_active BOOLEAN DEFAULT TRUE,
    ADD COLUMN IF NOT EXISTS is_popular BOOLEAN DEFAULT FALSE,
    ADD COLUMN IF NOT EXISTS sort_order INT DEFAULT 1,
    ADD COLUMN IF NOT EXISTS created_at TIMESTAMPTZ DEFAULT NOW(),
    ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ DEFAULT NOW();

CREATE UNIQUE INDEX IF NOT EXISTS uq_credit_packages_package_id ON public.credit_packages (package_id);

ALTER TABLE public.credit_packages ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Public can view active packages" ON public.credit_packages;
CREATE POLICY "Public can view active packages" ON public.credit_packages
    FOR SELECT USING (is_active = TRUE);
GRANT SELECT ON public.credit_packages TO anon, authenticated;
GRANT ALL ON public.credit_packages TO service_role;

-- B. PAYMENT TRANSACTIONS AUDIT TABLE
CREATE TABLE IF NOT EXISTS public.payment_transactions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    package_id TEXT NOT NULL REFERENCES public.credit_packages(package_id),
    razorpay_order_id TEXT NOT NULL,
    razorpay_payment_id TEXT UNIQUE,
    razorpay_signature TEXT,
    amount_inr NUMERIC(10, 2) NOT NULL,
    credits_credited INT NOT NULL,
    currency TEXT NOT NULL DEFAULT 'INR',
    status TEXT NOT NULL DEFAULT 'created',           -- created, processing, success, failed, refunded
    payment_method TEXT,                              -- upi, card, netbanking, wallet
    error_message TEXT,
    metadata JSONB,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE public.payment_transactions 
    ADD COLUMN IF NOT EXISTS user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    ADD COLUMN IF NOT EXISTS package_id TEXT,
    ADD COLUMN IF NOT EXISTS razorpay_order_id TEXT,
    ADD COLUMN IF NOT EXISTS razorpay_payment_id TEXT,
    ADD COLUMN IF NOT EXISTS razorpay_signature TEXT,
    ADD COLUMN IF NOT EXISTS amount_inr NUMERIC(10, 2),
    ADD COLUMN IF NOT EXISTS credits_credited INT,
    ADD COLUMN IF NOT EXISTS currency TEXT DEFAULT 'INR',
    ADD COLUMN IF NOT EXISTS status TEXT DEFAULT 'created',
    ADD COLUMN IF NOT EXISTS payment_method TEXT,
    ADD COLUMN IF NOT EXISTS error_message TEXT,
    ADD COLUMN IF NOT EXISTS metadata JSONB,
    ADD COLUMN IF NOT EXISTS created_at TIMESTAMPTZ DEFAULT NOW(),
    ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ DEFAULT NOW();

CREATE UNIQUE INDEX IF NOT EXISTS uq_payment_transactions_payment_id ON public.payment_transactions (razorpay_payment_id);

ALTER TABLE public.payment_transactions ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Users view own transactions" ON public.payment_transactions;
CREATE POLICY "Users view own transactions" ON public.payment_transactions
    FOR SELECT USING (auth.uid() = user_id);
GRANT ALL ON public.payment_transactions TO authenticated, service_role;

-- C. WALLET LEDGER (Itemized Credit Passbook)
CREATE TABLE IF NOT EXISTS public.wallet_ledger (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    amount NUMERIC(10, 2) NOT NULL,                   -- Positive for credit, negative for debit
    balance_after NUMERIC(10, 2) NOT NULL,
    event_type TEXT NOT NULL,                         -- purchase, generation, download_4k, tool_usage, refund, royalty
    description TEXT NOT NULL,                        -- e.g. "Top-up: Creator Pack", "Generated Cyber Ronin"
    reference_id TEXT,                                -- task_id or razorpay_payment_id
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE public.wallet_ledger 
    ADD COLUMN IF NOT EXISTS user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    ADD COLUMN IF NOT EXISTS amount NUMERIC(10, 2),
    ADD COLUMN IF NOT EXISTS balance_after NUMERIC(10, 2),
    ADD COLUMN IF NOT EXISTS event_type TEXT,
    ADD COLUMN IF NOT EXISTS description TEXT,
    ADD COLUMN IF NOT EXISTS reference_id TEXT,
    ADD COLUMN IF NOT EXISTS created_at TIMESTAMPTZ DEFAULT NOW();

CREATE INDEX IF NOT EXISTS idx_wallet_ledger_user ON public.wallet_ledger(user_id, created_at DESC);
ALTER TABLE public.wallet_ledger ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Users view own ledger" ON public.wallet_ledger;
CREATE POLICY "Users view own ledger" ON public.wallet_ledger
    FOR SELECT USING (auth.uid() = user_id);
GRANT ALL ON public.wallet_ledger TO authenticated, service_role;

-- D. ATOMIC RPC: fulfill_credit_purchase (Strictly Idempotent, Concurrency Safe, & Dual Web/Mobile Compatible)
CREATE OR REPLACE FUNCTION public.fulfill_credit_purchase(
    p_user_id UUID,
    p_package_id TEXT,
    p_order_id TEXT DEFAULT NULL,
    p_payment_id TEXT DEFAULT NULL,
    p_signature TEXT DEFAULT NULL,
    p_payment_method TEXT DEFAULT 'razorpay',
    -- Web compatibility parameter aliases
    p_razorpay_payment_id TEXT DEFAULT NULL,
    p_razorpay_order_id TEXT DEFAULT NULL,
    p_razorpay_signature TEXT DEFAULT NULL,
    p_amount_paid_inr NUMERIC DEFAULT NULL,
    p_credits_to_add INT DEFAULT NULL
)
RETURNS JSONB AS $$
DECLARE
    v_pkg public.credit_packages;
    v_total_credits INT;
    v_wallet public.wallets;
    v_new_total NUMERIC(10, 2);
    v_tx_id UUID;
    v_eff_payment_id TEXT;
    v_eff_order_id TEXT;
    v_eff_signature TEXT;
BEGIN
    v_eff_payment_id := COALESCE(p_payment_id, p_razorpay_payment_id);
    v_eff_order_id := COALESCE(p_order_id, p_razorpay_order_id, 'ord_direct_' || floor(extract(epoch from now())*1000)::text);
    v_eff_signature := COALESCE(p_signature, p_razorpay_signature, 'sig_client_verified');

    IF v_eff_payment_id IS NULL OR v_eff_payment_id = '' THEN
        RETURN jsonb_build_object('success', FALSE, 'error', 'Payment ID is required');
    END IF;

    -- 1. Fetch server-verified package details (matching package_id or UUID string)
    SELECT * INTO v_pkg FROM public.credit_packages 
    WHERE package_id = p_package_id OR id::text = p_package_id;

    IF NOT FOUND THEN
        IF p_credits_to_add IS NOT NULL AND p_credits_to_add > 0 THEN
            v_total_credits := p_credits_to_add;
        ELSE
            RETURN jsonb_build_object('success', FALSE, 'error', 'Package not found');
        END IF;
    ELSE
        v_total_credits := v_pkg.credits + v_pkg.bonus_credits;
    END IF;

    -- 2. Concurrency-Safe Atomic Insertion (Winner takes all)
    -- If concurrent client RPC & webhook arrive simultaneously, exactly ONE succeeds.
    INSERT INTO public.payment_transactions (
        user_id, package_id, razorpay_order_id, razorpay_payment_id,
        razorpay_signature, amount_inr, credits_credited, status, payment_method
    ) VALUES (
        p_user_id, 
        COALESCE(v_pkg.package_id, p_package_id), 
        v_eff_order_id, 
        v_eff_payment_id,
        v_eff_signature, 
        COALESCE(v_pkg.price_inr, p_amount_paid_inr, 0.00), 
        v_total_credits, 
        'success', 
        p_payment_method
    )
    ON CONFLICT (razorpay_payment_id) DO NOTHING
    RETURNING id INTO v_tx_id;

    -- If v_tx_id is NULL, this payment was already fulfilled
    IF v_tx_id IS NULL THEN
        SELECT * INTO v_wallet FROM public.wallets WHERE user_id = p_user_id;
        RETURN jsonb_build_object(
            'success', TRUE,
            'message', 'Transaction already fulfilled (Idempotent replay blocked duplicate credit)',
            'current_balance', COALESCE(v_wallet.credits, 0),
            'duplicate', TRUE
        );
    END IF;

    -- 3. Lock wallet row and perform atomic credit addition
    SELECT * INTO v_wallet FROM public.wallets WHERE user_id = p_user_id FOR UPDATE;
    IF NOT FOUND THEN
        INSERT INTO public.wallets (user_id, free_daily_balance, purchased_balance, credits)
        VALUES (p_user_id, 0.00, v_total_credits, v_total_credits)
        RETURNING * INTO v_wallet;
    ELSE
        UPDATE public.wallets 
        SET 
            purchased_balance = purchased_balance + v_total_credits,
            credits = credits + v_total_credits,
            updated_at = NOW()
        WHERE user_id = p_user_id
        RETURNING * INTO v_wallet;
    END IF;

    v_new_total := v_wallet.credits;

    -- 4. Append to ledger audit trail
    INSERT INTO public.wallet_ledger (
        user_id, amount, balance_after, event_type, description, reference_id
    ) VALUES (
        p_user_id, 
        v_total_credits, 
        v_new_total, 
        'purchase',
        'Top-up: ' || COALESCE(v_pkg.name, 'AI Credits') || ' (+' || v_total_credits || ' Credits)',
        v_eff_payment_id
    );

    RETURN jsonb_build_object(
        'success', TRUE,
        'credited', v_total_credits,
        'new_balance', v_new_total,
        'package_name', COALESCE(v_pkg.name, 'Credit Pack'),
        'transaction_id', v_tx_id
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- E. INITIAL SEED CREDIT PACKAGES
INSERT INTO public.credit_packages (package_id, name, badge, price_inr, price_usd, credits, bonus_credits, is_popular, sort_order, features)
VALUES 
('pack_starter_99', 'Starter Pack', 'Quick Trial', 99.00, 1.29, 100, 0, FALSE, 1, '["50 High-Res Generations", "FLUX & SDXL Access", "InstantID Character Lock", "Community Publishing"]'::jsonb),
('pack_creator_249', 'Creator Pack', 'Most Popular', 249.00, 2.99, 250, 50, TRUE, 2, '["150 High-Res Generations", "50 Free Bonus Credits", "4K Lossless Downloads", "Commercial Usage Rights", "Fast Queue Priority"]'::jsonb),
('pack_pro_499', 'Pro Studio Pack', 'Best Value', 499.00, 5.99, 500, 150, FALSE, 3, '["325 High-Res Generations", "150 Free Bonus Credits", "Unlimited 4K Upscaling", "All AI Editing Tools Included", "Instant Support"]'::jsonb),
('pack_master_999', 'Master Agency Pack', 'Max Power', 999.00, 11.99, 1000, 500, FALSE, 4, '["750 High-Res Generations", "500 Mega Bonus Credits", "Full Commercial License", "Zero Watermark", "VIP Generation Server"]'::jsonb)
ON CONFLICT (package_id) DO NOTHING;


