-- ============================================================
-- PHARMACY MANAGEMENT SYSTEM - TERM PROJECT
-- Converted for Supabase (PostgreSQL)
-- Student: Enrollment# 01-134242-007
-- Course: Database Management Systems
-- Instructor: Ali Irfan
-- Bahria University Islamabad
-- ============================================================

-- NOTE: Run this entire file in Supabase SQL Editor (supabase.com)
-- Go to your project → SQL Editor → New Query → Paste & Run

-- ============================================================
-- DDL: CREATE TABLES
-- ============================================================

-- 1. PERSON (Super Type)
CREATE TABLE PERSON (
    person_id   SERIAL        PRIMARY KEY,
    name        VARCHAR(100)  NOT NULL,
    phone       VARCHAR(20)   NOT NULL,
    email       VARCHAR(100)  NULL,
    address     VARCHAR(200)  NULL,
    created_at  TIMESTAMP     DEFAULT NOW(),
    updated_at  TIMESTAMP     NULL,
    is_active   BOOLEAN       DEFAULT TRUE
);

-- 2. DOCTOR
CREATE TABLE DOCTOR (
    doctor_id      SERIAL       PRIMARY KEY,
    person_id      INT          NOT NULL REFERENCES PERSON(person_id),
    specialization VARCHAR(100) NOT NULL,
    license_no     VARCHAR(50)  NOT NULL,
    license_expiry DATE         NOT NULL
);

-- 3. PHARMACIST
CREATE TABLE PHARMACIST (
    pharmacist_id  SERIAL       PRIMARY KEY,
    person_id      INT          NOT NULL REFERENCES PERSON(person_id),
    license_no     VARCHAR(50)  NOT NULL,
    license_expiry DATE         NOT NULL
);

-- 4. CUSTOMER
CREATE TABLE CUSTOMER (
    customer_id    SERIAL  PRIMARY KEY,
    person_id      INT     NOT NULL REFERENCES PERSON(person_id),
    loyalty_points INT     DEFAULT 0
);

-- 5. MEDICINE
CREATE TABLE MEDICINE (
    medicine_id  SERIAL        PRIMARY KEY,
    name         VARCHAR(150)  NOT NULL,
    manufacturer VARCHAR(150)  NOT NULL,
    unit_price   NUMERIC(10,2) NOT NULL,
    category     VARCHAR(100)  NOT NULL,
    created_at   TIMESTAMP     DEFAULT NOW(),
    updated_at   TIMESTAMP     NULL,
    is_active    BOOLEAN       DEFAULT TRUE
);

-- 6. OTC_MEDICINE
CREATE TABLE OTC_MEDICINE (
    medicine_id     INT          PRIMARY KEY REFERENCES MEDICINE(medicine_id),
    shelf_category  VARCHAR(100) NOT NULL,
    age_restriction VARCHAR(50)  NULL
);

-- 7. PRESC_MEDICINE
CREATE TABLE PRESC_MEDICINE (
    medicine_id    INT          PRIMARY KEY REFERENCES MEDICINE(medicine_id),
    max_dose       VARCHAR(50)  NOT NULL,
    schedule_class VARCHAR(50)  NOT NULL,
    is_controlled  BOOLEAN      DEFAULT FALSE
);

-- 8. PRESCRIPTION
CREATE TABLE PRESCRIPTION (
    prescription_id SERIAL        PRIMARY KEY,
    doctor_id       INT           NOT NULL REFERENCES DOCTOR(doctor_id),
    customer_id     INT           NOT NULL REFERENCES CUSTOMER(customer_id),
    pharmacist_id   INT           NULL REFERENCES PHARMACIST(pharmacist_id),
    status          VARCHAR(30)   DEFAULT 'Pending',
    prescribed_date DATE          NOT NULL,
    expiry_date     DATE          NOT NULL,
    dispensed_at    TIMESTAMP     NULL,
    created_at      TIMESTAMP     DEFAULT NOW(),
    updated_at      TIMESTAMP     NULL,
    updated_by      VARCHAR(100)  NULL
);

-- 9. PRESC_MED_DETAIL
CREATE TABLE PRESC_MED_DETAIL (
    prescription_id     INT          NOT NULL REFERENCES PRESCRIPTION(prescription_id),
    medicine_id         INT          NOT NULL REFERENCES MEDICINE(medicine_id),
    quantity            INT          NOT NULL,
    dosage_instructions VARCHAR(300) NOT NULL,
    added_at            TIMESTAMP    DEFAULT NOW(),
    modified_at         TIMESTAMP    NULL,
    PRIMARY KEY (prescription_id, medicine_id)
);

