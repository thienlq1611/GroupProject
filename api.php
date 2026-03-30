<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');

// Connect to the database
$conn = new mysqli('127.0.0.1', 'root', 'Top@2805961155', 'pharmacydb');
if ($conn->connect_error) {
    http_response_code(500);
    echo json_encode(['error' => 'Connection failed: ' . $conn->connect_error]);
    exit;
}

// Get the action from the URL e.g. api.php?action=find_patient
$action = $_GET['action'] ?? '';

switch ($action) {

    // FIND PATIENT
    // SELECTION query with LIKE: search patients by name, DOB, and city
    case 'find_patient':
        $name = '%' . $conn->real_escape_string($_GET['name'] ?? '') . '%';
        $dob  = $conn->real_escape_string($_GET['dob'] ?? '');
        $city = '%' . $conn->real_escape_string($_GET['city'] ?? '') . '%';

        // Only add DOB filter if the user typed a date
        $dob_filter = ($dob !== '') ? "AND DOB = '$dob'" : "";

        $result = $conn->query(
            "SELECT ID, PHN, Fname, Lname, DOB, Phone, Email
             FROM patients
             WHERE (Fname LIKE '$name' OR Lname LIKE '$name')
             $dob_filter
             AND City LIKE '$city'"
        );
        echo json_encode($result->fetch_all(MYSQLI_ASSOC));
        break;

    // GET SINGLE PATIENT (full detail)
    // SELECTION: WHERE finds one patient by ID, PHN, last name, or full name
    case 'get_patient':
        $q = $conn->real_escape_string($_GET['q'] ?? '');

        $result = $conn->query(
            "SELECT ID, PHN, Fname, Lname, DOB, St, City, PostCode, Country, Phone, Email, Allergies, Medical_History, Notes, Prov
             FROM patients
             WHERE ID = '$q' OR PHN = '$q'
        );
        $patient = $result->fetch_assoc();

        if (!$patient) {
            echo json_encode(['error' => "Patient \"$q\" not found."]);
            break;
        }

        $pid = $patient['ID'];

        // JOIN: get insurance info by joining is_insured and insurance tables
        $result2 = $conn->query(
            "SELECT i.Iname, ii.PolicyNo, ii.MemberID, ii.Notes AS CoverageType
             FROM is_insured ii
             JOIN insurance i
             ON i.ID = ii.InsID
             WHERE ii.PatID = $pid"
        );
        $patient['insurance'] = $result2->fetch_all(MYSQLI_ASSOC);

        // SELECTION: get patient's dependents
        $result3 = $conn->query(
            "SELECT Name, DOB, Allergies, Medical_History
             FROM dependents
             WHERE PatID = $pid"
        );
        $patient['dependents'] = $result3->fetch_all(MYSQLI_ASSOC);

        echo json_encode($patient);
        break;

    // GET SINGLE PRESCRIPTION
    // JOIN: joins prescriptions, patients, medications, and doctors tables
    case 'get_prescription':
        $id = (int)($_GET['id'] ?? 0);

        $result = $conn->query(
            "SELECT p.Prescription_ID, p.Date_Issued, p.Expiry_Date, p.Instructions, p.Refills,
                    pt.Fname, pt.Lname,
                    m.Drug_Name, m.Strength, m.DIN, m.Cost,
                    d.Fname AS Doc_Fname, d.Lname AS Doc_Lname, d.Specialty
             FROM prescriptions p
             JOIN patients pt   ON pt.ID = p.Patient_ID
             JOIN contains c    ON c.Prescription_ID = p.Prescription_ID
             JOIN medications m ON m.ID = c.ID
             LEFT JOIN prescribe_for pf ON pf.PrescriptionID = p.Prescription_ID
             LEFT JOIN doctors d        ON d.ID = pf.DoctorID
             WHERE p.Prescription_ID = $id
             LIMIT 1"
        );
        $rx = $result->fetch_assoc();

        if (!$rx) {
            echo json_encode(['error' => "Prescription #$id not found."]);
            break;
        }

        // COUNT (aggregation): count how many times this prescription was dispensed
        $result2 = $conn->query(
            "SELECT COUNT(*) AS used
             FROM dispense
             WHERE Prescription_ID = $id"
        );
        $rx['Refills_Used'] = (int)$result2->fetch_assoc()['used'];

        echo json_encode($rx);
        break;

    // ── ALL PRESCRIPTIONS FOR ONE PATIENT ────────────────────────────────────
    // JOIN: links prescriptions, medications, and doctors for one patient
    case 'patient_prescriptions':
        $q = $conn->real_escape_string($_GET['q'] ?? '');

        // First find the patient
        $result = $conn->query(
            "SELECT ID, Fname, Lname
             FROM patients
             WHERE ID = '$q' OR PHN = '$q' OR Lname = '$q' OR CONCAT(Fname, ' ', Lname) = '$q'"
        );
        $patient = $result->fetch_assoc();

        if (!$patient) {
            echo json_encode(['error' => "Patient \"$q\" not found."]);
            break;
        }

        $pid = $patient['ID'];

        // JOIN: get all prescriptions with medication and doctor info
        $result2 = $conn->query(
            "SELECT p.Prescription_ID, p.Date_Issued, p.Expiry_Date, p.Instructions, p.Refills,
                    m.Drug_Name, m.Strength, m.DIN,
                    d.Fname AS Doc_Fname, d.Lname AS Doc_Lname, d.Specialty
             FROM prescriptions p
             JOIN contains c    ON c.Prescription_ID = p.Prescription_ID
             JOIN medications m ON m.ID = c.ID
             LEFT JOIN prescribe_for pf ON pf.PrescriptionID = p.Prescription_ID
             LEFT JOIN doctors d        ON d.ID = pf.DoctorID
             WHERE p.Patient_ID = $pid
             ORDER BY p.Date_Issued DESC"
        );

        echo json_encode([
            'patient_id'   => $patient['ID'],
            'patient_name' => $patient['Fname'] . ' ' . $patient['Lname'],
            'rows'         => $result2->fetch_all(MYSQLI_ASSOC)
        ]);
        break;

    // ── RECORD DISPENSE (INSERT) ──────────────────────────────────────────────
    // INSERT: adds a new row into the dispense table
    case 'record_dispense':
        $empId = (int)($_POST['emp_id']     ?? 0);
        $rxId  = (int)($_POST['rx_id']      ?? 0);
        $pay   = $conn->real_escape_string($_POST['pay_method'] ?? '');

        if (!$empId || !$rxId || !$pay) {
            echo json_encode(['error' => 'Missing required fields.']);
            break;
        }

        // Check employee exists
        $emp = $conn->query("SELECT ID, Fname, Lname, Role FROM employees WHERE ID = $empId")->fetch_assoc();
        if (!$emp) { echo json_encode(['error' => "Employee ID $empId not found."]); break; }

        // Check prescription exists
        $rx = $conn->query("SELECT Prescription_ID, Expiry_Date FROM prescriptions WHERE Prescription_ID = $rxId")->fetch_assoc();
        if (!$rx) { echo json_encode(['error' => "Prescription #$rxId not found."]); break; }

        // Check prescription is not expired
        if ($rx['Expiry_Date'] && $rx['Expiry_Date'] !== '0000-00-00' && strtotime($rx['Expiry_Date']) < time()) {
            echo json_encode(['error' => "Prescription #$rxId expired on {$rx['Expiry_Date']}."]);
            break;
        }

        // COUNT: check this employee hasn't already dispensed this prescription
        $check = $conn->query(
            "SELECT COUNT(*) AS n
             FROM dispense
             WHERE EmpID = $empId AND Prescription_ID = $rxId"
        )->fetch_assoc();
        if ($check['n'] > 0) {
            echo json_encode(['error' => "{$emp['Fname']} already dispensed prescription #$rxId."]);
            break;
        }

        $invoiceNo = rand(10000, 99999);
        $today = date('Y-m-d');

        // INSERT new dispense record
        $conn->query(
            "INSERT INTO dispense (EmpID, Prescription_ID, Invoice_No, Pay_Method, Date_Of_Invoice)
             VALUES ($empId, $rxId, $invoiceNo, '$pay', '$today')"
        );

        // JOIN: get medication info for the confirmation message
        $med = $conn->query(
            "SELECT m.Drug_Name, m.Strength, m.Cost
             FROM medications m
             JOIN contains c ON c.ID = m.ID
             WHERE c.Prescription_ID = $rxId
             LIMIT 1"
        )->fetch_assoc();

        echo json_encode([
            'success'    => true,
            'invoice_no' => $invoiceNo,
            'date'       => $today,
            'employee'   => "{$emp['Fname']} {$emp['Lname']} ({$emp['Role']})",
            'rx_id'      => $rxId,
            'medication' => $med ? "{$med['Drug_Name']} ({$med['Strength']})" : '—',
            'cost'       => $med['Cost'] ?? null,
            'pay_method' => $pay,
        ]);
        break;

    // ── PAYMENT HISTORY ───────────────────────────────────────────────────────
    // JOIN: links dispense, prescriptions, medications, and employees tables
    case 'payment_history':
        $q = $conn->real_escape_string($_GET['q'] ?? '');

        $patient = $conn->query(
            "SELECT ID, Fname, Lname
             FROM patients
             WHERE ID = '$q' OR PHN = '$q' OR Lname = '$q' OR CONCAT(Fname, ' ', Lname) = '$q'"
        )->fetch_assoc();
        if (!$patient) { echo json_encode(['error' => "Patient \"$q\" not found."]); break; }

        $pid = $patient['ID'];

        $result = $conn->query(
            "SELECT d.Invoice_No, d.Date_Of_Invoice, d.Pay_Method,
                    p.Prescription_ID,
                    m.Drug_Name, m.Strength, m.Cost,
                    e.Fname AS Emp_Fname, e.Lname AS Emp_Lname
             FROM dispense d
             JOIN prescriptions p ON p.Prescription_ID = d.Prescription_ID
             JOIN contains c      ON c.Prescription_ID = p.Prescription_ID
             JOIN medications m   ON m.ID = c.ID
             JOIN employees e     ON e.ID = d.EmpID
             WHERE p.Patient_ID = $pid
             ORDER BY d.Date_Of_Invoice DESC"
        );
        echo json_encode(['patient' => $patient, 'rows' => $result->fetch_all(MYSQLI_ASSOC)]);
        break;

    // ── STAFF LOG ─────────────────────────────────────────────────────────────
    // JOIN: links dispense, employees, and medications tables
    case 'staff_log':
        $q    = $conn->real_escape_string($_GET['q']    ?? '');
        $date = $conn->real_escape_string($_GET['date'] ?? '');

        $empId = 0;
        if ($q !== '') {
            $found = $conn->query(
                "SELECT ID FROM employees
                 WHERE ID = '$q' OR Lname = '$q' OR CONCAT(Fname, ' ', Lname) = '$q'"
            )->fetch_assoc();
            if (!$found) { echo json_encode(['error' => "Employee \"$q\" not found."]); break; }
            $empId = $found['ID'];
        }

        // Add optional filters
        $emp_filter  = $empId  ? "AND d.EmpID = $empId"                  : "";
        $date_filter = $date   ? "AND d.Date_Of_Invoice = '$date'"        : "";

        $result = $conn->query(
            "SELECT d.Invoice_No, d.Date_Of_Invoice, d.Pay_Method, d.Prescription_ID,
                    e.Fname, e.Lname, e.Role,
                    m.Drug_Name, m.Strength
             FROM dispense d
             JOIN employees e   ON e.ID = d.EmpID
             JOIN contains c    ON c.Prescription_ID = d.Prescription_ID
             JOIN medications m ON m.ID = c.ID
             WHERE 1=1 $emp_filter $date_filter
             ORDER BY d.Date_Of_Invoice DESC"
        );
        echo json_encode($result->fetch_all(MYSQLI_ASSOC));
        break;

    // ── MEDICATION SEARCH ─────────────────────────────────────────────────────
    // PROJECTION + SELECTION with LIKE: search medications by name, DIN, or strength
    case 'medication_search':
        $q = '%' . $conn->real_escape_string($_GET['q'] ?? '') . '%';

        $result = $conn->query(
            "SELECT ID, Drug_Name, Manufacturer, Strength, Cost, DIN, Stock_Qty, Qty_per_unit
             FROM medications
             WHERE Drug_Name LIKE '$q' OR DIN LIKE '$q' OR Strength LIKE '$q'"
        );
        echo json_encode($result->fetch_all(MYSQLI_ASSOC));
        break;

    // ── COVERAGE ELIGIBILITY ──────────────────────────────────────────────────
    // JOIN: joins is_insured and insurance tables to check patient coverage
    case 'coverage_eligibility':
        $q   = $conn->real_escape_string($_GET['q']   ?? '');
        $din = $conn->real_escape_string($_GET['din'] ?? '');

        $patient = $conn->query(
            "SELECT ID, Fname, Lname
             FROM patients
             WHERE ID = '$q' OR PHN = '$q' OR Lname = '$q' OR CONCAT(Fname, ' ', Lname) = '$q'"
        )->fetch_assoc();
        if (!$patient) { echo json_encode(['error' => "Patient \"$q\" not found."]); break; }

        $pid = $patient['ID'];

        $result = $conn->query(
            "SELECT i.Iname, ii.PolicyNo, ii.MemberID, ii.Notes AS CoverageType
             FROM is_insured ii
             JOIN insurance i ON i.ID = ii.InsID
             WHERE ii.PatID = $pid"
        );
        $coverage = $result->fetch_all(MYSQLI_ASSOC);

        $med = null;
        if ($din !== '') {
            $med = $conn->query(
                "SELECT ID, Drug_Name, Strength, Cost, DIN
                 FROM medications
                 WHERE DIN = '$din' OR Drug_Name LIKE '%$din%'
                 LIMIT 1"
            )->fetch_assoc();
        }

        echo json_encode(['patient' => $patient, 'coverage' => $coverage, 'medication' => $med]);
        break;

    // ── COVERAGE LIMITS ───────────────────────────────────────────────────────
    // JOIN: joins is_insured, insurance, and patients by policy number
    case 'coverage_limits':
        $policy = $conn->real_escape_string($_GET['policy'] ?? '');
        $din    = $conn->real_escape_string($_GET['din']    ?? '');

        $row = $conn->query(
            "SELECT ii.PolicyNo, ii.MemberID, ii.Notes AS CoverageType,
                    i.Iname, i.Notes AS PlanNotes,
                    p.Fname, p.Lname
             FROM is_insured ii
             JOIN insurance i ON i.ID = ii.InsID
             JOIN patients p  ON p.ID = ii.PatID
             WHERE ii.PolicyNo = '$policy'"
        )->fetch_assoc();
        if (!$row) { echo json_encode(['error' => "Policy \"$policy\" not found."]); break; }

        $med = null;
        if ($din !== '') {
            $med = $conn->query(
                "SELECT Drug_Name, Strength, Cost
                 FROM medications
                 WHERE DIN = '$din' OR Drug_Name LIKE '%$din%'
                 LIMIT 1"
            )->fetch_assoc();
        }

        echo json_encode(['policy' => $row, 'medication' => $med]);
        break;

    // ── ALL EMPLOYEES ─────────────────────────────────────────────────────────
    // Simple SELECT: get all employees sorted by role then last name
    case 'all_employees':
        $result = $conn->query(
            "SELECT ID, Fname, Lname, Role, Phone, Email
             FROM employees
             ORDER BY Role, Lname"
        );
        echo json_encode($result->fetch_all(MYSQLI_ASSOC));
        break;

    default:
        echo json_encode(['error' => "Unknown action: $action"]);
        break;
}

$conn->close();
?>
