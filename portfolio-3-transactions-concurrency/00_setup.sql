-- =====================================================================
-- ParcelPark | Portfolio 3: setup for the transaction demos
-- Creates a SMALL demo car (50 kg capacity), one trip, and two 30 kg
-- parcels. Two parcels will NOT both fit: perfect for concurrency tests.
-- Re-runnable: removes previous demo data first.
-- Run the whole file once (click Execute with nothing highlighted).
-- =====================================================================

-- ---------- clean up any earlier demo data --------------------------
DROP VIEW IF EXISTS demo_trip_load;
DELETE FROM tracking_event WHERE parcel_id IN (SELECT parcel_id FROM parcel WHERE tracking_code LIKE 'PPDEMO%');
DELETE FROM payment        WHERE parcel_id IN (SELECT parcel_id FROM parcel WHERE tracking_code LIKE 'PPDEMO%');
DELETE FROM parcel_trip    WHERE parcel_id IN (SELECT parcel_id FROM parcel WHERE tracking_code LIKE 'PPDEMO%');
DELETE FROM parcel         WHERE tracking_code LIKE 'PPDEMO%';
DELETE FROM trip           WHERE vehicle_id IN (SELECT vehicle_id FROM vehicle WHERE plate_no = 'DEMO-CAR-01');
DELETE FROM vehicle        WHERE plate_no = 'DEMO-CAR-01';

-- ---------- a small car owned by Swift Lines ------------------------
INSERT INTO vehicle (company_id, plate_no, vehicle_type, capacity_kg)
SELECT company_id, 'DEMO-CAR-01', 'car', 50
FROM transport_company WHERE name = 'Swift Lines Ltd';

-- ---------- one trip: Jibowu (Lagos) -> Mile 1 (Port Harcourt) ------
INSERT INTO trip (company_id, vehicle_id, driver_id, origin_park_id,
                  dest_park_id, scheduled_departure, status)
SELECT v.company_id, v.vehicle_id,
       (SELECT min(driver_id) FROM driver WHERE company_id = v.company_id),
       (SELECT park_id FROM park WHERE name = 'Jibowu Motor Park'),
       (SELECT park_id FROM park WHERE name = 'Mile 1 Motor Park'),
       now() + interval '2 hours', 'boarding'
FROM vehicle v WHERE v.plate_no = 'DEMO-CAR-01';

-- ---------- two 30 kg parcels waiting to be loaded ------------------
INSERT INTO parcel (tracking_code, sender_id, company_id, receiver_name,
                    receiver_phone, origin_park_id, dest_park_id,
                    description, weight_kg, declared_value, fee, current_status)
SELECT code, c.customer_id, tc.company_id, rname, rphone,
       (SELECT park_id FROM park WHERE name = 'Jibowu Motor Park'),
       (SELECT park_id FROM park WHERE name = 'Mile 1 Motor Park'),
       descr, 30, 100000, 8000, 'paid'
FROM (VALUES ('PPDEMO0001', 'Emeka Nwankwo', '08099990001', 'Generator'),
             ('PPDEMO0002', 'Blessing Ade',  '08099990002', 'Bag of rice'))
     AS d(code, rname, rphone, descr),
     customer c, transport_company tc
WHERE c.phone = '08071110001' AND tc.name = 'Swift Lines Ltd';

-- ---------- helper view: how full is the demo car? ------------------
CREATE VIEW demo_trip_load AS
SELECT t.trip_id,
       v.plate_no,
       v.capacity_kg,
       COALESCE(SUM(p.weight_kg), 0)                 AS loaded_kg,
       v.capacity_kg - COALESCE(SUM(p.weight_kg), 0) AS free_kg
FROM trip t
JOIN vehicle v          ON v.vehicle_id = t.vehicle_id
LEFT JOIN parcel_trip pt ON pt.trip_id  = t.trip_id
LEFT JOIN parcel p       ON p.parcel_id = pt.parcel_id
WHERE v.plate_no = 'DEMO-CAR-01'
GROUP BY t.trip_id, v.plate_no, v.capacity_kg;

-- ---------- check -----------------------------------------------------
SELECT * FROM demo_trip_load;          -- expect: capacity 50, loaded 0, free 50
