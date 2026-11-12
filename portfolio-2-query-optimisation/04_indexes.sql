-- =====================================================================
-- ParcelPark | Portfolio 2: optimisation (indexes)
-- Each index targets a specific slow query from 03_explain_before.sql.
-- =====================================================================

-- Q2: tracking history looks up ONE parcel's events and sorts by time.
-- Composite index: finds the parcel's rows AND returns them already sorted.
CREATE INDEX idx_event_parcel_time ON tracking_event (parcel_id, event_time);

-- Q3: find parcels by sender. Foreign keys are NOT indexed automatically
-- in PostgreSQL, so the join had to scan all 200,000 parcels.
CREATE INDEX idx_parcel_sender ON parcel (sender_id);

-- Q4: monthly report filters parcels by a date range.
CREATE INDEX idx_parcel_created ON parcel (created_at);

-- Q5: PARTIAL index - only covers parcels still in transit (~10% of rows),
-- so it is small, and the delay alert reads only what it needs.
CREATE INDEX idx_parcel_in_transit ON parcel (dest_park_id, created_at)
    WHERE current_status = 'in_transit';

-- (Q1 needs nothing: tracking_code is UNIQUE, and PostgreSQL automatically
--  creates an index for every PRIMARY KEY and UNIQUE constraint.)

ANALYZE parcel;
ANALYZE tracking_event;

-- ---------------------------------------------------------------------
-- The cost of indexes: they take disk space and slow down writes.
-- ---------------------------------------------------------------------
SELECT indexrelname                                  AS index_name,
       relname                                       AS table_name,
       pg_size_pretty(pg_relation_size(indexrelid))  AS index_size
FROM pg_stat_user_indexes
WHERE indexrelname IN ('idx_event_parcel_time', 'idx_parcel_sender',
                       'idx_parcel_created', 'idx_parcel_in_transit')
ORDER BY pg_relation_size(indexrelid) DESC;

SELECT pg_size_pretty(pg_relation_size('tracking_event')) AS tracking_event_table_size,
       pg_size_pretty(pg_relation_size('parcel'))         AS parcel_table_size;

-- ---------------------------------------------------------------------
-- To repeat the "before" experiment, drop the indexes with:
-- DROP INDEX idx_event_parcel_time, idx_parcel_sender,
--            idx_parcel_created, idx_parcel_in_transit;
-- ---------------------------------------------------------------------
