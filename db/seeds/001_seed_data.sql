-- Seed data: 100 hotel bookings across multiple cities, orgs, and statuses
-- plus booking events for some of them

-- Organization UUIDs
DO $$
DECLARE
    org_ids UUID[] := ARRAY[
        'a1b2c3d4-e5f6-4a7b-8c9d-0e1f2a3b4c5d',
        'b2c3d4e5-f6a7-4b8c-9d0e-1f2a3b4c5d6e',
        'c3d4e5f6-a7b8-4c9d-0e1f-2a3b4c5d6e7f',
        'd4e5f6a7-b8c9-4d0e-1f2a-3b4c5d6e7f8a',
        'e5f6a7b8-c9d0-4e1f-2a3b-4c5d6e7f8a9b'
    ];
    cities TEXT[] := ARRAY['delhi', 'mumbai', 'bangalore', 'chennai', 'kolkata', 'hyderabad', 'pune', 'jaipur'];
    statuses TEXT[] := ARRAY['confirmed', 'cancelled', 'pending', 'checked_in', 'checked_out'];
    hotel_ids TEXT[] := ARRAY['HTL001', 'HTL002', 'HTL003', 'HTL004', 'HTL005', 'HTL006', 'HTL007', 'HTL008', 'HTL009', 'HTL010'];
    booking_id UUID;
    i INT;
    rand_org UUID;
    rand_city TEXT;
    rand_status TEXT;
    rand_hotel TEXT;
    rand_amount NUMERIC;
    rand_checkin DATE;
    rand_checkout DATE;
    rand_created TIMESTAMP;
BEGIN
    FOR i IN 1..120 LOOP
        rand_org := org_ids[1 + floor(random() * array_length(org_ids, 1))::int];
        rand_city := cities[1 + floor(random() * array_length(cities, 1))::int];
        rand_status := statuses[1 + floor(random() * array_length(statuses, 1))::int];
        rand_hotel := hotel_ids[1 + floor(random() * array_length(hotel_ids, 1))::int];
        rand_amount := round((1000 + random() * 9000)::numeric, 2);
        rand_checkin := CURRENT_DATE - (floor(random() * 60)::int);
        rand_checkout := rand_checkin + (1 + floor(random() * 5)::int);
        rand_created := NOW() - (floor(random() * 45)::int || ' days')::interval;

        INSERT INTO hotel_bookings (org_id, hotel_id, city, checkin_date, checkout_date, amount, status, created_at)
        VALUES (rand_org, rand_hotel, rand_city, rand_checkin, rand_checkout, rand_amount, rand_status, rand_created)
        RETURNING id INTO booking_id;

        -- Add booking events for roughly 60% of bookings
        IF random() < 0.6 THEN
            INSERT INTO booking_events (booking_id, event_type, payload, created_at)
            VALUES (
                booking_id,
                'booking_created',
                jsonb_build_object('source', 'web', 'ip', '192.168.1.' || floor(random() * 255)::int),
                rand_created
            );
        END IF;

        IF random() < 0.3 THEN
            INSERT INTO booking_events (booking_id, event_type, payload, created_at)
            VALUES (
                booking_id,
                'payment_received',
                jsonb_build_object('method', 'credit_card', 'amount', rand_amount),
                rand_created + interval '1 hour'
            );
        END IF;

        IF random() < 0.2 THEN
            INSERT INTO booking_events (booking_id, event_type, payload, created_at)
            VALUES (
                booking_id,
                'booking_modified',
                jsonb_build_object('field', 'checkout_date', 'old_value', rand_checkout::text, 'new_value', (rand_checkout + 1)::text),
                rand_created + interval '2 hours'
            );
        END IF;
    END LOOP;
END $$;