-- 10. SUPPLIER
CREATE TABLE SUPPLIER (
    supplier_id    SERIAL        PRIMARY KEY,
    name           VARCHAR(150)  NOT NULL,
    phone          VARCHAR(20)   NOT NULL,
    email          VARCHAR(100)  NULL,
    contact_person VARCHAR(100)  NOT NULL,
    contract_start DATE          NOT NULL,
    contract_end   DATE          NULL,
    is_active      BOOLEAN       DEFAULT TRUE
);

-- 11. PURCHASE_ORDER
CREATE TABLE PURCHASE_ORDER (
    po_id            SERIAL        PRIMARY KEY,
    supplier_id      INT           NOT NULL REFERENCES SUPPLIER(supplier_id),
    medicine_id      INT           NOT NULL REFERENCES MEDICINE(medicine_id),
    quantity_ordered INT           NOT NULL,
    unit_cost        NUMERIC(10,2) NOT NULL,
    status           VARCHAR(30)   DEFAULT 'Ordered',
    ordered_at       TIMESTAMP     DEFAULT NOW(),
    received_at      TIMESTAMP     NULL,
    created_by       VARCHAR(100)  NOT NULL
);

-- 12. INVENTORY
CREATE TABLE INVENTORY (
    inventory_id   SERIAL        PRIMARY KEY,
    medicine_id    INT           NOT NULL REFERENCES MEDICINE(medicine_id),
    quantity       INT           NOT NULL DEFAULT 0,
    monitor_level  INT           NOT NULL DEFAULT 10,
    expiry_date    DATE          NULL,
    last_restocked TIMESTAMP     NULL,
    updated_at     TIMESTAMP     DEFAULT NOW(),
    updated_by     VARCHAR(100)  NOT NULL
);

-- 13. INVOICE
CREATE TABLE INVOICE (
    invoice_id      SERIAL        PRIMARY KEY,
    prescription_id INT           NULL REFERENCES PRESCRIPTION(prescription_id),
    subtotal        NUMERIC(10,2) NOT NULL,
    tax             NUMERIC(10,2) DEFAULT 0,
    total_amount    NUMERIC(10,2) NOT NULL,
    issued_at       TIMESTAMP     DEFAULT NOW(),
    updated_at      TIMESTAMP     NULL
);

-- 14. PAYMENT
CREATE TABLE PAYMENT (
    payment_id     SERIAL        PRIMARY KEY,
    invoice_id     INT           NOT NULL REFERENCES INVOICE(invoice_id),
    amount_paid    NUMERIC(10,2) NOT NULL,
    payment_method VARCHAR(50)   NOT NULL,
    payment_date   TIMESTAMP     DEFAULT NOW(),
    payment_status VARCHAR(30)   DEFAULT 'Completed',
    refunded_at    TIMESTAMP     NULL
);

-- ============================================================
-- DML: INSERT DATA
-- ============================================================

