-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Host: 127.0.0.1
-- Generation Time: Mar 30, 2026 at 06:18 AM
-- Server version: 10.4.32-MariaDB
-- PHP Version: 8.2.12

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Database: `pharmacydb`
--

-- --------------------------------------------------------

--
-- Table structure for table `contains`
--

CREATE TABLE `contains` (
  `ID` int(11) NOT NULL,
  `Prescription_ID` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `contains`
--

INSERT INTO `contains` (`ID`, `Prescription_ID`) VALUES
(6, 1),
(7, 2),
(8, 3),
(9, 4),
(10, 5),
(11, 6),
(12, 7),
(13, 8),
(14, 9);

-- --------------------------------------------------------

--
-- Table structure for table `dependents`
--

CREATE TABLE `dependents` (
  `PatID` int(11) NOT NULL,
  `Name` varchar(70) NOT NULL,
  `DOB` date DEFAULT NULL,
  `Allergies` varchar(100) DEFAULT NULL,
  `Medical_History` varchar(400) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `dependents`
--

INSERT INTO `dependents` (`PatID`, `Name`, `DOB`, `Allergies`, `Medical_History`) VALUES
(1, 'James', '2006-05-28', 'Peanuts', 'Asthma'),
(1, 'Lily', '2010-03-15', 'None', 'Healthy'),
(2, 'Ethan', '2008-11-02', 'Dust', 'Allergic rhinitis'),
(2, 'Sophia', '2012-07-21', 'None', 'Healthy'),
(3, 'Emma', '2014-06-18', 'None', 'Healthy'),
(3, 'Noah', '2005-09-10', 'Shellfish', 'Eczema'),
(4, 'Mason', '2013-04-12', 'None', 'Healthy'),
(5, 'Olivia', '2011-01-30', 'None', 'Healthy'),
(6, 'Ava', '2007-08-25', 'Milk', 'Lactose intolerance'),
(7, 'Lucas', '2009-12-18', 'Pollen', 'Mild asthma');

-- --------------------------------------------------------

--
-- Table structure for table `dispense`
--

CREATE TABLE `dispense` (
  `EmpID` int(11) NOT NULL,
  `Prescription_ID` int(11) NOT NULL,
  `Invoice_No` int(11) DEFAULT NULL,
  `Pay_Method` varchar(50) DEFAULT NULL,
  `Date_Of_Invoice` date DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `dispense`
--

INSERT INTO `dispense` (`EmpID`, `Prescription_ID`, `Invoice_No`, `Pay_Method`, `Date_Of_Invoice`) VALUES
(2, 1, 10004, 'VISA', '2026-03-05'),
(5, 2, 10002, 'CASH', '2026-03-03'),
(7, 2, 10006, 'MASTERCARD', '2026-03-07'),
(1, 3, 10000, 'VISA', '2026-03-01'),
(4, 3, 10005, 'CASH', '2026-03-06'),
(3, 4, 10001, 'MASTERCARD', '2026-03-02'),
(5, 5, 10003, 'DEBIT', '2026-03-04');

-- --------------------------------------------------------

--
-- Table structure for table `doctors`
--

CREATE TABLE `doctors` (
  `ID` int(11) NOT NULL,
  `Fname` varchar(70) DEFAULT NULL,
  `Lname` varchar(70) DEFAULT NULL,
  `Specialty` varchar(70) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `doctors`
--

INSERT INTO `doctors` (`ID`, `Fname`, `Lname`, `Specialty`) VALUES
(1, 'James', 'Mitchell', 'General Practice'),
(2, 'Sarah', 'Nguyen', 'Cardiology'),
(3, 'David', 'Patel', 'Dermatology');

-- --------------------------------------------------------

--
-- Table structure for table `employees`
--

CREATE TABLE `employees` (
  `ID` int(11) NOT NULL,
  `Fname` varchar(70) NOT NULL,
  `Lname` varchar(70) NOT NULL,
  `Street` varchar(70) DEFAULT NULL,
  `City` varchar(70) DEFAULT NULL,
  `Prov` varchar(3) DEFAULT NULL,
  `PostCode` varchar(70) DEFAULT NULL,
  `Phone` varchar(25) DEFAULT NULL,
  `Email` varchar(254) DEFAULT NULL,
  `DOB` date DEFAULT NULL,
  `SIN` int(11) NOT NULL,
  `Role` varchar(20) NOT NULL,
  `PharmID` varchar(30) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `employees`
--

INSERT INTO `employees` (`ID`, `Fname`, `Lname`, `Street`, `City`, `Prov`, `PostCode`, `Phone`, `Email`, `DOB`, `SIN`, `Role`, `PharmID`) VALUES
(1, 'Ava', 'Nguyen', '123 Granville St', 'Vancouver', 'BC', 'V6Z1L2', '604-111-1111', 'ava@gmail.com', '1998-05-10', 111111111, 'Pharmacist', 'A1001'),
(2, 'Liam', 'Patel', '456 Robson St', 'Vancouver', 'BC', 'V6B2B7', '604-222-2222', 'liam@gmail.com', '1995-08-21', 222222222, 'Assistant', 'A1002'),
(3, 'Emma', 'Chen', '789 Broadway W', 'Vancouver', 'BC', 'V5Z1J5', '604-333-3333', 'emma@gmail.com', '1997-03-15', 333333333, 'Technician', 'A1003'),
(4, 'Noah', 'Kim', '321 Main St', 'Vancouver', 'BC', 'V6A2T2', '604-444-4444', 'noah@gmail.com', '1996-11-30', 444444444, 'Pharmacist', 'A1004'),
(5, 'Sophia', 'Martinez', '654 Kingsway', 'Vancouver', 'BC', 'V5V3C4', '604-555-5555', 'sophia@gmail.com', '1999-01-25', 555555555, 'Assistant', 'A1005'),
(6, 'Ethan', 'Singh', '987 Commercial Dr', 'Vancouver', 'BC', 'V5L3W9', '604-666-6666', 'ethan@gmail.com', '1994-07-12', 666666666, 'Technician', 'A1006'),
(7, 'Olivia', 'Garcia', '159 Hastings St', 'Vancouver', 'BC', 'V6A1P6', '604-777-7777', 'olivia@gmail.com', '1998-09-18', 777777777, 'Pharmacist', 'A1007');

-- --------------------------------------------------------

--
-- Table structure for table `handles`
--

CREATE TABLE `handles` (
  `ID` int(11) NOT NULL,
  `EmpID` int(11) NOT NULL,
  `Order_ID` int(11) NOT NULL,
  `Qty` int(11) DEFAULT NULL,
  `Qty_Received` int(11) DEFAULT NULL,
  `Notes` varchar(200) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `handles`
--

INSERT INTO `handles` (`ID`, `EmpID`, `Order_ID`, `Qty`, `Qty_Received`, `Notes`) VALUES
(3, 2, 1, 200, 150, ''),
(5, 1, 2, 180, 160, ''),
(7, 4, 3, 250, 200, ''),
(9, 6, 4, 300, 280, ''),
(12, 3, 5, 220, 210, '');

-- --------------------------------------------------------

--
-- Table structure for table `insurance`
--

CREATE TABLE `insurance` (
  `ID` int(11) NOT NULL,
  `Iname` varchar(70) NOT NULL,
  `Phone` varchar(25) DEFAULT NULL,
  `Notes` varchar(70) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `insurance`
--

INSERT INTO `insurance` (`ID`, `Iname`, `Phone`, `Notes`) VALUES
(1234, 'Sun Life', '6041234567', 'Comprehensive plan'),
(2234, 'Blue Cross', '6042345678', 'Basic coverage'),
(3234, 'Manulife', '6043456789', 'Premium plan'),
(4234, 'Great-West Life', '6044567890', 'Standard coverage');

-- --------------------------------------------------------

--
-- Table structure for table `insurance_seq`
--

CREATE TABLE `insurance_seq` (
  `next_not_cached_value` bigint(21) NOT NULL,
  `minimum_value` bigint(21) NOT NULL,
  `maximum_value` bigint(21) NOT NULL,
  `start_value` bigint(21) NOT NULL COMMENT 'start value when sequences is created or value if RESTART is used',
  `increment` bigint(21) NOT NULL COMMENT 'increment value',
  `cache_size` bigint(21) UNSIGNED NOT NULL,
  `cycle_option` tinyint(1) UNSIGNED NOT NULL COMMENT '0 if no cycles are allowed, 1 if the sequence should begin a new cycle when maximum_value is passed',
  `cycle_count` bigint(21) NOT NULL COMMENT 'How many cycles have been done'
) ENGINE=InnoDB;

--
-- Dumping data for table `insurance_seq`
--

INSERT INTO `insurance_seq` (`next_not_cached_value`, `minimum_value`, `maximum_value`, `start_value`, `increment`, `cache_size`, `cycle_option`, `cycle_count`) VALUES
(1234, 1, 9223372036854775806, 1234, 1000, 0, 0, 0);

-- --------------------------------------------------------

--
-- Table structure for table `is_insured`
--

CREATE TABLE `is_insured` (
  `InsID` int(11) NOT NULL,
  `PatID` int(11) NOT NULL,
  `PolicyNo` int(11) NOT NULL,
  `MemberID` int(11) NOT NULL,
  `Notes` varchar(70) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `is_insured`
--

INSERT INTO `is_insured` (`InsID`, `PatID`, `PolicyNo`, `MemberID`, `Notes`) VALUES
(1234, 1, 1, 1111111, 'Primary'),
(1234, 5, 5, 1111115, 'Secondary'),
(2234, 2, 2, 1111112, 'Primary'),
(2234, 6, 6, 1111116, 'Secondary'),
(3234, 3, 3, 1111113, 'Primary'),
(3234, 7, 7, 1111117, 'Secondary'),
(4234, 4, 4, 1111114, 'Primary');

-- --------------------------------------------------------

--
-- Table structure for table `makes_orders`
--

CREATE TABLE `makes_orders` (
  `EmpId` int(11) NOT NULL,
  `VID` int(11) NOT NULL,
  `OID` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `makes_orders`
--

INSERT INTO `makes_orders` (`EmpId`, `VID`, `OID`) VALUES
(1, 1, 1),
(1, 1, 2),
(3, 1, 3),
(3, 1, 4),
(6, 1, 5);

-- --------------------------------------------------------

--
-- Table structure for table `medications`
--

CREATE TABLE `medications` (
  `ID` int(11) NOT NULL,
  `Drug_Name` varchar(70) DEFAULT NULL,
  `Manufacturer` varchar(70) DEFAULT NULL,
  `Strength` varchar(70) DEFAULT NULL,
  `Cost` double DEFAULT NULL,
  `DIN` int(11) DEFAULT NULL,
  `Qty_per_unit` int(11) DEFAULT NULL,
  `Stock_Qty` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `medications`
--

INSERT INTO `medications` (`ID`, `Drug_Name`, `Manufacturer`, `Strength`, `Cost`, `DIN`, `Qty_per_unit`, `Stock_Qty`) VALUES
(1, 'Tylenol', 'Johnson & Johnson', '500mg', 9.99, 2394481, 15, 200),
(2, 'Advil', 'Pfizer', '200mg', 12.5, 2394482, 10, 150),
(3, 'Aspirin', 'Bayer', '325mg', 8.75, 2394483, 25, 400),
(4, 'Amoxicillin', 'Teva', '250mg', 15.2, 2394484, 30, 500),
(5, 'Metformin', 'Sandoz', '500mg', 11.3, 2394485, 12, 180),
(6, 'Hydrocortisone Cream', 'Pfizer', '1% topical cream', 12.99, 2394486, 35, 300),
(7, 'Amoxicillin', 'Teva', '500mg capsule', 18.49, 2394487, 18, 220),
(8, 'Pancrelipase', 'AbbVie', '10000 units capsule', 45.99, 2394488, 22, 350),
(9, 'Ibuprofen', 'Apotex', '400mg tablet', 6.99, 2394489, 8, 120),
(10, 'Lisinopril', 'Auro Pharma Inc', '10mg tablet', 15.49, 2394480, 16, 260),
(11, 'Alendronate', 'Accord Healthcare Inc', '70mg tablet', 38.99, 2381494, 14, 240),
(12, 'Humira', 'AbbVie', '40mg/0.8ml injection', 1850, 2381391, 28, 450),
(13, 'Lactase Enzyme', 'Kirkland', '9000 FCC units capsule', 18.99, 2394490, 35, 600),
(14, 'Diphenhydramine', 'Benadryl', '25mg tablet', 9.99, 2194390, 20, 300);

-- --------------------------------------------------------

--
-- Table structure for table `orders`
--

CREATE TABLE `orders` (
  `Order_ID` int(11) NOT NULL,
  `Order_Date` date NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `orders`
--

INSERT INTO `orders` (`Order_ID`, `Order_Date`) VALUES
(1, '2026-02-01'),
(2, '2026-02-05'),
(3, '2026-02-10'),
(4, '0000-00-00'),
(5, '0000-00-00');

-- --------------------------------------------------------

--
-- Table structure for table `patients`
--

CREATE TABLE `patients` (
  `ID` int(11) NOT NULL,
  `PHN` int(11) DEFAULT NULL,
  `Fname` varchar(70) NOT NULL,
  `Lname` varchar(70) NOT NULL,
  `DOB` date DEFAULT NULL,
  `St` varchar(70) DEFAULT NULL,
  `City` varchar(70) DEFAULT NULL,
  `PostCode` varchar(70) DEFAULT NULL,
  `Country` varchar(70) DEFAULT NULL,
  `Phone` varchar(25) DEFAULT NULL,
  `Email` varchar(254) DEFAULT NULL,
  `Allergies` varchar(70) DEFAULT NULL,
  `Medical_History` varchar(200) DEFAULT NULL,
  `Notes` varchar(70) DEFAULT NULL,
  `Prov` varchar(70) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `patients`
--

INSERT INTO `patients` (`ID`, `PHN`, `Fname`, `Lname`, `DOB`, `St`, `City`, `PostCode`, `Country`, `Phone`, `Email`, `Allergies`, `Medical_History`, `Notes`, `Prov`) VALUES
(1, NULL, 'Kerry', 'Maniscalco', '1972-05-04', '1231 Keith Road', 'North Vancouver', 'V7T 1N1', 'CANADA', '604-987-8676', 'KerryJManiscalco@armyspy.com', 'Nuts', 'Excema', '', 'BC'),
(2, 231413566, 'Xiong', 'Yao', '1992-09-10', '526 Speers Road', 'Oakville', 'L6H 3H5 ', 'CANADA', '905-483-4529', 'XiongY88888@gmail.com', '', '', '', 'ON'),
(3, 223341344, 'Raymond', 'Yao', '1988-08-01', 'Rue Henri Lambert 268', 'Oakville', 'L6H 3H5 ', 'CANADA', '905-482-4112', 'Ray888@yahoo.com', 'Gluten', 'Celiac', '', 'ON'),
(4, NULL, 'Amanda', 'Dias', '1970-08-01', 'Rue Henri Lambert 268', 'Harsin', '6950', 'BELGIUM', '0474 48 83 61', '', '', '', '', ''),
(5, NULL, 'Daniel', 'Steffensen', '1970-08-01', '3900 Yonge Street', 'Toronto', 'M4W 1J7', 'CANADA', '416-973-5734', '', '', '', '', 'ON'),
(6, 123456789, 'Ayden', 'Watt', '1990-03-15', '452 Granville Street', 'Vancouver', 'V6C 1V4', 'CANADA', '604-123-4567', 'AydenWatt@gmail.com', 'Lactose', '', '', 'BC'),
(7, 987654321, 'Mina', 'Tokushige', '1988-07-22', '452 Granville Street', 'Vancouver', 'V6C 1V4', 'CANADA', '604-765-4321', 'MinaTokushige@gmail.com', 'Shrimp', '', '', 'BC'),
(8, NULL, 'Andrew', 'Stevens', '1963-03-20', '123 Robson St', 'Vancouver', 'V8N2K9', 'CANADA', '', '', '', '', '', 'BC'),
(9, NULL, 'Faye ', 'Stevens', '1968-07-08', '', '', '', '', '', '', '', '', '', '');

-- --------------------------------------------------------

--
-- Table structure for table `practices`
--

CREATE TABLE `practices` (
  `ID` int(11) NOT NULL,
  `Pname` varchar(70) DEFAULT NULL,
  `St` varchar(70) DEFAULT NULL,
  `Prov` varchar(3) DEFAULT NULL,
  `City` varchar(70) DEFAULT NULL,
  `PostCode` varchar(70) DEFAULT NULL,
  `Phone` varchar(25) DEFAULT NULL,
  `Fax` varchar(25) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `practices`
--

INSERT INTO `practices` (`ID`, `Pname`, `St`, `Prov`, `City`, `PostCode`, `Phone`, `Fax`) VALUES
(1, 'Vancouver Medical Clinic', '123 Robson Street', 'BC', 'Vancouver', 'V6B 1B9', '604-555-0101', '604-555-0102'),
(2, 'North Shore Health Centre', '456 Lonsdale Avenue', 'BC', 'North Vancouver', 'V7M 2G3', '604-555-0201', '604-555-0202'),
(3, 'Oakville Family Practice', '789 Kerr Street', 'ON', 'Oakville', 'L6K 3C7', '905-555-0301', '905-555-0302'),
(4, 'Toronto Medical Associates', '321 Yonge Street', 'ON', 'Toronto', 'M4W 2G8', '416-555-0401', '416-555-0402'),
(5, 'Burnaby Health Clinic', '654 Hastings Street', 'BC', 'Burnaby', 'V5B 1R2', '604-555-0501', '604-555-0502');

-- --------------------------------------------------------

--
-- Table structure for table `practice_at`
--

CREATE TABLE `practice_at` (
  `DocID` int(11) NOT NULL,
  `PracID` int(11) NOT NULL,
  `ExtNo` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `practice_at`
--

INSERT INTO `practice_at` (`DocID`, `PracID`, `ExtNo`) VALUES
(1, 1, 101),
(2, 2, 201),
(3, 3, 301);

-- --------------------------------------------------------

--
-- Table structure for table `prescribe_for`
--

CREATE TABLE `prescribe_for` (
  `DoctorID` int(11) NOT NULL,
  `PrescriptionID` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `prescribe_for`
--

INSERT INTO `prescribe_for` (`DoctorID`, `PrescriptionID`) VALUES
(1, 2),
(1, 3),
(1, 5),
(1, 8),
(2, 1),
(2, 4),
(3, 6),
(3, 7),
(3, 9);

-- --------------------------------------------------------

--
-- Table structure for table `prescriptions`
--

CREATE TABLE `prescriptions` (
  `Prescription_ID` int(11) NOT NULL,
  `Instructions` varchar(500) DEFAULT NULL,
  `Refills` int(11) DEFAULT NULL,
  `Date_Issued` date DEFAULT NULL,
  `Expiry_Date` date DEFAULT NULL,
  `Patient_ID` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `prescriptions`
--

INSERT INTO `prescriptions` (`Prescription_ID`, `Instructions`, `Refills`, `Date_Issued`, `Expiry_Date`, `Patient_ID`) VALUES
(1, 'Apply a thin layer to affected area twice daily. Avoid contact with eyes.', 3, '2024-01-15', '2025-01-15', 1),
(2, 'Take 1 tablet by mouth once daily in the morning.', 2, '2024-02-10', '2025-02-10', 2),
(3, 'Take 1 capsule by mouth once daily with meals. Avoid gluten-containing foods.', 6, '2024-03-05', '2025-03-05', 3),
(4, 'Take 2 tablets by mouth every 6 hours as needed for pain. Do not exceed 8 tablets per day.', 0, '2024-04-20', '2024-10-20', 4),
(5, 'Take 1 tablet by mouth once daily with or without food.', 1, '2024-05-15', '2025-05-15', 5),
(6, 'Take 1 tablet by mouth once weekly. Take with full glass of water and remain upright for 30 minutes.', 2, '2024-06-01', '2025-06-01', 1),
(7, 'Inject 0.5ml subcutaneously once every two weeks. Rotate injection sites.', 1, '2024-07-10', '2025-07-10', 3),
(8, 'Take 1 lactase enzyme capsule before every meal containing dairy products.', 2, '2024-08-05', '2025-08-05', 6),
(9, 'Take 1 antihistamine tablet immediately upon accidental shrimp exposure. Carry EpiPen at all times.', 0, '2024-08-10', '2025-08-10', 7);

-- --------------------------------------------------------

--
-- Table structure for table `vendors`
--

CREATE TABLE `vendors` (
  `VendorID` int(11) NOT NULL,
  `VendorName` varchar(70) NOT NULL,
  `Street` varchar(70) DEFAULT NULL,
  `City` varchar(70) DEFAULT NULL,
  `Prov` varchar(3) DEFAULT NULL,
  `PostCode` varchar(70) DEFAULT NULL,
  `Phone` varchar(25) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `vendors`
--

INSERT INTO `vendors` (`VendorID`, `VendorName`, `Street`, `City`, `Prov`, `PostCode`, `Phone`) VALUES
(1, 'McKesson', '123 Distribution Ave', 'Vancouver', 'BC', 'V5K 0A1', '6041237890');

--
-- Indexes for dumped tables
--

--
-- Indexes for table `contains`
--
ALTER TABLE `contains`
  ADD PRIMARY KEY (`ID`,`Prescription_ID`),
  ADD KEY `Prescription_ID` (`Prescription_ID`);

--
-- Indexes for table `dependents`
--
ALTER TABLE `dependents`
  ADD PRIMARY KEY (`PatID`,`Name`);

--
-- Indexes for table `dispense`
--
ALTER TABLE `dispense`
  ADD PRIMARY KEY (`Prescription_ID`,`EmpID`),
  ADD KEY `EmpID` (`EmpID`);

--
-- Indexes for table `doctors`
--
ALTER TABLE `doctors`
  ADD PRIMARY KEY (`ID`);

--
-- Indexes for table `employees`
--
ALTER TABLE `employees`
  ADD PRIMARY KEY (`ID`),
  ADD UNIQUE KEY `PharmID` (`PharmID`);

--
-- Indexes for table `handles`
--
ALTER TABLE `handles`
  ADD PRIMARY KEY (`ID`,`EmpID`,`Order_ID`),
  ADD KEY `EmpID` (`EmpID`),
  ADD KEY `Order_ID` (`Order_ID`);

--
-- Indexes for table `insurance`
--
ALTER TABLE `insurance`
  ADD PRIMARY KEY (`ID`);

--
-- Indexes for table `is_insured`
--
ALTER TABLE `is_insured`
  ADD PRIMARY KEY (`InsID`,`PatID`,`PolicyNo`,`MemberID`),
  ADD KEY `PatID` (`PatID`);

--
-- Indexes for table `makes_orders`
--
ALTER TABLE `makes_orders`
  ADD PRIMARY KEY (`EmpId`,`VID`,`OID`),
  ADD KEY `VID` (`VID`),
  ADD KEY `OID` (`OID`);

--
-- Indexes for table `medications`
--
ALTER TABLE `medications`
  ADD PRIMARY KEY (`ID`),
  ADD UNIQUE KEY `DIN` (`DIN`);

--
-- Indexes for table `orders`
--
ALTER TABLE `orders`
  ADD PRIMARY KEY (`Order_ID`);

--
-- Indexes for table `patients`
--
ALTER TABLE `patients`
  ADD PRIMARY KEY (`ID`);

--
-- Indexes for table `practices`
--
ALTER TABLE `practices`
  ADD PRIMARY KEY (`ID`);

--
-- Indexes for table `practice_at`
--
ALTER TABLE `practice_at`
  ADD PRIMARY KEY (`DocID`,`PracID`),
  ADD KEY `PracID` (`PracID`);

--
-- Indexes for table `prescribe_for`
--
ALTER TABLE `prescribe_for`
  ADD PRIMARY KEY (`DoctorID`,`PrescriptionID`),
  ADD KEY `PrescriptionID` (`PrescriptionID`);

--
-- Indexes for table `prescriptions`
--
ALTER TABLE `prescriptions`
  ADD PRIMARY KEY (`Prescription_ID`),
  ADD KEY `Patient_ID` (`Patient_ID`);

--
-- Indexes for table `vendors`
--
ALTER TABLE `vendors`
  ADD PRIMARY KEY (`VendorID`);

--
-- Constraints for dumped tables
--

--
-- Constraints for table `contains`
--
ALTER TABLE `contains`
  ADD CONSTRAINT `contains_ibfk_1` FOREIGN KEY (`ID`) REFERENCES `medications` (`ID`),
  ADD CONSTRAINT `contains_ibfk_2` FOREIGN KEY (`Prescription_ID`) REFERENCES `prescriptions` (`Prescription_ID`);

--
-- Constraints for table `dependents`
--
ALTER TABLE `dependents`
  ADD CONSTRAINT `dependents_ibfk_1` FOREIGN KEY (`PatID`) REFERENCES `patients` (`ID`) ON DELETE CASCADE;

--
-- Constraints for table `dispense`
--
ALTER TABLE `dispense`
  ADD CONSTRAINT `dispense_ibfk_1` FOREIGN KEY (`EmpID`) REFERENCES `employees` (`ID`),
  ADD CONSTRAINT `dispense_ibfk_2` FOREIGN KEY (`Prescription_ID`) REFERENCES `prescriptions` (`Prescription_ID`);

--
-- Constraints for table `handles`
--
ALTER TABLE `handles`
  ADD CONSTRAINT `handles_ibfk_1` FOREIGN KEY (`ID`) REFERENCES `medications` (`ID`),
  ADD CONSTRAINT `handles_ibfk_2` FOREIGN KEY (`EmpID`) REFERENCES `employees` (`ID`),
  ADD CONSTRAINT `handles_ibfk_3` FOREIGN KEY (`Order_ID`) REFERENCES `orders` (`Order_ID`);

--
-- Constraints for table `is_insured`
--
ALTER TABLE `is_insured`
  ADD CONSTRAINT `is_insured_ibfk_1` FOREIGN KEY (`PatID`) REFERENCES `patients` (`ID`),
  ADD CONSTRAINT `is_insured_ibfk_2` FOREIGN KEY (`InsID`) REFERENCES `insurance` (`ID`);

--
-- Constraints for table `makes_orders`
--
ALTER TABLE `makes_orders`
  ADD CONSTRAINT `makes_orders_ibfk_1` FOREIGN KEY (`EmpId`) REFERENCES `employees` (`ID`),
  ADD CONSTRAINT `makes_orders_ibfk_2` FOREIGN KEY (`VID`) REFERENCES `vendors` (`VendorID`),
  ADD CONSTRAINT `makes_orders_ibfk_3` FOREIGN KEY (`OID`) REFERENCES `orders` (`Order_ID`);

--
-- Constraints for table `practice_at`
--
ALTER TABLE `practice_at`
  ADD CONSTRAINT `practice_at_ibfk_1` FOREIGN KEY (`DocID`) REFERENCES `doctors` (`ID`),
  ADD CONSTRAINT `practice_at_ibfk_2` FOREIGN KEY (`PracID`) REFERENCES `practices` (`ID`);

--
-- Constraints for table `prescribe_for`
--
ALTER TABLE `prescribe_for`
  ADD CONSTRAINT `prescribe_for_ibfk_1` FOREIGN KEY (`DoctorID`) REFERENCES `doctors` (`ID`),
  ADD CONSTRAINT `prescribe_for_ibfk_2` FOREIGN KEY (`PrescriptionID`) REFERENCES `prescriptions` (`Prescription_ID`);

--
-- Constraints for table `prescriptions`
--
ALTER TABLE `prescriptions`
  ADD CONSTRAINT `prescriptions_ibfk_1` FOREIGN KEY (`Patient_ID`) REFERENCES `patients` (`ID`) ON DELETE CASCADE;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
