-- =====================================================================
-- ParcelPark | Portfolio 3 | Demo 5: FIX 1 - pessimistic locking with SELECT ... FOR UPDATE
-- WINDOW B of 2.  Open a SECOND Query Tool on parcelpark for the other
-- window. Run the steps in NUMBER ORDER, switching windows as told.
-- Highlight ONE step at a time and run it.
-- =====================================================================

-- STEP 2  Agent B tries to lock the same trip...
BEGIN;
SELECT trip_id FROM trip
WHERE trip_id = (SELECT trip_id FROM demo_trip_load)
FOR UPDATE;
-- ...and WAITS (the query keeps spinning). This is the lock working.
-- Leave it running and go to WINDOW A, step 3.

-- STEP 4  B's lock was granted once A committed. Now B checks space:
SELECT * FROM demo_trip_load;   -- free_kg = 20 -> 30 kg does NOT fit
-- Agent B correctly decides not to load, and ends the transaction:
ROLLBACK;

-- (now go to WINDOW A, step 5)
