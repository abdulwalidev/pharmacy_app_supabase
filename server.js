const express = require('express');
const sql = require('mssql');
const cors = require('cors');
const path = require('path');

const app = express();
app.use(cors());
app.use(express.json());
app.use(express.static(__dirname)); // serve frontend

// ── DB CONFIG ─────────────────────────────────────────────────
// Edit these to match your SQL Server setup
const dbConfig = {
  user: '',                  // leave blank if using Windows Auth
  password: '',              // leave blank if using Windows Auth
  server: 'localhost',       // or your server name e.g. DESKTOP-XXXX\\SQLEXPRESS
  database: 'PharmacyDB',
  options: {
    trustedConnection: true,       // Windows Authentication (no username/password needed)
    trustServerCertificate: true,
    enableArithAbort: true,
  }
};

let pool;
async function getPool() {
  if (!pool) pool = await sql.connect(dbConfig);
  return pool;
}

// ── HELPERS ───────────────────────────────────────────────────
function ok(res, data)  { res.json({ ok: true, data }); }
function err(res, e)    { console.error(e); res.status(500).json({ ok: false, error: e.message }); }

// ── ROUTES ───────────────────────────────────────────────────

// GET /api/stats — dashboard numbers
app.get('/api/stats', async (req, res) => {
  try {
    const db = await getPool();
    const r = await db.request().query(`
      SELECT
        (SELECT COUNT(*) FROM PRESCRIPTION) AS totalRx,
        (SELECT COUNT(*) FROM PRESCRIPTION WHERE status='Dispensed') AS dispensed,
        (SELECT COUNT(*) FROM PRESCRIPTION WHERE status='Pending')   AS pending,
        (SELECT COUNT(*) FROM PRESCRIPTION WHERE status='Expired')   AS expired,
        (SELECT COUNT(*) FROM MEDICINE)     AS totalMeds,
        (SELECT COUNT(*) FROM INVENTORY WHERE quantity < monitor_level) AS lowStock,
        (SELECT COUNT(*) FROM SUPPLIER WHERE is_active=1) AS suppliers,
        (SELECT ISNULL(SUM(amount_paid),0) FROM PAYMENT WHERE payment_status='Completed') AS totalRevenue
    `);
    ok(res, r.recordset[0]);
  } catch(e) { err(res, e); }
});

// GET /api/prescriptions
app.get('/api/prescriptions', async (req, res) => {
  try {
    const db = await getPool();
    const r = await db.request().query(`
      SELECT
        RX.prescription_id, RX.status, RX.prescribed_date, RX.expiry_date, RX.dispensed_at,
        DP.name AS doctor_name, D.specialization,
        CP.name AS customer_name,
        PP.name AS pharmacist_name,
        STRING_AGG(M.name, ', ') AS medicines
      FROM PRESCRIPTION RX
      JOIN DOCTOR      D   ON RX.doctor_id     = D.doctor_id
      JOIN PERSON      DP  ON D.person_id       = DP.person_id
      JOIN CUSTOMER    C   ON RX.customer_id    = C.customer_id
      JOIN PERSON      CP  ON C.person_id       = CP.person_id
      LEFT JOIN PHARMACIST PH ON RX.pharmacist_id = PH.pharmacist_id
      LEFT JOIN PERSON PP     ON PH.person_id     = PP.person_id
      LEFT JOIN PRESC_MED_DETAIL PMD ON RX.prescription_id = PMD.prescription_id
      LEFT JOIN MEDICINE M           ON PMD.medicine_id     = M.medicine_id
      GROUP BY RX.prescription_id, RX.status, RX.prescribed_date, RX.expiry_date,
               RX.dispensed_at, DP.name, D.specialization, CP.name, PP.name
      ORDER BY RX.prescription_id DESC
    `);
    ok(res, r.recordset);
  } catch(e) { err(res, e); }
});

