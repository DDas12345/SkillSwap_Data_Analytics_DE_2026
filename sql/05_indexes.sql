-- CP3: Query Optimization Indexes
-- Database: olx_de_dbms
-- Schema: olx

SET search_path TO olx;
--
-- Each index is linked to the workload queries it is intended to improve.
-- We will validate every index using EXPLAIN ANALYZE and benchmark results.

-- R01, R19: Active listings in a particular city and category.
-- Equality filters first; posting date supports newest-first ordering.
CREATE INDEX idx_listings_active_city_category_posted
ON listings (city_id, category_id, posted_at DESC)
WHERE status = 'ACTIVE';

-- R06, R19, R25: Find conversations belonging to a listing.
CREATE INDEX idx_chat_threads_listing
ON chat_threads (listing_id);

-- R06, R19, R25: Find messages in a conversation, newest first.
CREATE INDEX idx_chat_messages_thread_sent
ON chat_messages (thread_id, sent_at DESC);

-- R10, W04: Find active listings by expiry date.
CREATE INDEX idx_listings_active_expires
ON listings (expires_at)
WHERE status = 'ACTIVE';

-- R22: Support newest-first listing pagination.
CREATE INDEX idx_listings_posted_desc
ON listings (posted_at DESC);

-- R03: Support substring searches such as ILIKE '%iphone 13%'.
-- Requires pg_trgm, which is available in this PostgreSQL installation.
CREATE EXTENSION IF NOT EXISTS pg_trgm;

CREATE INDEX idx_listings_title_trgm
ON listings USING GIN (title gin_trgm_ops);