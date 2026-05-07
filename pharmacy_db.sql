-- ============================================================
-- PHARMACY MANAGEMENT SYSTEM - TERM PROJECT
-- Student: Enrollment# 01-134242-007
-- Course: Database Management Systems
-- Instructor: Ali Irfan
-- Bahria University Islamabad
-- ============================================================

-- Create and use the database
CREATE DATABASE PharmacyDB;
GO
USE PharmacyDB;
GO

-- ============================================================
-- DDL: CREATE TABLES
-- ============================================================

-- 1. PERSON (Super Type) -- Person Hierarchy
CREATE TABLE PERSON (
    person_id      INT           PRIMARY KEY IDENTITY(1,1),
    name           VARCHAR(100)  NOT NULL,
    phone          VARCHAR(20)   NOT NULL,
    email          VARCHAR(100)  NULL,
    address        VARCHAR(200)  NULL,
    created_at     DATETIME      DEFAULT GETDATE(),
    updated_at     DATETIME      NULL,
    is_active      BIT           DEFAULT 1
);
GO

-- 2. DOCTOR (Sub Type of PERSON)
CREATE TABLE DOCTOR (
    doctor_id       INT          PRIMARY KEY IDENTITY(1,1),
    person_id       INT          NOT NULL FOREIGN KEY REFERENCES PERSON(person_id),
    specialization  VARCHAR(100) NOT NULL,
    license_no      VARCHAR(50)  NOT NULL,
    license_expiry  DATE         NOT NULL
);
GO

-- 3. PHARMACIST (Sub Type of PERSON)
CREATE TABLE PHARMACIST (
    pharmacist_id  INT          PRIMARY KEY IDENTITY(1,1),
    person_id      INT          NOT NULL FOREIGN KEY REFERENCES PERSON(person_id),
    license_no     VARCHAR(50)  NOT NULL,
    license_expiry DATE         NOT NULL
);
GO

-- 4. CUSTOMER (Sub Type of PERSON)
CREATE TABLE CUSTOMER (
    customer_id    INT   PRIMARY KEY IDENTITY(1,1),
    person_id      INT   NOT NULL FOREIGN KEY REFERENCES PERSON(person_id),
    loyalty_points INT   DEFAULT 0
);
GO

-- 5. MEDICINE (Super Type) -- Medicine Hierarchy
CREATE TABLE MEDICINE (
    medicine_id  INT           PRIMARY KEY IDENTITY(1,1),
    name         VARCHAR(150)  NOT NULL,
    manufacturer VARCHAR(150)  NOT NULL,
    unit_price   SMALLMONEY    NOT NULL,
    category     VARCHAR(100)  NOT NULL,
    created_at   DATETIME      DEFAULT GETDATE(),
    updated_at   DATETIME      NULL,
    is_active    BIT           DEFAULT 1
);
GO

-- 6. OTC_MEDICINE (Sub Type of MEDICINE - Over The Counter)
CREATE TABLE OTC_MEDICINE (
    medicine_id     INT          PRIMARY KEY FOREIGN KEY REFERENCES MEDICINE(medicine_id),
    shelf_category  VARCHAR(100) NOT NULL,
    age_restriction VARCHAR(50)  NULL
);
GO

-- 7. PRESC_MEDICINE (Sub Type of MEDICINE - Prescription Only)
CREATE TABLE PRESC_MEDICINE (
    medicine_id    INT          PRIMARY KEY FOREIGN KEY REFERENCES MEDICINE(medicine_id),
    max_dose       VARCHAR(50)  NOT NULL,
    schedule_class VARCHAR(50)  NOT NULL,
    is_controlled  BIT          DEFAULT 0
);
GO

-- 8. PRESCRIPTION
CREATE TABLE PRESCRIPTION (
    prescription_id  INT           PRIMARY KEY IDENTITY(1,1),
    doctor_id        INT           NOT NULL FOREIGN KEY REFERENCES DOCTOR(doctor_id),
    customer_id      INT           NOT NULL FOREIGN KEY REFERENCES CUSTOMER(customer_id),
    pharmacist_id    INT           NULL FOREIGN KEY REFERENCES PHARMACIST(pharmacist_id),
    status           VARCHAR(30)   DEFAULT 'Pending',   -- Pending, Dispensed, Expired
    prescribed_date  DATE          NOT NULL,
    expiry_date      DATE          NOT NULL,
    dispensed_at     DATETIME      NULL,
    created_at       DATETIME      DEFAULT GETDATE(),
    updated_at       DATETIME      NULL,
    updated_by       VARCHAR(100)  NULL
);
GO

-- 9. PRESC_MED_DETAIL (Bridge between PRESCRIPTION and MEDICINE)
CREATE TABLE PRESC_MED_DETAIL (
    prescription_id     INT          NOT NULL FOREIGN KEY REFERENCES PRESCRIPTION(prescription_id),
    medicine_id         INT          NOT NULL FOREIGN KEY REFERENCES MEDICINE(medicine_id),
    quantity            INT          NOT NULL,
    dosage_instructions VARCHAR(300) NOT NULL,
    added_at            DATETIME     DEFAULT GETDATE(),
    modified_at         DATETIME     NULL,
    PRIMARY KEY (prescription_id, medicine_id)
);
GO

