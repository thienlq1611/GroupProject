<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');

// ── DB CONNECTION ─────────────────────────────────────────────────────────────
$host = '127.0.0.1';
$db   = 'pharmacydb';
$user = 'root';
$pass = 'Top@2805961155';

try {
    $pdo = new PDO("mysql:host=$host;dbname=$db;charset=utf8mb4", $user, $pass);
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
    $pdo->setAttribute(PDO::ATTR_DEFAULT_FETCH_MODE, PDO::FETCH_ASSOC);
} catch (PDOException $e) {
    http_response_code(500);
    echo json_encode(['error' => 'DB connection failed: ' . $e->getMessage()]);
    exit;
}

$action = $_GET['action'] ?? '';

// ── HELPER: resolve patient by ID, PHN, last name, or full name ───────────────
function resolvePatient($pdo, $q) {
    $stmt = $pdo->prepare(
        "SELECT ID, PHN, Fname, Lname, DOB, St, City, PostCode, Country,
                Phone, Email, Allergies, Medical_History, Notes, Prov
         FROM patients
         WHERE ID = :id
            OR (PHN IS NOT NULL AND PHN != 0 AND PHN = :phn)
            OR Lname = :name
            OR CONCAT(Fname,' ',Lname) = :full"
    );
    $stmt->execute([':id' => $q, ':phn' => $q, ':name' => $q, ':full' => $q]);
    return $stmt->fetch();
}

