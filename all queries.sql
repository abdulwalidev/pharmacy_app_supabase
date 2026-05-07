-- pharmacy management system - term project
-- student: enrollment# 01-134242-007
-- course: database management systems
-- instructor: ali irfan
-- bahria university islamabad

-- ============================================================
-- normalization — all tables satisfy third normal form (3nf)
-- ============================================================
-- 1nf: all column values are atomic (no multivalued/repeating groups).
--      medicines in a prescription are stored as individual rows in
--      Rx_Items, not as comma-separated values in one column.
--
-- 2nf: no partial dependencies exist.
--      all tables with a single surrogate pk (serial) trivially satisfy
--      2nf. the composite-pk table Rx_Items(prescription_id, medicine_id)
--      has every non-key attribute dependent on the full composite key.
--
-- 3nf: no transitive dependencies exist.
--      example: Doctor stores only doctor-specific attributes and
--      references Person(person_id) for shared attributes.
-- ============================================================

-- ============================================================
-- cardinality of relationships
-- ============================================================
--  relationship                     cardinality
--  -----------------------------    -----------
--  Person      →  Doctor            1 : 1
--  Person      →  Pharmacist        1 : 1
--  Person      →  Customer          1 : 1
--  Medicine    →  Otc_Med           1 : 1  (subtype)
--  Medicine    →  Rx_Med            1 : 1  (subtype)
--  Doctor      →  Prescription      1 : m
--  Customer    →  Prescription      1 : m
--  Pharmacist  →  Prescription      1 : m
--  Prescription × Medicine          m : n  (resolved by Rx_Items)
--  Supplier    →  Purchase_Order    1 : m
--  Medicine    →  Purchase_Order    1 : m
--  Medicine    →  Inventory         1 : 1
--  Prescription →  Invoice          1 : 1
--  Invoice     →  Payment           1 : m
-- ============================================================

-- person (super)
CREATE TABLE Person (
    person_id   SERIAL        PRIMARY KEY,
    name        VARCHAR(100)  NOT NULL,
    phone       VARCHAR(20)   NOT NULL,
    email       VARCHAR(100)  NULL,
    address     VARCHAR(200)  NULL,
    created_at  TIMESTAMP     DEFAULT NOW(),
    updated_at  TIMESTAMP     NULL,
    is_active   BOOLEAN       DEFAULT TRUE
);

-- doctor (sub)
CREATE TABLE Doctor (
    doctor_id      SERIAL       PRIMARY KEY,
    person_id      INT          NOT NULL REFERENCES Person(person_id),
    specialization VARCHAR(100) NOT NULL,
    license_no     VARCHAR(50)  NOT NULL,
    license_expiry DATE         NOT NULL
);

-- pharmacist (sub)
CREATE TABLE Pharmacist (
    pharmacist_id  SERIAL       PRIMARY KEY,
    person_id      INT          NOT NULL REFERENCES Person(person_id),
    license_no     VARCHAR(50)  NOT NULL,
    license_expiry DATE         NOT NULL
);

-- customer (sub)
CREATE TABLE Customer (
    customer_id    SERIAL  PRIMARY KEY,
    person_id      INT     NOT NULL REFERENCES Person(person_id),
    loyalty_points INT     DEFAULT 0
);

-- medicine
CREATE TABLE Medicine (
    medicine_id  SERIAL        PRIMARY KEY,
    name         VARCHAR(150)  NOT NULL,
    manufacturer VARCHAR(150)  NOT NULL,
    unit_price   NUMERIC(10,2) NOT NULL,
    category     VARCHAR(100)  NOT NULL,
    created_at   TIMESTAMP     DEFAULT NOW(),
    updated_at   TIMESTAMP     NULL,
    is_active    BOOLEAN       DEFAULT TRUE
);

-- otc_med (over the counter subtype)
CREATE TABLE Otc_Med (
    medicine_id     INT          PRIMARY KEY REFERENCES Medicine(medicine_id),
    shelf_category  VARCHAR(100) NOT NULL,
    age_restriction VARCHAR(50)  NULL
);

