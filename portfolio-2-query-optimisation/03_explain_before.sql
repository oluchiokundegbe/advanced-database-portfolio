-- =====================================================================
-- ParcelPark | Portfolio 2: execution plans BEFORE indexing (run after 01_generate_data.sql)
-- Highlight ONE query at a time and run it. Run each query TWICE and
-- record the second "Execution Time" (the first run warms the cache).
-- =====================================================================

-- Q1  "Where is my parcel?"  (customer types a tracking code)
EXPLAIN (ANALYZE, BUFFERS)
SELECT p.tracking_code, p.current_status, o.name AS origin, d.name AS destination,
       p.receiver_name, p.created_at
FROM parcel p
JOIN park o ON o.park_id = p.origin_park_id
JOIN park d ON d.park_id = p.dest_park_id
WHERE p.tracking_code = 'PP00054321';

-- Q2  Full tracking history of that parcel, in time order
EXPLAIN (ANALYZE, BUFFERS)
SELECT te.status, te.event_time, pk.name AS park, s.full_name AS recorded_by
FROM tracking_event te
LEFT JOIN park  pk ON pk.park_id  = te.park_id
LEFT JOIN staff s  ON s.staff_id  = te.staff_id
WHERE te.parcel_id = (SELECT parcel_id FROM parcel WHERE tracking_code = 'PP00054321')
ORDER BY te.event_time;

-- Q3  All parcels sent by a customer (agent searches by phone number)
EXPLAIN (ANALYZE, BUFFERS)
SELECT p.tracking_code, p.current_status, p.fee, p.created_at
FROM customer c
JOIN parcel p ON p.sender_id = c.customer_id
WHERE c.phone = '07000012345'
ORDER BY p.created_at DESC;

-- Q4  Management report: October 2026 revenue per origin park
EXPLAIN (ANALYZE, BUFFERS)
SELECT pk.name AS origin_park, count(*) AS parcels, sum(pay.amount) AS revenue
FROM parcel p
JOIN payment pay ON pay.parcel_id = p.parcel_id AND pay.status = 'successful'
JOIN park pk     ON pk.park_id    = p.origin_park_id
WHERE p.created_at >= '2026-10-01' AND p.created_at < '2026-11-01'
GROUP BY pk.name
ORDER BY revenue DESC;

-- Q5  Delay alert: parcels heading to Mile 1 (park 2) still in transit after 3 days
EXPLAIN (ANALYZE, BUFFERS)
SELECT p.tracking_code, p.created_at, now() - p.created_at AS waiting_for
FROM parcel p
WHERE p.dest_park_id = 2
  AND p.current_status = 'in_transit'
  AND p.created_at < now() - interval '3 days'
ORDER BY p.created_at
LIMIT 50;