-- PERSON
INSERT INTO PERSON (name, phone, email, address, is_active) VALUES
('Dr. Salman Raza',        '0321-1001001', 'salman@bui.edu.pk',    'F-8/1, Islamabad',       TRUE),
('Dr. Ayesha Nawaz',       '0333-2002002', 'ayesha@bui.edu.pk',    'G-10, Islamabad',         TRUE),
('Dr. Tariq Mehmood',      '0300-3003003', 'tariq@bui.edu.pk',     'E-11, Islamabad',         TRUE),
('Pharmacist Hina Baig',   '0315-4004004', 'hina@pharma.pk',       'Bahria Town, Rwp',        TRUE),
('Pharmacist Usman Ali',   '0321-5005005', 'usman@pharma.pk',      'DHA Phase 2, Rwp',        TRUE),
('Ahmed Siddiqui',         '0312-6006006', 'ahmed@gmail.com',      'I-8/2, Islamabad',        TRUE),
('Fatima Malik',           '0301-7007007', 'fatima@gmail.com',     'Saddar, Rawalpindi',      TRUE),
('Bilal Cheema',           '0345-8008008', 'bilal@gmail.com',      'Wah Cantt',               TRUE),
('Sara Hussain',           '0323-9009009', 'sara@gmail.com',       'Chaklala, Rwp',           TRUE),
('Imran Farooq',           '0336-1010101', 'imran@gmail.com',      'Satellite Town, Rwp',     TRUE),
('Nadia Iqbal',            '0311-2020202', 'nadia@gmail.com',      'Khanna Pul, Rwp',         TRUE),
('Dr. Kamran Shah',        '0322-3030303', 'kamran@bui.edu.pk',    'H-13, Islamabad',         TRUE),
('Pharmacist Zara Javed',  '0313-4040404', 'zara@pharma.pk',       'G-9, Islamabad',          TRUE),
('Omer Bashir',            '0331-5050505', 'omer@gmail.com',       'Tench Bhata, Rwp',        TRUE),
('Rabia Qureshi',          '0344-6060606', 'rabia@gmail.com',      'Gulzar-e-Quaid, Rwp',     TRUE),
('Hamza Waqas',            '0302-7070707', 'hamza@gmail.com',      'PWD Colony, Islamabad',   TRUE),
('Maryam Shafiq',          '0321-8080808', 'maryam@gmail.com',     'Morgah, Rwp',             TRUE),
('Khalid Rehman',          '0333-9090909', 'khalid@gmail.com',     'Asghar Mall, Rwp',        TRUE),
('Sana Riaz',              '0315-1112223', 'sana@gmail.com',       'Bahria Town Ph1, Rwp',    TRUE),
('Adeel Zaman',            '0300-2223334', 'adeel@gmail.com',      'Clifton, Rwp',            TRUE),
('Dr. Bushra Niazi',       '0312-3334445', 'bushra@bui.edu.pk',    'F-10, Islamabad',         TRUE),
('Pharmacist Raza Haider', '0345-4445556', 'raza@pharma.pk',       'I-10, Islamabad',         TRUE);

-- DOCTOR (person_id 1,2,3,12,21)
INSERT INTO DOCTOR (person_id, specialization, license_no, license_expiry) VALUES
(1,  'General Physician', 'PMC-001122', '2026-12-31'),
(2,  'Cardiologist',      'PMC-002233', '2025-12-31'),
(3,  'Dermatologist',     'PMC-003344', '2027-06-30'),
(12, 'Neurologist',       'PMC-012121', '2026-09-30'),
(21, 'Pulmonologist',     'PMC-021212', '2025-09-30');

-- PHARMACIST (person_id 4,5,13,22)
INSERT INTO PHARMACIST (person_id, license_no, license_expiry) VALUES
(4,  'PPC-441144', '2026-03-31'),
(5,  'PPC-552255', '2025-11-30'),
(13, 'PPC-131313', '2027-01-31'),
(22, 'PPC-221122', '2026-07-31');

-- CUSTOMER (person_id 6-11, 14-20)
INSERT INTO CUSTOMER (person_id, loyalty_points) VALUES
(6,  150),
(7,  320),
(8,  80),
(9,  500),
(10, 0),
(11, 210),
(14, 450),
(15, 90),
(16, 640),
(17, 25),
(18, 310),
(19, 180),
(20, 720);

-- MEDICINE
INSERT INTO MEDICINE (name, manufacturer, unit_price, category, is_active) VALUES
('Panadol 500mg',       'GSK Pakistan',      15.00,   'Analgesic',         TRUE),
('Augmentin 625mg',     'GSK Pakistan',      180.00,  'Antibiotic',        TRUE),
('Insulin Glargine',    'Sanofi Pakistan',   850.00,  'Antidiabetic',      TRUE),
('Lipitor 20mg',        'Pfizer Pakistan',   230.00,  'Lipid Lowering',    TRUE),
('Brufen 400mg',        'Abbott Pakistan',   25.00,   'Anti-inflammatory', TRUE),
('Norflox 400mg',       'OBS Pakistan',      60.00,   'Antibiotic',        TRUE),
('Omeprazole 20mg',     'Hilton Pharma',     45.00,   'Antacid',           TRUE),
('Ventolin Inhaler',    'GSK Pakistan',      320.00,  'Bronchodilator',    TRUE),
('Metformin 500mg',     'Getz Pharma',       35.00,   'Antidiabetic',      TRUE),
('Alprazolam 0.5mg',    'Searle Pakistan',   55.00,   'Anxiolytic',        TRUE),
('Cough Syrup Benylin', 'J&J Pakistan',      95.00,   'Cough Suppressant', TRUE),
('Vitamin C 500mg',     'Heltone Pharma',    20.00,   'Supplement',        TRUE),
('Amlodipine 5mg',      'CCL Pharma',        40.00,   'Antihypertensive',  TRUE),
('Warfarin 5mg',        'Ferozsons Pharma',  75.00,   'Anticoagulant',     TRUE),
('Cetirizine 10mg',     'Sami Pharma',       18.00,   'Antihistamine',     TRUE),
('Codeine Phosphate',   'Sanofi Pakistan',   120.00,  'Opioid Analgesic',  TRUE),
('Flagyl 400mg',        'Sanofi Pakistan',   30.00,   'Antiprotozoal',     TRUE),
('Diazepam 5mg',        'Roche Pakistan',    65.00,   'Sedative',          TRUE),
('Bisoprolol 5mg',      'Novartis Pakistan', 90.00,   'Beta Blocker',      TRUE),
('Salbutamol Syrup',    'GSK Pakistan',      55.00,   'Bronchodilator',    TRUE),
('Calcium Sandoz',      'Novartis Pakistan', 110.00,  'Supplement',        TRUE),
('Lantus SoloStar',     'Sanofi Pakistan',   1200.00, 'Antidiabetic',      TRUE);