-- 10. SUPPLIER
CREATE TABLE SUPPLIER (
    supplier_id    INT           PRIMARY KEY IDENTITY(1,1),
    name           VARCHAR(150)  NOT NULL,
    phone          VARCHAR(20)   NOT NULL,
    email          VARCHAR(100)  NULL,
    contact_person VARCHAR(100)  NOT NULL,
    contract_start DATE          NOT NULL,
    contract_end   DATE          NULL,
    is_active      BIT           DEFAULT 1
);
GO

-- 11. PURCHASE_ORDER (Procurement)
CREATE TABLE PURCHASE_ORDER (
    po_id           INT          PRIMARY KEY IDENTITY(1,1),
    supplier_id     INT          NOT NULL FOREIGN KEY REFERENCES SUPPLIER(supplier_id),
    medicine_id     INT          NOT NULL FOREIGN KEY REFERENCES MEDICINE(medicine_id),
    quantity_ordered INT         NOT NULL,
    unit_cost        SMALLMONEY  NOT NULL,
    status          VARCHAR(30)  DEFAULT 'Ordered',   -- Ordered, Received, Cancelled
    ordered_at      DATETIME     DEFAULT GETDATE(),
    received_at     DATETIME     NULL,
    created_by      VARCHAR(100) NOT NULL
);
GO

-- 12. INVENTORY
CREATE TABLE INVENTORY (
    inventory_id    INT          PRIMARY KEY IDENTITY(1,1),
    medicine_id     INT          NOT NULL FOREIGN KEY REFERENCES MEDICINE(medicine_id),
    quantity        INT          NOT NULL DEFAULT 0,
    monitor_level   INT          NOT NULL DEFAULT 10,   -- reorder threshold
    expiry_date     DATE         NULL,
    last_restocked  DATETIME     NULL,
    updated_at      DATETIME     DEFAULT GETDATE(),
    updated_by      VARCHAR(100) NOT NULL
);
GO

-- 13. INVOICE (Billing)
CREATE TABLE INVOICE (
    invoice_id      INT          PRIMARY KEY IDENTITY(1,1),
    prescription_id INT          NULL FOREIGN KEY REFERENCES PRESCRIPTION(prescription_id),
    subtotal        SMALLMONEY   NOT NULL,
    tax             SMALLMONEY   DEFAULT 0,
    total_amount    SMALLMONEY   NOT NULL,
    issued_at       DATETIME     DEFAULT GETDATE(),
    updated_at      DATETIME     NULL
);
GO

-- 14. PAYMENT
CREATE TABLE PAYMENT (
    payment_id      INT          PRIMARY KEY IDENTITY(1,1),
    invoice_id      INT          NOT NULL FOREIGN KEY REFERENCES INVOICE(invoice_id),
    amount_paid     SMALLMONEY   NOT NULL,
    payment_method  VARCHAR(50)  NOT NULL,   -- Cash, Card, Online
    payment_date    DATETIME     DEFAULT GETDATE(),
    payment_status  VARCHAR(30)  DEFAULT 'Completed',
    refunded_at     DATETIME     NULL
);
GO

-- ============================================================
-- DML: INSERT DATA (minimum 20 rows per table)
-- ============================================================

