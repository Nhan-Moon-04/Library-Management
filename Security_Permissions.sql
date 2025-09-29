-- HUIT Library Management System
-- Security and Permissions Configuration
-- Row-level Security and Role-based Access Control

USE HUIT_LibraryManagement;
GO

-- =============================================
-- 1. CREATE DATABASE ROLES
-- =============================================

-- Drop roles if they exist
IF DATABASE_PRINCIPAL_ID('db_student') IS NOT NULL
    DROP ROLE db_student;
IF DATABASE_PRINCIPAL_ID('db_faculty') IS NOT NULL
    DROP ROLE db_faculty;
IF DATABASE_PRINCIPAL_ID('db_staff') IS NOT NULL
    DROP ROLE db_staff;
IF DATABASE_PRINCIPAL_ID('db_librarian') IS NOT NULL
    DROP ROLE db_librarian;
IF DATABASE_PRINCIPAL_ID('db_admin') IS NOT NULL
    DROP ROLE db_admin;

-- Create database roles
CREATE ROLE db_student;
CREATE ROLE db_faculty;
CREATE ROLE db_staff;
CREATE ROLE db_librarian;
CREATE ROLE db_admin;

-- =============================================
-- 2. GRANT PERMISSIONS TO ROLES
-- =============================================

-- Student permissions (read-only access to public data, manage own bookings)
GRANT SELECT ON Departments TO db_student;
GRANT SELECT ON ResourceCategories TO db_student;
GRANT SELECT ON Locations TO db_student;
GRANT SELECT ON Resources TO db_student;
GRANT SELECT ON RoomDetails TO db_student;
GRANT SELECT ON EquipmentDetails TO db_student;

-- Students can view their own data
GRANT SELECT ON Users TO db_student;
GRANT SELECT ON Bookings TO db_student;
GRANT SELECT ON Penalties TO db_student;

-- Students can create bookings
GRANT INSERT ON Bookings TO db_student;
GRANT UPDATE ON Bookings TO db_student; -- Limited by RLS

-- Students can use utility procedures
GRANT EXECUTE ON sp_GetAvailableResources TO db_student;
GRANT EXECUTE ON sp_GetUserBookingHistory TO db_student;
GRANT EXECUTE ON sp_ExtendBooking TO db_student;
GRANT EXECUTE ON sp_CancelBooking TO db_student;

-- Faculty permissions (extended privileges)
GRANT SELECT ON Departments TO db_faculty;
GRANT SELECT ON ResourceCategories TO db_faculty;
GRANT SELECT ON Locations TO db_faculty;
GRANT SELECT ON Resources TO db_faculty;
GRANT SELECT ON RoomDetails TO db_faculty;
GRANT SELECT ON EquipmentDetails TO db_faculty;
GRANT SELECT ON Users TO db_faculty;
GRANT SELECT ON Bookings TO db_faculty;
GRANT SELECT ON Penalties TO db_faculty;

-- Faculty can create and manage bookings
GRANT INSERT ON Bookings TO db_faculty;
GRANT UPDATE ON Bookings TO db_faculty;

-- Faculty can use all user procedures
GRANT EXECUTE ON sp_GetAvailableResources TO db_faculty;
GRANT EXECUTE ON sp_GetUserBookingHistory TO db_faculty;
GRANT EXECUTE ON sp_ExtendBooking TO db_faculty;
GRANT EXECUTE ON sp_CancelBooking TO db_faculty;

-- Staff permissions (administrative access)
GRANT SELECT, INSERT, UPDATE ON Departments TO db_staff;
GRANT SELECT, INSERT, UPDATE ON ResourceCategories TO db_staff;
GRANT SELECT, INSERT, UPDATE ON Locations TO db_staff;
GRANT SELECT, INSERT, UPDATE ON Resources TO db_staff;
GRANT SELECT, INSERT, UPDATE ON RoomDetails TO db_staff;
GRANT SELECT, INSERT, UPDATE ON EquipmentDetails TO db_staff;
GRANT SELECT, INSERT, UPDATE ON Users TO db_staff;
GRANT SELECT, INSERT, UPDATE ON Bookings TO db_staff;
GRANT SELECT, INSERT, UPDATE ON Penalties TO db_staff;
GRANT SELECT ON AuditLogs TO db_staff;

