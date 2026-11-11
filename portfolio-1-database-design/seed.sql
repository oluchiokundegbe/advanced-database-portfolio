-- =====================================================================
-- ParcelPark | Portfolio 1: small sample dataset
-- (A large generated dataset is added in Portfolio 2 for performance tests.)
-- =====================================================================

INSERT INTO park (name, city, state, address) VALUES
  ('Jibowu Motor Park',   'Lagos',         'Lagos',  'Ikorodu Rd, Yaba'),
  ('Mile 1 Motor Park',   'Port Harcourt', 'Rivers', 'Ikwerre Rd, Mile 1'),
  ('Utako Motor Park',    'Abuja',         'FCT',    'Utako District'),
  ('Ring Road Park',      'Benin City',    'Edo',    'Ring Road'),
  ('Upper Iweka Park',    'Onitsha',       'Anambra','Upper Iweka Rd');

INSERT INTO transport_company (name, phone, email) VALUES
  ('Swift Lines Ltd',    '08030000001', 'ops@swiftlines.ng'),
  ('Delta Express Co',   '08030000002', 'hello@deltaexpress.ng'),
  ('Eastern Movers',     '08030000003', NULL);

INSERT INTO company_park (company_id, park_id) VALUES
  (1,1),(1,2),(1,4),     -- Swift: Lagos, PH, Benin
  (2,1),(2,3),           -- Delta: Lagos, Abuja
  (3,2),(3,5);           -- Eastern: PH, Onitsha

INSERT INTO vehicle (company_id, plate_no, vehicle_type, capacity_kg) VALUES
  (1, 'LND-123-AA', 'bus',   800),
  (1, 'LND-456-AB', 'van',   500),
  (2, 'ABJ-789-XY', 'bus',   900),
  (3, 'PHC-321-KL', 'truck', 3000);

INSERT INTO driver (company_id, full_name, phone, licence_no) VALUES
  (1, 'Emeka Obi',      '08051110001', 'LAG-DL-0001'),
  (1, 'Tunde Bakare',   '08051110002', 'LAG-DL-0002'),
  (2, 'Musa Ibrahim',   '08051110003', 'FCT-DL-0003'),
  (3, 'Chinedu Okafor', '08051110004', 'RIV-DL-0004');

INSERT INTO staff (park_id, full_name, phone, role) VALUES
  (1, 'Bisi Adeyemi',  '08061110001', 'agent'),
  (2, 'Ngozi Eze',     '08061110002', 'agent'),
  (3, 'Halima Bello',  '08061110003', 'supervisor'),
  (4, 'Osas Igbinosa', '08061110004', 'agent');

INSERT INTO customer (full_name, phone, email) VALUES
  ('Ada Nwosu',     '08071110001', 'ada@mail.com'),
  ('Kunle Ajayi',   '08071110002', NULL),
  ('Fatima Sule',   '08071110003', 'fatima@mail.com');

INSERT INTO parcel (tracking_code, sender_id, company_id, receiver_name,
                    receiver_phone, origin_park_id, dest_park_id,
                    description, weight_kg, declared_value, fee, current_status)
VALUES
  ('PP00000001', 1, 1, 'Ifeoma Nwosu', '08081110001', 1, 2,
   'Box of documents', 2.5,  20000, 3500, 'in_transit'),
  ('PP00000002', 2, 2, 'Sani Musa',    '08081110002', 1, 3,
   'Laptop',           3.0, 450000, 6000, 'collected'),
  ('PP00000003', 3, 1, 'Grace Okon',   '08081110003', 1, 2,
   'Food items',      15.0,  30000, 5000, 'paid');

INSERT INTO trip (company_id, vehicle_id, driver_id, origin_park_id,
                  dest_park_id, scheduled_departure, actual_departure,
                  actual_arrival, status)
VALUES
  (1, 1, 1, 1, 4, '2026-11-10 07:00+01', '2026-11-10 07:20+01', '2026-11-10 13:00+01', 'arrived'),
  (1, 2, 2, 4, 2, '2026-11-10 15:00+01', '2026-11-10 15:10+01', NULL,                  'departed'),
  (2, 3, 3, 1, 3, '2026-11-09 06:00+01', '2026-11-09 06:15+01', '2026-11-09 17:40+01', 'arrived');

-- Parcel 1 travels in two legs: Lagos -> Benin -> Port Harcourt
INSERT INTO parcel_trip (parcel_id, leg_no, trip_id, company_id) VALUES
  (1, 1, 1, 1),
  (1, 2, 2, 1),
  (2, 1, 3, 2);

INSERT INTO tracking_event (parcel_id, park_id, staff_id, status, note, event_time) VALUES
  (1, 1, 1,    'registered', 'Dropped at Jibowu',        '2026-11-10 06:30+01'),
  (1, 1, 1,    'paid',       NULL,                       '2026-11-10 06:35+01'),
  (1, 1, 1,    'loaded',     'Leg 1 on LND-123-AA',      '2026-11-10 06:50+01'),
  (1, NULL, NULL,'in_transit','Departed Lagos',          '2026-11-10 07:20+01'),
  (1, 4, 4,    'loaded',     'Transferred at Benin',     '2026-11-10 14:30+01'),
  (2, 1, 1,    'registered', NULL,                       '2026-11-09 05:30+01'),
  (2, 1, 1,    'paid',       NULL,                       '2026-11-09 05:32+01'),
  (2, 3, 3,    'arrived',    NULL,                       '2026-11-09 17:45+01'),
  (2, 3, 3,    'collected',  'ID checked',               '2026-11-09 19:00+01'),
  (3, 1, 1,    'registered', NULL,                       '2026-11-11 09:00+01'),
  (3, 1, 1,    'paid',       NULL,                       '2026-11-11 09:05+01');

INSERT INTO payment (parcel_id, amount, method, status, reference, paid_at) VALUES
  (1, 3500, 'transfer', 'successful', 'TRF-2026-0001', '2026-11-10 06:35+01'),
  (2, 6000, 'card',     'failed',     'CRD-2026-0001', '2026-11-09 05:31+01'),
  (2, 6000, 'ussd',     'successful', 'USD-2026-0001', '2026-11-09 05:32+01'),
  (3, 5000, 'cash',     'successful', 'CSH-2026-0001', '2026-11-11 09:05+01');