-- PERSON
INSERT INTO PERSON (name, phone, email, address, created_at, is_active) VALUES
('Dr. Salman Raza',       '0321-1001001', 'salman@bui.edu.pk',    'F-8/1, Islamabad',       GETDATE(), 1),
('Dr. Ayesha Nawaz',      '0333-2002002', 'ayesha@bui.edu.pk',    'G-10, Islamabad',        GETDATE(), 1),
('Dr. Tariq Mehmood',     '0300-3003003', 'tariq@bui.edu.pk',     'E-11, Islamabad',        GETDATE(), 1),
('Pharmacist Hina Baig',  '0315-4004004', 'hina@pharma.pk',       'Bahria Town, Rwp',       GETDATE(), 1),
('Pharmacist Usman Ali',  '0321-5005005', 'usman@pharma.pk',      'DHA Phase 2, Rwp',       GETDATE(), 1),
('Ahmed Siddiqui',        '0312-6006006', 'ahmed@gmail.com',      'I-8/2, Islamabad',       GETDATE(), 1),
('Fatima Malik',          '0301-7007007', 'fatima@gmail.com',     'Saddar, Rawalpindi',     GETDATE(), 1),
('Bilal Cheema',          '0345-8008008', 'bilal@gmail.com',      'Wah Cantt',              GETDATE(), 1),
('Sara Hussain',          '0323-9009009', 'sara@gmail.com',       'Chaklala, Rwp',          GETDATE(), 1),
('Imran Farooq',          '0336-1010101', 'imran@gmail.com',      'Satellite Town, Rwp',    GETDATE(), 1),
('Nadia Iqbal',           '0311-2020202', 'nadia@gmail.com',      'Khanna Pul, Rwp',        GETDATE(), 1),
('Dr. Kamran Shah',       '0322-3030303', 'kamran@bui.edu.pk',    'H-13, Islamabad',        GETDATE(), 1),
('Pharmacist Zara Javed', '0313-4040404', 'zara@pharma.pk',       'G-9, Islamabad',         GETDATE(), 1),
('Omer Bashir',           '0331-5050505', 'omer@gmail.com',       'Tench Bhata, Rwp',       GETDATE(), 1),
('Rabia Qureshi',         '0344-6060606', 'rabia@gmail.com',      'Gulzar-e-Quaid, Rwp',    GETDATE(), 1),
('Hamza Waqas',           '0302-7070707', 'hamza@gmail.com',      'PWD Colony, Islamabad',  GETDATE(), 1),
('Maryam Shafiq',         '0321-8080808', 'maryam@gmail.com',     'Morgah, Rwp',            GETDATE(), 1),
('Khalid Rehman',         '0333-9090909', 'khalid@gmail.com',     'Asghar Mall, Rwp',       GETDATE(), 1),
('Sana Riaz',             '0315-1112223', 'sana@gmail.com',       'Bahria Town Ph1, Rwp',   GETDATE(), 1),
('Adeel Zaman',           '0300-2223334', 'adeel@gmail.com',      'Clifton, Rwp',           GETDATE(), 1),
('Dr. Bushra Niazi',      '0312-3334445', 'bushra@bui.edu.pk',    'F-10, Islamabad',        GETDATE(), 1),
('Pharmacist Raza Haider','0345-4445556', 'raza@pharma.pk',       'I-10, Islamabad',        GETDATE(), 1);
GO

-- DOCTOR (person_id 1,2,3,12,21)
INSERT INTO DOCTOR (person_id, specialization, license_no, license_expiry) VALUES
(1,  'General Physician',  'PMC-001122', '2026-12-31'),
(2,  'Cardiologist',       'PMC-002233', '2025-12-31'),
(3,  'Dermatologist',      'PMC-003344', '2027-06-30'),
(12, 'Neurologist',        'PMC-012121', '2026-09-30'),
(21, 'Pulmonologist',      'PMC-021212', '2025-09-30');
GO

-- PHARMACIST (person_id 4,5,13,22)
INSERT INTO PHARMACIST (person_id, license_no, license_expiry) VALUES
(4,  'PPC-441144', '2026-03-31'),
(5,  'PPC-552255', '2025-11-30'),
(13, 'PPC-131313', '2027-01-31'),
(22, 'PPC-221122', '2026-07-31');
GO

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
GO

-- MEDICINE
INSERT INTO MEDICINE (name, manufacturer, unit_price, category, created_at, is_active) VALUES
('Panadol 500mg',        'GSK Pakistan',       15.00,  'Analgesic',         GETDATE(), 1),
('Augmentin 625mg',      'GSK Pakistan',       180.00, 'Antibiotic',        GETDATE(), 1),
('Insulin Glargine',     'Sanofi Pakistan',    850.00, 'Antidiabetic',      GETDATE(), 1),
('Lipitor 20mg',         'Pfizer Pakistan',    230.00, 'Lipid Lowering',    GETDATE(), 1),
('Brufen 400mg',         'Abbott Pakistan',    25.00,  'Anti-inflammatory', GETDATE(), 1),
('Norflox 400mg',        'OBS Pakistan',       60.00,  'Antibiotic',        GETDATE(), 1),
('Omeprazole 20mg',      'Hilton Pharma',      45.00,  'Antacid',           GETDATE(), 1),
('Ventolin Inhaler',     'GSK Pakistan',       320.00, 'Bronchodilator',    GETDATE(), 1),
('Metformin 500mg',      'Getz Pharma',        35.00,  'Antidiabetic',      GETDATE(), 1),
('Alprazolam 0.5mg',     'Searle Pakistan',    55.00,  'Anxiolytic',        GETDATE(), 1),
('Cough Syrup Benylin',  'J&J Pakistan',       95.00,  'Cough Suppressant', GETDATE(), 1),
('Vitamin C 500mg',      'Heltone Pharma',     20.00,  'Supplement',        GETDATE(), 1),
('Amlodipine 5mg',       'CCL Pharma',         40.00,  'Antihypertensive',  GETDATE(), 1),
('Warfarin 5mg',         'Ferozsons Pharma',   75.00,  'Anticoagulant',     GETDATE(), 1),
('Cetirizine 10mg',      'Sami Pharma',        18.00,  'Antihistamine',     GETDATE(), 1),
('Codeine Phosphate',    'Sanofi Pakistan',    120.00, 'Opioid Analgesic',  GETDATE(), 1),
('Flagyl 400mg',         'Sanofi Pakistan',    30.00,  'Antiprotozoal',     GETDATE(), 1),
('Diazepam 5mg',         'Roche Pakistan',     65.00,  'Sedative',          GETDATE(), 1),
('Bisoprolol 5mg',       'Novartis Pakistan',  90.00,  'Beta Blocker',      GETDATE(), 1),
('Salbutamol Syrup',     'GSK Pakistan',       55.00,  'Bronchodilator',    GETDATE(), 1),
('Calcium Sandoz',       'Novartis Pakistan',  110.00, 'Supplement',        GETDATE(), 1),
('Lantus SoloStar',      'Sanofi Pakistan',    1200.00,'Antidiabetic',      GETDATE(), 1);
GO