-- Staff can execute management procedures
GRANT EXECUTE ON sp_GetAvailableResources TO db_staff;
GRANT EXECUTE ON sp_GetUserBookingHistory TO db_staff;
GRANT EXECUTE ON sp_ApproveBooking TO db_staff;
GRANT EXECUTE ON sp_CheckInOut TO db_staff;
GRANT EXECUTE ON sp_ExtendBooking TO db_staff;
GRANT EXECUTE ON sp_CancelBooking TO db_staff;
GRANT EXECUTE ON sp_PayPenalty TO db_staff;

-- Librarian permissions (full operational access)
GRANT SELECT, INSERT, UPDATE, DELETE ON Departments TO db_librarian;
GRANT SELECT, INSERT, UPDATE, DELETE ON ResourceCategories TO db_librarian;
GRANT SELECT, INSERT, UPDATE, DELETE ON Locations TO db_librarian;
GRANT SELECT, INSERT, UPDATE, DELETE ON Resources TO db_librarian;
GRANT SELECT, INSERT, UPDATE, DELETE ON RoomDetails TO db_librarian;
GRANT SELECT, INSERT, UPDATE, DELETE ON EquipmentDetails TO db_librarian;
GRANT SELECT, INSERT, UPDATE, DELETE ON Users TO db_librarian;
GRANT SELECT, INSERT, UPDATE, DELETE ON Bookings TO db_librarian;
GRANT SELECT, INSERT, UPDATE, DELETE ON Penalties TO db_librarian;
GRANT SELECT ON AuditLogs TO db_librarian;
GRANT SELECT, INSERT, UPDATE ON SystemConfig TO db_librarian;

-- Librarian can execute all procedures
GRANT EXECUTE ON sp_GetAvailableResources TO db_librarian;
GRANT EXECUTE ON sp_GetUserBookingHistory TO db_librarian;
GRANT EXECUTE ON sp_ApproveBooking TO db_librarian;
GRANT EXECUTE ON sp_CheckInOut TO db_librarian;
GRANT EXECUTE ON sp_ExtendBooking TO db_librarian;
GRANT EXECUTE ON sp_CancelBooking TO db_librarian;
GRANT EXECUTE ON sp_PayPenalty TO db_librarian;
GRANT EXECUTE ON sp_DatabaseMaintenance TO db_librarian;

-- Admin permissions (full system access)
GRANT CONTROL ON SCHEMA::dbo TO db_admin;

-- =============================================
-- 3. ROW-LEVEL SECURITY (RLS) SETUP
-- =============================================

-- Enable RLS on sensitive tables
ALTER TABLE Users ENABLE ROW LEVEL SECURITY;
ALTER TABLE Bookings ENABLE ROW LEVEL SECURITY;
ALTER TABLE Penalties ENABLE ROW LEVEL SECURITY;
ALTER TABLE AuditLogs ENABLE ROW LEVEL SECURITY;

-- =============================================
-- 4. SECURITY PREDICATE FUNCTIONS
-- =============================================

-- Function to get current user's UserID
CREATE FUNCTION fn_GetCurrentUserID()
RETURNS int
AS
BEGIN
    DECLARE @UserID int;
    DECLARE @UserCode nvarchar(20) = USER_NAME();
    
    -- Try to get UserID from Users table based on login name
    SELECT @UserID = UserID 
    FROM Users 
    WHERE UserCode = @UserCode OR Email = @UserCode + '@huit.edu.vn';
    
    -- If not found, return 0 (no access)
    IF @UserID IS NULL
        SET @UserID = 0;
    
    RETURN @UserID;
END
GO

-- Function to check if current user is librarian or admin
CREATE FUNCTION fn_IsLibrarianOrAdmin()
RETURNS bit
AS
BEGIN
    DECLARE @IsLibrarianOrAdmin bit = 0;
    
    IF IS_MEMBER('db_librarian') = 1 OR IS_MEMBER('db_admin') = 1
        SET @IsLibrarianOrAdmin = 1;
    
    RETURN @IsLibrarianOrAdmin;
END
GO

