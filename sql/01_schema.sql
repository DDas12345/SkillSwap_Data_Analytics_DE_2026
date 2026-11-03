
-- =====================================================
-- OLX BUY & SELL DATABASE
-- DE DBMS CP1 - Schema Design
-- Team: T0038
-- =====================================================

-- Create the database schema
CREATE SCHEMA IF NOT EXISTS olx;

-- Set the default schema for this session
SET search_path TO olx;

-- =====================================================
-- TABLE 1: CITIES
-- =====================================================

CREATE TABLE cities (
    city_id INTEGER PRIMARY KEY,
    city_name VARCHAR(100) NOT NULL,
    state VARCHAR(100) NOT NULL
);

-- =====================================================
-- TABLE 2: CATEGORIES
-- =====================================================

CREATE TABLE categories (
    category_id INTEGER PRIMARY KEY,
    category_name VARCHAR(100) NOT NULL,
    parent_id INTEGER,
    CONSTRAINT fk_categories_parent
        FOREIGN KEY (parent_id)
        REFERENCES categories(category_id)
        ON DELETE RESTRICT
);

-- =====================================================
-- TABLE 3: BOOST PACKAGES
-- =====================================================

CREATE TABLE boost_packages (
    package_id INTEGER PRIMARY KEY,
    package_name VARCHAR(100) NOT NULL,
    price NUMERIC(10,2) NOT NULL,
    duration_days INTEGER NOT NULL,

    CONSTRAINT chk_boost_price
        CHECK (price >= 0),

    CONSTRAINT chk_boost_duration
        CHECK (duration_days > 0)
);

-- =====================================================
-- TABLE 4: USERS
-- =====================================================

CREATE TABLE users (
    user_id INTEGER PRIMARY KEY,
    full_name VARCHAR(100) NOT NULL,
    phone VARCHAR(20) NOT NULL UNIQUE,
    email VARCHAR(254) UNIQUE,
    city_id INTEGER NOT NULL,
    phone_verified BOOLEAN NOT NULL,
    is_banned BOOLEAN NOT NULL,
    joined_at TIMESTAMPTZ NOT NULL,

    CONSTRAINT fk_users_city
        FOREIGN KEY (city_id)
        REFERENCES cities(city_id)
        ON DELETE RESTRICT
);

-- =====================================================
-- TABLE 5: LISTINGS
-- =====================================================

CREATE TABLE listings (
    listing_id INTEGER PRIMARY KEY,
    seller_id INTEGER NOT NULL,
    category_id INTEGER NOT NULL,
    title VARCHAR(255) NOT NULL,
    description TEXT,
    price NUMERIC(12,2) NOT NULL,
    is_negotiable BOOLEAN NOT NULL,
    item_condition VARCHAR(20) NOT NULL,
    attributes JSONB NOT NULL,
    city_id INTEGER NOT NULL,
    locality VARCHAR(100) NOT NULL,
    latitude NUMERIC(9,6) NOT NULL,
    longitude NUMERIC(9,6) NOT NULL,
    image_count INTEGER NOT NULL,
    view_count INTEGER NOT NULL,
    boost_package_id INTEGER,
    status VARCHAR(20) NOT NULL,
    posted_at TIMESTAMPTZ NOT NULL,
    expires_at TIMESTAMPTZ NOT NULL,
    sold_at TIMESTAMPTZ,

    CONSTRAINT fk_listings_seller
        FOREIGN KEY (seller_id)
        REFERENCES users(user_id)
        ON DELETE RESTRICT,

    CONSTRAINT fk_listings_category
        FOREIGN KEY (category_id)
        REFERENCES categories(category_id)
        ON DELETE RESTRICT,

    CONSTRAINT fk_listings_city
        FOREIGN KEY (city_id)
        REFERENCES cities(city_id)
        ON DELETE RESTRICT,

    CONSTRAINT fk_listings_boost
        FOREIGN KEY (boost_package_id)
        REFERENCES boost_packages(package_id)
        ON DELETE RESTRICT,

    CONSTRAINT uq_listings_listing_seller
        UNIQUE (listing_id, seller_id),

    CONSTRAINT chk_listings_price
        CHECK (price >= 0),

    CONSTRAINT chk_listings_condition
        CHECK (item_condition IN ('FAIR', 'GOOD', 'LIKE_NEW', 'NEW')),

    CONSTRAINT chk_listings_attributes
        CHECK (jsonb_typeof(attributes) = 'object'),

    CONSTRAINT chk_listings_latitude
        CHECK (latitude BETWEEN -90 AND 90),

    CONSTRAINT chk_listings_longitude
        CHECK (longitude BETWEEN -180 AND 180),

    CONSTRAINT chk_listings_image_count
        CHECK (image_count >= 0),

    CONSTRAINT chk_listings_view_count
        CHECK (view_count >= 0),

    CONSTRAINT chk_listings_status
        CHECK (status IN ('ACTIVE', 'EXPIRED', 'REMOVED', 'SOLD')),

    CONSTRAINT chk_listings_expiry
        CHECK (posted_at <= expires_at),

    CONSTRAINT chk_listings_sold_at
        CHECK (sold_at IS NULL OR sold_at >= posted_at)
);

