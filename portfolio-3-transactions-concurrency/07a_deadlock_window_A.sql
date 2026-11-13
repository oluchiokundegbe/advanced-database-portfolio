-- =====================================================================
-- ParcelPark | Portfolio 3 | Demo 7 (bonus): DEADLOCK detection
-- WINDOW A of 2.  Open a SECOND Query Tool on parcelpark for the other
-- window. Run the steps in NUMBER ORDER, switching windows as told.
-- Highlight ONE step at a time and run it.
-- =====================================================================
-- Agent A updates parcel 1 then parcel 2. Agent B does it in REVERSE order.
-- Each ends up waiting for the other forever, so PostgreSQL steps in.

-- STEP 1
BEGIN;
UPDATE parcel SET current_status = 'loaded' WHERE tracking_code = 'PPDEMO0001';

-- (now go to WINDOW B, step 2)

-- STEP 3  A now needs parcel 2, which B holds -> A WAITS (keeps spinning)
UPDATE parcel SET current_status = 'loaded' WHERE tracking_code = 'PPDEMO0002';
-- Leave it running and go to WINDOW B, step 4.

-- STEP 5  after B was cancelled, A's update went through
COMMIT;
SELECT tracking_code, current_status FROM parcel WHERE tracking_code LIKE 'PPDEMO000%';
