-- =====================================================
-- PHASE 5: ADDITIONAL LARGE-DATA INDEXES
-- Original Phase 4 indexes remain unchanged.
-- =====================================================

SET search_path TO olx;

-- R04: Find a seller's ratings efficiently
CREATE INDEX idx_seller_ratings_seller_stars
ON seller_ratings (seller_id)
INCLUDE (stars);


-- R05 and W02: Find a seller's listings efficiently
CREATE INDEX idx_listings_seller_listing
ON listings (seller_id, listing_id);


-- W03: Find a buyer's latest conversation
CREATE INDEX idx_chat_threads_buyer_thread
ON chat_threads (buyer_id, thread_id DESC);


-- W05: Find pending offers for a particular listing
CREATE INDEX idx_offers_pending_listing_price
ON offers (listing_id, offer_price DESC, offer_id)
WHERE status = 'PENDING';