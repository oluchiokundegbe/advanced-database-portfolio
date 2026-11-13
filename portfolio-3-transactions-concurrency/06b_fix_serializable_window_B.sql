-- =====================================================================
-- ParcelPark | Portfolio 3 | Demo 6: FIX 2 - optimistic control with SERIALIZABLE isolation
-- WINDOW B of 2.  Open a SECOND Query Tool on parcelpark for the other
-- window. Run the steps in NUMBER ORDER, switching windows as told.
-- Highlight ONE step at a time and run it.
-- =====================================================================

-- STEP 2
BEGIN ISOLATION LEVEL SERIALIZABLE;
SELECT * FROM demo_trip_load;   -- free_kg = 50

-- (now go to WINDOW A, step 3)

-- STEP 4  Agent B loads (no waiting, no locks)
INSERT INTO parcel_trip (parcel_id, leg_no, trip_id, company_id)
SELECT p.parcel_id, 1, d.trip_id, p.company_id
FROM parcel p, demo_trip_load d WHERE p.tracking_code = 'PPDEMO0002';

-- (now go to WINDOW A, step 5)

-- STEP 6  Agent B tries to commit...
COMMIT;
-- -> ERROR: could not serialize access due to read/write dependencies
--    among transactions.  PostgreSQL refused the overload!
-- (If the error appears at step 4 instead, that is also correct.)

-- STEP 6b  the application would now RETRY: check again
ROLLBACK;
SELECT * FROM demo_trip_load;   -- free_kg = 20 -> 30 kg does not fit

-- (now go to WINDOW A, step 7)