-- OTC_MEDICINE (medicine_id: 1,5,7,11,12,15,17,20,21)
INSERT INTO OTC_MEDICINE (medicine_id, shelf_category, age_restriction) VALUES
(1,  'Pain Relief',       NULL),
(5,  'Pain Relief',       NULL),
(7,  'Digestive',         NULL),
(11, 'Cold & Flu',        'Under 12 consult doctor'),
(12, 'Vitamins',          NULL),
(15, 'Allergy',           NULL),
(17, 'Digestive',         NULL),
(20, 'Respiratory',       'Under 6 consult doctor'),
(21, 'Vitamins & Minerals', NULL);
GO

-- PRESC_MEDICINE (medicine_id: 2,3,4,6,8,9,10,13,14,16,18,19,22)
INSERT INTO PRESC_MEDICINE (medicine_id, max_dose, schedule_class, is_controlled) VALUES
(2,  '3 times/day',  'Schedule-H',  0),
(3,  'As prescribed','Schedule-H',  0),
(4,  '1 time/day',   'Schedule-H',  0),
(6,  '2 times/day',  'Schedule-H',  0),
(8,  'As needed',    'Schedule-H',  0),
(9,  '2 times/day',  'Schedule-H',  0),
(10, '1 time/day',   'Schedule-X',  1),
(13, '1 time/day',   'Schedule-H',  0),
(14, '1 time/day',   'Schedule-H',  1),
(16, '4-6 hourly',   'Schedule-X',  1),
(18, '1-2 times/day','Schedule-X',  1),
(19, '1 time/day',   'Schedule-H',  0),
(22, 'As prescribed','Schedule-H',  0);
GO

-- SUPPLIER
INSERT INTO SUPPLIER (name, phone, email, contact_person, contract_start, contract_end, is_active) VALUES
('MedCo Distributors',     '051-1112223', 'medco@dist.pk',     'Arif Butt',    '2024-01-01', '2025-12-31', 1),
('Pharma Plus Supply',     '051-2223334', 'pharmaplus@pk',     'Yasmin Tariq', '2024-03-01', '2026-03-01', 1),
('HealthLine Wholesalers', '051-3334445', 'hlwholesale@pk',    'Junaid Mir',   '2023-06-01', '2025-06-01', 1),
('UniMed Imports',         '051-4445556', 'unimed@imports.pk', 'Shahid Nazir', '2024-07-01', NULL,         1),
('CureMart Pvt Ltd',       '051-5556667', 'curemart@pk',       'Lubna Awan',   '2024-01-15', '2025-12-31', 1),
('AlphaPharma Logistics',  '051-6667778', 'alpha@pharma.pk',   'Raza Khan',    '2023-09-01', NULL,         1),
('SkyMed Solutions',       '051-7778889', 'skymed@sol.pk',     'Munir Ahmed',  '2024-04-01', '2026-04-01', 1),
('NovaDrug Dealers',       '051-8889990', 'nova@drug.pk',      'Faisal Karim', '2024-02-01', '2026-02-01', 1),
('GreenLeaf Medical',      '051-9990001', 'greenleaf@med.pk',  'Amna Bashir',  '2023-12-01', NULL,         1),
('CarePlus Distribution',  '051-0001112', 'careplus@dist.pk',  'Naveed Shah',  '2024-08-01', '2026-08-01', 1);
GO