// POST /api/prescriptions — issue new prescription
app.post('/api/prescriptions', async (req, res) => {
  const { doctor_id, customer_id, medicine_id, quantity, dosage, prescribed_date, expiry_date } = req.body;
  try {
    const db = await getPool();
    // Insert prescription
    const rxResult = await db.request()
      .input('did', sql.Int, doctor_id)
      .input('cid', sql.Int, customer_id)
      .input('pd',  sql.Date, prescribed_date)
      .input('ed',  sql.Date, expiry_date)
      .query(`
        INSERT INTO PRESCRIPTION (doctor_id, customer_id, status, prescribed_date, expiry_date, created_at)
        OUTPUT INSERTED.prescription_id
        VALUES (@did, @cid, 'Pending', @pd, @ed, GETDATE())
      `);
    const rxId = rxResult.recordset[0].prescription_id;

    // Insert medicine detail
    await db.request()
      .input('rxid', sql.Int, rxId)
      .input('mid',  sql.Int, medicine_id)
      .input('qty',  sql.Int, quantity)
      .input('dos',  sql.VarChar, dosage)
      .query(`
        INSERT INTO PRESC_MED_DETAIL (prescription_id, medicine_id, quantity, dosage_instructions, added_at)
        VALUES (@rxid, @mid, @qty, @dos, GETDATE())
      `);

    ok(res, { prescription_id: rxId });
  } catch(e) { err(res, e); }
});

// PATCH /api/prescriptions/:id/dispense
app.patch('/api/prescriptions/:id/dispense', async (req, res) => {
  const { pharmacist_id } = req.body;
  try {
    const db = await getPool();
    await db.request()
      .input('id',  sql.Int, req.params.id)
      .input('pid', sql.Int, pharmacist_id)
      .query(`
        UPDATE PRESCRIPTION
        SET status='Dispensed', pharmacist_id=@pid,
            dispensed_at=GETDATE(), updated_at=GETDATE(), updated_by='Pharmacist'
        WHERE prescription_id=@id
      `);
    ok(res, { updated: true });
  } catch(e) { err(res, e); }
});

// GET /api/medicines
app.get('/api/medicines', async (req, res) => {
  try {
    const db = await getPool();
    const r = await db.request().query(`
      SELECT M.medicine_id, M.name, M.category, M.unit_price, M.is_active,
        CASE WHEN O.medicine_id IS NOT NULL THEN 'OTC'
             WHEN P.medicine_id IS NOT NULL AND P.is_controlled=1 THEN 'Controlled'
             WHEN P.medicine_id IS NOT NULL THEN 'Prescription'
             ELSE 'Unknown' END AS medicine_type,
        ISNULL(I.quantity, 0) AS stock,
        ISNULL(I.monitor_level, 10) AS monitor_level
      FROM MEDICINE M
      LEFT JOIN OTC_MEDICINE   O ON M.medicine_id = O.medicine_id
      LEFT JOIN PRESC_MEDICINE P ON M.medicine_id = P.medicine_id
      LEFT JOIN INVENTORY      I ON M.medicine_id = I.medicine_id
      WHERE M.is_active = 1
      ORDER BY M.name
    `);
    ok(res, r.recordset);
  } catch(e) { err(res, e); }
});

// GET /api/inventory
app.get('/api/inventory', async (req, res) => {
  try {
    const db = await getPool();
    const r = await db.request().query(`
      SELECT I.inventory_id, M.name AS medicine_name, M.category,
             I.quantity, I.monitor_level, I.expiry_date,
             I.last_restocked, I.updated_at, I.updated_by,
             CASE WHEN I.quantity < I.monitor_level THEN 1 ELSE 0 END AS is_low
      FROM INVENTORY I
      JOIN MEDICINE M ON I.medicine_id = M.medicine_id
      ORDER BY is_low DESC, I.quantity ASC
    `);
    ok(res, r.recordset);
  } catch(e) { err(res, e); }
});

