-- =====================================================================
-- ParcelPark | Portfolio 2: bulk data generator
-- Adds a realistic large dataset on top of the Portfolio 1 sample data:
--   20 parks, 20 companies, ~200 vehicles/drivers, 100 staff,
--   50,000 customers, 200,000 parcels, 20,000 trips,
--   ~1 million tracking events, ~200,000 payments.
-- Run AFTER portfolio-1 schema.sql and seed.sql.
-- Takes roughly 1-3 minutes depending on the machine.
-- =====================================================================

SELECT setseed(0.8103);   -- makes the "random" data repeatable

-- ---------- 15 more parks (total 20) --------------------------------
INSERT INTO park (name, city, state) VALUES
  ('Ojota New Garage',      'Lagos',         'Lagos'),
  ('Iyana Ipaja Park',      'Lagos',         'Lagos'),
  ('Waterlines Park',       'Port Harcourt', 'Rivers'),
  ('Jabi Motor Park',       'Abuja',         'FCT'),
  ('Iwo Road Park',         'Ibadan',        'Oyo'),
  ('Holy Ghost Park',       'Enugu',         'Enugu'),
  ('Owerri Main Park',      'Owerri',        'Imo'),
  ('Ariaria Park',          'Aba',           'Abia'),
  ('Kano Line',             'Kano',          'Kano'),
  ('Kawo Motor Park',       'Kaduna',        'Kaduna'),
  ('Uyo Main Park',         'Uyo',           'Akwa Ibom'),
  ('Calabar Highway Park',  'Calabar',       'Cross River'),
  ('Warri Main Park',       'Warri',         'Delta'),
  ('Asaba Park',            'Asaba',         'Delta'),
  ('Ilorin Post Office Park','Ilorin',       'Kwara');

-- ---------- 17 more companies (total 20) ----------------------------
INSERT INTO transport_company (name, phone)
SELECT 'Carrier ' || lpad(g::text, 2, '0') || ' Transport Ltd',
       '0809' || lpad(g::text, 7, '0')
FROM generate_series(4, 20) g;

-- each company operates at 6 random parks
INSERT INTO company_park (company_id, park_id)
SELECT DISTINCT c.company_id, 1 + floor(random() * 20)::int
FROM transport_company c, generate_series(1, 6)
ON CONFLICT DO NOTHING;

-- ---------- vehicles & drivers: 10 per company ----------------------
INSERT INTO vehicle (company_id, plate_no, vehicle_type, capacity_kg)
SELECT c, 'GEN-' || lpad(c::text, 2, '0') || '-' || lpad(k::text, 3, '0'),
       (ARRAY['bus','van','truck'])[1 + floor(random()*3)::int],
       (ARRAY[600, 800, 1500, 3000])[1 + floor(random()*4)::int]
FROM generate_series(1, 20) c, generate_series(1, 10) k;

INSERT INTO driver (company_id, full_name, phone, licence_no)
SELECT c, 'Driver ' || c || '-' || k,
       '0812' || lpad((c * 100 + k)::text, 7, '0'),
       'GEN-DL-' || lpad((c * 100 + k)::text, 6, '0')
FROM generate_series(1, 20) c, generate_series(1, 10) k;

-- ---------- staff: 5 per park ---------------------------------------
INSERT INTO staff (park_id, full_name, phone, role)
SELECT p, 'Agent ' || p || '-' || k,
       '0813' || lpad((p * 10 + k)::text, 7, '0'),
       CASE WHEN k = 1 THEN 'supervisor' ELSE 'agent' END
FROM generate_series(1, 20) p, generate_series(1, 5) k;

-- ---------- 50,000 customers ----------------------------------------
INSERT INTO customer (full_name, phone, email, created_at)
SELECT 'Customer ' || g,
       '070' || lpad(g::text, 8, '0'),
       CASE WHEN random() < 0.6 THEN 'customer' || g || '@mail.com' END,
       timestamptz '2025-06-01' + random() * interval '520 days'
FROM generate_series(1, 50000) g;

-- ---------- 200,000 parcels -----------------------------------------
INSERT INTO parcel (tracking_code, sender_id, company_id, receiver_name,
                    receiver_phone, origin_park_id, dest_park_id,
                    description, weight_kg, declared_value, fee,
                    current_status, created_at)
SELECT 'PP' || lpad((g + 1000)::text, 8, '0'),
       1 + floor(random() * 50003)::int,
       1 + floor(random() * 20)::int,
       'Receiver ' || g,
       '071' || lpad(g::text, 8, '0'),
       o.origin,
       1 + ((o.origin - 1 + 1 + floor(random() * 19)::int) % 20),   -- never = origin
       (ARRAY['Documents','Clothes','Food items','Phone','Laptop',
              'Spare parts','Cosmetics','Drugs'])[1 + floor(random()*8)::int],
       round((0.5 + random() * 40)::numeric, 2),
       round((random() * 300000)::numeric, 2),
       (ARRAY[2500, 3500, 5000, 6000, 8000])[1 + floor(random()*5)::int],
       CASE WHEN r < 0.70 THEN 'collected'
            WHEN r < 0.80 THEN 'in_transit'
            WHEN r < 0.88 THEN 'arrived'
            WHEN r < 0.93 THEN 'paid'
            WHEN r < 0.96 THEN 'registered'
            WHEN r < 0.98 THEN 'returned'
            ELSE 'cancelled' END,
       timestamptz '2026-01-01' + random() * interval '315 days'
FROM generate_series(1, 200000) g,
     LATERAL (SELECT 1 + floor(random() * 20)::int AS origin,
                     random() AS r, g AS dummy) o;