-- OTC_MEDICINE
INSERT INTO OTC_MEDICINE (medicine_id, shelf_category, age_restriction) VALUES
(1,  'Pain Relief',         NULL),
(5,  'Pain Relief',         NULL),
(7,  'Digestive',           NULL),
(11, 'Cold & Flu',          'Under 12 consult doctor'),
(12, 'Vitamins',            NULL),
(15, 'Allergy',             NULL),
(17, 'Digestive',           NULL),
(20, 'Respiratory',         'Under 6 consult doctor'),
(21, 'Vitamins & Minerals', NULL);

-- PRESC_MEDICINE
INSERT INTO PRESC_MEDICINE (medicine_id, max_dose, schedule_class, is_controlled) VALUES
(2,  '3 times/day',   'Schedule-H', FALSE),
(3,  'As prescribed', 'Schedule-H', FALSE),
(4,  '1 time/day',    'Schedule-H', FALSE),
(6,  '2 times/day',   'Schedule-H', FALSE),
(8,  'As needed',     'Schedule-H', FALSE),
(9,  '2 times/day',   'Schedule-H', FALSE),
(10, '1 time/day',    'Schedule-X', TRUE),
(13, '1 time/day',    'Schedule-H', FALSE),
(14, '1 time/day',    'Schedule-H', TRUE),
(16, '4-6 hourly',    'Schedule-X', TRUE),
(18, '1-2 times/day', 'Schedule-X', TRUE),
(19, '1 time/day',    'Schedule-H', FALSE),
(22, 'As prescribed', 'Schedule-H', FALSE);

-- SUPPLIER
INSERT INTO SUPPLIER (name, phone, email, contact_person, contract_start, contract_end, is_active) VALUES
('MedCo Distributors',     '051-1112223', 'medco@dist.pk',     'Arif Butt',    '2024-01-01', '2025-12-31', TRUE),
('Pharma Plus Supply',     '051-2223334', 'pharmaplus@pk',     'Yasmin Tariq', '2024-03-01', '2026-03-01', TRUE),
('HealthLine Wholesalers', '051-3334445', 'hlwholesale@pk',    'Junaid Mir',   '2023-06-01', '2025-06-01', TRUE),
('UniMed Imports',         '051-4445556', 'unimed@imports.pk', 'Shahid Nazir', '2024-07-01', NULL,         TRUE),
('CureMart Pvt Ltd',       '051-5556667', 'curemart@pk',       'Lubna Awan',   '2024-01-15', '2025-12-31', TRUE),
('AlphaPharma Logistics',  '051-6667778', 'alpha@pharma.pk',   'Raza Khan',    '2023-09-01', NULL,         TRUE),
('SkyMed Solutions',       '051-7778889', 'skymed@sol.pk',     'Munir Ahmed',  '2024-04-01', '2026-04-01', TRUE),
('NovaDrug Dealers',       '051-8889990', 'nova@drug.pk',      'Faisal Karim', '2024-02-01', '2026-02-01', TRUE),
('GreenLeaf Medical',      '051-9990001', 'greenleaf@med.pk',  'Amna Bashir',  '2023-12-01', NULL,         TRUE),
('CarePlus Distribution',  '051-0001112', 'careplus@dist.pk',  'Naveed Shah',  '2024-08-01', '2026-08-01', TRUE);