-- rx_med (prescription medicine subtype)
CREATE TABLE Rx_Med (
    medicine_id    INT          PRIMARY KEY REFERENCES Medicine(medicine_id),
    max_dose       VARCHAR(50)  NOT NULL,
    schedule_class VARCHAR(50)  NOT NULL,
    is_controlled  BOOLEAN      DEFAULT FALSE
);

-- prescription
CREATE TABLE Prescription (
    prescription_id SERIAL        PRIMARY KEY,
    doctor_id       INT           NOT NULL REFERENCES Doctor(doctor_id),
    customer_id     INT           NOT NULL REFERENCES Customer(customer_id),
    pharmacist_id   INT           NULL REFERENCES Pharmacist(pharmacist_id),
    status          VARCHAR(30)   DEFAULT 'Pending',
    prescribed_date DATE          NOT NULL,
    expiry_date     DATE          NOT NULL,
    dispensed_at    TIMESTAMP     NULL,
    created_at      TIMESTAMP     DEFAULT NOW(),
    updated_at      TIMESTAMP     NULL,
    updated_by      VARCHAR(100)  NULL
);

-- rx_items (bridge table)
CREATE TABLE Rx_Items (
    prescription_id INT          NOT NULL REFERENCES Prescription(prescription_id),
    medicine_id     INT          NOT NULL REFERENCES Medicine(medicine_id),
    quantity        INT          NOT NULL,
    dosage          VARCHAR(300) NOT NULL,
    added_at        TIMESTAMP    DEFAULT NOW(),
    modified_at     TIMESTAMP    NULL,
    PRIMARY KEY (prescription_id, medicine_id)
);

-- supplier
CREATE TABLE Supplier (
    supplier_id    SERIAL        PRIMARY KEY,
    name           VARCHAR(150)  NOT NULL,
    phone          VARCHAR(20)   NOT NULL,
    email          VARCHAR(100)  NULL,
    contact_person VARCHAR(100)  NOT NULL,
    contract_start DATE          NOT NULL,
    contract_end   DATE          NULL,
    is_active      BOOLEAN       DEFAULT TRUE
);

-- purchase_order
CREATE TABLE Purchase_Order (
    po_id            SERIAL        PRIMARY KEY,
    supplier_id      INT           NOT NULL REFERENCES Supplier(supplier_id),
    medicine_id      INT           NOT NULL REFERENCES Medicine(medicine_id),
    quantity_ordered INT           NOT NULL,
    unit_cost        NUMERIC(10,2) NOT NULL,
    status           VARCHAR(30)   DEFAULT 'Ordered',
    ordered_at       TIMESTAMP     DEFAULT NOW(),
    received_at      TIMESTAMP     NULL,
    created_by       VARCHAR(100)  NOT NULL
);

-- inventory
CREATE TABLE Inventory (
    inventory_id   SERIAL        PRIMARY KEY,
    medicine_id    INT           NOT NULL REFERENCES Medicine(medicine_id),
    quantity       INT           NOT NULL DEFAULT 0,
    reorder_level  INT           NOT NULL DEFAULT 10,
    expiry_date    DATE          NULL,
    last_restocked TIMESTAMP     NULL,
    updated_at     TIMESTAMP     DEFAULT NOW(),
    updated_by     VARCHAR(100)  NOT NULL
);

-- invoice
CREATE TABLE Invoice (
    invoice_id      SERIAL        PRIMARY KEY,
    prescription_id INT           NULL REFERENCES Prescription(prescription_id),
    subtotal        NUMERIC(10,2) NOT NULL,
    tax             NUMERIC(10,2) DEFAULT 0,
    total_amount    NUMERIC(10,2) NOT NULL,
    issued_at       TIMESTAMP     DEFAULT NOW(),
    updated_at      TIMESTAMP     NULL
);

