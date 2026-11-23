SET search_path TO olx;

CREATE INDEX idx_listings_active_category_lat_lon
ON listings (category_id, latitude, longitude)
WHERE status = 'ACTIVE';

ANALYZE listings;
