-- =====================================================================
-- ParcelPark | Portfolio 2: optimising Q4 with a MATERIALIZED VIEW
-- Indexes did not speed up Q4, because the report must read and
-- aggregate ~20,000 parcels and ~200,000 payments every time it runs.
-- A materialized view pre-computes the answer once and stores it.
-- =====================================================================

DROP MATERIALIZED VIEW IF EXISTS mv_monthly_park_revenue;

CREATE MATERIALIZED VIEW mv_monthly_park_revenue AS
SELECT date_trunc('month', p.created_at) AS month,
       pk.park_id,
       pk.name          AS origin_park,
       count(*)         AS parcels,
       sum(pay.amount)  AS revenue
FROM parcel p
JOIN payment pay ON pay.parcel_id = p.parcel_id AND pay.status = 'successful'
JOIN park pk     ON pk.park_id    = p.origin_park_id
GROUP BY 1, 2, 3;

CREATE INDEX idx_mv_month ON mv_monthly_park_revenue (month);

-- Q4 rewritten to read the pre-computed summary (run twice, record 2nd time)
EXPLAIN (ANALYZE, BUFFERS)
SELECT origin_park, parcels, revenue
FROM mv_monthly_park_revenue
WHERE month = '2026-10-01'
ORDER BY revenue DESC;

-- Same result as the original Q4:
SELECT origin_park, parcels, revenue
FROM mv_monthly_park_revenue
WHERE month = '2026-10-01'
ORDER BY revenue DESC;

-- Trade-off: the view is a snapshot. New parcels are not included until
-- it is refreshed, e.g. nightly by a scheduled job:
-- REFRESH MATERIALIZED VIEW mv_monthly_park_revenue;