-- Function to check if current user is staff or higher
CREATE FUNCTION fn_IsStaffOrHigher()
RETURNS bit
AS
BEGIN
    DECLARE @IsStaffOrHigher bit = 0;
    
    IF IS_MEMBER('db_staff') = 1 OR IS_MEMBER('db_librarian') = 1 OR IS_MEMBER('db_admin') = 1
        SET @IsStaffOrHigher = 1;
    
    RETURN @IsStaffOrHigher;
END
GO

-- =============================================
-- 5. ROW-LEVEL SECURITY POLICIES
-- =============================================

-- Users table RLS - users can only see their own data unless they're staff+
CREATE SECURITY POLICY pol_Users
ADD FILTER PREDICATE dbo.fn_IsStaffOrHigher() = 1 OR UserID = dbo.fn_GetCurrentUserID() ON Users,
ADD BLOCK PREDICATE dbo.fn_IsStaffOrHigher() = 1 OR UserID = dbo.fn_GetCurrentUserID() ON Users AFTER UPDATE;

-- Bookings table RLS - users can only see their own bookings unless they're staff+
CREATE SECURITY POLICY pol_Bookings
ADD FILTER PREDICATE dbo.fn_IsStaffOrHigher() = 1 OR UserID = dbo.fn_GetCurrentUserID() ON Bookings,
ADD BLOCK PREDICATE dbo.fn_IsStaffOrHigher() = 1 OR 
    (UserID = dbo.fn_GetCurrentUserID() AND Status IN ('Pending', 'Approved')) ON Bookings AFTER UPDATE;

-- Penalties table RLS - users can only see their own penalties unless they're staff+
CREATE SECURITY POLICY pol_Penalties
ADD FILTER PREDICATE dbo.fn_IsStaffOrHigher() = 1 OR UserID = dbo.fn_GetCurrentUserID() ON Penalties;

-- Audit logs RLS - only staff and above can see audit logs
CREATE SECURITY POLICY pol_AuditLogs
ADD FILTER PREDICATE dbo.fn_IsStaffOrHigher() = 1 ON AuditLogs;

-- =============================================
-- 6. DATA ENCRYPTION FOR SENSITIVE INFORMATION
-- =============================================

-- Create master key for encryption
IF NOT EXISTS (SELECT * FROM sys.symmetric_keys WHERE name = '##MS_DatabaseMasterKey##')
BEGIN
    CREATE MASTER KEY ENCRYPTION BY PASSWORD = 'HUIT_LibrarySystem_MasterKey_2024!';
END

-- Create certificate for encryption
IF NOT EXISTS (SELECT * FROM sys.certificates WHERE name = 'HUIT_Library_Cert')
BEGIN
    CREATE CERTIFICATE HUIT_Library_Cert
    WITH SUBJECT = 'HUIT Library Management Certificate',
    EXPIRY_DATE = '2029-12-31';
END

-- Create symmetric key for sensitive data encryption
IF NOT EXISTS (SELECT * FROM sys.symmetric_keys WHERE name = 'HUIT_Library_Key')
BEGIN
    CREATE SYMMETRIC KEY HUIT_Library_Key
    WITH ALGORITHM = AES_256
    ENCRYPTION BY CERTIFICATE HUIT_Library_Cert;
END

-- =============================================
-- 7. ENCRYPTION HELPER FUNCTIONS
-- =============================================

-- Function to encrypt sensitive data
CREATE FUNCTION fn_EncryptData(@PlainText nvarchar(max))
RETURNS varbinary(max)
AS
BEGIN
    DECLARE @EncryptedData varbinary(max);
    
    OPEN SYMMETRIC KEY HUIT_Library_Key
    DECRYPTION BY CERTIFICATE HUIT_Library_Cert;
    
    SET @EncryptedData = EncryptByKey(Key_GUID('HUIT_Library_Key'), @PlainText);
    
    CLOSE SYMMETRIC KEY HUIT_Library_Key;
    
    RETURN @EncryptedData;
END
GO