// GET /api/doctors
app.get('/api/doctors', async (req, res) => {
  try {
    const db = await getPool();
    const r = await db.request().query(`
      SELECT D.doctor_id, P.name, D.specialization, D.license_no, D.license_expiry,
             P.phone, P.email, P.is_active
      FROM DOCTOR D JOIN PERSON P ON D.person_id = P.person_id
      ORDER BY P.name
    `);
    ok(res, r.recordset);
  } catch(e) { err(res, e); }
});

// GET /api/pharmacists
app.get('/api/pharmacists', async (req, res) => {
  try {
    const db = await getPool();
    const r = await db.request().query(`
      SELECT PH.pharmacist_id, P.name, PH.license_no, PH.license_expiry, P.phone, P.is_active
      FROM PHARMACIST PH JOIN PERSON P ON PH.person_id = P.person_id
      ORDER BY P.name
    `);
    ok(res, r.recordset);
  } catch(e) { err(res, e); }
});

// GET /api/customers
app.get('/api/customers', async (req, res) => {
  try {
    const db = await getPool();
    const r = await db.request().query(`
      SELECT C.customer_id, P.name, P.phone, P.email, P.address, C.loyalty_points
      FROM CUSTOMER C JOIN PERSON P ON C.person_id = P.person_id
      ORDER BY P.name
    `);
    ok(res, r.recordset);
  } catch(e) { err(res, e); }
});

// GET /api/customers/:id/prescriptions
app.get('/api/customers/:id/prescriptions', async (req, res) => {
  try {
    const db = await getPool();
    const r = await db.request()
      .input('cid', sql.Int, req.params.id)
      .query(`
        SELECT RX.prescription_id, RX.status, RX.prescribed_date, RX.expiry_date,
               DP.name AS doctor_name, STRING_AGG(M.name, ', ') AS medicines
        FROM PRESCRIPTION RX
        JOIN DOCTOR D   ON RX.doctor_id = D.doctor_id
        JOIN PERSON DP  ON D.person_id  = DP.person_id
        LEFT JOIN PRESC_MED_DETAIL PMD ON RX.prescription_id = PMD.prescription_id
        LEFT JOIN MEDICINE M           ON PMD.medicine_id     = M.medicine_id
        WHERE RX.customer_id = @cid
        GROUP BY RX.prescription_id, RX.status, RX.prescribed_date, RX.expiry_date, DP.name
        ORDER BY RX.prescribed_date DESC
      `);
    ok(res, r.recordset);
  } catch(e) { err(res, e); }
});

// GET /api/customers/:id/payments
app.get('/api/customers/:id/payments', async (req, res) => {
  try {
    const db = await getPool();
    const r = await db.request()
      .input('cid', sql.Int, req.params.id)
      .query(`
        SELECT PAY.payment_id, INV.invoice_id, PAY.amount_paid,
               PAY.payment_method, PAY.payment_date, PAY.payment_status
        FROM PAYMENT PAY
        JOIN INVOICE INV ON PAY.invoice_id = INV.invoice_id
        JOIN PRESCRIPTION RX ON INV.prescription_id = RX.prescription_id
        WHERE RX.customer_id = @cid
        ORDER BY PAY.payment_date DESC
      `);
    ok(res, r.recordset);
  } catch(e) { err(res, e); }
});

// GET /api/suppliers
app.get('/api/suppliers', async (req, res) => {
  try {
    const db = await getPool();
    const r = await db.request().query(`
      SELECT supplier_id, name, phone, email, contact_person,
             contract_start, contract_end, is_active
      FROM SUPPLIER ORDER BY name
    `);
    ok(res, r.recordset);
  } catch(e) { err(res, e); }
});

// GET /api/billing
app.get('/api/billing', async (req, res) => {
  try {
    const db = await getPool();
    const r = await db.request().query(`
      SELECT INV.invoice_id, ISNULL(CP.name,'Walk-in') AS customer_name,
             INV.subtotal, INV.total_amount, INV.issued_at,
             PAY.amount_paid, PAY.payment_method, PAY.payment_status
      FROM INVOICE INV
      LEFT JOIN PRESCRIPTION RX ON INV.prescription_id = RX.prescription_id
      LEFT JOIN CUSTOMER C      ON RX.customer_id       = C.customer_id
      LEFT JOIN PERSON CP       ON C.person_id          = CP.person_id
      LEFT JOIN PAYMENT PAY     ON INV.invoice_id       = PAY.invoice_id
      ORDER BY INV.invoice_id DESC
    `);
    ok(res, r.recordset);
  } catch(e) { err(res, e); }
});