-- PURCHASE_ORDER
INSERT INTO PURCHASE_ORDER (supplier_id, medicine_id, quantity_ordered, unit_cost, status, ordered_at, received_at, created_by) VALUES
(1, 1,  500, 12.00,  'Received',   '2025-01-10', '2025-01-15', 'Hina Baig'),
(2, 2,  200, 160.00, 'Received',   '2025-01-12', '2025-01-18', 'Hina Baig'),
(3, 3,   50, 800.00, 'Received',   '2025-01-20', '2025-01-25', 'Usman Ali'),
(4, 4,  150, 210.00, 'Ordered',    '2025-02-01', NULL,         'Hina Baig'),
(5, 5,  400, 22.00,  'Received',   '2025-01-05', '2025-01-10', 'Usman Ali'),
(6, 6,  300, 55.00,  'Received',   '2025-01-15', '2025-01-20', 'Zara Javed'),
(7, 8,   80, 290.00, 'Received',   '2025-01-22', '2025-01-28', 'Zara Javed'),
(8, 10, 100, 50.00,  'Received',   '2025-01-30', '2025-02-05', 'Raza Haider'),
(9, 14,  60, 70.00,  'Ordered',    '2025-02-10', NULL,         'Raza Haider'),
(10,16, 120, 110.00, 'Cancelled',  '2025-01-18', NULL,         'Usman Ali'),
(1, 12, 300, 18.00,  'Received',   '2025-01-08', '2025-01-13', 'Hina Baig'),
(2, 15, 250, 16.00,  'Received',   '2025-01-25', '2025-02-01', 'Hina Baig'),
(3, 9,  400, 32.00,  'Ordered',    '2025-02-15', NULL,         'Usman Ali'),
(4, 19, 100, 85.00,  'Received',   '2025-01-28', '2025-02-03', 'Zara Javed'),
(5, 22,  30, 1100.00,'Ordered',    '2025-02-20', NULL,         'Raza Haider'),
(6, 7,  350, 42.00,  'Received',   '2025-01-14', '2025-01-19', 'Raza Haider'),
(7, 13, 180, 37.00,  'Received',   '2025-01-17', '2025-01-22', 'Zara Javed'),
(8, 18,  80, 60.00,  'Received',   '2025-02-03', '2025-02-08', 'Raza Haider'),
(9, 11, 200, 88.00,  'Received',   '2025-01-23', '2025-01-29', 'Hina Baig'),
(10,20, 160, 50.00,  'Received',   '2025-01-26', '2025-02-01', 'Usman Ali'),
(1, 17, 300, 27.00,  'Received',   '2025-01-11', '2025-01-16', 'Hina Baig'),
(2, 21, 120, 105.00, 'Ordered',    '2025-02-18', NULL,         'Zara Javed');
GO

-- INVENTORY
INSERT INTO INVENTORY (medicine_id, quantity, monitor_level, expiry_date, last_restocked, updated_at, updated_by) VALUES
(1,  480, 50,  '2027-06-01', '2025-01-15', GETDATE(), 'Hina Baig'),
(2,  195, 30,  '2026-12-01', '2025-01-18', GETDATE(), 'Hina Baig'),
(3,   48, 10,  '2026-03-01', '2025-01-25', GETDATE(), 'Usman Ali'),
(4,  148, 20,  '2027-01-01', GETDATE(),    GETDATE(), 'Hina Baig'),
(5,  390, 50,  '2026-09-01', '2025-01-10', GETDATE(), 'Usman Ali'),
(6,  295, 30,  '2026-07-01', '2025-01-20', GETDATE(), 'Zara Javed'),
(7,  342, 40,  '2026-11-01', '2025-01-19', GETDATE(), 'Raza Haider'),
(8,   78, 10,  '2026-04-01', '2025-01-28', GETDATE(), 'Zara Javed'),
(9,    8, 20,  '2026-08-01', GETDATE(),    GETDATE(), 'Usman Ali'),   -- LOW STOCK
(10, 98,  15,  '2026-02-01', '2025-02-05', GETDATE(), 'Raza Haider'),
(11, 198, 25,  '2025-10-01', '2025-01-29', GETDATE(), 'Hina Baig'),
(12, 295, 30,  '2027-03-01', '2025-01-13', GETDATE(), 'Hina Baig'),
(13, 177, 20,  '2026-06-01', '2025-01-22', GETDATE(), 'Zara Javed'),
(14,  58, 10,  '2026-10-01', GETDATE(),    GETDATE(), 'Raza Haider'),
(15, 245, 30,  '2026-05-01', '2025-02-01', GETDATE(), 'Hina Baig'),
(16, 118, 15,  '2025-12-01', GETDATE(),    GETDATE(), 'Raza Haider'),
(17, 295, 30,  '2026-08-01', '2025-01-16', GETDATE(), 'Hina Baig'),
(18,  77, 10,  '2027-02-01', '2025-02-08', GETDATE(), 'Raza Haider'),
(19,  98, 15,  '2026-07-01', '2025-02-03', GETDATE(), 'Zara Javed'),
(20, 158, 20,  '2025-11-01', '2025-02-01', GETDATE(), 'Usman Ali'),
(21, 118, 15,  '2026-09-01', GETDATE(),    GETDATE(), 'Zara Javed'),
(22,  28, 5,   '2025-08-01', GETDATE(),    GETDATE(), 'Raza Haider');
GO

