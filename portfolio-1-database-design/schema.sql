-- =====================================================================
-- ParcelPark: Inter-city Motor Park Parcel Tracking Platform
-- MIT 8103 Advanced Database Systems | Portfolio 1: Database Design
-- DBMS: PostgreSQL 17
-- =====================================================================
-- Run order: schema.sql -> seed.sql -> constraint_tests.sql
-- Re-runnable: drops existing objects first.
-- =====================================================================

DROP TABLE IF EXISTS payment, tracking_event, parcel_trip, trip, parcel,
                     customer, staff, driver, vehicle, company_park,
                     transport_company, park CASCADE;

-- ---------------------------------------------------------------------
-- PARK: a physical motor park where parcels are dropped off / collected
-- ---------------------------------------------------------------------
CREATE TABLE park (
    park_id     INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name        VARCHAR(100) NOT NULL,
    city        VARCHAR(60)  NOT NULL,
    state       VARCHAR(40)  NOT NULL,
    address     VARCHAR(200),
    CONSTRAINT uq_park_name_city UNIQUE (name, city)
);

-- ---------------------------------------------------------------------
-- TRANSPORT_COMPANY: carriers that plug into the platform
-- ---------------------------------------------------------------------
CREATE TABLE transport_company (
    company_id    INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name          VARCHAR(100) NOT NULL UNIQUE,
    phone         VARCHAR(20)  NOT NULL,
    email         VARCHAR(120) UNIQUE,
    joined_at     TIMESTAMPTZ  NOT NULL DEFAULT now()
);

-- ---------------------------------------------------------------------
-- COMPANY_PARK: which companies operate at which parks (M:N)
-- ---------------------------------------------------------------------
CREATE TABLE company_park (
    company_id  INT NOT NULL REFERENCES transport_company(company_id),
    park_id     INT NOT NULL REFERENCES park(park_id),
    PRIMARY KEY (company_id, park_id)
);

-- ---------------------------------------------------------------------
-- VEHICLE: owned by exactly one company
-- ---------------------------------------------------------------------
CREATE TABLE vehicle (
    vehicle_id    INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    company_id    INT NOT NULL REFERENCES transport_company(company_id),
    plate_no      VARCHAR(15) NOT NULL UNIQUE,
    vehicle_type  VARCHAR(20) NOT NULL
                  CHECK (vehicle_type IN ('bus', 'van', 'truck', 'car')),
    capacity_kg   NUMERIC(8,2) NOT NULL CHECK (capacity_kg > 0),
    -- lets trip reference (vehicle_id, company_id) together
    CONSTRAINT uq_vehicle_company UNIQUE (vehicle_id, company_id)
);

-- ---------------------------------------------------------------------
-- DRIVER: employed by exactly one company
-- ---------------------------------------------------------------------
CREATE TABLE driver (
    driver_id    INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    company_id   INT NOT NULL REFERENCES transport_company(company_id),
    full_name    VARCHAR(100) NOT NULL,
    phone        VARCHAR(20)  NOT NULL UNIQUE,
    licence_no   VARCHAR(30)  NOT NULL UNIQUE,
    CONSTRAINT uq_driver_company UNIQUE (driver_id, company_id)
);

-- ---------------------------------------------------------------------
-- STAFF: park agents who receive, load and release parcels
-- ---------------------------------------------------------------------
CREATE TABLE staff (
    staff_id    INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    park_id     INT NOT NULL REFERENCES park(park_id),
    full_name   VARCHAR(100) NOT NULL,
    phone       VARCHAR(20)  NOT NULL UNIQUE,
    role        VARCHAR(20)  NOT NULL
                CHECK (role IN ('agent', 'supervisor', 'admin'))
);

-- ---------------------------------------------------------------------
-- CUSTOMER: registered senders
-- ---------------------------------------------------------------------
CREATE TABLE customer (
    customer_id  INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    full_name    VARCHAR(100) NOT NULL,
    phone        VARCHAR(20)  NOT NULL UNIQUE,
    email        VARCHAR(120) UNIQUE,
    created_at   TIMESTAMPTZ  NOT NULL DEFAULT now()
);

-- ---------------------------------------------------------------------
-- PARCEL: the item being shipped. Receiver may not be registered,
-- so receiver details are stored directly on the parcel.
-- ---------------------------------------------------------------------
CREATE TABLE parcel (
    parcel_id        BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tracking_code    CHAR(10)     NOT NULL UNIQUE,
    sender_id        INT          NOT NULL REFERENCES customer(customer_id),
    company_id       INT          NOT NULL REFERENCES transport_company(company_id),
    receiver_name    VARCHAR(100) NOT NULL,
    receiver_phone   VARCHAR(20)  NOT NULL,
    origin_park_id   INT          NOT NULL REFERENCES park(park_id),
    dest_park_id     INT          NOT NULL REFERENCES park(park_id),
    description      VARCHAR(200),
    weight_kg        NUMERIC(7,2) NOT NULL CHECK (weight_kg > 0),
    declared_value   NUMERIC(12,2) NOT NULL DEFAULT 0 CHECK (declared_value >= 0),
    fee              NUMERIC(10,2) NOT NULL CHECK (fee >= 0),
    current_status   VARCHAR(20)  NOT NULL DEFAULT 'registered'
                     CHECK (current_status IN ('registered', 'paid', 'loaded',
                            'in_transit', 'arrived', 'collected',
                            'returned', 'cancelled')),
    created_at       TIMESTAMPTZ  NOT NULL DEFAULT now(),
    CONSTRAINT chk_parcel_route CHECK (origin_park_id <> dest_park_id),
    CONSTRAINT uq_parcel_company UNIQUE (parcel_id, company_id)
);

