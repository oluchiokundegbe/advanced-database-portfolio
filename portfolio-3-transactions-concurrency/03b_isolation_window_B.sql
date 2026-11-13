-- =====================================================================
-- ParcelPark | Portfolio 3 | Demo 3: isolation levels (dirty read, non-repeatable read)
-- WINDOW B of 2.  Open a SECOND Query Tool on parcelpark for the other
-- window. Run the steps in NUMBER ORDER, switching windows as told.
-- Highlight ONE step at a time and run it.
-- =====================================================================

-- STEP 2  change the status but DO NOT commit yet
BEGIN;
UPDATE parcel SET current_status = 'loaded' WHERE tracking_code = 'PPDEMO0001';

-- (now go to WINDOW A, step 3)

-- STEP 4
COMMIT;

-- (now go to WINDOW A, step 5)

-- STEP 8  a single auto-committed update
UPDATE parcel SET current_status = 'in_transit' WHERE tracking_code = 'PPDEMO0001';

-- (now go to WINDOW A, step 9)