// POST /api/persons — add new person (Admin)
app.post('/api/persons', async (req, res) => {
  const { name, role, phone, email, address } = req.body;
  try {
    const db = await getPool();
    const personResult = await db.request()
      .input('name',    sql.VarChar, name)
      .input('phone',   sql.VarChar, phone)
      .input('email',   sql.VarChar, email || null)
      .input('address', sql.VarChar, address || null)
      .query(`
        INSERT INTO PERSON (name, phone, email, address, created_at, is_active)
        OUTPUT INSERTED.person_id
        VALUES (@name, @phone, @email, @address, GETDATE(), 1)
      `);
    const person_id = personResult.recordset[0].person_id;

    if (role === 'Customer') {
      await db.request()
        .input('pid', sql.Int, person_id)
        .query(`INSERT INTO CUSTOMER (person_id, loyalty_points) VALUES (@pid, 0)`);
    }
    ok(res, { person_id, role });
  } catch(e) { err(res, e); }
});

// GET /api/query/:n — run one of the 3 assignment queries
app.get('/api/query/:n', async (req, res) => {
  const queries = {
    1: `
      SELECT DP.name AS DoctorName, D.specialization, CP.name AS CustomerName,
             ISNULL(PP.name,'—') AS PharmacistName,
             RX.prescribed_date AS PrescribedDate, RX.dispensed_at AS DispensedAt
      FROM PRESCRIPTION RX
      JOIN DOCTOR     D   ON RX.doctor_id     = D.doctor_id
      JOIN PERSON     DP  ON D.person_id       = DP.person_id
      JOIN CUSTOMER   C   ON RX.customer_id   = C.customer_id
      JOIN PERSON     CP  ON C.person_id       = CP.person_id
      LEFT JOIN PHARMACIST PH ON RX.pharmacist_id = PH.pharmacist_id
      LEFT JOIN PERSON PP     ON PH.person_id     = PP.person_id
      WHERE RX.status = 'Dispensed'
      ORDER BY RX.dispensed_at DESC`,
    2: `
      SELECT PAY.payment_method AS PaymentMethod,
             COUNT(PAY.payment_id) AS TotalTransactions,
             SUM(PAY.amount_paid) AS TotalRevenue,
             AVG(PAY.amount_paid) AS AvgValue
      FROM PAYMENT PAY
      JOIN INVOICE INV ON PAY.invoice_id = INV.invoice_id
      WHERE PAY.payment_status = 'Completed'
      GROUP BY PAY.payment_method
      ORDER BY TotalRevenue DESC`,
    3: `
      SELECT M.name AS MedicineName, M.category,
             INV.quantity AS CurrentStock, INV.monitor_level AS ReorderLevel,
             INV.expiry_date, S.name AS Supplier, S.phone AS SupplierPhone, PO.status AS LastOrder
      FROM INVENTORY INV
      JOIN MEDICINE       M  ON INV.medicine_id = M.medicine_id
      JOIN PURCHASE_ORDER PO ON M.medicine_id   = PO.medicine_id
      JOIN SUPPLIER       S  ON PO.supplier_id  = S.supplier_id
      WHERE INV.quantity < INV.monitor_level
      ORDER BY INV.quantity ASC`
  };
  try {
    const db = await getPool();
    const r = await db.request().query(queries[req.params.n]);
    ok(res, r.recordset);
  } catch(e) { err(res, e); }
});

const PORT = 3000;
app.listen(PORT, () => console.log(`\n✅ Pharmacy server running at http://localhost:${PORT}\n`));
