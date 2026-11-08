-- ============================================================
-- CP4: HASH PARTITIONING EXPERIMENT
-- Project: OLX Buy & Sell
-- Partition key: listing_id
-- Strategy: HASH partitioning
-- Number of partitions: 8
--
-- IMPORTANT:
-- This experiment creates an isolated schema named olx_cp4.
-- The original olx schema and its tables remain untouched.
-- ============================================================

-- Step 1: Reset only the isolated CP4 experiment schema
DROP SCHEMA IF EXISTS olx_cp4 CASCADE;

CREATE SCHEMA olx_cp4;

-- Step 2: Create a partitioned copy of the original listings table
CREATE TABLE olx_cp4.listings
(
    LIKE olx.listings INCLUDING ALL
)
PARTITION BY HASH (listing_id);

-- Step 3: Create eight hash partitions

CREATE TABLE olx_cp4.listings_h0
PARTITION OF olx_cp4.listings
FOR VALUES WITH (MODULUS 8, REMAINDER 0);

CREATE TABLE olx_cp4.listings_h1
PARTITION OF olx_cp4.listings
FOR VALUES WITH (MODULUS 8, REMAINDER 1);

CREATE TABLE olx_cp4.listings_h2
PARTITION OF olx_cp4.listings
FOR VALUES WITH (MODULUS 8, REMAINDER 2);

CREATE TABLE olx_cp4.listings_h3
PARTITION OF olx_cp4.listings
FOR VALUES WITH (MODULUS 8, REMAINDER 3);

CREATE TABLE olx_cp4.listings_h4
PARTITION OF olx_cp4.listings
FOR VALUES WITH (MODULUS 8, REMAINDER 4);

CREATE TABLE olx_cp4.listings_h5
PARTITION OF olx_cp4.listings
FOR VALUES WITH (MODULUS 8, REMAINDER 5);

CREATE TABLE olx_cp4.listings_h6
PARTITION OF olx_cp4.listings
FOR VALUES WITH (MODULUS 8, REMAINDER 6);

CREATE TABLE olx_cp4.listings_h7
PARTITION OF olx_cp4.listings
FOR VALUES WITH (MODULUS 8, REMAINDER 7);

-- Step 4: Restore outgoing foreign-key relationships

ALTER TABLE olx_cp4.listings
ADD CONSTRAINT fk_cp4_listing_seller
FOREIGN KEY (seller_id)
REFERENCES olx.users(user_id);

ALTER TABLE olx_cp4.listings
ADD CONSTRAINT fk_cp4_listing_category
FOREIGN KEY (category_id)
REFERENCES olx.categories(category_id);

ALTER TABLE olx_cp4.listings
ADD CONSTRAINT fk_cp4_listing_city
FOREIGN KEY (city_id)
REFERENCES olx.cities(city_id);

ALTER TABLE olx_cp4.listings
ADD CONSTRAINT fk_cp4_listing_boost
FOREIGN KEY (boost_package_id)
REFERENCES olx.boost_packages(package_id);

-- Step 5: Copy the original seed data

INSERT INTO olx_cp4.listings
SELECT *
FROM olx.listings;

-- Step 6: Verify row counts

SELECT
    'Original listings' AS table_name,
    COUNT(*) AS total
FROM olx.listings

UNION ALL

SELECT
    'Partitioned listings',
    COUNT(*)
FROM olx_cp4.listings;

-- Step 7: Verify distribution across partitions

SELECT
    tableoid::regclass AS partition_name,
    COUNT(*) AS total_listings
FROM olx_cp4.listings
GROUP BY tableoid
ORDER BY partition_name;

-- ============================================================
-- END OF PARTITIONING SETUP
-- ============================================================