-- PURCHASE_ORDER
INSERT INTO PURCHASE_ORDER (supplier_id, medicine_id, quantity_ordered, unit_cost, status, ordered_at, received_at, created_by) VALUES
(1,  1,   500, 12.00,   'Received',  '2025-01-10', '2025-01-15', 'Hina Baig'),
(2,  2,   200, 160.00,  'Received',  '2025-01-12', '2025-01-18', 'Hina Baig'),
(3,  3,    50, 800.00,  'Received',  '2025-01-20', '2025-01-25', 'Usman Ali'),
(4,  4,   150, 210.00,  'Ordered',   '2025-02-01', NULL,         'Hina Baig'),
(5,  5,   400, 22.00,   'Received',  '2025-01-05', '2025-01-10', 'Usman Ali'),
(6,  6,   300, 55.00,   'Received',  '2025-01-15', '2025-01-20', 'Zara Javed'),
(7,  8,    80, 290.00,  'Received',  '2025-01-22', '2025-01-28', 'Zara Javed'),
(8,  10,  100, 50.00,   'Received',  '2025-01-30', '2025-02-05', 'Raza Haider'),
(9,  14,   60, 70.00,   'Ordered',   '2025-02-10', NULL,         'Raza Haider'),
(10, 16,  120, 110.00,  'Cancelled', '2025-01-18', NULL,         'Usman Ali'),
(1,  12,  300, 18.00,   'Received',  '2025-01-08', '2025-01-13', 'Hina Baig'),
(2,  15,  250, 16.00,   'Received',  '2025-01-25', '2025-02-01', 'Hina Baig'),
(3,  9,   400, 32.00,   'Ordered',   '2025-02-15', NULL,         'Usman Ali'),
(4,  19,  100, 85.00,   'Received',  '2025-01-28', '2025-02-03', 'Zara Javed'),
(5,  22,   30, 1100.00, 'Ordered',   '2025-02-20', NULL,         'Raza Haider'),
(6,  7,   350, 42.00,   'Received',  '2025-01-14', '2025-01-19', 'Raza Haider'),
(7,  13,  180, 37.00,   'Received',  '2025-01-17', '2025-01-22', 'Zara Javed'),
(8,  18,   80, 60.00,   'Received',  '2025-02-03', '2025-02-08', 'Raza Haider'),
(9,  11,  200, 88.00,   'Received',  '2025-01-23', '2025-01-29', 'Hina Baig'),
(10, 20,  160, 50.00,   'Received',  '2025-01-26', '2025-02-01', 'Usman Ali'),
(1,  17,  300, 27.00,   'Received',  '2025-01-11', '2025-01-16', 'Hina Baig'),
(2,  21,  120, 105.00,  'Ordered',   '2025-02-18', NULL,         'Zara Javed');

-- INVENTORY
INSERT INTO INVENTORY (medicine_id, quantity, monitor_level, expiry_date, last_restocked, updated_by) VALUES
(1,  480, 50, '2027-06-01', '2025-01-15', 'Hina Baig'),
(2,  195, 30, '2026-12-01', '2025-01-18', 'Hina Baig'),
(3,   48, 10, '2026-03-01', '2025-01-25', 'Usman Ali'),
(4,  148, 20, '2027-01-01', NOW(),        'Hina Baig'),
(5,  390, 50, '2026-09-01', '2025-01-10', 'Usman Ali'),
(6,  295, 30, '2026-07-01', '2025-01-20', 'Zara Javed'),
(7,  342, 40, '2026-11-01', '2025-01-19', 'Raza Haider'),
(8,   78, 10, '2026-04-01', '2025-01-28', 'Zara Javed'),
(9,    8, 20, '2026-08-01', NOW(),        'Usman Ali'),   -- LOW STOCK
(10,  98, 15, '2026-02-01', '2025-02-05', 'Raza Haider'),
(11, 198, 25, '2025-10-01', '2025-01-29', 'Hina Baig'),
(12, 295, 30, '2027-03-01', '2025-01-13', 'Hina Baig'),
(13, 177, 20, '2026-06-01', '2025-01-22', 'Zara Javed'),
(14,  58, 10, '2026-10-01', NOW(),        'Raza Haider'),
(15, 245, 30, '2026-05-01', '2025-02-01', 'Hina Baig'),
(16, 118, 15, '2025-12-01', NOW(),        'Raza Haider'),
(17, 295, 30, '2026-08-01', '2025-01-16', 'Hina Baig'),
(18,  77, 10, '2027-02-01', '2025-02-08', 'Raza Haider'),
(19,  98, 15, '2026-07-01', '2025-02-03', 'Zara Javed'),
(20, 158, 20, '2025-11-01', '2025-02-01', 'Usman Ali'),
(21, 118, 15, '2026-09-01', NOW(),        'Zara Javed'),
(22,  28,  5, '2025-08-01', NOW(),        'Raza Haider');

