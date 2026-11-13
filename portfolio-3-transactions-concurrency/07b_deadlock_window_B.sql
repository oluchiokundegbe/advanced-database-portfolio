-- =====================================================================
-- ParcelPark | Portfolio 3 | Demo 7 (bonus): DEADLOCK detection
-- WINDOW B of 2.  Open a SECOND Query Tool on parcelpark for the other
-- window. Run the steps in NUMBER ORDER, switching windows as told.
-- Highlight ONE step at a time and run it.
-- =====================================================================

-- STEP 2
BEGIN;
UPDATE parcel SET current_status = 'paid' WHERE tracking_code = 'PPDEMO0002';

-- (now go to WINDOW A, step 3)

-- STEP 4  B now needs parcel 1, which A holds -> circular wait!
UPDATE parcel SET current_status = 'paid' WHERE tracking_code = 'PPDEMO0001';
-- -> after about 1 second: ERROR: deadlock detected
--    PostgreSQL cancels ONE transaction (this one) so the other can finish.

-- STEP 4b
ROLLBACK;

-- (now go to WINDOW A, step 5)
