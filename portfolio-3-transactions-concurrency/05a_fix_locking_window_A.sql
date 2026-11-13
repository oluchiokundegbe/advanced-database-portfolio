-- =====================================================================
-- ParcelPark | Portfolio 3 | Demo 5: FIX 1 - pessimistic locking with SELECT ... FOR UPDATE
-- WINDOW A of 2.  Open a SECOND Query Tool on parcelpark for the other
-- window. Run the steps in NUMBER ORDER, switching windows as told.
-- Highlight ONE step at a time and run it.
-- =====================================================================
-- Before checking space, each agent LOCKS the trip row. A second agent
-- must WAIT until the first one finishes. Check + load become one unit.

-- STEP 0  reset: empty the car
DELETE FROM parcel_trip WHERE trip_id = (SELECT trip_id FROM demo_trip_load);
SELECT * FROM demo_trip_load;   -- free_kg = 50

-- STEP 1  Agent A locks the trip, then checks space
BEGIN;
SELECT trip_id FROM trip
WHERE trip_id = (SELECT trip_id FROM demo_trip_load)
FOR UPDATE;
SELECT * FROM demo_trip_load;   -- free_kg = 50

-- (now go to WINDOW B, step 2)

-- STEP 3  Agent A loads and commits -> this RELEASES the lock
INSERT INTO parcel_trip (parcel_id, leg_no, trip_id, company_id)
SELECT p.parcel_id, 1, d.trip_id, p.company_id
FROM parcel p, demo_trip_load d WHERE p.tracking_code = 'PPDEMO0001';
COMMIT;

-- (now go to WINDOW B: its query has finished waiting. Do step 4)

-- STEP 5  final state
SELECT * FROM demo_trip_load;   -- loaded_kg = 30, free_kg = 20  CORRECT
