-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Host: 127.0.0.1
-- Generation Time: Mar 30, 2026 at 06:18 AM
-- Server version: 10.4.32-MariaDB
-- PHP Version: 8.2.12


CREATE DATABASE pharmacydb;

USE pharmacydb;

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

SET FOREIGN_KEY_CHECKS = 0;

-- 1. Doctors & Practices
CREATE TABLE Doctors (
  ID INT AUTO_INCREMENT PRIMARY KEY,
  Fname VARCHAR(70),
  Lname VARCHAR(70),
  Specialty VARCHAR(70)
);

CREATE TABLE Practices (
  ID INT AUTO_INCREMENT PRIMARY KEY,
  Pname VARCHAR(70),
  St VARCHAR(70),
  Prov VARCHAR(3),
  City VARCHAR(70),
  PostCode VARCHAR(70),
  Phone VARCHAR(25),
  Fax VARCHAR(25)
);

CREATE TABLE Practice_at (
  DocID INT,
  PracID INT,
  ExtNo INT,
  PRIMARY KEY (DocID, PracID),
  FOREIGN KEY (DocID) REFERENCES Doctors(ID),
  FOREIGN KEY (PracID) REFERENCES Practices(ID)
);

-- 2. Patients & Dependents
CREATE TABLE Patients (
  ID INT AUTO_INCREMENT PRIMARY KEY,
  PHN BIGINT,
  Fname VARCHAR(70) NOT NULL,
  Lname VARCHAR(70) NOT NULL,
  DOB DATE,
  St VARCHAR(70),
  City VARCHAR(70),
  PostCode VARCHAR(70),
  Country VARCHAR(70),
  Phone VARCHAR(25),
  Email VARCHAR(254),
  Allergies VARCHAR(70),
  Spouse_ID INT,
  Medical_History VARCHAR(200),
  Notes VARCHAR(70),
  Prov VARCHAR(70),
  FOREIGN KEY (Spouse_ID) REFERENCES Patients(ID)
);

CREATE TABLE Dependents (
  PatID INT NOT NULL,
  Name VARCHAR(70) NOT NULL,
  DOB DATE,
  Allergies VARCHAR(100),
  Medical_History VARCHAR(400),
  PRIMARY KEY (PatID, Name),
  FOREIGN KEY (PatID) REFERENCES Patients(ID) ON DELETE CASCADE
);

-- 3. Insurance
CREATE TABLE Insurance (
  ID INT PRIMARY KEY,
  Iname VARCHAR(70) NOT NULL,
  Phone VARCHAR(25),
  Notes VARCHAR(70)
);

-- 4. Is_Insured
CREATE TABLE Is_Insured (
  InsID INT,
  PatID INT,
  PolicyNo INT,
  MemberID INT,
  Notes VARCHAR(70),
  PRIMARY KEY (InsID, PatID, PolicyNo, MemberID),
  FOREIGN KEY (PatID) REFERENCES Patients(ID),
  FOREIGN KEY (InsID) REFERENCES Insurance(ID)
);

-- 5. Medications & Prescriptions
CREATE TABLE Medications (
  ID INT AUTO_INCREMENT PRIMARY KEY,
  Drug_Name VARCHAR(70),
  Manufacturer VARCHAR(70),
  Strength VARCHAR(70),
  Cost DECIMAL(10,2),
  DIN INT UNIQUE CHECK (DIN BETWEEN 10000000 AND 99999999),
  Qty_per_unit INT,
  Stock_Qty INT
);

CREATE TABLE Prescriptions (
  Prescription_ID INT AUTO_INCREMENT PRIMARY KEY,
  Instructions VARCHAR(500),
  Refills INT,
  Date_Issued DATE,
  Expiry_Date DATE,
  Patient_ID INT,
  FOREIGN KEY (Patient_ID) REFERENCES Patients(ID) ON DELETE CASCADE
);

