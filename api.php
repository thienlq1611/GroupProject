<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
// Connect to database
$conn = new mysqli('127.0.0.1', 'root', 'root', 'pharmacydb');
if ($conn->connect_error) {
    http_response_code(500);
    echo json_encode(['error' => 'Connection failed: ' . $conn->connect_error]);
    exit;
}

// Get the action from the URL e.g. api.php?action=find_patient
$action = $_GET['action'] ?? '';

switch ($action) {

    // verify patient in the pharmacy's database for "Find Patient" feature
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

    // get a single patient's info for "Patient Information" feature
    case 'get_patient':
        $q = $conn->real_escape_string($_GET['q'] ?? '');

        $result = $conn->query(
            "SELECT ID, PHN, Fname, Lname, DOB, St, City, PostCode, Country, Phone, Email, Allergies, Medical_History, Notes, Prov
             FROM patients
             WHERE ID = '$q' OR PHN = '$q'"
        );
        $patient = $result->fetch_assoc();

        if (!$patient) {
            echo json_encode(['error' => "Patient \"$q\" not found."]);
            break;
        }

        $pid = $patient['ID'];

        // diplays insurance info for each patient 
        $result2 = $conn->query(
            "SELECT i.Iname, ii.PolicyNo, ii.MemberID, ii.Notes AS CoverageType
             FROM is_insured ii
             JOIN insurance i
             ON i.ID = ii.InsID
             WHERE ii.PatID = $pid"
        );
        $patient['insurance'] = $result2->fetch_all(MYSQLI_ASSOC);

        // displays dependent info for each patient
        $result3 = $conn->query(
            "SELECT Name, DOB, Allergies, Medical_History
             FROM dependents
             WHERE PatID = $pid"
        );
        $patient['dependents'] = $result3->fetch_all(MYSQLI_ASSOC);

        echo json_encode($patient);
        break;

    // retrieve patient personal information or medical record for "Patient Medical Records" feature
    // meets the requirement of Projection query
    case 'patient_records':
        $q    = $conn->real_escape_string($_GET['q']    ?? '');
        $type = $_GET['type'] ?? 'all';

        if ($type === 'contact') {
            $select = "Fname, Lname, Phone, Email, City";
        } elseif ($type === 'medical') {
            $select = "Fname, Lname, Allergies, Medical_History";
        } else {
            $select = "Fname, Lname, DOB, Phone, Email, City, Allergies, Medical_History";
        }

        $result = $conn->query("SELECT $select 
                                FROM patients 
                                WHERE ID = '$q'");

        if (!$result) { echo json_encode(['error' => "Patient \"$q\" not found."]); break; }
        $row = $result->fetch_assoc();
        if (!$row) { echo json_encode(['error' => "Patient \"$q\" not found."]); break; }
        echo json_encode($row);
        break;

    // retrieve prescriptions details for "Track Prescription" feature
    // meets the requirement of Join query
    case 'get_prescription':
        $id = (int)($_GET['id'] ?? 0);

        $result = $conn->query(
            "SELECT p.Prescription_ID, p.Date_Issued, p.Expiry_Date, p.Instructions, p.Refills,
                    pt.Fname, pt.Lname,
                    m.Drug_Name, m.Strength, m.DIN, m.Cost,
                    d.Fname AS Doc_Fname, d.Lname AS Doc_Lname, d.Specialty
             FROM prescriptions p
             JOIN patients pt
             ON pt.ID = p.Patient_ID
             JOIN contains c
             ON c.Prescription_ID = p.Prescription_ID
             JOIN medications m
             ON m.ID = c.ID
             JOIN prescribe_for pf
             ON pf.PrescriptionID = p.Prescription_ID
             JOIN doctors d
             ON d.ID = pf.DoctorID
             WHERE p.Prescription_ID = $id
             LIMIT 1"
        );
        $rx = $result->fetch_assoc();

        if (!$rx) {
            echo json_encode(['error' => "Prescription #$id not found."]);
            break;
        }

        // count the number of times this prescription was dispensed to calculate the remaining refills in pharmacy.js
        $result2 = $conn->query(
            "SELECT COUNT(*) AS used
             FROM dispense
             WHERE Prescription_ID = $id"
        );
        $rx['Refills_Used'] = (int)$result2->fetch_assoc()['used'];

        echo json_encode($rx);
        break;

    // Retrieves all prescriptions for a patient for "Prescription History" feature
    // meets the requirement of Selection query
    case 'patient_prescriptions':
        $q = $conn->real_escape_string($_GET['q'] ?? '');

        // find and display patients' name
        $result = $conn->query(
            "SELECT ID, Fname, Lname
             FROM patients
             WHERE ID = '$q'"
        );
        $patient = $result->fetch_assoc();

        if (!$patient) {
            echo json_encode(['error' => "Patient \"$q\" not found."]);
            break;
        }

        $pid = $patient['ID'];

        // retrieves all prescriptions for the patient selected
        $result2 = $conn->query(
            "SELECT p.Prescription_ID, p.Date_Issued, p.Expiry_Date, p.Instructions, p.Refills,
                    m.Drug_Name, m.Strength, m.DIN,
                    d.Fname AS Doc_Fname, d.Lname AS Doc_Lname
             FROM prescriptions p
             JOIN contains c
             ON c.Prescription_ID = p.Prescription_ID
             JOIN medications m
             ON m.ID = c.ID
             JOIN prescribe_for pf
             ON pf.PrescriptionID = p.Prescription_ID
             JOIN doctors d
             ON d.ID = pf.DoctorID
             WHERE p.Patient_ID = $pid
             ORDER BY p.Date_Issued DESC"
        );

        echo json_encode([
            'patient_id'   => $patient['ID'],
            'patient_name' => $patient['Fname'] . ' ' . $patient['Lname'],
            'rows'         => $result2->fetch_all(MYSQLI_ASSOC)
        ]);
        break;


    // retrieves payment history for "Payment History" feature
    case 'payment_history':
        $q = $conn->real_escape_string($_GET['q'] ?? '');

        $patient = $conn->query(

            "SELECT ID, Fname, Lname
             FROM patients
             WHERE ID = '$q'"

        )->fetch_assoc();

        if (!$patient) { echo json_encode(['error' => "Patient \"$q\" not found."]); break; }

        $pid = $patient['ID'];

        $result = $conn->query(
            "SELECT d.Invoice_No, d.Date_Of_Invoice, d.Pay_Method,
                    p.Prescription_ID,
                    m.Drug_Name, m.Strength, m.Cost,
                    e.Fname AS Emp_Fname, e.Lname AS Emp_Lname
             FROM dispense d
             JOIN prescriptions p 
             ON p.Prescription_ID = d.Prescription_ID
             JOIN contains c
             ON c.Prescription_ID = p.Prescription_ID
             JOIN medications m
             ON m.ID = c.ID
             JOIN employees e
             ON e.ID = d.EmpID
             WHERE p.Patient_ID = $pid
             ORDER BY d.Date_Of_Invoice DESC"
        );
        echo json_encode(['patient' => $patient, 'rows' => $result->fetch_all(MYSQLI_ASSOC)]);
        break;


    // retrieves medication inventory for "Medication Inventory" feature
    // meets the requirement for Aggregation query
    case 'medication_search':
        $q = '%' . $conn->real_escape_string($_GET['q'] ?? '') . '%';

        $result = $conn->query(
            "SELECT ID, Drug_Name, Manufacturer, Strength, Cost, DIN, Stock_Qty, Qty_per_unit
            FROM medications
            WHERE (Drug_Name LIKE '$q' OR DIN LIKE '$q')
            AND Stock_Qty = (SELECT MAX(Stock_Qty)
                            FROM medications)"
            
        );
        echo json_encode($result->fetch_all(MYSQLI_ASSOC));
        break;


    // verify patients' insurance coverage for a specific medication for "Coverage Eligibility" feature
    // meets the requirement for Join query
    case 'coverage_eligibility':
        $q   = $conn->real_escape_string($_GET['q']   ?? '');
        $din = $conn->real_escape_string($_GET['din'] ?? '');

        $patient = $conn->query(
            "SELECT ID, Fname, Lname
             FROM patients
             WHERE ID = '$q' OR Lname = '$q'"

        )->fetch_assoc();
        if (!$patient) { echo json_encode(['error' => "Patient \"$q\" not found."]); break; }

        $pid = $patient['ID'];

        $result = $conn->query(
            "SELECT i.Iname, ii.PolicyNo, ii.MemberID, ii.Notes AS CoverageType
             FROM is_insured ii
             JOIN insurance i
             ON i.ID = ii.InsID
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


    // finds patients with more prescriptions than the average for "High-Volume Patients" feature
    // meets the requirement for Nested Aggregation with Group By
    case 'high_volume_patients':
        $result = $conn->query(
            "SELECT pt.ID, pt.Fname, pt.Lname, COUNT(p.Prescription_ID) AS Prescription_Count
             FROM patients pt
             JOIN prescriptions p ON p.Patient_ID = pt.ID
             GROUP BY pt.ID, pt.Fname, pt.Lname
             HAVING COUNT(p.Prescription_ID) > ( SELECT AVG(Prescription_Count) FROM (
                     SELECT COUNT(Prescription_ID) AS Prescription_Count
                     FROM prescriptions
                     GROUP BY Patient_ID
                 ) AS counts
             )
             ORDER BY Prescription_Count DESC"
        );
        echo json_encode($result->fetch_all(MYSQLI_ASSOC));
        break;

    // delete patients from the database for "Delete Patient" feature
    // meets the requirement of Delete operation
    case 'delete_patient':
        $id = (int)($_GET['id'] ?? 0);

        $patient = $conn->query("SELECT ID, Fname, Lname 
                                FROM patients 
                                WHERE ID = $id")->fetch_assoc();

        if (!$patient) { echo json_encode(['error' => "Patient ID $id not found."]); break; }

        $conn->query("DELETE FROM patients WHERE ID = $id");

        echo json_encode(['success' => "Patient {$patient['Fname']} {$patient['Lname']} (ID $id) has been deleted."]);
        break;

    // update patients' contact information for "Update Patient" feature
    // meets the requirement of Update operation
    case 'update_patient':
        $id    = (int)($_GET['id']    ?? 0);
        $phone = $conn->real_escape_string($_GET['phone'] ?? '');
        $email = $conn->real_escape_string($_GET['email'] ?? '');
        $city  = $conn->real_escape_string($_GET['city']  ?? '');

        $patient = $conn->query("SELECT ID, Fname, Lname 
                                FROM patients WHERE ID = $id")->fetch_assoc();

        if (!$patient) { echo json_encode(['error' => "Patient ID $id not found."]); break; }

        $conn->query("UPDATE patients 
                    SET Phone = '$phone', Email = '$email', City = '$city' 
                    WHERE ID = $id");

        echo json_encode(['success' => "Patient {$patient['Fname']} {$patient['Lname']} updated successfully."]);
        break;

    // find vendors that supply every medication
    // meets the requirement of Division query
    case 'full_coverage_vendors':
        $result = $conn->query(
            "SELECT v.VendorID, v.Name
             FROM Vendors v
             WHERE NOT EXISTS (
                 SELECT m.ID FROM Medications m
                 WHERE NOT EXISTS (
                     SELECT * FROM Supplied_By sb
                     WHERE sb.VendID = v.VendorID AND sb.MedID = m.ID
                 )
             )"
        );
        echo json_encode($result->fetch_all(MYSQLI_ASSOC));
        break;

    // retrieve all employees for "All Employees" features
    //
    case 'all_employees':
        $result = $conn->query(
            "SELECT e.ID, e.Fname, e.Lname, r.RoleName AS Role, e.Phone, e.Email
             FROM employees e
             JOIN roles r 
             ON r.RoleID = e.RoleID
             ORDER BY r.RoleName, e.Lname"
        );
        echo json_encode($result->fetch_all(MYSQLI_ASSOC));
        break;

    default:
        echo json_encode(['error' => "Unknown action: $action"]);
        break;


    
}



$conn->close();
?>
