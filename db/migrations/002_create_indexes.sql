-- Index to optimize the query:
-- SELECT org_id, status, COUNT(*), SUM(amount)
-- FROM hotel_bookings
-- WHERE city = 'delhi' AND created_at >= NOW() - INTERVAL '30 days'
-- GROUP BY org_id, status;
--
-- This composite index covers the WHERE clause (city, created_at) and
-- includes org_id, status, and amount so PostgreSQL can satisfy the
-- entire query from the index alone without reading the table rows.
-- This is called a "covering index" and avoids heap lookups entirely.

CREATE INDEX IF NOT EXISTS idx_hotel_bookings_city_created_at
    ON hotel_bookings (city, created_at)
    INCLUDE (org_id, status, amount);

CREATE INDEX IF NOT EXISTS idx_booking_events_booking_id
    ON booking_events (booking_id);