-- PRESCRIPTION
INSERT INTO PRESCRIPTION (doctor_id, customer_id, pharmacist_id, status, prescribed_date, expiry_date, dispensed_at, updated_by) VALUES
(1, 1,  1, 'Dispensed', '2025-01-05', '2025-04-05', '2025-01-06 10:30', 'Hina Baig'),
(2, 2,  2, 'Dispensed', '2025-01-08', '2025-04-08', '2025-01-09 11:00', 'Usman Ali'),
(3, 3,  1, 'Pending',   '2025-02-01', '2025-05-01', NULL,               NULL),
(1, 4,  3, 'Dispensed', '2025-01-15', '2025-04-15', '2025-01-16 09:15', 'Zara Javed'),
(4, 5,  4, 'Dispensed', '2025-01-20', '2025-04-20', '2025-01-21 14:00', 'Raza Haider'),
(2, 6,  2, 'Expired',   '2024-11-01', '2025-02-01', NULL,               NULL),
(5, 7,  1, 'Dispensed', '2025-02-02', '2025-05-02', '2025-02-03 10:00', 'Hina Baig'),
(3, 8,  3, 'Pending',   '2025-02-10', '2025-05-10', NULL,               NULL),
(1, 9,  4, 'Dispensed', '2025-01-28', '2025-04-28', '2025-01-29 16:30', 'Raza Haider'),
(4, 10, 2, 'Dispensed', '2025-02-05', '2025-05-05', '2025-02-06 11:45', 'Usman Ali'),
(2, 11, 1, 'Dispensed', '2025-01-18', '2025-04-18', '2025-01-19 09:00', 'Hina Baig'),
(5, 1,  3, 'Pending',   '2025-02-15', '2025-05-15', NULL,               NULL),
(1, 2,  2, 'Dispensed', '2025-01-25', '2025-04-25', '2025-01-26 13:00', 'Usman Ali'),
(3, 3,  4, 'Dispensed', '2025-02-08', '2025-05-08', '2025-02-09 10:30', 'Raza Haider'),
(4, 4,  1, 'Pending',   '2025-02-18', '2025-05-18', NULL,               NULL),
(2, 5,  3, 'Dispensed', '2025-01-10', '2025-04-10', '2025-01-11 15:00', 'Zara Javed'),
(1, 6,  2, 'Dispensed', '2025-01-22', '2025-04-22', '2025-01-23 11:15', 'Usman Ali'),
(5, 7,  4, 'Expired',   '2024-10-15', '2025-01-15', NULL,               NULL),
(3, 8,  1, 'Dispensed', '2025-02-12', '2025-05-12', '2025-02-13 09:45', 'Hina Baig'),
(4, 9,  2, 'Pending',   '2025-02-20', '2025-05-20', NULL,               NULL),
(1, 10, 3, 'Dispensed', '2025-01-30', '2025-04-30', '2025-01-31 10:00', 'Zara Javed'),
(2, 11, 4, 'Dispensed', '2025-02-03', '2025-05-03', '2025-02-04 14:30', 'Raza Haider');

