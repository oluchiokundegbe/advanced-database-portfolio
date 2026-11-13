-- =====================================================================
-- ParcelPark | Portfolio 3 | Demo 1: COMMIT (atomic parcel registration)
-- Registering a parcel touches THREE tables. Either all of it happens,
-- or none of it does. A transaction guarantees that (Atomicity).
-- One window only.
-- =====================================================================

-- STEP 1  highlight from BEGIN down to COMMIT and run it all together
BEGIN;

INSERT INTO parcel (tracking_code, sender_id, company_id, receiver_name,
                    receiver_phone, origin_park_id, dest_park_id,
                    description, weight_kg, declared_value, fee)
VALUES ('PPDEMO0100',
        (SELECT customer_id FROM customer WHERE phone = '08071110001'),
        (SELECT company_id FROM transport_company WHERE name = 'Swift Lines Ltd'),
        'Chioma Eze', '08099990100',
        (SELECT park_id FROM park WHERE name = 'Jibowu Motor Park'),
        (SELECT park_id FROM park WHERE name = 'Mile 1 Motor Park'),
        'Shoes', 4, 50000, 3500);

INSERT INTO tracking_event (parcel_id, park_id, status, note)
SELECT parcel_id, origin_park_id, 'registered', 'Dropped at park'
FROM parcel WHERE tracking_code = 'PPDEMO0100';

INSERT INTO payment (parcel_id, amount, method, status, reference)
SELECT parcel_id, fee, 'transfer', 'successful', 'DEMO-PAY-0100'
FROM parcel WHERE tracking_code = 'PPDEMO0100';

UPDATE parcel SET current_status = 'paid'
WHERE tracking_code = 'PPDEMO0100';

INSERT INTO tracking_event (parcel_id, park_id, status, note)
SELECT parcel_id, origin_park_id, 'paid', 'Paid by transfer'
FROM parcel WHERE tracking_code = 'PPDEMO0100';

COMMIT;

-- STEP 2  verify: parcel, payment and both tracking events all exist
SELECT p.tracking_code, p.current_status, pay.amount, pay.status AS payment_status,
       te.status AS event, te.event_time
FROM parcel p
JOIN payment pay       ON pay.parcel_id = p.parcel_id
JOIN tracking_event te ON te.parcel_id  = p.parcel_id
WHERE p.tracking_code = 'PPDEMO0100'
ORDER BY te.event_time;
