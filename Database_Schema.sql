-- HUIT Library Management System
-- Database Schema for Ho Chi Minh City University of Industry
-- Created for comprehensive library, equipment, and classroom management

USE master;
GO

-- Create database if it doesn't exist
IF NOT EXISTS (SELECT name FROM sys.databases WHERE name = 'HUIT_LibraryManagement')
BEGIN
    CREATE DATABASE HUIT_LibraryManagement;
END
GO

USE HUIT_LibraryManagement;
GO

-- Enable SQL Server specific features
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

-- =============================================
-- 1. MAIN TABLES SCHEMA
-- =============================================

-- Departments/Faculties at HUIT
CREATE TABLE Departments (
    DepartmentID int IDENTITY(1,1) PRIMARY KEY,
    DepartmentCode nvarchar(10) NOT NULL UNIQUE,
    DepartmentName nvarchar(200) NOT NULL,
    DepartmentType nvarchar(50) NOT NULL, -- 'Academic', 'Administrative', 'Support'
    Description nvarchar(500),
    IsActive bit NOT NULL DEFAULT 1,
    CreatedDate datetime2 NOT NULL DEFAULT GETDATE(),
    ModifiedDate datetime2 NOT NULL DEFAULT GETDATE()
);

-- User roles in the system
CREATE TABLE UserRoles (
    RoleID int IDENTITY(1,1) PRIMARY KEY,
    RoleName nvarchar(50) NOT NULL UNIQUE,
    Description nvarchar(200),
    IsActive bit NOT NULL DEFAULT 1
);

-- Main users table (students, faculty, staff)
CREATE TABLE Users (
    UserID int IDENTITY(1,1) PRIMARY KEY,
    UserCode nvarchar(20) NOT NULL UNIQUE, -- Student ID or Staff ID
    FullName nvarchar(200) NOT NULL,
    Email nvarchar(100) NOT NULL UNIQUE,
    PhoneNumber nvarchar(20),
    UserType nvarchar(20) NOT NULL, -- 'Student', 'Staff', 'Faculty', 'Admin'
    DepartmentID int,
    RoleID int NOT NULL,
    YearOfStudy int NULL, -- For students only
    IsActive bit NOT NULL DEFAULT 1,
    CreatedDate datetime2 NOT NULL DEFAULT GETDATE(),
    ModifiedDate datetime2 NOT NULL DEFAULT GETDATE(),
    FOREIGN KEY (DepartmentID) REFERENCES Departments(DepartmentID),
    FOREIGN KEY (RoleID) REFERENCES UserRoles(RoleID)
);

-- Resource categories
CREATE TABLE ResourceCategories (
    CategoryID int IDENTITY(1,1) PRIMARY KEY,
    CategoryName nvarchar(100) NOT NULL UNIQUE,
    CategoryType nvarchar(20) NOT NULL, -- 'Book', 'Equipment', 'Room'
    Description nvarchar(500),
    MaxLoanDays int NOT NULL DEFAULT 14,
    MaxRenewals int NOT NULL DEFAULT 1,
    RequiresApproval bit NOT NULL DEFAULT 0,
    IsActive bit NOT NULL DEFAULT 1
);

-- Physical locations within the library
CREATE TABLE Locations (
    LocationID int IDENTITY(1,1) PRIMARY KEY,
    LocationCode nvarchar(20) NOT NULL UNIQUE,
    LocationName nvarchar(100) NOT NULL,
    LocationType nvarchar(20) NOT NULL, -- 'Floor', 'Room', 'Section', 'Shelf'
    ParentLocationID int NULL,
    Capacity int NULL,
    IsActive bit NOT NULL DEFAULT 1,
    FOREIGN KEY (ParentLocationID) REFERENCES Locations(LocationID)
);

