-- =====================================================================
-- ParcelPark | Portfolio 3 | Demo 4: THE PROBLEM - two agents overload the same car
-- WINDOW A of 2.  Open a SECOND Query Tool on parcelpark for the other
-- window. Run the steps in NUMBER ORDER, switching windows as told.
-- Highlight ONE step at a time and run it.
-- =====================================================================
-- Agent A wants to load PPDEMO0001 (30 kg). Agent B wants PPDEMO0002 (30 kg).
-- The car holds 50 kg, so only ONE should fit.

-- STEP 0  reset: empty the car
DELETE FROM parcel_trip WHERE trip_id = (SELECT trip_id FROM demo_trip_load);
SELECT * FROM demo_trip_load;   -- free_kg = 50

-- STEP 1  Agent A checks the space
BEGIN;
SELECT * FROM demo_trip_load;   -- free_kg = 50 -> "30 kg fits, I'll load it"

-- (now go to WINDOW B, step 2)

-- STEP 3  Agent A loads the parcel and commits
INSERT INTO parcel_trip (parcel_id, leg_no, trip_id, company_id)
SELECT p.parcel_id, 1, d.trip_id, p.company_id
FROM parcel p, demo_trip_load d WHERE p.tracking_code = 'PPDEMO0001';
COMMIT;

-- (now go to WINDOW B, step 4)

-- STEP 5  look at the car now
SELECT * FROM demo_trip_load;   -- loaded_kg = 60, free_kg = -10  OVERLOADED!