switch ($action) {

    // ── FIND PATIENT (search) ─────────────────────────────────────────────────
    case 'find_patient':
        $name = '%' . ($_GET['name'] ?? '') . '%';
        $dob  = $_GET['dob']  ?? '';
        $city = '%' . ($_GET['city'] ?? '') . '%';

        $stmt = $pdo->prepare(
            "SELECT ID, PHN, Fname, Lname, DOB, St, City, PostCode, Country, Phone, Email, Allergies, Medical_History, Notes, Prov
             FROM patients
             WHERE (Fname LIKE :name OR Lname LIKE :name OR CONCAT(Fname,' ',Lname) LIKE :name)
               AND (:dob = '' OR DOB = :dob)
               AND (City LIKE :city)"
        );
        $stmt->execute([':name' => $name, ':dob' => $dob, ':city' => $city]);
        echo json_encode($stmt->fetchAll());
        break;

    // ── GET SINGLE PATIENT (full detail) ─────────────────────────────────────
    case 'get_patient':
        $q = $_GET['q'] ?? '';
        $patient = resolvePatient($pdo, $q);
        if (!$patient) {
            echo json_encode(['error' => "Patient \"$q\" not found. Try ID (1–9), PHN, or full name."]);
            break;
        }

        // Insurance
        $stmt2 = $pdo->prepare(
            "SELECT i.ID as InsID, i.Iname, i.Phone as InsPhone, i.Notes as PlanNotes,
                    ii.PolicyNo, ii.MemberID, ii.Notes as CoverageType
             FROM is_insured ii
             JOIN insurance i ON i.ID = ii.InsID
             WHERE ii.PatID = :pid"
        );
        $stmt2->execute([':pid' => $patient['ID']]);
        $patient['insurance'] = $stmt2->fetchAll();

        // Dependents
        $stmt3 = $pdo->prepare(
            "SELECT Name, DOB, Allergies, Medical_History
             FROM dependents WHERE PatID = :pid"
        );
        $stmt3->execute([':pid' => $patient['ID']]);
        $patient['dependents'] = $stmt3->fetchAll();

        echo json_encode($patient);
        break;

    // ── GET SINGLE PRESCRIPTION ───────────────────────────────────────────────
    case 'get_prescription':
        $id = $_GET['id'] ?? '';
        $stmt = $pdo->prepare(
            "SELECT p.Prescription_ID, p.Date_Issued, p.Expiry_Date,
                    p.Instructions, p.Refills, p.Patient_ID,
                    pt.Fname, pt.Lname,
                    m.Drug_Name, m.Strength, m.DIN, m.Cost,
                    d.Fname AS Doc_Fname, d.Lname AS Doc_Lname, d.Specialty
             FROM prescriptions p
             JOIN patients pt ON pt.ID = p.Patient_ID
             JOIN contains c  ON c.Prescription_ID = p.Prescription_ID
             JOIN medications m ON m.ID = c.ID
             LEFT JOIN prescribe_for pf ON pf.PrescriptionID = p.Prescription_ID
             LEFT JOIN doctors d ON d.ID = pf.DoctorID
             WHERE p.Prescription_ID = :id
             LIMIT 1"
        );
        $stmt->execute([':id' => $id]);
        $rx = $stmt->fetch();
        if (!$rx) { echo json_encode(['error' => "Prescription #$id not found."]); break; }

        // Count how many times dispensed = refills used
        $stmt2 = $pdo->prepare(
            "SELECT COUNT(*) as used FROM dispense WHERE Prescription_ID = :id"
        );
        $stmt2->execute([':id' => $id]);
        $rx['Refills_Used'] = (int)$stmt2->fetch()['used'];

        echo json_encode($rx);
        break;

    // ── PATIENT PRESCRIPTIONS (all for one patient) ───────────────────────────
    case 'patient_prescriptions':
        $q = $_GET['q'] ?? '';
        $patient = resolvePatient($pdo, $q);
        if (!$patient) {
            echo json_encode(['error' => "Patient \"$q\" not found."]);
            break;
        }

        $stmt = $pdo->prepare(
            "SELECT p.Prescription_ID, p.Date_Issued, p.Expiry_Date,
                    p.Instructions, p.Refills,
                    m.Drug_Name, m.Strength, m.DIN,
                    d.Fname AS Doc_Fname, d.Lname AS Doc_Lname, d.Specialty
             FROM prescriptions p
             JOIN contains c ON c.Prescription_ID = p.Prescription_ID
             JOIN medications m ON m.ID = c.ID
             LEFT JOIN prescribe_for pf ON pf.PrescriptionID = p.Prescription_ID
             LEFT JOIN doctors d ON d.ID = pf.DoctorID
             WHERE p.Patient_ID = :pid
             ORDER BY p.Date_Issued DESC"
        );
        $stmt->execute([':pid' => $patient['ID']]);
        echo json_encode([
            'patient_id'   => $patient['ID'],
            'patient_name' => $patient['Fname'] . ' ' . $patient['Lname'],
            'rows'         => $stmt->fetchAll()
        ]);
        break;

    // ── RECORD DISPENSE ───────────────────────────────────────────────────────
    case 'record_dispense':
        $empId = (int)($_POST['emp_id']    ?? 0);
        $rxId  = (int)($_POST['rx_id']     ?? 0);
        $pay   =       $_POST['pay_method'] ?? '';

        if (!$empId || !$rxId || !$pay) {
            echo json_encode(['error' => 'Missing required fields.']); break;
        }

        $emp = $pdo->prepare("SELECT ID, Fname, Lname, Role FROM employees WHERE ID = :id");
        $emp->execute([':id' => $empId]);
        $emp = $emp->fetch();
        if (!$emp) { echo json_encode(['error' => "Employee ID $empId not found. Valid: 1–7."]); break; }

        $rx = $pdo->prepare("SELECT Prescription_ID, Expiry_Date, Patient_ID FROM prescriptions WHERE Prescription_ID = :id");
        $rx->execute([':id' => $rxId]);
        $rx = $rx->fetch();
        if (!$rx) { echo json_encode(['error' => "Prescription #$rxId not found. Valid: 1–9."]); break; }

        if ($rx['Expiry_Date'] && $rx['Expiry_Date'] !== '0000-00-00' && strtotime($rx['Expiry_Date']) < time()) {
            echo json_encode(['error' => "Prescription #$rxId expired on {$rx['Expiry_Date']}. Cannot dispense."]); break;
        }

        // Check PRIMARY KEY constraint (EmpID + Prescription_ID must be unique)
        $chk = $pdo->prepare("SELECT COUNT(*) as n FROM dispense WHERE EmpID = :e AND Prescription_ID = :r");
        $chk->execute([':e' => $empId, ':r' => $rxId]);
        if ($chk->fetch()['n'] > 0) {
            echo json_encode(['error' => "{$emp['Fname']} {$emp['Lname']} has already dispensed prescription #$rxId."]); break;
        }

        $invoiceNo = rand(10000, 99999);
        $today     = date('Y-m-d');

        $ins = $pdo->prepare(
            "INSERT INTO dispense (EmpID, Prescription_ID, Invoice_No, Pay_Method, Date_Of_Invoice)
             VALUES (:emp, :rx, :inv, :pay, :date)"
        );
        $ins->execute([':emp' => $empId, ':rx' => $rxId, ':inv' => $invoiceNo, ':pay' => $pay, ':date' => $today]);

        // Get medication for confirmation
        $med = $pdo->prepare(
            "SELECT m.Drug_Name, m.Strength, m.Cost
             FROM medications m JOIN contains c ON c.ID = m.ID
             WHERE c.Prescription_ID = :id LIMIT 1"
        );
        $med->execute([':id' => $rxId]);
        $med = $med->fetch();

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
    case 'payment_history':
        $q = $_GET['q'] ?? '';
        $patient = resolvePatient($pdo, $q);
        if (!$patient) { echo json_encode(['error' => "Patient \"$q\" not found."]); break; }

        $stmt = $pdo->prepare(
            "SELECT d.Invoice_No, d.Date_Of_Invoice, d.Pay_Method,
                    p.Prescription_ID,
                    m.Drug_Name, m.Strength, m.Cost,
                    e.Fname AS Emp_Fname, e.Lname AS Emp_Lname
             FROM dispense d
             JOIN prescriptions p ON p.Prescription_ID = d.Prescription_ID
             JOIN contains c ON c.Prescription_ID = p.Prescription_ID
             JOIN medications m ON m.ID = c.ID
             JOIN employees e ON e.ID = d.EmpID
             WHERE p.Patient_ID = :pid
             ORDER BY d.Date_Of_Invoice DESC"
        );
        $stmt->execute([':pid' => $patient['ID']]);
        echo json_encode(['patient' => $patient, 'rows' => $stmt->fetchAll()]);
        break;

    // ── STAFF OPERATIONS LOG ──────────────────────────────────────────────────
    case 'staff_log':
        $q    = $_GET['q']    ?? '';
        $date = $_GET['date'] ?? '';

        $empId = 0;
        if ($q !== '') {
            $e = $pdo->prepare(
                "SELECT ID, Fname, Lname, Role FROM employees
                 WHERE ID = :id OR Lname = :name OR CONCAT(Fname,' ',Lname) = :full"
            );
            $e->execute([':id' => $q, ':name' => $q, ':full' => $q]);
            $found = $e->fetch();
            if (!$found) { echo json_encode(['error' => "Employee \"$q\" not found. Try ID (1–7) or name."]); break; }
            $empId = $found['ID'];
        }

        $stmt = $pdo->prepare(
            "SELECT d.Invoice_No, d.Date_Of_Invoice, d.Pay_Method,
                    d.Prescription_ID,
                    e.Fname, e.Lname, e.Role,
                    m.Drug_Name, m.Strength
             FROM dispense d
             JOIN employees e ON e.ID = d.EmpID
             JOIN contains c ON c.Prescription_ID = d.Prescription_ID
             JOIN medications m ON m.ID = c.ID
             WHERE (:emp_id = 0 OR d.EmpID = :emp_id2)
               AND (:date = '' OR d.Date_Of_Invoice = :date2)
             ORDER BY d.Date_Of_Invoice DESC"
        );
        $stmt->execute([
            ':emp_id'  => $empId, ':emp_id2' => $empId,
            ':date'    => $date,  ':date2'   => $date,
        ]);
        echo json_encode($stmt->fetchAll());
        break;

    // ── MEDICATION SEARCH ─────────────────────────────────────────────────────
    case 'medication_search':
        $q = '%' . ($_GET['q'] ?? '') . '%';
        $stmt = $pdo->prepare(
            "SELECT ID, Drug_Name, Manufacturer, Strength, Cost, DIN, Stock_Qty, Qty_per_unit
             FROM medications
             WHERE Drug_Name LIKE :q OR DIN LIKE :q OR Strength LIKE :q"
        );
        $stmt->execute([':q' => $q]);
        echo json_encode($stmt->fetchAll());
        break;

    // ── COVERAGE ELIGIBILITY ──────────────────────────────────────────────────
    case 'coverage_eligibility':
        $q   = $_GET['q']   ?? '';
        $din = $_GET['din'] ?? '';

        $patient = resolvePatient($pdo, $q);
        if (!$patient) { echo json_encode(['error' => "Patient \"$q\" not found."]); break; }

        $stmt = $pdo->prepare(
            "SELECT i.ID as InsID, i.Iname, i.Phone as InsPhone, i.Notes as PlanNotes,
                    ii.PolicyNo, ii.MemberID, ii.Notes as CoverageType
             FROM is_insured ii
             JOIN insurance i ON i.ID = ii.InsID
             WHERE ii.PatID = :pid"
        );
        $stmt->execute([':pid' => $patient['ID']]);
        $coverage = $stmt->fetchAll();

        $med = null;
        if ($din) {
            $stmt2 = $pdo->prepare(
                "SELECT ID, Drug_Name, Strength, Cost, DIN
                 FROM medications
                 WHERE DIN = :din OR Drug_Name LIKE :name
                 LIMIT 1"
            );
            $stmt2->execute([':din' => $din, ':name' => '%' . $din . '%']);
            $med = $stmt2->fetch();
        }

        echo json_encode(['patient' => $patient, 'coverage' => $coverage, 'medication' => $med]);
        break;

    // ── COVERAGE LIMITS ───────────────────────────────────────────────────────
    case 'coverage_limits':
        $policy = $_GET['policy'] ?? '';
        $din    = $_GET['din']    ?? '';

        $stmt = $pdo->prepare(
            "SELECT ii.PolicyNo, ii.MemberID, ii.Notes AS CoverageType,
                    i.ID AS InsID, i.Iname, i.Notes AS PlanNotes,
                    p.Fname, p.Lname
             FROM is_insured ii
             JOIN insurance i ON i.ID = ii.InsID
             JOIN patients p ON p.ID = ii.PatID
             WHERE ii.PolicyNo = :policy"
        );
        $stmt->execute([':policy' => $policy]);
        $row = $stmt->fetch();
        if (!$row) { echo json_encode(['error' => "Policy \"$policy\" not found. Valid: 1–7."]); break; }

        $med = null;
        if ($din) {
            $stmt2 = $pdo->prepare(
                "SELECT ID, Drug_Name, Strength, Cost FROM medications
                 WHERE DIN = :din OR Drug_Name LIKE :name LIMIT 1"
            );
            $stmt2->execute([':din' => $din, ':name' => '%' . $din . '%']);
            $med = $stmt2->fetch();
        }
        echo json_encode(['policy' => $row, 'medication' => $med]);
        break;

    // ── ALL EMPLOYEES ─────────────────────────────────────────────────────────
    case 'all_employees':
        $stmt = $pdo->query(
            "SELECT ID, Fname, Lname, Role, Phone, Email FROM employees ORDER BY Role, Lname"
        );
        echo json_encode($stmt->fetchAll());
        break;

    default:
        echo json_encode(['error' => "Unknown action: $action"]);
        break;
}
?>