-- Main resources table (books, equipment, rooms)
CREATE TABLE Resources (
    ResourceID int IDENTITY(1,1) PRIMARY KEY,
    ResourceCode nvarchar(50) NOT NULL UNIQUE,
    Title nvarchar(500) NOT NULL,
    ResourceType nvarchar(20) NOT NULL, -- 'Book', 'Equipment', 'Room'
    CategoryID int NOT NULL,
    LocationID int,
    Author nvarchar(200), -- For books
    Publisher nvarchar(200), -- For books
    ISBN nvarchar(20), -- For books
    PublicationYear int, -- For books
    Description nvarchar(1000),
    PurchasePrice decimal(10,2),
    PurchaseDate date,
    CurrentStatus nvarchar(20) NOT NULL DEFAULT 'Available', -- 'Available', 'Borrowed', 'Reserved', 'Maintenance', 'Lost', 'Damaged'
    TotalCopies int NOT NULL DEFAULT 1,
    AvailableCopies int NOT NULL DEFAULT 1,
    IsActive bit NOT NULL DEFAULT 1,
    CreatedDate datetime2 NOT NULL DEFAULT GETDATE(),
    ModifiedDate datetime2 NOT NULL DEFAULT GETDATE(),
    FOREIGN KEY (CategoryID) REFERENCES ResourceCategories(CategoryID),
    FOREIGN KEY (LocationID) REFERENCES Locations(LocationID)
);

-- Equipment specific details
CREATE TABLE EquipmentDetails (
    EquipmentID int PRIMARY KEY,
    Brand nvarchar(100),
    Model nvarchar(100),
    SerialNumber nvarchar(100),
    WarrantyExpiry date,
    MaintenanceSchedule nvarchar(200),
    UsageHours decimal(10,2) DEFAULT 0,
    MaxUsageHours decimal(10,2),
    FOREIGN KEY (EquipmentID) REFERENCES Resources(ResourceID)
);

-- Room specific details
CREATE TABLE RoomDetails (
    RoomID int PRIMARY KEY,
    RoomNumber nvarchar(20) NOT NULL,
    Floor int NOT NULL,
    Capacity int NOT NULL,
    RoomType nvarchar(50), -- 'Classroom', 'Lab', 'Meeting', 'Study'
    HasProjector bit DEFAULT 0,
    HasComputers bit DEFAULT 0,
    HasWhiteboard bit DEFAULT 0,
    HasAircon bit DEFAULT 0,
    FOREIGN KEY (RoomID) REFERENCES Resources(ResourceID)
);

-- Booking/Loan requests
CREATE TABLE Bookings (
    BookingID int IDENTITY(1,1) PRIMARY KEY,
    BookingCode nvarchar(50) NOT NULL UNIQUE,
    UserID int NOT NULL,
    ResourceID int NOT NULL,
    BookingType nvarchar(20) NOT NULL, -- 'Loan', 'Reservation'
    RequestDate datetime2 NOT NULL DEFAULT GETDATE(),
    StartDate datetime2 NOT NULL,
    EndDate datetime2 NOT NULL,
    ReturnDate datetime2 NULL,
    Status nvarchar(20) NOT NULL DEFAULT 'Pending', -- 'Pending', 'Approved', 'Active', 'Completed', 'Cancelled', 'Overdue'
    ApprovedBy int NULL,
    ApprovalDate datetime2 NULL,
    Purpose nvarchar(500),
    Notes nvarchar(1000),
    FOREIGN KEY (UserID) REFERENCES Users(UserID),
    FOREIGN KEY (ResourceID) REFERENCES Resources(ResourceID),
    FOREIGN KEY (ApprovedBy) REFERENCES Users(UserID)
);

-- Penalties and fines
CREATE TABLE Penalties (
    PenaltyID int IDENTITY(1,1) PRIMARY KEY,
    BookingID int NOT NULL,
    UserID int NOT NULL,
    PenaltyType nvarchar(20) NOT NULL, -- 'Late', 'NoShow', 'Damage', 'Lost'
    PenaltyAmount decimal(10,2) NOT NULL,
    DaysOverdue int NULL,
    Description nvarchar(500),
    IssueDate datetime2 NOT NULL DEFAULT GETDATE(),
    DueDate datetime2 NOT NULL,
    PaidDate datetime2 NULL,
    Status nvarchar(20) NOT NULL DEFAULT 'Unpaid', -- 'Unpaid', 'Paid', 'Waived'
    PaidBy int NULL,
    PaymentMethod nvarchar(50) NULL,
    FOREIGN KEY (BookingID) REFERENCES Bookings(BookingID),
    FOREIGN KEY (UserID) REFERENCES Users(UserID),
    FOREIGN KEY (PaidBy) REFERENCES Users(UserID)
);