-- Function to decrypt sensitive data
CREATE FUNCTION fn_DecryptData(@EncryptedData varbinary(max))
RETURNS nvarchar(max)
AS
BEGIN
    DECLARE @PlainText nvarchar(max);
    
    IF @EncryptedData IS NULL
        RETURN NULL;
    
    OPEN SYMMETRIC KEY HUIT_Library_Key
    DECRYPTION BY CERTIFICATE HUIT_Library_Cert;
    
    SET @PlainText = CONVERT(nvarchar(max), DecryptByKey(@EncryptedData));
    
    CLOSE SYMMETRIC KEY HUIT_Library_Key;
    
    RETURN @PlainText;
END
GO

-- =============================================
-- 8. SECURE VIEWS FOR SENSITIVE DATA
-- =============================================

-- Secure view for user personal information
CREATE VIEW vw_SecureUserInfo AS
SELECT 
    UserID,
    UserCode,
    FullName,
    CASE 
        WHEN dbo.fn_IsStaffOrHigher() = 1 OR UserID = dbo.fn_GetCurrentUserID() THEN Email
        ELSE LEFT(Email, 3) + '***@' + RIGHT(Email, CHARINDEX('@', REVERSE(Email)) - 1)
    END as Email,
    CASE 
        WHEN dbo.fn_IsStaffOrHigher() = 1 OR UserID = dbo.fn_GetCurrentUserID() THEN PhoneNumber
        ELSE LEFT(PhoneNumber, 3) + 'XXX' + RIGHT(PhoneNumber, 3)
    END as PhoneNumber,
    UserType,
    DepartmentID,
    YearOfStudy,
    IsActive,
    CreatedDate
FROM Users
WHERE dbo.fn_IsStaffOrHigher() = 1 OR UserID = dbo.fn_GetCurrentUserID();

GO

-- =============================================
-- 9. SECURITY MONITORING PROCEDURES
-- =============================================

-- Procedure to log security events
CREATE PROCEDURE sp_LogSecurityEvent
    @EventType nvarchar(50),
    @Description nvarchar(500),
    @UserID int = NULL,
    @IPAddress nvarchar(50) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    INSERT INTO AuditLogs (TableName, RecordID, Action, NewValues, UserID, IPAddress)
    VALUES ('Security', 0, @EventType, @Description, @UserID, @IPAddress);
END
GO

-- Procedure to check for suspicious activities
CREATE PROCEDURE sp_CheckSuspiciousActivity
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Check for multiple failed login attempts
    SELECT 
        UserID,
        COUNT(*) as FailedAttempts,
        MAX(LogDate) as LastAttempt
    FROM AuditLogs 
    WHERE Action = 'LOGIN_FAILED' 
    AND LogDate > DATEADD(HOUR, -1, GETDATE())
    GROUP BY UserID
    HAVING COUNT(*) > 3;
    
    -- Check for unusual access patterns
    SELECT 
        UserID,
        COUNT(*) as AccessCount,
        MIN(LogDate) as FirstAccess,
        MAX(LogDate) as LastAccess
    FROM AuditLogs 
    WHERE LogDate > DATEADD(HOUR, -24, GETDATE())
    GROUP BY UserID
    HAVING COUNT(*) > 100;
END
GO

-- =============================================
-- 10. DEMO USERS FOR TESTING
-- =============================================

-- Note: In production, these would be created through proper identity management
-- This is just for demonstration purposes

PRINT 'Security and permissions configured successfully for HUIT Library Management System';
PRINT 'Bảo mật và phân quyền đã được cấu hình thành công cho Hệ thống Quản lý Thư viện HUIT';

-- Display security summary
SELECT 
    'Database Roles' as SecurityComponent,
    COUNT(*) as Count
FROM sys.database_principals 
WHERE type = 'R' AND name LIKE 'db_%'

UNION ALL

SELECT 
    'RLS Policies' as SecurityComponent,
    COUNT(*) as Count
FROM sys.security_policies

UNION ALL

SELECT 
    'Symmetric Keys' as SecurityComponent,
    COUNT(*) as Count
FROM sys.symmetric_keys
WHERE name = 'HUIT_Library_Key'

UNION ALL

SELECT 
    'Certificates' as SecurityComponent,
    COUNT(*) as Count
FROM sys.certificates
WHERE name = 'HUIT_Library_Cert';

GO