-- 6. Roles & Employees
CREATE TABLE Roles (
  RoleID INT PRIMARY KEY,
  RoleName VARCHAR(50) UNIQUE NOT NULL
);

CREATE TABLE Employees (
  ID INT AUTO_INCREMENT PRIMARY KEY,
  Fname VARCHAR(70),
  Lname VARCHAR(70),
  Street VARCHAR(70),
  City VARCHAR(70),
  Prov VARCHAR(3),
  PostCode VARCHAR(70),
  Phone VARCHAR(25),
  Email VARCHAR(254),
  DOB DATE,
  SIN BIGINT,
  PharmID VARCHAR(30) UNIQUE,
  RoleID INT,
  FOREIGN KEY (RoleID) REFERENCES Roles(RoleID)
);

-- 7. Quote System
CREATE TABLE Quote_Status (
  StatusID INT PRIMARY KEY,
  Status_Name VARCHAR(50)
);

CREATE TABLE Vendors (
  VendorID INT PRIMARY KEY,
  Name VARCHAR(100),
  Contact VARCHAR(100),
  Notes VARCHAR(200)
);

CREATE TABLE Quotes (
  QuoteID INT PRIMARY KEY,
  QuoteDate DATE,
  Cost DECIMAL(10,2),
  StatusID INT,
  VendorID INT,
  PrescriptionID INT UNIQUE,
  EmpID INT,
  FOREIGN KEY (StatusID) REFERENCES Quote_Status(StatusID),
  FOREIGN KEY (VendorID) REFERENCES Vendors(VendorID),
  FOREIGN KEY (PrescriptionID) REFERENCES Prescriptions(Prescription_ID),
  FOREIGN KEY (EmpID) REFERENCES Employees(ID)
);

-- 8. Orders 
CREATE TABLE Orders (
  Order_ID INT PRIMARY KEY,
  Order_Date DATE NOT NULL
);

-- 9. Contains: links Medications to Prescriptions 
CREATE TABLE Contains (
  ID INT,
  Prescription_ID INT,
  PRIMARY KEY (ID, Prescription_ID),
  FOREIGN KEY (ID) REFERENCES Medications(ID),
  FOREIGN KEY (Prescription_ID) REFERENCES Prescriptions(Prescription_ID)
);

-- 10. Dispense: records employee dispensing a prescription 
CREATE TABLE Dispense (
  EmpID INT,
  Prescription_ID INT,
  Invoice_No INT,
  Pay_Method VARCHAR(50),
  Date_Of_Invoice DATE,
  PRIMARY KEY (Prescription_ID, EmpID),
  FOREIGN KEY (EmpID) REFERENCES Employees(ID),
  FOREIGN KEY (Prescription_ID) REFERENCES Prescriptions(Prescription_ID)
);

-- 11. Handles: links employees to medication orders 
CREATE TABLE Handles (
  ID INT,
  EmpID INT,
  Order_ID INT,
  Qty INT,
  Qty_Received INT,
  Notes VARCHAR(200),
  PRIMARY KEY (ID, EmpID, Order_ID),
  FOREIGN KEY (ID) REFERENCES Medications(ID),
  FOREIGN KEY (EmpID) REFERENCES Employees(ID),
  FOREIGN KEY (Order_ID) REFERENCES Orders(Order_ID)
);

-- 12. Makes_Orders: links employees to vendors and orders 
CREATE TABLE Makes_Orders (
  EmpID INT,
  VID INT,
  OID INT,
  PRIMARY KEY (EmpID, VID, OID),
  FOREIGN KEY (EmpID) REFERENCES Employees(ID),
  FOREIGN KEY (VID) REFERENCES Vendors(VendorID),
  FOREIGN KEY (OID) REFERENCES Orders(Order_ID)
);