-- PRESCRIPTION
INSERT INTO PRESCRIPTION (doctor_id, customer_id, pharmacist_id, status, prescribed_date, expiry_date, dispensed_at, created_at, updated_by) VALUES
(1, 1,  1, 'Dispensed', '2025-01-05', '2025-04-05', '2025-01-06 10:30', GETDATE(), 'Hina Baig'),
(2, 2,  2, 'Dispensed', '2025-01-08', '2025-04-08', '2025-01-09 11:00', GETDATE(), 'Usman Ali'),
(3, 3,  1, 'Pending',   '2025-02-01', '2025-05-01', NULL,               GETDATE(), NULL),
(1, 4,  3, 'Dispensed', '2025-01-15', '2025-04-15', '2025-01-16 09:15', GETDATE(), 'Zara Javed'),
(4, 5,  4, 'Dispensed', '2025-01-20', '2025-04-20', '2025-01-21 14:00', GETDATE(), 'Raza Haider'),
(2, 6,  2, 'Expired',   '2024-11-01', '2025-02-01', NULL,               GETDATE(), NULL),
(5, 7,  1, 'Dispensed', '2025-02-02', '2025-05-02', '2025-02-03 10:00', GETDATE(), 'Hina Baig'),
(3, 8,  3, 'Pending',   '2025-02-10', '2025-05-10', NULL,               GETDATE(), NULL),
(1, 9,  4, 'Dispensed', '2025-01-28', '2025-04-28', '2025-01-29 16:30', GETDATE(), 'Raza Haider'),
(4, 10, 2, 'Dispensed', '2025-02-05', '2025-05-05', '2025-02-06 11:45', GETDATE(), 'Usman Ali'),
(2, 11, 1, 'Dispensed', '2025-01-18', '2025-04-18', '2025-01-19 09:00', GETDATE(), 'Hina Baig'),
(5, 1,  3, 'Pending',   '2025-02-15', '2025-05-15', NULL,               GETDATE(), NULL),
(1, 2,  2, 'Dispensed', '2025-01-25', '2025-04-25', '2025-01-26 13:00', GETDATE(), 'Usman Ali'),
(3, 3,  4, 'Dispensed', '2025-02-08', '2025-05-08', '2025-02-09 10:30', GETDATE(), 'Raza Haider'),
(4, 4,  1, 'Pending',   '2025-02-18', '2025-05-18', NULL,               GETDATE(), NULL),
(2, 5,  3, 'Dispensed', '2025-01-10', '2025-04-10', '2025-01-11 15:00', GETDATE(), 'Zara Javed'),
(1, 6,  2, 'Dispensed', '2025-01-22', '2025-04-22', '2025-01-23 11:15', GETDATE(), 'Usman Ali'),
(5, 7,  4, 'Expired',   '2024-10-15', '2025-01-15', NULL,               GETDATE(), NULL),
(3, 8,  1, 'Dispensed', '2025-02-12', '2025-05-12', '2025-02-13 09:45', GETDATE(), 'Hina Baig'),
(4, 9,  2, 'Pending',   '2025-02-20', '2025-05-20', NULL,               GETDATE(), NULL),
(1, 10, 3, 'Dispensed', '2025-01-30', '2025-04-30', '2025-01-31 10:00', GETDATE(), 'Zara Javed'),
(2, 11, 4, 'Dispensed', '2025-02-03', '2025-05-03', '2025-02-04 14:30', GETDATE(), 'Raza Haider');
GO

-- PRESC_MED_DETAIL
INSERT INTO PRESC_MED_DETAIL (prescription_id, medicine_id, quantity, dosage_instructions, added_at) VALUES
(1,  2,  1, 'Take 1 tablet 3 times a day after meals for 7 days',            GETDATE()),
(1,  7,  1, 'Take 1 capsule before breakfast for 2 weeks',                   GETDATE()),
(2,  4,  1, 'Take 1 tablet once daily with food',                            GETDATE()),
(2, 13,  1, 'Take 1 tablet once daily in the evening',                       GETDATE()),
(3, 10,  1, 'Take half tablet at night. Do not exceed dose.',                GETDATE()),
(4,  3,  1, 'Inject as per diabetic protocol morning before breakfast',      GETDATE()),
(4,  9,  2, 'Take 1 tablet twice daily with meals for 3 months',             GETDATE()),
(5, 14,  1, 'Take 1 tablet at same time daily. Monitor INR weekly.',         GETDATE()),
(6,  8,  1, 'Use 2 puffs every 4-6 hours as needed for breathlessness',      GETDATE()),
(7, 19,  1, 'Take 1 tablet daily at night',                                  GETDATE()),
(7,  4,  1, 'Take 1 tablet once daily with food',                            GETDATE()),
(8, 18,  1, 'Take 1 tablet at night only when needed. Max 14 days.',         GETDATE()),
(9,  2,  1, 'Take 1 tablet 3 times a day after meals for 10 days',           GETDATE()),
(9,  6,  1, 'Take 1 tablet twice daily for 5 days',                          GETDATE()),
(10, 9,  2, 'Take 2 tablets twice daily with meals',                         GETDATE()),
(10,13,  1, 'Take 1 tablet once daily at bedtime',                           GETDATE()),
(11,22,  1, 'Inject at bedtime as per physician instruction',                 GETDATE()),
(12,16,  1, 'Take 1 tablet every 6 hours for pain. Max 4 days.',             GETDATE()),
(13, 4,  1, 'Take 1 tablet once daily with food',                            GETDATE()),
(13, 2,  1, 'Take 1 tablet 3 times a day after meals for 7 days',            GETDATE()),
(14, 3,  1, 'Inject as per diabetic protocol',                               GETDATE()),
(15,14,  1, 'Take 1 tablet at same time daily. Regular INR monitoring.',     GETDATE()),
(16, 8,  1, 'Use 2 puffs as needed',                                         GETDATE()),
(16,19,  1, 'Take 1 tablet daily at night for blood pressure',               GETDATE()),
(17, 2,  2, 'Take 1 tablet 3 times a day after meals for 7 days',            GETDATE()),
(18,10,  1, 'Take half tablet at night. Review in 4 weeks.',                 GETDATE()),
(19, 6,  1, 'Take 1 tablet twice daily for 5 days',                          GETDATE()),
(19, 7,  1, 'Take 1 capsule before breakfast',                               GETDATE()),
(20,22,  1, 'Inject at bedtime per physician instruction',                    GETDATE()),
(20, 9,  1, 'Take 1 tablet twice daily with meals',                          GETDATE()),
(21,13,  1, 'Take 1 tablet once daily at bedtime',                           GETDATE()),
(21,19,  1, 'Take 1 tablet daily for blood pressure',                        GETDATE()),
(22, 4,  1, 'Take 1 tablet once daily with food',                            GETDATE()),
(22,14,  1, 'Take 1 tablet at same time daily. INR monitoring required.',    GETDATE());
GO

