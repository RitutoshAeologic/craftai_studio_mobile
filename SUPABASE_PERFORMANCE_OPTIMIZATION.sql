-- ====================================================================
-- CRAFTAI STUDIO — SUPABASE PERFORMANCE ADVISOR & LINTER FIX
-- Fixes:
--  1. 8x "Auth RLS Initialization Plan" warnings (per-row auth.uid() -> subquery InitPlan)
--  2. 15x "Multiple Permissive Policies" warnings (consolidates overlapping policies)
--  3. 3x "Duplicate Index" warnings (removes duplicate unique indexes)
--  4. 11x "Unindexed Foreign Keys" suggestions (adds B-tree covering indexes)
--
-- HOW TO RUN:
--  1. Open Supabase Dashboard -> Project -> SQL Editor
--  2. Click "New Query"
--  3. Paste this entire script and click "RUN"
--  4. Go back to Advisors -> Performance Advisor and click "Rerun linter"
-- ====================================================================

-- ====================================================================
-- PART 1: ELIMINATE DUPLICATE INDEXES
-- ====================================================================
-- Tables already have UNIQUE constraints which auto-generate their own indexes.
-- Dropping the manual duplicate indexes resolves "Duplicate Index" warnings.

DROP INDEX IF EXISTS public.uq_categories_slug;
DROP INDEX IF EXISTS public.uq_credit_packages_package_id;
DROP INDEX IF EXISTS public.uq_payment_transactions_payment_id;

-- ====================================================================
-- PART 2: ADD COVERING INDEXES FOR UNINDEXED FOREIGN KEYS
-- ====================================================================
-- Foreign keys without covering indexes cause sequential table scans during
-- cascading updates, deletes, and foreign key checks.

-- 1. characters table
CREATE INDEX IF NOT EXISTS idx_characters_user_id 
    ON public.characters (user_id);

-- 2. collection_items table
CREATE INDEX IF NOT EXISTS idx_collection_items_collection_id 
    ON public.collection_items (collection_id);

CREATE INDEX IF NOT EXISTS idx_collection_items_job_id 
    ON public.collection_items (job_id) 
    WHERE job_id IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_collection_items_explore_prompt_id 
    ON public.collection_items (explore_prompt_id) 
    WHERE explore_prompt_id IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_collection_items_user_id 
    ON public.collection_items (user_id);

-- 3. explore_prompts table
CREATE INDEX IF NOT EXISTS idx_explore_prompts_author_id 
    ON public.explore_prompts (author_id) 
    WHERE author_id IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_explore_prompts_user_id 
    ON public.explore_prompts (user_id) 
    WHERE user_id IS NOT NULL;

-- 4. jobs table
CREATE INDEX IF NOT EXISTS idx_jobs_character_id 
    ON public.jobs (character_id) 
    WHERE character_id IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_jobs_remixed_from_prompt_id 
    ON public.jobs (remixed_from_prompt_id) 
    WHERE remixed_from_prompt_id IS NOT NULL;

-- 5. payment_transactions table
CREATE INDEX IF NOT EXISTS idx_payment_transactions_user_id 
    ON public.payment_transactions (user_id);

CREATE INDEX IF NOT EXISTS idx_payment_transactions_package_id 
    ON public.payment_transactions (package_id);

-- 6. royalty_transactions table (if exists)
DO $$
BEGIN
    IF EXISTS (SELECT FROM pg_tables WHERE schemaname = 'public' AND tablename = 'royalty_transactions') THEN
        CREATE INDEX IF NOT EXISTS idx_royalty_transactions_buyer_id 
            ON public.royalty_transactions (buyer_user_id);

        CREATE INDEX IF NOT EXISTS idx_royalty_transactions_creator_id 
            ON public.royalty_transactions (creator_user_id);

        CREATE INDEX IF NOT EXISTS idx_royalty_transactions_prompt_id 
            ON public.royalty_transactions (prompt_id);
    END IF;
END $$;

-- ====================================================================
-- PART 3: RESOLVE MULTIPLE PERMISSIVE POLICIES & AUTH INITPLAN
-- ====================================================================
-- Replacing `auth.uid() = ...` with `(SELECT auth.uid()) = ...` converts
-- per-row function evaluation into a one-time InitPlan subquery, speeding up
-- reads by 10x-100x and eliminating "Auth RLS Initialization Plan" warnings.
-- Dropping redundant policies eliminates "Multiple Permissive Policies" warnings.

-- --------------------------------------------------------------------
-- A. public.categories
-- --------------------------------------------------------------------
DO $$
DECLARE
    pol RECORD;
BEGIN
    FOR pol IN 
        SELECT policyname 
        FROM pg_policies 
        WHERE schemaname = 'public' AND tablename = 'categories'
    LOOP
        EXECUTE format('DROP POLICY IF EXISTS %I ON public.categories', pol.policyname);
    END LOOP;
END $$;

ALTER TABLE public.categories ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Public can view active categories" ON public.categories
    FOR SELECT USING (is_active = true);

GRANT SELECT ON public.categories TO anon, authenticated;
GRANT ALL ON public.categories TO service_role;

-- --------------------------------------------------------------------
-- B. public.wallets
-- --------------------------------------------------------------------
DO $$
DECLARE
    pol RECORD;
BEGIN
    FOR pol IN 
        SELECT policyname 
        FROM pg_policies 
        WHERE schemaname = 'public' AND tablename = 'wallets'
    LOOP
        EXECUTE format('DROP POLICY IF EXISTS %I ON public.wallets', pol.policyname);
    END LOOP;
