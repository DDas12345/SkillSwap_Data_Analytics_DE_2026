SET search_path TO olx;

-- R03: Search titles only among active listings
CREATE INDEX idx_listings_active_title_trgm
ON listings USING GIN (title gin_trgm_ops)
WHERE status = 'ACTIVE';