-- INVOICE
INSERT INTO INVOICE (prescription_id, subtotal, tax, total_amount, issued_at) VALUES
(1,  225.00, 0.00,  225.00, '2025-01-06'),
(2,  270.00, 0.00,  270.00, '2025-01-09'),
(4,  920.00, 0.00,  920.00, '2025-01-16'),
(5,   75.00, 0.00,   75.00, '2025-01-21'),
(7,  320.00, 0.00,  320.00, '2025-02-03'),
(9,  240.00, 0.00,  240.00, '2025-01-29'),
(10,  75.00, 0.00,   75.00, '2025-02-06'),
(11,1200.00, 0.00, 1200.00, '2025-01-19'),
(13, 410.00, 0.00,  410.00, '2025-01-26'),
(14, 850.00, 0.00,  850.00, '2025-02-09'),
(16,  90.00, 0.00,   90.00, '2025-01-11'),
(17, 565.00, 0.00,  565.00, '2025-01-23'),
(19, 90.00,  0.00,   90.00, '2025-02-13'),
(21,  40.00, 0.00,   40.00, '2025-01-31'),
(22,1290.00, 0.00, 1290.00, '2025-02-04'),
-- OTC walk-in invoices (no prescription)
(NULL, 15.00, 0.00,  15.00, '2025-01-14'),
(NULL, 40.00, 0.00,  40.00, '2025-01-17'),
(NULL, 20.00, 0.00,  20.00, '2025-01-22'),
(NULL, 55.00, 0.00,  55.00, '2025-02-01'),
(NULL, 95.00, 0.00,  95.00, '2025-02-07'),
(NULL,110.00, 0.00, 110.00, '2025-02-11'),
(NULL, 35.00, 0.00,  35.00, '2025-02-14');
GO

-- PAYMENT
INSERT INTO PAYMENT (invoice_id, amount_paid, payment_method, payment_date, payment_status) VALUES
(1,  225.00,  'Cash',   '2025-01-06', 'Completed'),
(2,  270.00,  'Card',   '2025-01-09', 'Completed'),
(3,  920.00,  'Cash',   '2025-01-16', 'Completed'),
(4,   75.00,  'Cash',   '2025-01-21', 'Completed'),
(5,  320.00,  'Online', '2025-02-03', 'Completed'),
(6,  240.00,  'Cash',   '2025-01-29', 'Completed'),
(7,   75.00,  'Card',   '2025-02-06', 'Completed'),
(8, 1200.00,  'Online', '2025-01-19', 'Completed'),
(9,  410.00,  'Cash',   '2025-01-26', 'Completed'),
(10, 850.00,  'Card',   '2025-02-09', 'Completed'),
(11,  90.00,  'Cash',   '2025-01-11', 'Completed'),
(12, 565.00,  'Online', '2025-01-23', 'Completed'),
(13,  90.00,  'Cash',   '2025-02-13', 'Completed'),
(14,  40.00,  'Cash',   '2025-01-31', 'Completed'),
(15,1290.00,  'Card',   '2025-02-04', 'Completed'),
(16,  15.00,  'Cash',   '2025-01-14', 'Completed'),
(17,  40.00,  'Cash',   '2025-01-17', 'Completed'),
(18,  20.00,  'Cash',   '2025-01-22', 'Completed'),
(19,  55.00,  'Card',   '2025-02-01', 'Completed'),
(20,  95.00,  'Cash',   '2025-02-07', 'Completed'),
(21, 110.00,  'Online', '2025-02-11', 'Completed'),
(22,  35.00,  'Cash',   '2025-02-14', 'Completed');
GO

