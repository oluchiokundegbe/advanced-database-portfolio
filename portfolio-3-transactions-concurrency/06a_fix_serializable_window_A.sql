-- =====================================================================
-- ParcelPark | Portfolio 3 | Demo 6: FIX 2 - optimistic control with SERIALIZABLE isolation
-- WINDOW A of 2.  Open a SECOND Query Tool on parcelpark for the other
-- window. Run the steps in NUMBER ORDER, switching windows as told.
-- Highlight ONE step at a time and run it.
-- =====================================================================
-- No locks. Both agents work freely. At COMMIT, PostgreSQL checks whether
-- the result could have happened if they had run one after the other.
-- If not, it rejects one transaction, which must retry.

-- STEP 0  reset: empty the car
DELETE FROM parcel_trip WHERE trip_id = (SELECT trip_id FROM demo_trip_load);
SELECT * FROM demo_trip_load;   -- free_kg = 50

-- STEP 1
BEGIN ISOLATION LEVEL SERIALIZABLE;
SELECT * FROM demo_trip_load;   -- free_kg = 50

-- (now go to WINDOW B, step 2)

-- STEP 3  Agent A loads
INSERT INTO parcel_trip (parcel_id, leg_no, trip_id, company_id)
SELECT p.parcel_id, 1, d.trip_id, p.company_id
FROM parcel p, demo_trip_load d WHERE p.tracking_code = 'PPDEMO0001';

-- (now go to WINDOW B, step 4)

-- STEP 5  Agent A commits first -> succeeds
COMMIT;

-- (now go to WINDOW B, step 6)

-- STEP 7  final state
SELECT * FROM demo_trip_load;   -- loaded_kg = 30, free_kg = 20  CORRECT