-- 13. Prescribe_For: links doctors to prescriptions 
CREATE TABLE Prescribe_For (
  DoctorID INT,
  PrescriptionID INT,
  PRIMARY KEY (DoctorID, PrescriptionID),
  FOREIGN KEY (DoctorID) REFERENCES Doctors(ID),
  FOREIGN KEY (PrescriptionID) REFERENCES Prescriptions(Prescription_ID)
);

CREATE TABLE Supplied_By (
  MedID INT,
  VendID INT,
  PRIMARY KEY ( MedID, VendID),
  FOREIGN KEY (MedID) REFERENCES Medications(ID),
  FOREIGN KEY (VendID) REFERENCES Vendors(VendorID)
);

-- DATA insertions:

INSERT INTO Doctors (Fname, Lname, Specialty) VALUES 
('James', 'Mitchell', 'General Practice'), 
('Sarah', 'Nguyen', 'Cardiology'), 
('David', 'Patel', 'Dermatology');

INSERT INTO Practices (Pname, St, Prov, City, PostCode, Phone, Fax) VALUES 
('Vancouver Medical Clinic', '123 Robson Street', 'BC', 'Vancouver', 'V6B 1B9', '604-555-0101', '604-555-0102'),
('North Shore Health Centre', '456 Lonsdale Avenue', 'BC', 'North Vancouver', 'V7M 2G3', '604-555-0201', '604-555-0202'),
('Oakville Family Practice', '789 Kerr Street', 'ON', 'Oakville', 'L6K 3C7', '905-555-0301', '905-555-0302'),
('Toronto Medical Associates', '321 Yonge Street', 'ON', 'Toronto', 'M4W 2G8', '416-555-0401', '416-555-0402'),
('Burnaby Health Clinic', '654 Hastings Street', 'BC', 'Burnaby', 'V5B 1R2', '604-555-0501', '604-555-0502');

INSERT INTO Practice_at (DocID, PracID, ExtNo) VALUES (1, 1, 101), (2, 2, 201), (3, 3, 301);

INSERT INTO Patients (PHN, Fname, Lname, DOB, St, City, PostCode, Country, Phone, Email, Allergies, Medical_History, Prov) VALUES 
(NULL, 'Kerry', 'Maniscalco', '1972-05-04', '1231 Keith Road', 'North Vancouver', 'V7T 1N1', 'CANADA', '604-987-8676', 'KerryJManiscalco@armyspy.com', 'Nuts', 'Excema', 'BC'),
(231413566, 'Xiong', 'Yao', '1992-09-10', '526 Speers Road', 'Oakville', 'L6H 3H5', 'CANADA', '905-483-4529', 'XiongY88888@gmail.com', NULL, NULL, 'ON'),
(223341344, 'Raymond', 'Yao', '1988-08-01', 'Rue Henri Lambert 268', 'Oakville', 'L6H 3H5', 'CANADA', '905-482-4112', 'Ray888@yahoo.com', 'Gluten', 'Celiac', 'ON'),
(NULL, 'Amanda', 'Dias', '1970-08-01', 'Rue Henri Lambert 268', 'Harsin', '6950', 'BELGIUM', '0474 48 83 61', NULL, NULL, NULL, NULL),
(NULL, 'Daniel', 'Steffensen', '1970-08-01', '3900 Yonge Street', 'Toronto', 'M4W 1J7', 'CANADA', '416-973-5734', NULL, NULL, NULL, 'ON'),
(123456789, 'Ayden', 'Watt', '1990-03-15', '452 Granville Street', 'Vancouver', 'V6C 1V4', 'CANADA', '604-123-4567', 'AydenWatt@gmail.com', 'Lactose', NULL, 'BC'),
(987654321, 'Mina', 'Tokushige', '1988-07-22', '452 Granville Street', 'Vancouver', 'V6C 1V4', 'CANADA', '604-765-4321', 'MinaTokushige@gmail.com', 'Shrimp', NULL, 'BC');

