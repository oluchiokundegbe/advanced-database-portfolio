-- =====================================================================
-- ParcelPark | Portfolio 3 | Demo 2: ROLLBACK and SAVEPOINT
-- One window only. Run Demo 1 first (needs parcel PPDEMO0100).
-- IMPORTANT (pgAdmin): turn OFF "Auto rollback on error" for this demo.
-- Highlight and run ONE step at a time.
-- =====================================================================

-- ---------- Part A: manual ROLLBACK (an agent changes their mind) -----
-- STEP A1
BEGIN;
UPDATE parcel SET current_status = 'cancelled' WHERE tracking_code = 'PPDEMO0100';

-- STEP A2  inside the transaction the change is visible...
SELECT tracking_code, current_status FROM parcel WHERE tracking_code = 'PPDEMO0100';

-- STEP A3  ...but we undo it
ROLLBACK;

-- STEP A4  back to 'paid': as if the cancel never happened
SELECT tracking_code, current_status FROM parcel WHERE tracking_code = 'PPDEMO0100';


-- ---------- Part B: an ERROR aborts the whole transaction -------------
-- STEP B1  highlight all four statements and run together.
-- The payment re-uses reference DEMO-PAY-0100 -> UNIQUE violation.
BEGIN;
INSERT INTO parcel (tracking_code, sender_id, company_id, receiver_name,
                    receiver_phone, origin_park_id, dest_park_id, weight_kg, fee)
VALUES ('PPDEMO0101',
        (SELECT customer_id FROM customer WHERE phone = '08071110001'),
        (SELECT company_id FROM transport_company WHERE name = 'Swift Lines Ltd'),
        'Tobi Lawal', '08099990101',
        (SELECT park_id FROM park WHERE name = 'Jibowu Motor Park'),
        (SELECT park_id FROM park WHERE name = 'Mile 1 Motor Park'), 2, 2500);
INSERT INTO tracking_event (parcel_id, park_id, status)
SELECT parcel_id, origin_park_id, 'registered' FROM parcel WHERE tracking_code = 'PPDEMO0101';
INSERT INTO payment (parcel_id, amount, method, status, reference)
SELECT parcel_id, fee, 'cash', 'successful', 'DEMO-PAY-0100'
FROM parcel WHERE tracking_code = 'PPDEMO0101';

-- STEP B2  the transaction is now "aborted": even a simple query fails
SELECT 1;

-- STEP B3
ROLLBACK;

-- STEP B4  the parcel and its tracking event were NOT saved (count = 0)
SELECT count(*) AS ppdemo0101_rows FROM parcel WHERE tracking_code = 'PPDEMO0101';


-- ---------- Part C: SAVEPOINT (undo only PART of a transaction) -------
-- STEP C1  load the parcel and record the event, then set a savepoint
BEGIN;
UPDATE parcel SET current_status = 'loaded' WHERE tracking_code = 'PPDEMO0100';
INSERT INTO tracking_event (parcel_id, park_id, status, note)
SELECT parcel_id, origin_park_id, 'loaded', 'Loaded on bus' FROM parcel WHERE tracking_code = 'PPDEMO0100';
SAVEPOINT before_extra_charge;

-- STEP C2  try to add an extra charge with an invalid method -> ERROR
INSERT INTO payment (parcel_id, amount, method, status, reference)
SELECT parcel_id, 500, 'bitcoin', 'pending', 'DEMO-EXTRA-0100'
FROM parcel WHERE tracking_code = 'PPDEMO0100';

-- STEP C3  undo ONLY the failed part; the loading work is kept
ROLLBACK TO SAVEPOINT before_extra_charge;

-- STEP C4
COMMIT;

-- STEP C5  status is 'loaded' and the 'loaded' event exists; no extra charge
SELECT p.current_status,
       (SELECT count(*) FROM tracking_event te WHERE te.parcel_id = p.parcel_id AND te.status = 'loaded') AS loaded_events,
       (SELECT count(*) FROM payment pay      WHERE pay.parcel_id = p.parcel_id)                          AS payments
FROM parcel p WHERE p.tracking_code = 'PPDEMO0100';
