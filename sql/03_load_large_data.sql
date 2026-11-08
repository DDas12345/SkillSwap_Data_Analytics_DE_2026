-- CP4 large-data loader generated from sql/02_load_data.sql.
-- Expected input directory: large_data/ (do not commit the CSV files).
-- Run after sql/01_schema.sql on a fresh database; run sql/05_indexes.sql afterwards.


-- =====================================================
-- OLX BUY & SELL DATABASE - LARGE DATASET
-- DE DBMS CP4 - LARGE DATA LOADING
-- Team: T0038
-- =====================================================

SET search_path TO olx;

-- =====================================================
-- 1. CITIES
-- =====================================================

\copy olx.cities (city_id, city_name, state) FROM 'large_data/cities.csv' WITH (FORMAT CSV, HEADER TRUE);

-- =====================================================
-- 2. CATEGORIES
-- =====================================================

\copy olx.categories (category_id, category_name, parent_id) FROM 'large_data/categories.csv' WITH (FORMAT CSV, HEADER TRUE);

-- =====================================================
-- 3. BOOST PACKAGES
-- =====================================================

\copy olx.boost_packages (package_id, package_name, price, duration_days) FROM 'large_data/boost_packages.csv' WITH (FORMAT CSV, HEADER TRUE);

-- =====================================================
-- 4. USERS
-- =====================================================

\copy olx.users (user_id, full_name, phone, email, city_id, phone_verified, is_banned, joined_at) FROM 'large_data/users.csv' WITH (FORMAT CSV, HEADER TRUE);

-- =====================================================
-- 5. LISTINGS
-- =====================================================

\copy olx.listings (listing_id, seller_id, category_id, title, description, price, is_negotiable, item_condition, attributes, city_id, locality, latitude, longitude, image_count, view_count, boost_package_id, status, posted_at, expires_at, sold_at) FROM 'large_data/listings.csv' WITH (FORMAT CSV, HEADER TRUE);

-- =====================================================
-- 6. CHAT THREADS
-- =====================================================

\copy olx.chat_threads (thread_id, listing_id, buyer_id, created_at) FROM 'large_data/chat_threads.csv' WITH (FORMAT CSV, HEADER TRUE);

-- =====================================================
-- 7. CHAT MESSAGES
-- =====================================================

\copy olx.chat_messages (message_id, thread_id, sender_id, body, sent_at, is_read) FROM 'large_data/chat_messages.csv' WITH (FORMAT CSV, HEADER TRUE);

-- =====================================================
-- 8. OFFERS
-- =====================================================

\copy olx.offers (offer_id, listing_id, buyer_id, offer_price, status, created_at, responded_at) FROM 'large_data/offers.csv' WITH (FORMAT CSV, HEADER TRUE);

-- =====================================================
-- 9. FAVOURITES
-- =====================================================

\copy olx.favourites (user_id, listing_id, saved_at) FROM 'large_data/favourites.csv' WITH (FORMAT CSV, HEADER TRUE);

-- =====================================================
-- 10. REPORTS
-- =====================================================

\copy olx.reports (report_id, listing_id, reporter_id, reason, created_at, status) FROM 'large_data/reports.csv' WITH (FORMAT CSV, HEADER TRUE);

-- =====================================================
-- 11. SELLER RATINGS
-- =====================================================

\copy olx.seller_ratings (rating_id, seller_id, rater_id, listing_id, stars, comment, created_at) FROM 'large_data/seller_ratings.csv' WITH (FORMAT CSV, HEADER TRUE);

-- =====================================================
-- UPDATE TABLE STATISTICS
-- =====================================================

ANALYZE olx.cities;
ANALYZE olx.categories;
ANALYZE olx.boost_packages;
ANALYZE olx.users;
ANALYZE olx.listings;
ANALYZE olx.chat_threads;
ANALYZE olx.chat_messages;
ANALYZE olx.offers;
ANALYZE olx.favourites;
ANALYZE olx.reports;
ANALYZE olx.seller_ratings;