UPDATE Patients SET Spouse_ID = 3 WHERE ID = 2;
UPDATE Patients SET Spouse_ID = 2 WHERE ID = 3;
UPDATE Patients SET Spouse_ID = 7 WHERE ID = 6;
UPDATE Patients SET Spouse_ID = 6 WHERE ID = 7;

INSERT INTO Patients (PHN, Fname, Lname, DOB, St, City, PostCode, Country, Phone, Prov) VALUES
(NULL, 'Andrew', 'Stevens', '1963-03-20', '123 Robson St', 'Vancouver', 'V8N2K9', 'CANADA', NULL, 'BC');
INSERT INTO Patients (PHN, Fname, Lname, DOB, Prov) VALUES
(NULL, 'Faye', 'Stevens', '1968-07-08', NULL);

INSERT INTO Insurance (ID, Iname, Phone, Notes) VALUES 
(1234, 'Sun Life', '6041234567', 'Comprehensive plan'), 
(2234, 'Blue Cross', '6042345678', 'Basic coverage'), 
(3234, 'Manulife', '6043456789', 'Premium plan'), 
(4234, 'Great-West Life', '6044567890', 'Standard coverage');

INSERT INTO Is_Insured (InsID, PatID, PolicyNo, MemberID, Notes) VALUES 
(1234, 1, 1, 1111111, 'Primary'), 
(2234, 2, 2, 1111112, 'Primary'), 
(3234, 3, 3, 1111113, 'Primary'), 
(4234, 4, 4, 1111114, 'Primary'), 
(1234, 5, 5, 1111115, 'Secondary'), 
(2234, 6, 6, 1111116, 'Secondary'), 
(3234, 7, 7, 1111117, 'Secondary');

INSERT INTO Dependents (PatID, Name, DOB, Allergies, Medical_History) VALUES 
(1, 'James', '2006-05-28', 'Peanuts', 'Asthma'), 
(1, 'Lily', '2010-03-15', 'None', 'Healthy'), 
(2, 'Ethan', '2008-11-02', 'Dust', 'Allergic rhinitis'), 
(2, 'Sophia', '2012-07-21', 'None', 'Healthy'), 
(3, 'Noah', '2005-09-10', 'Shellfish', 'Eczema'), 
(4, 'Mason', '2013-04-12', 'None', 'Healthy'), 
(5, 'Olivia', '2011-01-30', 'None', 'Healthy'), 
(6, 'Ava', '2007-08-25', 'Milk', 'Lactose intolerance'), 
(7, 'Lucas', '2009-12-18', 'Pollen', 'Mild asthma'), 
(3, 'Emma', '2014-06-18', 'None', 'Healthy');

INSERT INTO Medications (Drug_Name, Manufacturer, Strength, Cost, DIN, Qty_per_unit, Stock_Qty) VALUES 
('Acetominophen (Tylenol)', 'Johnson & Johnson', '500mg', 9.99, 10000000, 15, 200), 
('ibuprofen (Advil)', 'Pfizer', '200mg', 12.50, 10000001, 10, 150), 
('Acetylsalicylic acid (Aspirin)', 'Bayer', '325mg', 8.75, 10000002, 25, 400), 
('Amoxicillin', 'Teva', '250mg', 15.20, 10000003, 30, 500), 
('Metformin', 'Sandoz', '500mg', 11.30, 10000004, 12, 180), 
('Hydrocortisone Cream', 'Pfizer', '1% topical cream', 12.99, 10000005, 35, 300), 
('Amoxicillin', 'Teva', '500mg capsule', 18.49, 10000006, 18, 220), 
('Pancrelipase', 'AbbVie', '10000 units capsule', 45.99, 10000007, 22, 350), 
('Ibuprofen', 'Apotex', '400mg tablet', 6.99, 10000008, 8, 120), 
('Lisinopril', 'Mylan', '10mg tablet', 15.49, 10000009, 16, 260), 
('Alendronate', 'Merck', '70mg tablet', 38.99, 10000010, 14, 240), 
('Adalimumab', 'AbbVie', '40mg/0.8ml injection', 1850.00, 10000011, 28, 450), 
('Lactase Enzyme', 'Kirkland', '9000 FCC units capsule', 18.99, 10000012, 35, 600), 
('Diphenhydramine (Benedryl)', 'Kenvue Inc', '25mg tablet', 9.99, 10000013, 20, 300),
('Lisinopril', 'Mylan', '50mg tablet', 20.49, 10000435, 16, 261), 
('Lisinopril', 'Mylan', '100mg tablet', 30.49, 10012435, 16, 261);