-- ============================================================
-- SQL QUERIES WITH RELATIONAL ALGEBRA
-- ============================================================

-- ============================================================
-- QUERY 1: List all dispensed prescriptions with doctor name,
--          customer name, and pharmacist who dispensed them
-- Relational Algebra:
--   Pi(P.name, C_P.name, Ph_P.name, RX.prescribed_date, RX.status)
--   (PRESCRIPTION |x| DOCTOR |x| PERSON(doctor) |x| CUSTOMER
--    |x| PERSON(customer) |x| PHARMACIST |x| PERSON(pharmacist))
--   WHERE RX.status = 'Dispensed'
-- ============================================================
SELECT
    DP.name              AS DoctorName,
    D.specialization     AS Specialization,
    CP.name              AS CustomerName,
    PP.name              AS PharmacistName,
    RX.prescribed_date   AS PrescribedDate,
    RX.dispensed_at      AS DispensedAt,
    RX.status            AS Status
FROM PRESCRIPTION RX
JOIN DOCTOR       D   ON RX.doctor_id     = D.doctor_id
JOIN PERSON       DP  ON D.person_id      = DP.person_id
JOIN CUSTOMER     C   ON RX.customer_id   = C.customer_id
JOIN PERSON       CP  ON C.person_id      = CP.person_id
JOIN PHARMACIST   PH  ON RX.pharmacist_id = PH.pharmacist_id
JOIN PERSON       PP  ON PH.person_id     = PP.person_id
WHERE RX.status = 'Dispensed'
ORDER BY RX.dispensed_at DESC;
GO

-- ============================================================
-- QUERY 2: Show total revenue per payment method and
--          count of transactions
-- Relational Algebra:
--   Pi(payment_method, SUM(amount_paid), COUNT(*))
--   (PAYMENT |x| INVOICE)
--   GROUP BY payment_method
-- ============================================================
SELECT
    PAY.payment_method                AS PaymentMethod,
    COUNT(PAY.payment_id)             AS TotalTransactions,
    SUM(PAY.amount_paid)              AS TotalRevenue,
    AVG(PAY.amount_paid)              AS AvgTransactionValue
FROM PAYMENT PAY
JOIN INVOICE  INV ON PAY.invoice_id = INV.invoice_id
WHERE PAY.payment_status = 'Completed'
GROUP BY PAY.payment_method
ORDER BY TotalRevenue DESC;
GO

-- ============================================================
-- QUERY 3: Show medicines with LOW STOCK (quantity below
--          monitor_level) along with their supplier info
-- Relational Algebra:
--   Pi(M.name, INV.quantity, INV.monitor_level, S.name)
--   (INVENTORY |x| MEDICINE |x| PURCHASE_ORDER |x| SUPPLIER)
--   WHERE INV.quantity < INV.monitor_level
-- ============================================================
SELECT
    M.name               AS MedicineName,
    M.category           AS Category,
    INV.quantity         AS CurrentStock,
    INV.monitor_level    AS ReorderLevel,
    INV.expiry_date      AS ExpiryDate,
    S.name               AS Supplier,
    S.phone              AS SupplierPhone,
    PO.status            AS LastOrderStatus
FROM INVENTORY INV
JOIN MEDICINE       M   ON INV.medicine_id  = M.medicine_id
JOIN PURCHASE_ORDER PO  ON M.medicine_id    = PO.medicine_id
JOIN SUPPLIER       S   ON PO.supplier_id   = S.supplier_id
WHERE INV.quantity < INV.monitor_level
ORDER BY INV.quantity ASC;
GO

-- ============================================================
-- BONUS QUERY 4 (Relational Algebra - Set Operations):
-- Find customers who have BOTH received a dispensed prescription
-- AND made a payment (INTERSECTION concept)
-- ============================================================
SELECT DISTINCT
    CP.name          AS CustomerName,
    CP.phone         AS Phone,
    C.loyalty_points AS LoyaltyPoints,
    COUNT(RX.prescription_id) AS TotalPrescriptions,
    SUM(PAY.amount_paid)      AS TotalSpent
FROM CUSTOMER     C
JOIN PERSON       CP  ON C.person_id      = CP.person_id
JOIN PRESCRIPTION RX  ON C.customer_id   = RX.customer_id
JOIN INVOICE      INV ON RX.prescription_id = INV.prescription_id
JOIN PAYMENT      PAY ON INV.invoice_id  = PAY.invoice_id
WHERE RX.status = 'Dispensed'
  AND PAY.payment_status = 'Completed'
GROUP BY CP.name, CP.phone, C.loyalty_points
ORDER BY TotalSpent DESC;
GO
