-- =====================================================================
-- ParcelPark | Portfolio 3 | Demo 3: isolation levels (dirty read, non-repeatable read)
-- WINDOW A of 2.  Open a SECOND Query Tool on parcelpark for the other
-- window. Run the steps in NUMBER ORDER, switching windows as told.
-- Highlight ONE step at a time and run it.
-- =====================================================================

-- STEP 0  reset the demo parcel
UPDATE parcel SET current_status = 'paid' WHERE tracking_code = 'PPDEMO0001';

-- ---------- Part 1: READ COMMITTED (PostgreSQL's default) -------------
-- STEP 1
BEGIN;   -- default isolation = READ COMMITTED
SELECT tracking_code, current_status FROM parcel WHERE tracking_code = 'PPDEMO0001';
-- -> 'paid'

-- (now go to WINDOW B, step 2)

-- STEP 3  B has changed it but NOT committed
SELECT tracking_code, current_status FROM parcel WHERE tracking_code = 'PPDEMO0001';
-- -> still 'paid': NO DIRTY READ. Uncommitted data is never visible.

-- (now go to WINDOW B, step 4)

-- STEP 5  B has committed. Same query, same transaction...
SELECT tracking_code, current_status FROM parcel WHERE tracking_code = 'PPDEMO0001';
-- -> 'loaded': a NON-REPEATABLE READ. The value changed mid-transaction.

-- STEP 6
COMMIT;

-- ---------- Part 2: REPEATABLE READ -----------------------------------
-- STEP 7
BEGIN ISOLATION LEVEL REPEATABLE READ;
SELECT tracking_code, current_status FROM parcel WHERE tracking_code = 'PPDEMO0001';
-- -> 'loaded'

-- (now go to WINDOW B, step 8)

-- STEP 9  B committed 'in_transit', but this transaction keeps its snapshot
SELECT tracking_code, current_status FROM parcel WHERE tracking_code = 'PPDEMO0001';
-- -> still 'loaded': the read is REPEATABLE

-- STEP 10  end the transaction and look again
COMMIT;
SELECT tracking_code, current_status FROM parcel WHERE tracking_code = 'PPDEMO0001';
-- -> 'in_transit': the new snapshot sees B's change