INSERT INTO Prescriptions (Instructions, Refills, Date_Issued, Expiry_Date, Patient_ID) VALUES 
('Apply a thin layer to affected area twice daily. Avoid contact with eyes.', 3, '2024-01-15', '2025-01-15', 1), 
('Take 1 tablet by mouth once daily in the morning.', 2, '2024-02-10', '2025-02-10', 2), 
('Take 1 capsule by mouth once daily with meals. Avoid gluten-containing foods.', 6, '2024-03-05', '2025-03-05', 3), 
('Take 2 tablets by mouth every 6 hours as needed for pain. Do not exceed 8 tablets per day.', 0, '2024-04-20', '2024-10-20', 4), 
('Take 1 tablet by mouth once daily with or without food.', 1, '2024-05-15', '2025-05-15', 5), 
('Take 1 tablet by mouth once weekly. Take with full glass of water and remain upright for 30 minutes.', 2, '2024-06-01', '2025-06-01', 1), 
('Inject 0.5ml subcutaneously once every two weeks. Rotate injection sites.', 1, '2024-07-10', '2025-07-10', 3), 
('Take 1 lactase enzyme capsule before every meal containing dairy products.', 2, '2024-08-05', '2025-08-05', 6), 
('Take 1 antihistamine tablet immediately upon accidental shrimp exposure. Carry EpiPen at all times.', 0, '2024-08-10', '2025-08-10', 7);

INSERT INTO Roles (RoleID, RoleName) VALUES (1, 'Owner'), (2, 'Pharmacist'), (3, 'Pharmacy Tech');

INSERT INTO Employees (Fname, Lname, Street, City, Prov, PostCode, Phone, Email, DOB, SIN, PharmID, RoleID) VALUES 
('Ava', 'Nguyen', '123 Granville', 'Vancouver', 'BC', 'V6Z1L2', '604-111-1111', 'ava@gmail.com', '1998-05-10', 111111111, 'A1001', 1), 
('Liam', 'Patel', '456 Robson', 'Vancouver', 'BC', 'V6B2B7', '604-222-2222', 'liam@gmail.com', '1995-08-21', 222222222, 'A1002', 2), 
('Emma', 'Chen', '789 Broadway', 'Vancouver', 'BC', 'V5Z1J5', '604-333-3333', 'emma@gmail.com', '1997-03-15', 333333333, 'A1003', 3), 
('Noah', 'Kim', '321 Main', 'Vancouver', 'BC', 'V6A2T2', '604-444-4444', 'noah@gmail.com', '1996-11-30', 444444444, 'A1004', 1), 
('Sophia', 'Martinez', '654 Kingsway', 'Vancouver', 'BC', 'V5V3C4', '604-555-5555', 'sophia@gmail.com', '1999-01-25', 555555555, 'A1005', 2), 
('Ethan', 'Singh', '987 Commercial', 'Vancouver', 'BC', 'V5L3W9', '604-666-6666', 'ethan@gmail.com', '1994-07-12', 666666666, 'A1006', 3), 
('Olivia', 'Garcia', '159 Hastings', 'Vancouver', 'BC', 'V6A1P6', '604-777-7777', 'olivia@gmail.com', '1998-09-18', 777777777, 'A1007', 1);