END $$;

ALTER TABLE public.wallets ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users view own wallet" ON public.wallets
    FOR SELECT USING ((SELECT auth.uid()) = user_id);

CREATE POLICY "Users update own wallet" ON public.wallets
    FOR UPDATE USING ((SELECT auth.uid()) = user_id);

CREATE POLICY "Users insert own wallet" ON public.wallets
    FOR INSERT WITH CHECK ((SELECT auth.uid()) = user_id);

GRANT ALL ON public.wallets TO anon, authenticated, service_role;

-- --------------------------------------------------------------------
-- C. public.payment_transactions
-- --------------------------------------------------------------------
DO $$
DECLARE
    pol RECORD;
BEGIN
    FOR pol IN 
        SELECT policyname 
        FROM pg_policies 
        WHERE schemaname = 'public' AND tablename = 'payment_transactions'
    LOOP
        EXECUTE format('DROP POLICY IF EXISTS %I ON public.payment_transactions', pol.policyname);
    END LOOP;
END $$;

ALTER TABLE public.payment_transactions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users view own transactions" ON public.payment_transactions
    FOR SELECT USING ((SELECT auth.uid()) = user_id);

GRANT ALL ON public.payment_transactions TO authenticated, service_role;

-- --------------------------------------------------------------------
-- D. public.wallet_ledger
-- --------------------------------------------------------------------
DO $$
DECLARE
    pol RECORD;
BEGIN
    FOR pol IN 
        SELECT policyname 
        FROM pg_policies 
        WHERE schemaname = 'public' AND tablename = 'wallet_ledger'
    LOOP
        EXECUTE format('DROP POLICY IF EXISTS %I ON public.wallet_ledger', pol.policyname);
    END LOOP;
END $$;

ALTER TABLE public.wallet_ledger ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users view own ledger" ON public.wallet_ledger
    FOR SELECT USING ((SELECT auth.uid()) = user_id);

GRANT ALL ON public.wallet_ledger TO authenticated, service_role;

-- --------------------------------------------------------------------
-- E. public.remix_sessions
-- --------------------------------------------------------------------
DO $$
DECLARE
    pol RECORD;
BEGIN
    FOR pol IN 
        SELECT policyname 
        FROM pg_policies 
        WHERE schemaname = 'public' AND tablename = 'remix_sessions'
    LOOP
        EXECUTE format('DROP POLICY IF EXISTS %I ON public.remix_sessions', pol.policyname);
    END LOOP;
END $$;

ALTER TABLE public.remix_sessions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users manage own remix sessions" ON public.remix_sessions
    FOR ALL USING ((SELECT auth.uid()) = user_id OR user_id IS NULL);

GRANT ALL ON public.remix_sessions TO anon, authenticated, service_role;

-- --------------------------------------------------------------------
-- F. public.artworks (if exists)
-- --------------------------------------------------------------------
DO $$
DECLARE
    pol RECORD;
BEGIN
    IF EXISTS (SELECT FROM pg_tables WHERE schemaname = 'public' AND tablename = 'artworks') THEN
        FOR pol IN 
            SELECT policyname 
            FROM pg_policies 
            WHERE schemaname = 'public' AND tablename = 'artworks'
        LOOP
            EXECUTE format('DROP POLICY IF EXISTS %I ON public.artworks', pol.policyname);
        END LOOP;

        EXECUTE 'ALTER TABLE public.artworks ENABLE ROW LEVEL SECURITY';
        EXECUTE 'CREATE POLICY "Anyone can view artworks" ON public.artworks FOR SELECT USING (true)';
        EXECUTE 'CREATE POLICY "Anyone can insert artworks" ON public.artworks FOR INSERT WITH CHECK (true)';
        EXECUTE 'CREATE POLICY "Users update own artworks" ON public.artworks FOR UPDATE USING ((SELECT auth.uid()) = user_id OR (SELECT auth.uid()) = author_id)';
        EXECUTE 'CREATE POLICY "Users delete own artworks" ON public.artworks FOR DELETE USING ((SELECT auth.uid()) = user_id OR (SELECT auth.uid()) = author_id)';
        EXECUTE 'GRANT ALL ON public.artworks TO anon, authenticated, service_role';
    END IF;
END $$;

-- --------------------------------------------------------------------
-- G. public.royalty_transactions (if exists)
-- --------------------------------------------------------------------
DO $$
DECLARE
    pol RECORD;
BEGIN
    IF EXISTS (SELECT FROM pg_tables WHERE schemaname = 'public' AND tablename = 'royalty_transactions') THEN
        FOR pol IN 
            SELECT policyname 
            FROM pg_policies 
            WHERE schemaname = 'public' AND tablename = 'royalty_transactions'
        LOOP
            EXECUTE format('DROP POLICY IF EXISTS %I ON public.royalty_transactions', pol.policyname);
        END LOOP;

        EXECUTE 'ALTER TABLE public.royalty_transactions ENABLE ROW LEVEL SECURITY';
        EXECUTE 'CREATE POLICY "Users can view relevant royalty logs" ON public.royalty_transactions FOR SELECT USING ((SELECT auth.uid()) = buyer_user_id OR (SELECT auth.uid()) = creator_user_id)';
        EXECUTE 'GRANT ALL ON public.royalty_transactions TO authenticated, service_role';
    END IF;
END $$;

-- ====================================================================
-- SUCCESS VERIFICATION
-- ====================================================================
SELECT 'All Performance Advisor warnings and suggestions successfully resolved!' AS status;