-- payment
CREATE TABLE Payment (
    payment_id     SERIAL        PRIMARY KEY,
    invoice_id     INT           NOT NULL REFERENCES Invoice(invoice_id),
    amount_paid    NUMERIC(10,2) NOT NULL,
    payment_method VARCHAR(50)   NOT NULL,
    payment_date   TIMESTAMP     DEFAULT NOW(),
    payment_status VARCHAR(30)   DEFAULT 'Completed',
    refunded_at    TIMESTAMP     NULL
);

-- rx_audit_log (tracks all prescription changes)
CREATE TABLE Rx_Audit_Log (
    log_id            SERIAL       PRIMARY KEY,
    prescription_id   INT          NOT NULL,
    changed_at        TIMESTAMP    DEFAULT NOW(),
    changed_by        VARCHAR(100),
    old_status        VARCHAR(30),
    new_status        VARCHAR(30),
    old_pharmacist_id INT,
    new_pharmacist_id INT,
    old_dispensed_at  TIMESTAMP,
    new_dispensed_at  TIMESTAMP,
    operation         VARCHAR(10)  DEFAULT 'UPDATE'
);

-- ============================================================
-- row level security
-- ============================================================
ALTER TABLE Person        ENABLE ROW LEVEL SECURITY;
ALTER TABLE Doctor        ENABLE ROW LEVEL SECURITY;
ALTER TABLE Pharmacist    ENABLE ROW LEVEL SECURITY;
ALTER TABLE Customer      ENABLE ROW LEVEL SECURITY;
ALTER TABLE Medicine      ENABLE ROW LEVEL SECURITY;
ALTER TABLE Otc_Med       ENABLE ROW LEVEL SECURITY;
ALTER TABLE Rx_Med        ENABLE ROW LEVEL SECURITY;
ALTER TABLE Prescription  ENABLE ROW LEVEL SECURITY;
ALTER TABLE Rx_Items      ENABLE ROW LEVEL SECURITY;
ALTER TABLE Supplier      ENABLE ROW LEVEL SECURITY;
ALTER TABLE Purchase_Order ENABLE ROW LEVEL SECURITY;
ALTER TABLE Inventory     ENABLE ROW LEVEL SECURITY;
ALTER TABLE Invoice       ENABLE ROW LEVEL SECURITY;
ALTER TABLE Payment       ENABLE ROW LEVEL SECURITY;
ALTER TABLE Rx_Audit_Log  ENABLE ROW LEVEL SECURITY;

CREATE POLICY "public_all" ON Person         FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "public_all" ON Doctor         FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "public_all" ON Pharmacist     FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "public_all" ON Customer       FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "public_all" ON Medicine       FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "public_all" ON Otc_Med        FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "public_all" ON Rx_Med         FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "public_all" ON Prescription   FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "public_all" ON Rx_Items       FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "public_all" ON Supplier       FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "public_all" ON Purchase_Order FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "public_all" ON Inventory      FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "public_all" ON Invoice        FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "public_all" ON Payment        FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "public_all" ON Rx_Audit_Log   FOR ALL USING (true) WITH CHECK (true);

-- ============================================================
-- trigger: audit log on prescription update
-- ============================================================
CREATE OR REPLACE FUNCTION log_prescription_changes()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO Rx_Audit_Log (
        prescription_id,
        changed_at,
        changed_by,
        old_status,        new_status,
        old_pharmacist_id, new_pharmacist_id,
        old_dispensed_at,  new_dispensed_at,
        operation
    ) VALUES (
        OLD.prescription_id,
        NOW(),
        NEW.updated_by,
        OLD.status,        NEW.status,
        OLD.pharmacist_id, NEW.pharmacist_id,
        OLD.dispensed_at,  NEW.dispensed_at,
        TG_OP
    );
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_prescription_audit
BEFORE UPDATE ON Prescription
FOR EACH ROW
EXECUTE FUNCTION log_prescription_changes();