-- =====================================================
-- TABLE 6: CHAT_THREADS
-- =====================================================

CREATE TABLE chat_threads (
    thread_id INTEGER PRIMARY KEY,
    listing_id INTEGER NOT NULL,
    buyer_id INTEGER NOT NULL,
    created_at TIMESTAMPTZ NOT NULL,

    CONSTRAINT fk_chat_threads_listing
        FOREIGN KEY (listing_id)
        REFERENCES listings(listing_id)
        ON DELETE RESTRICT,

    CONSTRAINT fk_chat_threads_buyer
        FOREIGN KEY (buyer_id)
        REFERENCES users(user_id)
        ON DELETE RESTRICT
);

-- =====================================================
-- TABLE 7: CHAT_MESSAGES
-- =====================================================

CREATE TABLE chat_messages (
    message_id INTEGER PRIMARY KEY,
    thread_id INTEGER NOT NULL,
    sender_id INTEGER NOT NULL,
    body TEXT NOT NULL,
    sent_at TIMESTAMPTZ NOT NULL,
    is_read BOOLEAN NOT NULL,

    CONSTRAINT fk_chat_messages_thread
        FOREIGN KEY (thread_id)
        REFERENCES chat_threads(thread_id)
        ON DELETE RESTRICT,

    CONSTRAINT fk_chat_messages_sender
        FOREIGN KEY (sender_id)
        REFERENCES users(user_id)
        ON DELETE RESTRICT
);

-- =====================================================
-- TABLE 8: OFFERS
-- =====================================================

CREATE TABLE offers (
    offer_id INTEGER PRIMARY KEY,
    listing_id INTEGER NOT NULL,
    buyer_id INTEGER NOT NULL,
    offer_price NUMERIC(12,2) NOT NULL,
    status VARCHAR(20) NOT NULL,
    created_at TIMESTAMPTZ NOT NULL,
    responded_at TIMESTAMPTZ,

    CONSTRAINT fk_offers_listing
        FOREIGN KEY (listing_id)
        REFERENCES listings(listing_id)
        ON DELETE RESTRICT,

    CONSTRAINT fk_offers_buyer
        FOREIGN KEY (buyer_id)
        REFERENCES users(user_id)
        ON DELETE RESTRICT,

    CONSTRAINT chk_offers_price
        CHECK (offer_price >= 0),

    CONSTRAINT chk_offers_status
        CHECK (status IN ('ACCEPTED', 'COUNTERED', 'PENDING', 'REJECTED')),

    CONSTRAINT chk_offers_response_time
        CHECK (responded_at IS NULL OR responded_at >= created_at)
);

-- =====================================================
-- TABLE 9: FAVOURITES
-- =====================================================

CREATE TABLE favourites (
    user_id INTEGER NOT NULL,
    listing_id INTEGER NOT NULL,
    saved_at TIMESTAMPTZ NOT NULL,

    CONSTRAINT pk_favourites
        PRIMARY KEY (user_id, listing_id),

    CONSTRAINT fk_favourites_user
        FOREIGN KEY (user_id)
        REFERENCES users(user_id)
        ON DELETE RESTRICT,

    CONSTRAINT fk_favourites_listing
        FOREIGN KEY (listing_id)
        REFERENCES listings(listing_id)
        ON DELETE RESTRICT
);

-- =====================================================
-- TABLE 10: REPORTS
-- =====================================================

CREATE TABLE reports (
    report_id INTEGER PRIMARY KEY,
    listing_id INTEGER NOT NULL,
    reporter_id INTEGER NOT NULL,
    reason VARCHAR(30) NOT NULL,
    created_at TIMESTAMPTZ NOT NULL,
    status VARCHAR(20) NOT NULL,

    CONSTRAINT fk_reports_listing
        FOREIGN KEY (listing_id)
        REFERENCES listings(listing_id)
        ON DELETE RESTRICT,

    CONSTRAINT fk_reports_reporter
        FOREIGN KEY (reporter_id)
        REFERENCES users(user_id)
        ON DELETE RESTRICT,

    CONSTRAINT chk_reports_reason
        CHECK (reason IN ('ALREADY_SOLD', 'FRAUD', 'OFFENSIVE', 'SPAM', 'WRONG_CATEGORY')),

    CONSTRAINT chk_reports_status
        CHECK (status IN ('ACTIONED', 'DISMISSED', 'OPEN'))
);

-- =====================================================
-- TABLE 11: SELLER_RATINGS
-- =====================================================

CREATE TABLE seller_ratings (
    rating_id INTEGER PRIMARY KEY,
    seller_id INTEGER NOT NULL,
    rater_id INTEGER NOT NULL,
    listing_id INTEGER NOT NULL,
    stars INTEGER NOT NULL,
    comment TEXT,
    created_at TIMESTAMPTZ NOT NULL,

    CONSTRAINT fk_ratings_seller_listing
        FOREIGN KEY (listing_id, seller_id)
        REFERENCES listings(listing_id, seller_id)
        ON DELETE RESTRICT,

    CONSTRAINT fk_ratings_rater
        FOREIGN KEY (rater_id)
        REFERENCES users(user_id)
        ON DELETE RESTRICT,

    CONSTRAINT chk_ratings_stars
        CHECK (stars BETWEEN 1 AND 5)
);
