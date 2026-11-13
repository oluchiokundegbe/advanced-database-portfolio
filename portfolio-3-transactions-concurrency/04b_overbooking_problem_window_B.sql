-- =====================================================================
-- ParcelPark | Portfolio 3 | Demo 4: THE PROBLEM - two agents overload the same car
-- WINDOW B of 2.  Open a SECOND Query Tool on parcelpark for the other
-- window. Run the steps in NUMBER ORDER, switching windows as told.
-- Highlight ONE step at a time and run it.
-- =====================================================================

-- STEP 2  Agent B checks the space at the same moment
BEGIN;
SELECT * FROM demo_trip_load;   -- free_kg = 50 -> "30 kg fits, I'll load it"

-- (now go to WINDOW A, step 3)

-- STEP 4  Agent B loads, based on what B saw in step 2
INSERT INTO parcel_trip (parcel_id, leg_no, trip_id, company_id)
SELECT p.parcel_id, 1, d.trip_id, p.company_id
FROM parcel p, demo_trip_load d WHERE p.tracking_code = 'PPDEMO0002';
COMMIT;

-- (now go to WINDOW A, step 5)