-- Audit log for all system activities
CREATE TABLE AuditLogs (
    LogID int IDENTITY(1,1) PRIMARY KEY,
    TableName nvarchar(100) NOT NULL,
    RecordID int NOT NULL,
    Action nvarchar(20) NOT NULL, -- 'INSERT', 'UPDATE', 'DELETE'
    OldValues nvarchar(max),
    NewValues nvarchar(max),
    UserID int,
    LogDate datetime2 NOT NULL DEFAULT GETDATE(),
    IPAddress nvarchar(50),
    UserAgent nvarchar(500),
    FOREIGN KEY (UserID) REFERENCES Users(UserID)
);

-- System configuration
CREATE TABLE SystemConfig (
    ConfigID int IDENTITY(1,1) PRIMARY KEY,
    ConfigKey nvarchar(100) NOT NULL UNIQUE,
    ConfigValue nvarchar(1000) NOT NULL,
    Description nvarchar(500),
    ModifiedBy int,
    ModifiedDate datetime2 NOT NULL DEFAULT GETDATE(),
    FOREIGN KEY (ModifiedBy) REFERENCES Users(UserID)
);

GO

-- =============================================
-- 2. INDEXES FOR PERFORMANCE
-- =============================================

-- Users table indexes
CREATE INDEX IX_Users_UserCode ON Users(UserCode);
CREATE INDEX IX_Users_Email ON Users(Email);
CREATE INDEX IX_Users_UserType ON Users(UserType);
CREATE INDEX IX_Users_DepartmentID ON Users(DepartmentID);

-- Resources table indexes
CREATE INDEX IX_Resources_ResourceCode ON Resources(ResourceCode);
CREATE INDEX IX_Resources_ResourceType ON Resources(ResourceType);
CREATE INDEX IX_Resources_CategoryID ON Resources(CategoryID);
CREATE INDEX IX_Resources_CurrentStatus ON Resources(CurrentStatus);
CREATE INDEX IX_Resources_Title ON Resources(Title);

-- Bookings table indexes
CREATE INDEX IX_Bookings_UserID ON Bookings(UserID);
CREATE INDEX IX_Bookings_ResourceID ON Bookings(ResourceID);
CREATE INDEX IX_Bookings_Status ON Bookings(Status);
CREATE INDEX IX_Bookings_StartDate ON Bookings(StartDate);
CREATE INDEX IX_Bookings_EndDate ON Bookings(EndDate);
CREATE INDEX IX_Bookings_BookingType ON Bookings(BookingType);

-- Penalties table indexes
CREATE INDEX IX_Penalties_UserID ON Penalties(UserID);
CREATE INDEX IX_Penalties_BookingID ON Penalties(BookingID);
CREATE INDEX IX_Penalties_Status ON Penalties(Status);
CREATE INDEX IX_Penalties_PenaltyType ON Penalties(PenaltyType);

-- Audit logs indexes
CREATE INDEX IX_AuditLogs_TableName ON AuditLogs(TableName);
CREATE INDEX IX_AuditLogs_UserID ON AuditLogs(UserID);
CREATE INDEX IX_AuditLogs_LogDate ON AuditLogs(LogDate);

GO

-- =============================================
-- 3. VIEWS FOR REPORTING
-- =============================================

-- Resource Statistics View (completing from line 1105 as mentioned)
CREATE VIEW vw_ResourceStatistics AS
SELECT 
    r.ResourceType,
    rc.CategoryName,
    COUNT(*) as TotalResources,
    SUM(r.TotalCopies) as TotalCopies,
    SUM(r.AvailableCopies) as AvailableCopies,
    SUM(r.TotalCopies - r.AvailableCopies) as BorrowedCopies,
    CAST(SUM(r.TotalCopies - r.AvailableCopies) * 100.0 / SUM(r.TotalCopies) AS decimal(5,2)) as UtilizationRate,
    COUNT(CASE WHEN r.CurrentStatus = 'Available' THEN 1 END) as ResourcesAvailable,
    COUNT(CASE WHEN r.CurrentStatus = 'Borrowed' THEN 1 END) as ResourcesBorrowed,
    COUNT(CASE WHEN r.CurrentStatus = 'Maintenance' THEN 1 END) as ResourcesInMaintenance,
    COUNT(CASE WHEN r.CurrentStatus = 'Lost' THEN 1 END) as ResourcesLost,
    COUNT(CASE WHEN r.CurrentStatus = 'Damaged' THEN 1 END) as ResourcesDamaged
