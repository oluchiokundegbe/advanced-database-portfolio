-- =====================================================================
-- ParcelPark | Portfolio 1: constraint tests
-- Each statement below SHOULD FAIL. Screenshot the error messages
-- as evidence that the database enforces the business rules.
-- \set ON_ERROR_STOP off  (psql) so every test runs.
-- =====================================================================

-- T1  CHECK: origin and destination cannot be the same park
INSERT INTO parcel (tracking_code, sender_id, company_id, receiver_name,
                    receiver_phone, origin_park_id, dest_park_id, weight_kg, fee)
VALUES ('PPTEST0001', 1, 1, 'Test', '0800', 1, 1, 1, 1000);

-- T2  CHECK: weight must be positive
INSERT INTO parcel (tracking_code, sender_id, company_id, receiver_name,
                    receiver_phone, origin_park_id, dest_park_id, weight_kg, fee)
VALUES ('PPTEST0002', 1, 1, 'Test', '0800', 1, 2, -3, 1000);

-- T3  UNIQUE: tracking codes cannot repeat
INSERT INTO parcel (tracking_code, sender_id, company_id, receiver_name,
                    receiver_phone, origin_park_id, dest_park_id, weight_kg, fee)
VALUES ('PP00000001', 1, 1, 'Test', '0800', 1, 2, 1, 1000);

-- T4  FOREIGN KEY: sender must exist
INSERT INTO parcel (tracking_code, sender_id, company_id, receiver_name,
                    receiver_phone, origin_park_id, dest_park_id, weight_kg, fee)
VALUES ('PPTEST0004', 999, 1, 'Test', '0800', 1, 2, 1, 1000);

-- T5  COMPOSITE FK: Swift Lines (1) cannot use Delta's driver (3) on a trip
INSERT INTO trip (company_id, vehicle_id, driver_id, origin_park_id,
                  dest_park_id, scheduled_departure)
VALUES (1, 1, 3, 1, 2, now());

-- T6  COMPOSITE FK: a Delta parcel (2) cannot ride on a Swift trip (1)
INSERT INTO parcel_trip (parcel_id, leg_no, trip_id, company_id)
VALUES (2, 2, 1, 1);

-- T7  PARTIAL UNIQUE INDEX: only one successful payment per parcel
INSERT INTO payment (parcel_id, amount, method, status, reference)
VALUES (1, 3500, 'cash', 'successful', 'CSH-DUPLICATE');

-- T8  CHECK: invalid status value
UPDATE parcel SET current_status = 'lost' WHERE parcel_id = 1;

-- T9  FOREIGN KEY (RESTRICT): cannot delete a customer who has parcels
DELETE FROM customer WHERE customer_id = 1;