-- ---------------------------------------------------------------------
-- TRIP: one vehicle journey between two parks.
-- company_id + composite FKs guarantee the vehicle AND the driver
-- belong to the same company.
-- ---------------------------------------------------------------------
CREATE TABLE trip (
    trip_id              BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    company_id           INT NOT NULL,
    vehicle_id           INT NOT NULL,
    driver_id            INT NOT NULL,
    origin_park_id       INT NOT NULL REFERENCES park(park_id),
    dest_park_id         INT NOT NULL REFERENCES park(park_id),
    scheduled_departure  TIMESTAMPTZ NOT NULL,
    actual_departure     TIMESTAMPTZ,
    actual_arrival       TIMESTAMPTZ,
    status               VARCHAR(20) NOT NULL DEFAULT 'scheduled'
                         CHECK (status IN ('scheduled', 'boarding', 'departed',
                                           'arrived', 'cancelled')),
    CONSTRAINT fk_trip_vehicle FOREIGN KEY (vehicle_id, company_id)
        REFERENCES vehicle (vehicle_id, company_id),
    CONSTRAINT fk_trip_driver  FOREIGN KEY (driver_id, company_id)
        REFERENCES driver (driver_id, company_id),
    CONSTRAINT chk_trip_route  CHECK (origin_park_id <> dest_park_id),
    CONSTRAINT chk_trip_times  CHECK (actual_arrival IS NULL
                                      OR actual_departure IS NULL
                                      OR actual_arrival > actual_departure),
    CONSTRAINT uq_trip_company UNIQUE (trip_id, company_id)
);

-- ---------------------------------------------------------------------
-- PARCEL_TRIP: resolves M:N between parcel and trip.
-- A parcel may travel in several legs (e.g. Lagos -> Benin -> PH).
-- company_id ensures a parcel only rides on its own carrier's trips.
-- ---------------------------------------------------------------------
CREATE TABLE parcel_trip (
    parcel_id   BIGINT   NOT NULL,
    leg_no      SMALLINT NOT NULL CHECK (leg_no >= 1),
    trip_id     BIGINT   NOT NULL,
    company_id  INT      NOT NULL,
    loaded_at   TIMESTAMPTZ NOT NULL DEFAULT now(),
    PRIMARY KEY (parcel_id, leg_no),
    CONSTRAINT uq_parcel_trip UNIQUE (parcel_id, trip_id),
    CONSTRAINT fk_pt_parcel FOREIGN KEY (parcel_id, company_id)
        REFERENCES parcel (parcel_id, company_id),
    CONSTRAINT fk_pt_trip   FOREIGN KEY (trip_id, company_id)
        REFERENCES trip (trip_id, company_id)
);

-- ---------------------------------------------------------------------
-- TRACKING_EVENT: append-only audit trail of every status change
-- ---------------------------------------------------------------------
CREATE TABLE tracking_event (
    event_id    BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    parcel_id   BIGINT NOT NULL REFERENCES parcel(parcel_id),
    park_id     INT    REFERENCES park(park_id),     -- NULL while on the road
    staff_id    INT    REFERENCES staff(staff_id),   -- NULL for system events
    status      VARCHAR(20) NOT NULL
                CHECK (status IN ('registered', 'paid', 'loaded',
                       'in_transit', 'arrived', 'collected',
                       'returned', 'cancelled')),
    note        VARCHAR(200),
    event_time  TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ---------------------------------------------------------------------
-- PAYMENT: a parcel can have several attempts (failed, then successful)
-- ---------------------------------------------------------------------
CREATE TABLE payment (
    payment_id  BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    parcel_id   BIGINT NOT NULL REFERENCES parcel(parcel_id),
    amount      NUMERIC(10,2) NOT NULL CHECK (amount > 0),
    method      VARCHAR(15) NOT NULL
                CHECK (method IN ('cash', 'transfer', 'card', 'ussd')),
    status      VARCHAR(15) NOT NULL DEFAULT 'pending'
                CHECK (status IN ('pending', 'successful', 'failed', 'reversed')),
    reference   VARCHAR(40) NOT NULL UNIQUE,
    paid_at     TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Business rule: at most ONE successful payment per parcel
CREATE UNIQUE INDEX uq_one_successful_payment
    ON payment (parcel_id) WHERE status = 'successful';

-- NOTE: Foreign-key columns are deliberately NOT indexed yet.
-- Portfolio 2 measures query performance before and after indexing.