FROM Resources r
INNER JOIN ResourceCategories rc ON r.CategoryID = rc.CategoryID
WHERE r.IsActive = 1
GROUP BY r.ResourceType, rc.CategoryName;

GO

-- User Statistics View
CREATE VIEW vw_UserStatistics AS
SELECT 
    u.UserType,
    d.DepartmentName,
    COUNT(*) as TotalUsers,
    COUNT(CASE WHEN u.IsActive = 1 THEN 1 END) as ActiveUsers,
    COUNT(CASE WHEN u.IsActive = 0 THEN 1 END) as InactiveUsers,
    -- Current active bookings
    (SELECT COUNT(*) FROM Bookings b WHERE b.UserID = u.UserID AND b.Status = 'Active') as ActiveBookings,
    -- Total bookings this year
    (SELECT COUNT(*) FROM Bookings b WHERE b.UserID = u.UserID AND YEAR(b.RequestDate) = YEAR(GETDATE())) as BookingsThisYear,
    -- Unpaid penalties
    (SELECT COUNT(*) FROM Penalties p WHERE p.UserID = u.UserID AND p.Status = 'Unpaid') as UnpaidPenalties,
    (SELECT SUM(p.PenaltyAmount) FROM Penalties p WHERE p.UserID = u.UserID AND p.Status = 'Unpaid') as UnpaidAmount
FROM Users u
LEFT JOIN Departments d ON u.DepartmentID = d.DepartmentID
GROUP BY u.UserType, d.DepartmentName, u.UserID;

GO

-- Penalty and Financial Reports View
CREATE VIEW vw_PenaltyFinancialReport AS
SELECT 
    YEAR(p.IssueDate) as Year,
    MONTH(p.IssueDate) as Month,
    p.PenaltyType,
    u.UserType,
    d.DepartmentName,
    COUNT(*) as TotalPenalties,
    SUM(p.PenaltyAmount) as TotalAmount,
    SUM(CASE WHEN p.Status = 'Paid' THEN p.PenaltyAmount ELSE 0 END) as PaidAmount,
    SUM(CASE WHEN p.Status = 'Unpaid' THEN p.PenaltyAmount ELSE 0 END) as UnpaidAmount,
    SUM(CASE WHEN p.Status = 'Waived' THEN p.PenaltyAmount ELSE 0 END) as WaivedAmount,
    CAST(SUM(CASE WHEN p.Status = 'Paid' THEN p.PenaltyAmount ELSE 0 END) * 100.0 / SUM(p.PenaltyAmount) AS decimal(5,2)) as CollectionRate
FROM Penalties p
INNER JOIN Users u ON p.UserID = u.UserID
LEFT JOIN Departments d ON u.DepartmentID = d.DepartmentID
GROUP BY YEAR(p.IssueDate), MONTH(p.IssueDate), p.PenaltyType, u.UserType, d.DepartmentName;

GO

-- Usage Reports by Time Period View
CREATE VIEW vw_UsageReportByTime AS
SELECT 
    YEAR(b.StartDate) as Year,
    MONTH(b.StartDate) as Month,
    DATEPART(WEEK, b.StartDate) as WeekNumber,
    r.ResourceType,
    rc.CategoryName,
    u.UserType,
    d.DepartmentName,
    COUNT(*) as TotalBookings,
    COUNT(CASE WHEN b.Status = 'Completed' THEN 1 END) as CompletedBookings,
    COUNT(CASE WHEN b.Status = 'Cancelled' THEN 1 END) as CancelledBookings,
    COUNT(CASE WHEN b.Status = 'Overdue' THEN 1 END) as OverdueBookings,
    AVG(DATEDIFF(HOUR, b.StartDate, COALESCE(b.ReturnDate, b.EndDate))) as AvgUsageHours,
    SUM(DATEDIFF(HOUR, b.StartDate, COALESCE(b.ReturnDate, b.EndDate))) as TotalUsageHours
FROM Bookings b
INNER JOIN Resources r ON b.ResourceID = r.ResourceID
INNER JOIN ResourceCategories rc ON r.CategoryID = rc.CategoryID
INNER JOIN Users u ON b.UserID = u.UserID
LEFT JOIN Departments d ON u.DepartmentID = d.DepartmentID
GROUP BY YEAR(b.StartDate), MONTH(b.StartDate), DATEPART(WEEK, b.StartDate), 
         r.ResourceType, rc.CategoryName, u.UserType, d.DepartmentName;

GO