-- PRESC_MED_DETAIL
INSERT INTO PRESC_MED_DETAIL (prescription_id, medicine_id, quantity, dosage_instructions) VALUES
(1,  2,  1, 'Take 1 tablet 3 times a day after meals for 7 days'),
(1,  7,  1, 'Take 1 capsule before breakfast for 2 weeks'),
(2,  4,  1, 'Take 1 tablet once daily with food'),
(2, 13,  1, 'Take 1 tablet once daily in the evening'),
(3, 10,  1, 'Take half tablet at night. Do not exceed dose.'),
(4,  3,  1, 'Inject as per diabetic protocol morning before breakfast'),
(4,  9,  2, 'Take 1 tablet twice daily with meals for 3 months'),
(5, 14,  1, 'Take 1 tablet at same time daily. Monitor INR weekly.'),
(6,  8,  1, 'Use 2 puffs every 4-6 hours as needed for breathlessness'),
(7, 19,  1, 'Take 1 tablet daily at night'),
(7,  4,  1, 'Take 1 tablet once daily with food'),
(8, 18,  1, 'Take 1 tablet at night only when needed. Max 14 days.'),
(9,  2,  1, 'Take 1 tablet 3 times a day after meals for 10 days'),
(9,  6,  1, 'Take 1 tablet twice daily for 5 days'),
(10, 9,  2, 'Take 2 tablets twice daily with meals'),
(10,13,  1, 'Take 1 tablet once daily at bedtime'),
(11,22,  1, 'Inject at bedtime as per physician instruction'),
(12,16,  1, 'Take 1 tablet every 6 hours for pain. Max 4 days.'),
(13, 4,  1, 'Take 1 tablet once daily with food'),
(13, 2,  1, 'Take 1 tablet 3 times a day after meals for 7 days'),
(14, 3,  1, 'Inject as per diabetic protocol'),
(15,14,  1, 'Take 1 tablet at same time daily. Regular INR monitoring.'),
(16, 8,  1, 'Use 2 puffs as needed'),
(16,19,  1, 'Take 1 tablet daily at night for blood pressure'),
(17, 2,  2, 'Take 1 tablet 3 times a day after meals for 7 days'),
(18,10,  1, 'Take half tablet at night. Review in 4 weeks.'),
(19, 6,  1, 'Take 1 tablet twice daily for 5 days'),
(19, 7,  1, 'Take 1 capsule before breakfast'),
(20,22,  1, 'Inject at bedtime per physician instruction'),
(20, 9,  1, 'Take 1 tablet twice daily with meals'),
(21,13,  1, 'Take 1 tablet once daily at bedtime'),
(21,19,  1, 'Take 1 tablet daily for blood pressure'),
(22, 4,  1, 'Take 1 tablet once daily with food'),
(22,14,  1, 'Take 1 tablet at same time daily. INR monitoring required.');

-- INVOICE
INSERT INTO INVOICE (prescription_id, subtotal, tax, total_amount, issued_at) VALUES
(1,   225.00, 0, 225.00,  '2025-01-06'),
(2,   270.00, 0, 270.00,  '2025-01-09'),
(4,   920.00, 0, 920.00,  '2025-01-16'),
(5,    75.00, 0,  75.00,  '2025-01-21'),
(7,   320.00, 0, 320.00,  '2025-02-03'),
(9,   240.00, 0, 240.00,  '2025-01-29'),
(10,   75.00, 0,  75.00,  '2025-02-06'),
(11, 1200.00, 0,1200.00,  '2025-01-19'),
(13,  410.00, 0, 410.00,  '2025-01-26'),
(14,  850.00, 0, 850.00,  '2025-02-09'),
(16,   90.00, 0,  90.00,  '2025-01-11'),
(17,  565.00, 0, 565.00,  '2025-01-23'),
(19,   90.00, 0,  90.00,  '2025-02-13'),
(21,   40.00, 0,  40.00,  '2025-01-31'),
(22, 1290.00, 0,1290.00,  '2025-02-04'),
(NULL, 15.00, 0,  15.00,  '2025-01-14'),
(NULL, 40.00, 0,  40.00,  '2025-01-17'),
(NULL, 20.00, 0,  20.00,  '2025-01-22'),
(NULL, 55.00, 0,  55.00,  '2025-02-01'),
(NULL, 95.00, 0,  95.00,  '2025-02-07'),
(NULL,110.00, 0, 110.00,  '2025-02-11'),
(NULL, 35.00, 0,  35.00,  '2025-02-14');