-- ---------- 20,000 trips --------------------------------------------
-- pick a random vehicle, then a driver from the SAME company
INSERT INTO trip (company_id, vehicle_id, driver_id, origin_park_id,
                  dest_park_id, scheduled_departure, actual_departure,
                  actual_arrival, status)
SELECT v.company_id, v.vehicle_id, d.driver_id,
       t.origin, 1 + ((t.origin - 1 + 1 + floor(random() * 19)::int) % 20),
       t.dep, t.dep + interval '15 min', t.dep + interval '8 hours',
       'arrived'
FROM (SELECT g,
             1 + floor(random() * 20)::int AS origin,
             timestamptz '2026-01-01' + random() * interval '315 days' AS dep,
             1 + floor(random() * 20)::int AS comp,
             floor(random() * 10)::int AS vpick,
             floor(random() * 10)::int AS dpick
      FROM generate_series(1, 20000) g) t
JOIN LATERAL (SELECT vehicle_id, company_id FROM vehicle
              WHERE company_id = t.comp ORDER BY vehicle_id
              OFFSET t.vpick LIMIT 1) v ON true
JOIN LATERAL (SELECT driver_id FROM driver
              WHERE company_id = t.comp ORDER BY driver_id
              OFFSET t.dpick LIMIT 1) d ON true;

-- ---------- parcel_trip: parcels that have moved get 1 leg ----------
CREATE TEMP TABLE trip_pick AS
SELECT trip_id, company_id,
       row_number() OVER (PARTITION BY company_id ORDER BY trip_id) AS rn,
       count(*)     OVER (PARTITION BY company_id)                  AS cnt
FROM trip;
CREATE INDEX ON trip_pick (company_id, rn);

INSERT INTO parcel_trip (parcel_id, leg_no, trip_id, company_id, loaded_at)
SELECT p.parcel_id, 1, tp.trip_id, p.company_id, p.created_at + interval '1 hour'
FROM (SELECT parcel_id, company_id, created_at, random() AS r
      FROM parcel
      WHERE parcel_id > 3
        AND current_status IN ('in_transit','arrived','collected','returned')) p
JOIN LATERAL (SELECT cnt FROM trip_pick WHERE company_id = p.company_id LIMIT 1) c ON true
JOIN trip_pick tp ON tp.company_id = p.company_id
                 AND tp.rn = 1 + floor(p.r * c.cnt)::int;

-- ---------- ~1 million tracking events ------------------------------
-- each parcel gets the chain of events that leads to its current status
CREATE TEMP TABLE park_agent AS
SELECT park_id, min(staff_id) AS staff_id FROM staff GROUP BY park_id;

INSERT INTO tracking_event (parcel_id, park_id, staff_id, status, event_time)
SELECT p.parcel_id,
       CASE WHEN s.step <= 3 THEN p.origin_park_id
            WHEN s.status = 'in_transit' THEN NULL
            ELSE p.dest_park_id END,
       CASE WHEN s.status = 'in_transit' THEN NULL
            WHEN s.step <= 3 THEN oa.staff_id ELSE da.staff_id END,
       s.status,
       p.created_at + (s.step - 1) * interval '4 hours'
FROM parcel p
JOIN park_agent oa ON oa.park_id = p.origin_park_id
JOIN park_agent da ON da.park_id = p.dest_park_id
CROSS JOIN LATERAL (
    SELECT step, status
    FROM unnest(
        CASE p.current_status
          WHEN 'registered' THEN ARRAY['registered']
          WHEN 'paid'       THEN ARRAY['registered','paid']
          WHEN 'in_transit' THEN ARRAY['registered','paid','loaded','in_transit']
          WHEN 'arrived'    THEN ARRAY['registered','paid','loaded','in_transit','arrived']
          WHEN 'collected'  THEN ARRAY['registered','paid','loaded','in_transit','arrived','collected']
          WHEN 'returned'   THEN ARRAY['registered','paid','loaded','in_transit','arrived','returned']
          WHEN 'cancelled'  THEN ARRAY['registered','cancelled']
        END) WITH ORDINALITY AS u(status, step)
) s
WHERE p.parcel_id > 3;

-- ---------- payments ------------------------------------------------
-- ~5% of paid parcels had a failed attempt first
INSERT INTO payment (parcel_id, amount, method, status, reference, paid_at)
SELECT parcel_id, fee, 'card', 'failed',
       'GEN-' || parcel_id || '-F', created_at + interval '2 min'
FROM parcel
WHERE parcel_id > 3
  AND current_status NOT IN ('registered','cancelled')
  AND random() < 0.05;

INSERT INTO payment (parcel_id, amount, method, status, reference, paid_at)
SELECT parcel_id, fee,
       (ARRAY['cash','transfer','card','ussd'])[1 + floor(random()*4)::int],
       'successful', 'GEN-' || parcel_id || '-S', created_at + interval '5 min'
FROM parcel
WHERE parcel_id > 3
  AND current_status NOT IN ('registered','cancelled');

-- ---------- refresh planner statistics ------------------------------
ANALYZE;

-- ---------- summary -------------------------------------------------
SELECT 'park' AS table_name, count(*) AS row_count FROM park
UNION ALL SELECT 'transport_company', count(*) FROM transport_company
UNION ALL SELECT 'customer',       count(*) FROM customer
UNION ALL SELECT 'parcel',         count(*) FROM parcel
UNION ALL SELECT 'trip',           count(*) FROM trip
UNION ALL SELECT 'parcel_trip',    count(*) FROM parcel_trip
UNION ALL SELECT 'tracking_event', count(*) FROM tracking_event
UNION ALL SELECT 'payment',        count(*) FROM payment;