INSERT INTO Quote_Status (StatusID, Status_Name) VALUES (1, 'Emailed Vendor'), (2, 'Emailed Patient'), (3, 'Approved'), (4, 'Rejected'), (5, 'Cancelled');

INSERT INTO Vendors (VendorID, Name, Contact, Notes) VALUES 
(1, 'McKesson', '604-123-7890', 'Main distributor'), 
(2, 'AmerisourceBergen', '604-234-5678', 'Supplier'), 
(3, 'Cardinal Health', '604-345-6789', 'Medical supplies');

INSERT INTO Quotes (QuoteID, QuoteDate, Cost, StatusID, VendorID, PrescriptionID, EmpID) VALUES 
(1, '2025-01-01', 45.50, 1, 1, 1, 1), 
(2, '2025-02-15', 60.00, 2, 2, 2, 2), 
(3, '2025-03-20', 32.75, 3, 3, 3, 3), 
(4, '2025-04-10', 80.20, 4, 1, 4, 4), 
(5, '2025-05-05', 25.00, 5, 2, 5, 5);

INSERT INTO Orders (Order_ID, Order_Date) VALUES 
(1, '2026-02-01'), 
(2, '2026-02-05'), 
(3, '2026-02-10'), 
(4, '2026-02-15'), 
(5, '2026-02-20');

INSERT INTO Contains (ID, Prescription_ID) VALUES 
(6, 1), 
(7, 2), 
(8, 3), 
(9, 4), 
(10, 5), 
(11, 6), 
(12, 7), 
(13, 8), 
(14, 9);

INSERT INTO Dispense (EmpID, Prescription_ID, Invoice_No, Pay_Method, Date_Of_Invoice) VALUES 
(2, 1, 10004, 'VISA', '2026-03-05'), 
(5, 2, 10002, 'CASH', '2026-03-03'), 
(7, 2, 10006, 'MASTERCARD', '2026-03-07'), 
(1, 3, 10000, 'VISA', '2026-03-01'), 
(4, 3, 10005, 'CASH', '2026-03-06'), 
(3, 4, 10001, 'MASTERCARD', '2026-03-02'), 
(5, 5, 10003, 'DEBIT', '2026-03-04');

INSERT INTO Handles (ID, EmpID, Order_ID, Qty, Qty_Received, Notes) VALUES 
(3, 2, 1, 200, 150, ''), 
(5, 1, 2, 180, 160, ''), 
(7, 4, 3, 250, 200, ''), 
(9, 6, 4, 300, 280, ''), 
(12, 3, 5, 220, 210, '');

INSERT INTO Makes_Orders (EmpID, VID, OID) VALUES 
(1, 1, 1), 
(1, 1, 2), 
(3, 1, 3), 
(3, 1, 4), 
(6, 1, 5);

INSERT INTO Prescribe_For (DoctorID, PrescriptionID) VALUES 
(1, 2), 
(1, 3), 
(1, 5), 
(1, 8), 
(2, 1), 
(2, 4), 
(3, 6), 
(3, 7), 
(3, 9);

SET FOREIGN_KEY_CHECKS = 1;

INSERT INTO Supplied_By (MedID, VendID) VALUES 
(1,1),
(2,1),
(3,1),
(4,1), 
(5,1),
(6,1),
(7,1),
(8,1),
(9,1),
(10,1),
(11,1),
(12,1),
(13,1),
(14,1),
(15,1),
(16,1),
(1,2),
(2,2),
(6,2),
(5,2),
(14,2),
(13,2),
(7,2),
(1,3),
(2,3),
(3,3),
(4,3), 
(5,3),
(6,3),
(7,3),
(8,3),
(9,3),
(10,3),
(11,3),
(12,3),
(13,3),
(14,3),
(15,3),
(16,3),
(15,2),
(10,2),
(11,2),
(16,2);