-- PAYMENT
INSERT INTO PAYMENT (invoice_id, amount_paid, payment_method, payment_date, payment_status) VALUES
(1,   225.00, 'Cash',   '2025-01-06', 'Completed'),
(2,   270.00, 'Card',   '2025-01-09', 'Completed'),
(3,   920.00, 'Cash',   '2025-01-16', 'Completed'),
(4,    75.00, 'Cash',   '2025-01-21', 'Completed'),
(5,   320.00, 'Online', '2025-02-03', 'Completed'),
(6,   240.00, 'Cash',   '2025-01-29', 'Completed'),
(7,    75.00, 'Card',   '2025-02-06', 'Completed'),
(8,  1200.00, 'Online', '2025-01-19', 'Completed'),
(9,   410.00, 'Cash',   '2025-01-26', 'Completed'),
(10,  850.00, 'Card',   '2025-02-09', 'Completed'),
(11,   90.00, 'Cash',   '2025-01-11', 'Completed'),
(12,  565.00, 'Online', '2025-01-23', 'Completed'),
(13,   90.00, 'Cash',   '2025-02-13', 'Completed'),
(14,   40.00, 'Cash',   '2025-01-31', 'Completed'),
(15, 1290.00, 'Card',   '2025-02-04', 'Completed'),
(16,   15.00, 'Cash',   '2025-01-14', 'Completed'),
(17,   40.00, 'Cash',   '2025-01-17', 'Completed'),
(18,   20.00, 'Cash',   '2025-01-22', 'Completed'),
(19,   55.00, 'Card',   '2025-02-01', 'Completed'),
(20,   95.00, 'Cash',   '2025-02-07', 'Completed'),
(21,  110.00, 'Online', '2025-02-11', 'Completed'),
(22,   35.00, 'Cash',   '2025-02-14', 'Completed');

-- ============================================================
-- ENABLE ROW LEVEL SECURITY (Supabase requirement for public access)
-- Run these so the frontend can read data without login
-- ============================================================
ALTER TABLE PERSON           ENABLE ROW LEVEL SECURITY;
ALTER TABLE DOCTOR           ENABLE ROW LEVEL SECURITY;
ALTER TABLE PHARMACIST       ENABLE ROW LEVEL SECURITY;
ALTER TABLE CUSTOMER         ENABLE ROW LEVEL SECURITY;
ALTER TABLE MEDICINE         ENABLE ROW LEVEL SECURITY;
ALTER TABLE OTC_MEDICINE     ENABLE ROW LEVEL SECURITY;
ALTER TABLE PRESC_MEDICINE   ENABLE ROW LEVEL SECURITY;
ALTER TABLE PRESCRIPTION     ENABLE ROW LEVEL SECURITY;
ALTER TABLE PRESC_MED_DETAIL ENABLE ROW LEVEL SECURITY;
ALTER TABLE SUPPLIER         ENABLE ROW LEVEL SECURITY;
ALTER TABLE PURCHASE_ORDER   ENABLE ROW LEVEL SECURITY;
ALTER TABLE INVENTORY        ENABLE ROW LEVEL SECURITY;
ALTER TABLE INVOICE          ENABLE ROW LEVEL SECURITY;
ALTER TABLE PAYMENT          ENABLE ROW LEVEL SECURITY;

-- Allow public read + write (for demo purposes)
CREATE POLICY "public_all" ON PERSON           FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "public_all" ON DOCTOR           FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "public_all" ON PHARMACIST       FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "public_all" ON CUSTOMER         FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "public_all" ON MEDICINE         FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "public_all" ON OTC_MEDICINE     FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "public_all" ON PRESC_MEDICINE   FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "public_all" ON PRESCRIPTION     FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "public_all" ON PRESC_MED_DETAIL FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "public_all" ON SUPPLIER         FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "public_all" ON PURCHASE_ORDER   FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "public_all" ON INVENTORY        FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "public_all" ON INVOICE          FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "public_all" ON PAYMENT          FOR ALL USING (true) WITH CHECK (true);

-- ============================================================
-- QUERY 1: Dispensed Prescriptions
-- ============================================================
-- SELECT DP.name AS DoctorName, D.specialization, CP.name AS CustomerName,
--        PP.name AS PharmacistName, RX.prescribed_date, RX.dispensed_at
-- FROM PRESCRIPTION RX
-- JOIN DOCTOR D ON RX.doctor_id = D.doctor_id ...
-- WHERE RX.status = 'Dispensed'

-- ============================================================
-- QUERY 2: Revenue by Payment Method
-- ============================================================
-- SELECT PAY.payment_method, COUNT(*), SUM(PAY.amount_paid), AVG(PAY.amount_paid)
-- FROM PAYMENT PAY JOIN INVOICE INV ON PAY.invoice_id = INV.invoice_id
-- WHERE PAY.payment_status = 'Completed'
-- GROUP BY PAY.payment_method

-- ============================================================
-- QUERY 3: Low Stock Medicines
-- ============================================================
-- SELECT M.name, INV.quantity, INV.monitor_level, S.name
-- FROM INVENTORY INV JOIN MEDICINE M ... JOIN PURCHASE_ORDER PO ... JOIN SUPPLIER S ...
-- WHERE INV.quantity < INV.monitor_level
