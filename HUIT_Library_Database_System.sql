-- =====================================================
-- HUIT Library Management System Database
-- Ho Chi Minh City University of Industry and Trade
-- Complete Database Implementation
-- =====================================================

USE master;
GO

-- Create Database if not exists
IF NOT EXISTS (SELECT name FROM sys.databases WHERE name = 'HUIT_LibraryDB')
BEGIN
    CREATE DATABASE HUIT_LibraryDB;
END
GO

USE HUIT_LibraryDB;
GO

-- =====================================================
-- 1. SYSTEM CONFIGURATION
-- =====================================================

-- System Configuration Table
IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='SystemConfiguration' AND xtype='U')
CREATE TABLE SystemConfiguration (
    ConfigId INT IDENTITY(1,1) PRIMARY KEY,
    ConfigKey NVARCHAR(100) NOT NULL UNIQUE,
    ConfigValue NVARCHAR(500) NOT NULL,
    Description NVARCHAR(255),
    IsActive BIT DEFAULT 1,
    CreatedAt DATETIME2 DEFAULT GETDATE(),
    UpdatedAt DATETIME2 DEFAULT GETDATE()
);

-- =====================================================
-- 2. USER MANAGEMENT
-- =====================================================

-- User Roles
IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='UserRoles' AND xtype='U')
CREATE TABLE UserRoles (
    RoleId INT IDENTITY(1,1) PRIMARY KEY,
    RoleName NVARCHAR(50) NOT NULL UNIQUE,
    Description NVARCHAR(255),
    Permissions NVARCHAR(MAX), -- JSON format for permissions
    IsActive BIT DEFAULT 1,
    CreatedAt DATETIME2 DEFAULT GETDATE()
);

-- Faculties/Departments at HUIT
IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='Faculties' AND xtype='U')
CREATE TABLE Faculties (
    FacultyId INT IDENTITY(1,1) PRIMARY KEY,
    FacultyCode NVARCHAR(10) NOT NULL UNIQUE,
    FacultyName NVARCHAR(100) NOT NULL,
    Description NVARCHAR(255),
    IsActive BIT DEFAULT 1,
    CreatedAt DATETIME2 DEFAULT GETDATE()
);

-- Users (Students, Faculty, Staff)
IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='Users' AND xtype='U')
CREATE TABLE Users (
    UserId INT IDENTITY(1,1) PRIMARY KEY,
    UserCode NVARCHAR(20) NOT NULL UNIQUE, -- Student ID or Staff ID
    FullName NVARCHAR(100) NOT NULL,
    Email NVARCHAR(100) UNIQUE,
    PhoneNumber NVARCHAR(20),
    FacultyId INT,
    RoleId INT NOT NULL,
    Status NVARCHAR(20) DEFAULT 'ACTIVE', -- ACTIVE, INACTIVE, SUSPENDED
    PasswordHash NVARCHAR(255),
    LastLogin DATETIME2,
    CreatedAt DATETIME2 DEFAULT GETDATE(),
    UpdatedAt DATETIME2 DEFAULT GETDATE(),
    FOREIGN KEY (FacultyId) REFERENCES Faculties(FacultyId),
    FOREIGN KEY (RoleId) REFERENCES UserRoles(RoleId)
);

-- =====================================================
-- 3. RESOURCE MANAGEMENT
-- =====================================================

-- Resource Categories
IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='ResourceCategories' AND xtype='U')
CREATE TABLE ResourceCategories (
    CategoryId INT IDENTITY(1,1) PRIMARY KEY,
    CategoryName NVARCHAR(100) NOT NULL UNIQUE,
    Description NVARCHAR(255),
    CategoryType NVARCHAR(20) NOT NULL, -- BOOK, ROOM, EQUIPMENT
    IsActive BIT DEFAULT 1,
    CreatedAt DATETIME2 DEFAULT GETDATE()
);

-- Resource Status
IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='ResourceStatus' AND xtype='U')
CREATE TABLE ResourceStatus (
    StatusId INT IDENTITY(1,1) PRIMARY KEY,
    StatusCode NVARCHAR(20) NOT NULL UNIQUE,
    StatusName NVARCHAR(50) NOT NULL,
    Description NVARCHAR(255),
    IsActive BIT DEFAULT 1
);

-- Resources (Books, Study Rooms, Equipment)
IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='Resources' AND xtype='U')
CREATE TABLE Resources (
    ResourceId INT IDENTITY(1,1) PRIMARY KEY,
    ResourceCode NVARCHAR(50) NOT NULL UNIQUE,
    Title NVARCHAR(200) NOT NULL,
    Author NVARCHAR(100), -- For books
    Publisher NVARCHAR(100), -- For books
    ISBN NVARCHAR(20), -- For books
    PublicationYear INT, -- For books
    CategoryId INT NOT NULL,
    StatusId INT NOT NULL,
    Location NVARCHAR(100),
    Capacity INT, -- For rooms/equipment
    Description NVARCHAR(MAX),
    BookingDurationHours INT DEFAULT 24, -- Default booking duration
    FinePerHour DECIMAL(10,2) DEFAULT 5000, -- VND per hour overdue
    IsBookable BIT DEFAULT 1,
    CreatedAt DATETIME2 DEFAULT GETDATE(),
    UpdatedAt DATETIME2 DEFAULT GETDATE(),
    FOREIGN KEY (CategoryId) REFERENCES ResourceCategories(CategoryId),
    FOREIGN KEY (StatusId) REFERENCES ResourceStatus(StatusId)
);

-- =====================================================
-- 4. BOOKING SYSTEM
-- =====================================================

-- Booking Status
IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='BookingStatus' AND xtype='U')
CREATE TABLE BookingStatus (
    StatusId INT IDENTITY(1,1) PRIMARY KEY,
    StatusCode NVARCHAR(20) NOT NULL UNIQUE,
    StatusName NVARCHAR(50) NOT NULL,
    Description NVARCHAR(255),
    IsActive BIT DEFAULT 1
);

-- Bookings
IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='Bookings' AND xtype='U')
CREATE TABLE Bookings (
    BookingId INT IDENTITY(1,1) PRIMARY KEY,
    BookingCode NVARCHAR(20) NOT NULL UNIQUE,
    UserId INT NOT NULL,
    StatusCode NVARCHAR(20) NOT NULL DEFAULT 'PENDING',
    BookingDate DATETIME2 NOT NULL,
    StartTime DATETIME2 NOT NULL,
    EndTime DATETIME2 NOT NULL,
    ActualReturnTime DATETIME2,
    Purpose NVARCHAR(255),
    Notes NVARCHAR(500),
    CreatedAt DATETIME2 DEFAULT GETDATE(),
    UpdatedAt DATETIME2 DEFAULT GETDATE(),
    FOREIGN KEY (UserId) REFERENCES Users(UserId),
    FOREIGN KEY (StatusCode) REFERENCES BookingStatus(StatusCode)
);

-- Booking Items (Details)
IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='BookingItems' AND xtype='U')
CREATE TABLE BookingItems (
    BookingItemId INT IDENTITY(1,1) PRIMARY KEY,
    BookingId INT NOT NULL,
    ResourceId INT NOT NULL,
    Quantity INT DEFAULT 1,
    Status NVARCHAR(20) DEFAULT 'PENDING', -- PENDING, CONFIRMED, CANCELLED, COMPLETED
    Notes NVARCHAR(255),
    CreatedAt DATETIME2 DEFAULT GETDATE(),
    FOREIGN KEY (BookingId) REFERENCES Bookings(BookingId) ON DELETE CASCADE,
    FOREIGN KEY (ResourceId) REFERENCES Resources(ResourceId)
);

-- =====================================================
-- 5. FINE MANAGEMENT
-- =====================================================

-- Fine Types
IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='FineTypes' AND xtype='U')
CREATE TABLE FineTypes (
    FineTypeId INT IDENTITY(1,1) PRIMARY KEY,
    TypeCode NVARCHAR(20) NOT NULL UNIQUE,
    TypeName NVARCHAR(100) NOT NULL,
    DefaultAmount DECIMAL(10,2) NOT NULL,
    Description NVARCHAR(255),
    IsActive BIT DEFAULT 1,
    CreatedAt DATETIME2 DEFAULT GETDATE()
);

-- Fines
IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='Fines' AND xtype='U')
CREATE TABLE Fines (
    FineId INT IDENTITY(1,1) PRIMARY KEY,
    FineCode NVARCHAR(20) NOT NULL UNIQUE,
    UserId INT NOT NULL,
    BookingId INT,
    FineTypeId INT NOT NULL,
    Amount DECIMAL(10,2) NOT NULL,
    Reason NVARCHAR(255),
    Status NVARCHAR(20) DEFAULT 'UNPAID', -- UNPAID, PAID, WAIVED
    IssuedDate DATETIME2 DEFAULT GETDATE(),
    PaidDate DATETIME2,
    IssuedBy INT,
    PaidTo INT,
    PaymentMethod NVARCHAR(50),
    PaymentReference NVARCHAR(100),
    Notes NVARCHAR(500),
    CreatedAt DATETIME2 DEFAULT GETDATE(),
    UpdatedAt DATETIME2 DEFAULT GETDATE(),
    FOREIGN KEY (UserId) REFERENCES Users(UserId),
    FOREIGN KEY (BookingId) REFERENCES Bookings(BookingId),
    FOREIGN KEY (FineTypeId) REFERENCES FineTypes(FineTypeId),
    FOREIGN KEY (IssuedBy) REFERENCES Users(UserId),
    FOREIGN KEY (PaidTo) REFERENCES Users(UserId)
);

-- =====================================================
-- 6. AUDIT AND LOGGING
-- =====================================================

-- Audit Logs
IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='AuditLogs' AND xtype='U')
CREATE TABLE AuditLogs (
    AuditId INT IDENTITY(1,1) PRIMARY KEY,
    TableName NVARCHAR(100) NOT NULL,
    RecordId INT NOT NULL,
    Action NVARCHAR(20) NOT NULL, -- INSERT, UPDATE, DELETE
    OldValues NVARCHAR(MAX), -- JSON format
    NewValues NVARCHAR(MAX), -- JSON format
    UserId INT,
    IPAddress NVARCHAR(45),
    UserAgent NVARCHAR(255),
    CreatedAt DATETIME2 DEFAULT GETDATE(),
    FOREIGN KEY (UserId) REFERENCES Users(UserId)
);

-- =====================================================
-- 7. NOTIFICATION SYSTEM
-- =====================================================

-- Notification Types
-- =====================================================
-- 8. INDEXES FOR PERFORMANCE
-- =====================================================

-- Users indexes
CREATE INDEX IX_Users_UserCode ON Users(UserCode);
CREATE INDEX IX_Users_Email ON Users(Email);
CREATE INDEX IX_Users_FacultyId ON Users(FacultyId);
CREATE INDEX IX_Users_Status ON Users(Status);

-- Resources indexes
CREATE INDEX IX_Resources_ResourceCode ON Resources(ResourceCode);
CREATE INDEX IX_Resources_CategoryId ON Resources(CategoryId);
CREATE INDEX IX_Resources_StatusId ON Resources(StatusId);
CREATE INDEX IX_Resources_IsBookable ON Resources(IsBookable);

-- Bookings indexes
CREATE INDEX IX_Bookings_UserId ON Bookings(UserId);
CREATE INDEX IX_Bookings_StatusCode ON Bookings(StatusCode);
CREATE INDEX IX_Bookings_BookingDate ON Bookings(BookingDate);
CREATE INDEX IX_Bookings_StartTime ON Bookings(StartTime);
CREATE INDEX IX_Bookings_EndTime ON Bookings(EndTime);

-- BookingItems indexes
CREATE INDEX IX_BookingItems_BookingId ON BookingItems(BookingId);
CREATE INDEX IX_BookingItems_ResourceId ON BookingItems(ResourceId);

-- Fines indexes
CREATE INDEX IX_Fines_UserId ON Fines(UserId);
CREATE INDEX IX_Fines_Status ON Fines(Status);
CREATE INDEX IX_Fines_IssuedDate ON Fines(IssuedDate);

-- AuditLogs indexes
CREATE INDEX IX_AuditLogs_TableName ON AuditLogs(TableName);
CREATE INDEX IX_AuditLogs_RecordId ON AuditLogs(RecordId);
CREATE INDEX IX_AuditLogs_UserId ON AuditLogs(UserId);
CREATE INDEX IX_AuditLogs_CreatedAt ON AuditLogs(CreatedAt);

-- Notifications indexes
CREATE INDEX IX_Notifications_UserId ON Notifications(UserId);
CREATE INDEX IX_Notifications_IsRead ON Notifications(IsRead);
CREATE INDEX IX_Notifications_CreatedAt ON Notifications(CreatedAt);

-- =====================================================
-- 9. INITIAL DATA SETUP
-- =====================================================

-- System Configuration Data
INSERT INTO SystemConfiguration (ConfigKey, ConfigValue, Description) VALUES
('LIBRARY_NAME', N'Thư viện Đại học Công nghiệp TP.HCM', N'Tên thư viện'),
('MAX_BOOKING_DAYS', '7', N'Số ngày tối đa có thể đặt trước'),
('MAX_BOOKS_PER_USER', '5', N'Số sách tối đa một người có thể mượn'),
('FINE_GRACE_PERIOD_HOURS', '2', N'Thời gian gia hạn miễn phí (giờ)'),
('DEFAULT_BOOKING_DURATION_HOURS', '24', N'Thời gian mượn mặc định (giờ)'),
('LATE_FINE_PER_HOUR', '5000', N'Phí phạt trễ hạn mỗi giờ (VND)'),
('NOTIFICATION_EMAIL_ENABLED', '1', N'Bật thông báo qua email'),
('MAINTENANCE_START_TIME', '02:00', N'Giờ bắt đầu bảo trì hệ thống'),
('LIBRARY_OPENING_HOURS', '07:00-22:00', N'Giờ mở cửa thư viện'),
('MAX_RENEWAL_TIMES', '2', N'Số lần gia hạn tối đa');

-- User Roles
INSERT INTO UserRoles (RoleName, Description, Permissions) VALUES
('ADMIN', N'Quản trị viên hệ thống', N'{"all": true}'),
('LIBRARIAN', N'Thủ thư', N'{"bookings": "manage", "resources": "manage", "fines": "manage", "reports": "view"}'),
('STAFF', N'Cán bộ trường', N'{"bookings": "create", "resources": "view", "profile": "manage"}'),
('STUDENT', N'Sinh viên', N'{"bookings": "own", "resources": "view", "profile": "view"}'),
('FACULTY', N'Giảng viên', N'{"bookings": "create", "resources": "view", "profile": "manage"}');

-- Faculties at HUIT
INSERT INTO Faculties (FacultyCode, FacultyName, Description) VALUES
('CNTT', N'Công nghệ Thông tin', N'Khoa Công nghệ Thông tin'),
('CK', N'Cơ khí', N'Khoa Cơ khí'),
('DDT', N'Điện - Điện tử', N'Khoa Điện - Điện tử'),
('KT', N'Kinh tế', N'Khoa Kinh tế'),
('HOA', N'Hóa học', N'Khoa Hóa học'),
('XD', N'Xây dựng', N'Khoa Xây dựng'),
('ADMIN', N'Ban Giám hiệu', N'Ban Giám hiệu và các phòng ban');

-- Resource Categories
INSERT INTO ResourceCategories (CategoryName, Description, CategoryType) VALUES
(N'Sách Công nghệ Thông tin', N'Sách chuyên ngành CNTT', 'BOOK'),
(N'Sách Cơ khí', N'Sách chuyên ngành Cơ khí', 'BOOK'),
(N'Sách Điện - Điện tử', N'Sách chuyên ngành Điện - Điện tử', 'BOOK'),
(N'Sách Kinh tế', N'Sách chuyên ngành Kinh tế', 'BOOK'),
(N'Sách Hóa học', N'Sách chuyên ngành Hóa học', 'BOOK'),
(N'Sách Xây dựng', N'Sách chuyên ngành Xây dựng', 'BOOK'),
(N'Sách Tham khảo', N'Sách tham khảo chung', 'BOOK'),
(N'Tạp chí Khoa học', N'Tạp chí và báo khoa học', 'BOOK'),
(N'Phòng Học nhóm', N'Phòng học nhóm nhỏ', 'ROOM'),
(N'Phòng Hội thảo', N'Phòng hội thảo lớn', 'ROOM'),
(N'Phòng Máy tính', N'Phòng máy tính', 'ROOM'),
(N'Thiết bị Máy chiếu', N'Máy chiếu và thiết bị trình chiếu', 'EQUIPMENT'),
(N'Thiết bị Âm thanh', N'Thiết bị âm thanh, micro', 'EQUIPMENT'),
(N'Laptop', N'Laptop cho sinh viên mượn', 'EQUIPMENT');

-- Resource Status
INSERT INTO ResourceStatus (StatusCode, StatusName, Description) VALUES
('AVAILABLE', N'Có sẵn', N'Tài nguyên có sẵn để đặt'),
('BORROWED', N'Đang được mượn', N'Tài nguyên đang được sử dụng'),
('RESERVED', N'Đã được đặt', N'Tài nguyên đã được đặt trước'),
('MAINTENANCE', N'Bảo trì', N'Tài nguyên đang bảo trì'),
('DAMAGED', N'Hư hỏng', N'Tài nguyên bị hư hỏng'),
('LOST', N'Mất', N'Tài nguyên bị mất');

-- Booking Status
INSERT INTO BookingStatus (StatusCode, StatusName, Description) VALUES
('PENDING', N'Chờ xử lý', N'Đặt chỗ chờ xác nhận'),
('CONFIRMED', N'Đã xác nhận', N'Đặt chỗ đã được xác nhận'),
('ACTIVE', N'Đang sử dụng', N'Đang trong thời gian sử dụng'),
('COMPLETED', N'Hoàn thành', N'Đã trả và hoàn thành'),
('OVERDUE', N'Quá hạn', N'Quá thời gian quy định'),
('CANCELLED', N'Đã hủy', N'Đặt chỗ đã bị hủy'),
('NOSHOW', N'Không đến', N'Không đến sử dụng');

-- Fine Types
INSERT INTO FineTypes (TypeCode, TypeName, DefaultAmount, Description) VALUES
('OVERDUE', N'Phạt trễ hạn', 5000, N'Phạt khi trả muộn'),
('DAMAGE', N'Phạt hư hỏng', 50000, N'Phạt khi làm hư hỏng tài liệu'),
('LOST', N'Phạt mất', 200000, N'Phạt khi làm mất tài liệu'),
('NOSHOW', N'Phạt không đến', 10000, N'Phạt khi đặt chỗ nhưng không đến');

-- Notification Types
INSERT INTO NotificationTypes (TypeCode, TypeName, Template) VALUES
('BOOKING_CONFIRMED', N'Xác nhận đặt chỗ', N'Đặt chỗ {BookingCode} của bạn đã được xác nhận cho {ResourceTitle}'),
('BOOKING_REMINDER', N'Nhắc nhở đặt chỗ', N'Nhắc nhở: Bạn có lịch sử dụng {ResourceTitle} vào {StartTime}'),
('RETURN_REMINDER', N'Nhắc nhở trả', N'Nhắc nhở: Bạn cần trả {ResourceTitle} trước {EndTime}'),
('OVERDUE_NOTICE', N'Thông báo quá hạn', N'Thông báo: {ResourceTitle} đã quá hạn trả. Phí phạt: {FineAmount} VND'),
('FINE_ISSUED', N'Thông báo phạt', N'Bạn có khoản phạt mới: {FineAmount} VND. Lý do: {Reason}'),
('PAYMENT_RECEIVED', N'Xác nhận thanh toán', N'Đã nhận thanh toán phạt {FineAmount} VND');

-- =====================================================
-- 10. SAMPLE DATA FOR HUIT
-- =====================================================

-- Sample HUIT Users
INSERT INTO Users (UserCode, FullName, Email, PhoneNumber, FacultyId, RoleId, Status, PasswordHash) VALUES
-- Admin users
('ADMIN001', N'Nguyễn Văn Quản', 'admin@huit.edu.vn', '0283894445', 7, 1, 'ACTIVE', 'hashed_password_admin'),
('LIB001', N'Trần Thị Thu', 'library@huit.edu.vn', '0283894446', 7, 2, 'ACTIVE', 'hashed_password_lib'),

-- CNTT Faculty and Students
('GV001', N'PGS.TS Nguyễn Văn Hùng', 'hungnv@huit.edu.vn', '0283894447', 1, 5, 'ACTIVE', 'hashed_password_faculty'),
('20110001', N'Nguyễn Văn An', '20110001@student.huit.edu.vn', '0901234567', 1, 4, 'ACTIVE', 'hashed_password_student'),
('20110002', N'Trần Thị Bình', '20110002@student.huit.edu.vn', '0901234568', 1, 4, 'ACTIVE', 'hashed_password_student'),
('20110003', N'Lê Minh Cường', '20110003@student.huit.edu.vn', '0901234569', 1, 4, 'ACTIVE', 'hashed_password_student'),

-- Mechanical Faculty and Students
('GV002', N'TS. Phạm Minh Đức', 'ducpm@huit.edu.vn', '0283894448', 2, 5, 'ACTIVE', 'hashed_password_faculty'),
('20210001', N'Hoàng Văn Dũng', '20210001@student.huit.edu.vn', '0901234570', 2, 4, 'ACTIVE', 'hashed_password_student'),
('20210002', N'Đinh Thị Hoa', '20210002@student.huit.edu.vn', '0901234571', 2, 4, 'ACTIVE', 'hashed_password_student'),

-- Economics Faculty and Students
('GV003', N'ThS. Võ Thị Kim', 'kimvt@huit.edu.vn', '0283894449', 4, 5, 'ACTIVE', 'hashed_password_faculty'),
('20310001', N'Phan Văn Long', '20310001@student.huit.edu.vn', '0901234572', 4, 4, 'ACTIVE', 'hashed_password_student'),
('20310002', N'Mai Thị Ngọc', '20310002@student.huit.edu.vn', '0901234573', 4, 4, 'ACTIVE', 'hashed_password_student');

-- Sample Resources for HUIT
INSERT INTO Resources (ResourceCode, Title, Author, Publisher, ISBN, PublicationYear, CategoryId, StatusId, Location, Description, BookingDurationHours, FinePerHour, IsBookable) VALUES
-- CNTT Books
('BOOK_CNTT_001', N'Lập trình C# nâng cao', N'Nguyễn Văn A', N'NXB Đại học Quốc gia', '978-604-0000-001', 2023, 1, 1, N'Kệ A1-01', N'Sách chuyên sâu về C# và .NET', 168, 2000, 1),
('BOOK_CNTT_002', N'Cơ sở dữ liệu SQL Server', N'Trần Thị B', N'NXB Thông tin và Truyền thông', '978-604-0000-002', 2022, 1, 1, N'Kệ A1-02', N'Hướng dẫn SQL Server từ cơ bản đến nâng cao', 168, 2000, 1),
('BOOK_CNTT_003', N'Trí tuệ nhân tạo và Machine Learning', N'Lê Văn C', N'NXB Khoa học và Kỹ thuật', '978-604-0000-003', 2023, 1, 1, N'Kệ A1-03', N'AI và ML trong thời đại 4.0', 168, 2000, 1),

-- Mechanical Books
('BOOK_CK_001', N'Cơ học kỹ thuật', N'Phạm Văn D', N'NXB Xây dựng', '978-604-0000-004', 2021, 2, 1, N'Kệ B1-01', N'Giáo trình cơ học kỹ thuật', 168, 2000, 1),
('BOOK_CK_002', N'Thiết kế máy', N'Hoàng Thị E', N'NXB Khoa học và Kỹ thuật', '978-604-0000-005', 2022, 2, 1, N'Kệ B1-02', N'Thiết kế chi tiết máy', 168, 2000, 1),

-- Economics Books
('BOOK_KT_001', N'Kinh tế vĩ mô', N'Võ Văn F', N'NXB Kinh tế', '978-604-0000-006', 2023, 4, 1, N'Kệ C1-01', N'Lý thuyết kinh tế vĩ mô hiện đại', 168, 2000, 1),
('BOOK_KT_002', N'Marketing số', N'Đỗ Thị G', N'NXB Thời đại', '978-604-0000-007', 2023, 4, 1, N'Kệ C1-02', N'Marketing trong kỉ nguyên số', 168, 2000, 1),

-- Study Rooms
('ROOM_001', N'Phòng học nhóm A101', NULL, NULL, NULL, NULL, 9, 1, N'Tầng 1, Tòa A', N'Phòng học nhóm 6-8 người', 4, 10000, 1),
('ROOM_002', N'Phòng học nhóm A102', NULL, NULL, NULL, NULL, 9, 1, N'Tầng 1, Tòa A', N'Phòng học nhóm 6-8 người', 4, 10000, 1),
('ROOM_003', N'Phòng hội thảo B201', NULL, NULL, NULL, NULL, 10, 1, N'Tầng 2, Tòa B', N'Phòng hội thảo 30-40 người', 4, 20000, 1),
('ROOM_004', N'Phòng máy tính C301', NULL, NULL, NULL, NULL, 11, 1, N'Tầng 3, Tòa C', N'Phòng máy tính 20 máy', 4, 15000, 1),

-- Equipment
('EQUIP_001', N'Máy chiếu Epson EB-X41', NULL, NULL, NULL, NULL, 12, 1, N'Kho thiết bị A', N'Máy chiếu độ phân giải cao', 4, 25000, 1),
('EQUIP_002', N'Laptop Dell Inspiron 15', NULL, NULL, NULL, NULL, 14, 1, N'Kho thiết bị B', N'Laptop cho sinh viên mượn', 24, 10000, 1),
('EQUIP_003', N'Micro không dây Shure', NULL, NULL, NULL, NULL, 13, 1, N'Kho thiết bị C', N'Micro cho thuyết trình', 4, 15000, 1);

GO
IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='NotificationTypes' AND xtype='U')
CREATE TABLE NotificationTypes (
    TypeId INT IDENTITY(1,1) PRIMARY KEY,
    TypeCode NVARCHAR(20) NOT NULL UNIQUE,
-- =====================================================
-- 11. VIEWS AND STATISTICS (Line 1105 as specified)
-- =====================================================

-- Resource Statistics View (As specified in the problem statement from line 1105)
CREATE OR ALTER VIEW vw_ResourceStatistics AS
WITH BookingStats AS (
    SELECT 
        r.ResourceId,
        COUNT(b.BookingId) AS TotalBookings,
        COUNT(CASE WHEN b.StatusCode = 'COMPLETED' THEN 1 END) AS CompletedBookings,
        COUNT(CASE WHEN b.StatusCode = 'NOSHOW' THEN 1 END) AS NoShowBookings,
        COUNT(CASE WHEN b.StatusCode = 'OVERDUE' THEN 1 END) AS OverdueBookings,
        COUNT(CASE WHEN b.StatusCode = 'CANCELLED' THEN 1 END) AS CancelledBookings,
        AVG(CASE WHEN b.ActualReturnTime IS NOT NULL 
            THEN DATEDIFF(HOUR, b.StartTime, b.ActualReturnTime) 
            ELSE NULL END) AS AvgUsageHours,
        MAX(b.CreatedAt) AS LastBookingDate
    FROM Resources r
    LEFT JOIN BookingItems bi ON r.ResourceId = bi.ResourceId
    LEFT JOIN Bookings b ON bi.BookingId = b.BookingId
    WHERE b.CreatedAt >= DATEADD(MONTH, -12, GETDATE()) OR b.CreatedAt IS NULL
    GROUP BY r.ResourceId
),
FineStats AS (
    SELECT 
        bi.ResourceId,
        COUNT(f.FineId) AS TotalFines,
        SUM(f.Amount) AS TotalFineAmount,
        AVG(f.Amount) AS AvgFineAmount
    FROM BookingItems bi
    LEFT JOIN Bookings b ON bi.BookingId = b.BookingId
    LEFT JOIN Fines f ON b.BookingId = f.BookingId
    WHERE f.IssuedDate >= DATEADD(MONTH, -12, GETDATE()) OR f.IssuedDate IS NULL
    GROUP BY bi.ResourceId
)
SELECT 
    r.ResourceId,
    r.ResourceCode,
    r.Title,
    rc.CategoryName,
    rc.CategoryType,
    rs.StatusName AS CurrentStatus,
    r.Location,
    COALESCE(bs.TotalBookings, 0) AS TotalBookings,
    COALESCE(bs.CompletedBookings, 0) AS CompletedBookings,
    COALESCE(bs.NoShowBookings, 0) AS NoShowBookings,
    COALESCE(bs.OverdueBookings, 0) AS OverdueBookings,
    COALESCE(bs.CancelledBookings, 0) AS CancelledBookings,
    CASE 
        WHEN bs.TotalBookings > 0 
        THEN CAST((bs.CompletedBookings * 100.0 / bs.TotalBookings) AS DECIMAL(5,2))
        ELSE 0 
    END AS CompletionRate,
    CASE 
        WHEN bs.TotalBookings > 0 
        THEN CAST((bs.NoShowBookings * 100.0 / bs.TotalBookings) AS DECIMAL(5,2))
        ELSE 0 
    END AS NoShowRate,
    COALESCE(bs.AvgUsageHours, 0) AS AvgUsageHours,
    bs.LastBookingDate,
    COALESCE(fs.TotalFines, 0) AS TotalFines,
    COALESCE(fs.TotalFineAmount, 0) AS TotalFineAmount,
    COALESCE(fs.AvgFineAmount, 0) AS AvgFineAmount,
    CASE 
        WHEN bs.TotalBookings >= 50 THEN N'Cao'
        WHEN bs.TotalBookings >= 20 THEN N'Trung bình'
        WHEN bs.TotalBookings >= 5 THEN N'Thấp'
        ELSE N'Rất thấp'
    END AS PopularityLevel,
    r.CreatedAt,
    r.UpdatedAt
FROM Resources r
INNER JOIN ResourceCategories rc ON r.CategoryId = rc.CategoryId
INNER JOIN ResourceStatus rs ON r.StatusId = rs.StatusId
LEFT JOIN BookingStats bs ON r.ResourceId = bs.ResourceId
LEFT JOIN FineStats fs ON r.ResourceId = fs.ResourceId;

GO

-- User Activity Statistics View
CREATE OR ALTER VIEW vw_UserActivityStatistics AS
WITH UserBookingStats AS (
    SELECT 
        u.UserId,
        COUNT(b.BookingId) AS TotalBookings,
        COUNT(CASE WHEN b.StatusCode = 'COMPLETED' THEN 1 END) AS CompletedBookings,
        COUNT(CASE WHEN b.StatusCode = 'OVERDUE' THEN 1 END) AS OverdueBookings,
        COUNT(CASE WHEN b.StatusCode = 'NOSHOW' THEN 1 END) AS NoShowBookings,
        MAX(b.CreatedAt) AS LastBookingDate
    FROM Users u
    LEFT JOIN Bookings b ON u.UserId = b.UserId
    WHERE b.CreatedAt >= DATEADD(MONTH, -12, GETDATE()) OR b.CreatedAt IS NULL
    GROUP BY u.UserId
),
UserFineStats AS (
    SELECT 
        u.UserId,
        COUNT(f.FineId) AS TotalFines,
        SUM(CASE WHEN f.Status = 'UNPAID' THEN f.Amount ELSE 0 END) AS UnpaidFineAmount,
        SUM(f.Amount) AS TotalFineAmount
    FROM Users u
    LEFT JOIN Fines f ON u.UserId = f.UserId
    WHERE f.IssuedDate >= DATEADD(MONTH, -12, GETDATE()) OR f.IssuedDate IS NULL
    GROUP BY u.UserId
)
SELECT 
    u.UserId,
    u.UserCode,
    u.FullName,
    ur.RoleName,
    f.FacultyName,
    u.Status AS UserStatus,
    COALESCE(ubs.TotalBookings, 0) AS TotalBookings,
    COALESCE(ubs.CompletedBookings, 0) AS CompletedBookings,
    COALESCE(ubs.OverdueBookings, 0) AS OverdueBookings,
    COALESCE(ubs.NoShowBookings, 0) AS NoShowBookings,
    CASE 
        WHEN ubs.TotalBookings > 0 
        THEN CAST((ubs.CompletedBookings * 100.0 / ubs.TotalBookings) AS DECIMAL(5,2))
        ELSE 0 
    END AS CompletionRate,
    ubs.LastBookingDate,
    u.LastLogin,
    COALESCE(ufs.TotalFines, 0) AS TotalFines,
    COALESCE(ufs.UnpaidFineAmount, 0) AS UnpaidFineAmount,
    COALESCE(ufs.TotalFineAmount, 0) AS TotalFineAmount,
    CASE 
        WHEN ubs.TotalBookings >= 20 THEN N'Hoạt động cao'
        WHEN ubs.TotalBookings >= 10 THEN N'Hoạt động trung bình'
        WHEN ubs.TotalBookings >= 1 THEN N'Hoạt động thấp'
        ELSE N'Chưa có hoạt động'
    END AS ActivityLevel,
    u.CreatedAt,
    u.UpdatedAt
FROM Users u
INNER JOIN UserRoles ur ON u.RoleId = ur.RoleId
LEFT JOIN Faculties f ON u.FacultyId = f.FacultyId
LEFT JOIN UserBookingStats ubs ON u.UserId = ubs.UserId
LEFT JOIN UserFineStats ufs ON u.UserId = ufs.UserId;

GO

-- Faculty Statistics View
CREATE OR ALTER VIEW vw_FacultyStatistics AS
SELECT 
    f.FacultyId,
    f.FacultyCode,
    f.FacultyName,
    COUNT(DISTINCT u.UserId) AS TotalUsers,
    COUNT(DISTINCT CASE WHEN ur.RoleName = 'STUDENT' THEN u.UserId END) AS TotalStudents,
    COUNT(DISTINCT CASE WHEN ur.RoleName = 'FACULTY' THEN u.UserId END) AS TotalFaculty,
    COUNT(DISTINCT CASE WHEN ur.RoleName = 'STAFF' THEN u.UserId END) AS TotalStaff,
    COUNT(DISTINCT b.BookingId) AS TotalBookings,
    COUNT(DISTINCT CASE WHEN b.StatusCode = 'COMPLETED' THEN b.BookingId END) AS CompletedBookings,
    SUM(CASE WHEN fi.Status = 'UNPAID' THEN fi.Amount ELSE 0 END) AS UnpaidFines,
    SUM(fi.Amount) AS TotalFines
FROM Faculties f
LEFT JOIN Users u ON f.FacultyId = u.FacultyId AND u.Status = 'ACTIVE'
LEFT JOIN UserRoles ur ON u.RoleId = ur.RoleId
LEFT JOIN Bookings b ON u.UserId = b.UserId
LEFT JOIN Fines fi ON u.UserId = fi.UserId
GROUP BY f.FacultyId, f.FacultyCode, f.FacultyName;

GO

-- Daily Usage Statistics View
CREATE OR ALTER VIEW vw_DailyUsageStatistics AS
SELECT 
    CAST(b.BookingDate AS DATE) AS BookingDate,
    COUNT(DISTINCT b.BookingId) AS TotalBookings,
    COUNT(DISTINCT b.UserId) AS UniqueUsers,
    COUNT(DISTINCT bi.ResourceId) AS ResourcesUsed,
    COUNT(CASE WHEN b.StatusCode = 'COMPLETED' THEN 1 END) AS CompletedBookings,
    COUNT(CASE WHEN b.StatusCode = 'NOSHOW' THEN 1 END) AS NoShowBookings,
    COUNT(CASE WHEN b.StatusCode = 'CANCELLED' THEN 1 END) AS CancelledBookings,
    AVG(DATEDIFF(HOUR, b.StartTime, b.EndTime)) AS AvgBookingDuration
FROM Bookings b
INNER JOIN BookingItems bi ON b.BookingId = bi.BookingId
WHERE b.BookingDate >= DATEADD(MONTH, -3, GETDATE())
GROUP BY CAST(b.BookingDate AS DATE);

GO

-- =====================================================
-- 12. STORED PROCEDURES FOR BOOKING MANAGEMENT
-- =====================================================

-- Create Booking Procedure with HUIT Validation
CREATE OR ALTER PROCEDURE sp_CreateBooking
    @UserId INT,
    @ResourceIds NVARCHAR(MAX), -- Comma-separated list of ResourceIds
    @StartTime DATETIME2,
    @EndTime DATETIME2,
    @Purpose NVARCHAR(255) = NULL,
    @Notes NVARCHAR(500) = NULL,
    @BookingId INT OUTPUT,
    @ErrorMessage NVARCHAR(500) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        BEGIN TRANSACTION;
        
        -- Validate user exists and is active
        IF NOT EXISTS (SELECT 1 FROM Users WHERE UserId = @UserId AND Status = 'ACTIVE')
        BEGIN
            SET @ErrorMessage = N'Người dùng không tồn tại hoặc không hoạt động';
            ROLLBACK TRANSACTION;
            RETURN -1;
        END
        
        -- Check user's unpaid fines
        DECLARE @UnpaidFines DECIMAL(10,2);
        SELECT @UnpaidFines = ISNULL(SUM(Amount), 0) 
        FROM Fines 
        WHERE UserId = @UserId AND Status = 'UNPAID';
        
        IF @UnpaidFines > 100000 -- 100,000 VND limit
        BEGIN
            SET @ErrorMessage = N'Bạn có khoản phạt chưa thanh toán vượt quá 100,000 VND. Vui lòng thanh toán trước khi đặt chỗ mới.';
            ROLLBACK TRANSACTION;
            RETURN -2;
        END
        
        -- Validate booking time
        IF @StartTime >= @EndTime
        BEGIN
            SET @ErrorMessage = N'Thời gian bắt đầu phải trước thời gian kết thúc';
            ROLLBACK TRANSACTION;
            RETURN -3;
        END
        
        IF @StartTime < GETDATE()
        BEGIN
            SET @ErrorMessage = N'Không thể đặt chỗ cho thời gian trong quá khứ';
            ROLLBACK TRANSACTION;
            RETURN -4;
        END
        
        -- Check max booking days ahead
        DECLARE @MaxBookingDays INT;
        SELECT @MaxBookingDays = CAST(ConfigValue AS INT) 
        FROM SystemConfiguration 
        WHERE ConfigKey = 'MAX_BOOKING_DAYS';
        
        IF @StartTime > DATEADD(DAY, @MaxBookingDays, GETDATE())
        BEGIN
            SET @ErrorMessage = N'Không thể đặt chỗ quá ' + CAST(@MaxBookingDays AS NVARCHAR(10)) + N' ngày trước';
            ROLLBACK TRANSACTION;
            RETURN -5;
        END
        
        -- Generate booking code
        DECLARE @BookingCode NVARCHAR(20);
        SET @BookingCode = 'BK' + FORMAT(GETDATE(), 'yyyyMMdd') + RIGHT('000' + CAST(ABS(CHECKSUM(NEWID())) % 1000 AS NVARCHAR(3)), 3);
        
        -- Create booking
        INSERT INTO Bookings (BookingCode, UserId, StatusCode, BookingDate, StartTime, EndTime, Purpose, Notes)
        VALUES (@BookingCode, @UserId, 'PENDING', CAST(GETDATE() AS DATE), @StartTime, @EndTime, @Purpose, @Notes);
        
        SET @BookingId = SCOPE_IDENTITY();
        
        -- Add booking items
        DECLARE @ResourceId INT;
        DECLARE @xml XML = CAST('<r>' + REPLACE(@ResourceIds, ',', '</r><r>') + '</r>' AS XML);
        
        DECLARE resource_cursor CURSOR FOR
        SELECT CAST(x.value('.', 'INT') AS INT) AS ResourceId
        FROM @xml.nodes('/r') AS t(x)
        WHERE x.value('.', 'NVARCHAR(50)') != '';
        
        OPEN resource_cursor;
        FETCH NEXT FROM resource_cursor INTO @ResourceId;
        
        WHILE @@FETCH_STATUS = 0
        BEGIN
            -- Validate resource exists and is bookable
            IF NOT EXISTS (SELECT 1 FROM Resources WHERE ResourceId = @ResourceId AND IsBookable = 1)
            BEGIN
                SET @ErrorMessage = N'Tài nguyên ID ' + CAST(@ResourceId AS NVARCHAR(10)) + N' không tồn tại hoặc không thể đặt';
                CLOSE resource_cursor;
                DEALLOCATE resource_cursor;
                ROLLBACK TRANSACTION;
                RETURN -6;
            END
            
            -- Check resource availability
            IF EXISTS (
                SELECT 1 FROM BookingItems bi
                INNER JOIN Bookings b ON bi.BookingId = b.BookingId
                WHERE bi.ResourceId = @ResourceId
                AND b.StatusCode IN ('CONFIRMED', 'ACTIVE')
                AND (
                    (@StartTime BETWEEN b.StartTime AND b.EndTime) OR
                    (@EndTime BETWEEN b.StartTime AND b.EndTime) OR
                    (b.StartTime BETWEEN @StartTime AND @EndTime)
                )
            )
            BEGIN
                SET @ErrorMessage = N'Tài nguyên ID ' + CAST(@ResourceId AS NVARCHAR(10)) + N' đã được đặt trong khoảng thời gian này';
                CLOSE resource_cursor;
                DEALLOCATE resource_cursor;
                ROLLBACK TRANSACTION;
                RETURN -7;
            END
            
            -- Add booking item
            INSERT INTO BookingItems (BookingId, ResourceId, Quantity, Status)
            VALUES (@BookingId, @ResourceId, 1, 'PENDING');
            
            FETCH NEXT FROM resource_cursor INTO @ResourceId;
        END
        
        CLOSE resource_cursor;
        DEALLOCATE resource_cursor;
        
        -- Create notification
        INSERT INTO Notifications (UserId, TypeId, Title, Message, RelatedEntityType, RelatedEntityId)
        SELECT @UserId, nt.TypeId, 
               REPLACE(nt.Template, '{BookingCode}', @BookingCode),
               REPLACE(REPLACE(nt.Template, '{BookingCode}', @BookingCode), '{ResourceTitle}', 'các tài nguyên đã chọn'),
               'Booking', @BookingId
        FROM NotificationTypes nt
        WHERE nt.TypeCode = 'BOOKING_CONFIRMED';
        
        SET @ErrorMessage = N'Đặt chỗ thành công';
        COMMIT TRANSACTION;
        RETURN 0;
        
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        
        SET @ErrorMessage = ERROR_MESSAGE();
        RETURN -999;
    END CATCH
END;

GO

-- Confirm Booking Procedure
CREATE OR ALTER PROCEDURE sp_ConfirmBooking
    @BookingId INT,
    @LibrarianId INT,
    @ErrorMessage NVARCHAR(500) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        -- Validate booking exists and is pending
        IF NOT EXISTS (SELECT 1 FROM Bookings WHERE BookingId = @BookingId AND StatusCode = 'PENDING')
        BEGIN
            SET @ErrorMessage = N'Đặt chỗ không tồn tại hoặc không ở trạng thái chờ xử lý';
            RETURN -1;
        END
        
        -- Update booking status
        UPDATE Bookings 
        SET StatusCode = 'CONFIRMED', 
            UpdatedAt = GETDATE()
        WHERE BookingId = @BookingId;
        
        -- Update booking items
        UPDATE BookingItems 
        SET Status = 'CONFIRMED'
        WHERE BookingId = @BookingId;
        
        -- Update resource status to reserved
        UPDATE Resources 
        SET StatusId = (SELECT StatusId FROM ResourceStatus WHERE StatusCode = 'RESERVED')
        WHERE ResourceId IN (
            SELECT ResourceId FROM BookingItems WHERE BookingId = @BookingId
        );
        
        -- Log audit
        INSERT INTO AuditLogs (TableName, RecordId, Action, NewValues, UserId)
        VALUES ('Bookings', @BookingId, 'UPDATE', 
                '{"StatusCode": "CONFIRMED", "ConfirmedBy": ' + CAST(@LibrarianId AS NVARCHAR(10)) + '}', 
                @LibrarianId);
        
        SET @ErrorMessage = N'Xác nhận đặt chỗ thành công';
        RETURN 0;
        
    END TRY
    BEGIN CATCH
        SET @ErrorMessage = ERROR_MESSAGE();
        RETURN -999;
    END CATCH
END;

GO

-- =====================================================
-- 13. STORED PROCEDURES FOR FINE MANAGEMENT
-- =====================================================

-- Issue Fine Procedure
CREATE OR ALTER PROCEDURE sp_IssueFine
    @UserId INT,
    @BookingId INT = NULL,
    @FineTypeCode NVARCHAR(20),
    @Amount DECIMAL(10,2) = NULL,
    @Reason NVARCHAR(255),
    @IssuedBy INT,
    @FineId INT OUTPUT,
    @ErrorMessage NVARCHAR(500) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        -- Validate user exists
        IF NOT EXISTS (SELECT 1 FROM Users WHERE UserId = @UserId)
        BEGIN
            SET @ErrorMessage = N'Người dùng không tồn tại';
            RETURN -1;
        END
        
        -- Validate fine type
        DECLARE @DefaultAmount DECIMAL(10,2);
        SELECT @DefaultAmount = DefaultAmount 
        FROM FineTypes 
        WHERE TypeCode = @FineTypeCode AND IsActive = 1;
        
        IF @DefaultAmount IS NULL
        BEGIN
            SET @ErrorMessage = N'Loại phạt không hợp lệ';
            RETURN -2;
        END
        
        -- Use default amount if not specified
        IF @Amount IS NULL
            SET @Amount = @DefaultAmount;
            
        -- Generate fine code
        DECLARE @FineCode NVARCHAR(20);
        SET @FineCode = 'FN' + FORMAT(GETDATE(), 'yyyyMMdd') + RIGHT('000' + CAST(ABS(CHECKSUM(NEWID())) % 1000 AS NVARCHAR(3)), 3);
        
        -- Create fine
        INSERT INTO Fines (FineCode, UserId, BookingId, FineTypeId, Amount, Reason, Status, IssuedBy)
        SELECT @FineCode, @UserId, @BookingId, FineTypeId, @Amount, @Reason, 'UNPAID', @IssuedBy
        FROM FineTypes
        WHERE TypeCode = @FineTypeCode;
        
        SET @FineId = SCOPE_IDENTITY();
        
        -- Create notification
        INSERT INTO Notifications (UserId, TypeId, Title, Message, RelatedEntityType, RelatedEntityId)
        SELECT @UserId, nt.TypeId,
               REPLACE(REPLACE(nt.Template, '{FineAmount}', FORMAT(@Amount, 'N0')), '{Reason}', @Reason),
               REPLACE(REPLACE(nt.Template, '{FineAmount}', FORMAT(@Amount, 'N0')), '{Reason}', @Reason),
               'Fine', @FineId
        FROM NotificationTypes nt
        WHERE nt.TypeCode = 'FINE_ISSUED';
        
        SET @ErrorMessage = N'Tạo phạt thành công';
        RETURN 0;
        
    END TRY
    BEGIN CATCH
        SET @ErrorMessage = ERROR_MESSAGE();
        RETURN -999;
    END CATCH
END;

GO

-- Pay Fine Procedure
CREATE OR ALTER PROCEDURE sp_PayFine
    @FineId INT,
    @PaymentMethod NVARCHAR(50) = N'Tiền mặt',
    @PaymentReference NVARCHAR(100) = NULL,
    @PaidTo INT,
    @ErrorMessage NVARCHAR(500) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        -- Validate fine exists and is unpaid
        DECLARE @UserId INT, @Amount DECIMAL(10,2);
        SELECT @UserId = UserId, @Amount = Amount
        FROM Fines 
        WHERE FineId = @FineId AND Status = 'UNPAID';
        
        IF @UserId IS NULL
        BEGIN
            SET @ErrorMessage = N'Phạt không tồn tại hoặc đã được thanh toán';
            RETURN -1;
        END
        
        -- Update fine status
        UPDATE Fines
        SET Status = 'PAID',
            PaidDate = GETDATE(),
            PaidTo = @PaidTo,
            PaymentMethod = @PaymentMethod,
            PaymentReference = @PaymentReference,
            UpdatedAt = GETDATE()
        WHERE FineId = @FineId;
        
        -- Create notification
        INSERT INTO Notifications (UserId, TypeId, Title, Message, RelatedEntityType, RelatedEntityId)
        SELECT @UserId, nt.TypeId,
               REPLACE(nt.Template, '{FineAmount}', FORMAT(@Amount, 'N0')),
               REPLACE(nt.Template, '{FineAmount}', FORMAT(@Amount, 'N0')),
               'Fine', @FineId
        FROM NotificationTypes nt
        WHERE nt.TypeCode = 'PAYMENT_RECEIVED';
        
        SET @ErrorMessage = N'Thanh toán phạt thành công';
        RETURN 0;
        
    END TRY
    BEGIN CATCH
        SET @ErrorMessage = ERROR_MESSAGE();
        RETURN -999;
    END CATCH
END;

GO

-- =====================================================
-- 14. MAINTENANCE PROCEDURES
-- =====================================================

-- Check Overdue Bookings and Issue Fines
CREATE OR ALTER PROCEDURE sp_ProcessOverdueBookings
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @GracePeriodHours INT;
    SELECT @GracePeriodHours = CAST(ConfigValue AS INT)
    FROM SystemConfiguration
    WHERE ConfigKey = 'FINE_GRACE_PERIOD_HOURS';
    
    -- Find overdue bookings
    DECLARE @OverdueBookings TABLE (
        BookingId INT,
        UserId INT,
        OverdueHours INT,
        FineAmount DECIMAL(10,2)
    );
    
    INSERT INTO @OverdueBookings
    SELECT 
        b.BookingId,
        b.UserId,
        DATEDIFF(HOUR, b.EndTime, GETDATE()) - @GracePeriodHours AS OverdueHours,
        (DATEDIFF(HOUR, b.EndTime, GETDATE()) - @GracePeriodHours) * 
        (SELECT TOP 1 r.FinePerHour FROM BookingItems bi 
         INNER JOIN Resources r ON bi.ResourceId = r.ResourceId 
         WHERE bi.BookingId = b.BookingId) AS FineAmount
    FROM Bookings b
    WHERE b.StatusCode IN ('CONFIRMED', 'ACTIVE')
    AND b.EndTime < DATEADD(HOUR, -@GracePeriodHours, GETDATE())
    AND NOT EXISTS (
        SELECT 1 FROM Fines f 
        WHERE f.BookingId = b.BookingId 
        AND f.FineTypeId = (SELECT FineTypeId FROM FineTypes WHERE TypeCode = 'OVERDUE')
    );
    
    -- Process each overdue booking
    DECLARE @BookingId INT, @UserId INT, @OverdueHours INT, @FineAmount DECIMAL(10,2);
    DECLARE @FineId INT, @ErrorMessage NVARCHAR(500);
    
    DECLARE overdue_cursor CURSOR FOR
    SELECT BookingId, UserId, OverdueHours, FineAmount
    FROM @OverdueBookings
    WHERE OverdueHours > 0 AND FineAmount > 0;
    
    OPEN overdue_cursor;
    FETCH NEXT FROM overdue_cursor INTO @BookingId, @UserId, @OverdueHours, @FineAmount;
    
    WHILE @@FETCH_STATUS = 0
    BEGIN
        -- Update booking status to overdue
        UPDATE Bookings
        SET StatusCode = 'OVERDUE',
            UpdatedAt = GETDATE()
        WHERE BookingId = @BookingId;
        
        -- Issue fine
        EXEC sp_IssueFine 
            @UserId = @UserId,
            @BookingId = @BookingId,
            @FineTypeCode = 'OVERDUE',
            @Amount = @FineAmount,
            @Reason = N'Trả muộn ' + CAST(@OverdueHours AS NVARCHAR(10)) + N' giờ',
            @IssuedBy = 1, -- System user
            @FineId = @FineId OUTPUT,
            @ErrorMessage = @ErrorMessage OUTPUT;
        
        FETCH NEXT FROM overdue_cursor INTO @BookingId, @UserId, @OverdueHours, @FineAmount;
    END
    
    CLOSE overdue_cursor;
    DEALLOCATE overdue_cursor;
    
    SELECT COUNT(*) AS ProcessedOverdueBookings FROM @OverdueBookings WHERE OverdueHours > 0;
END;

GO

-- Database Maintenance Procedure
CREATE OR ALTER PROCEDURE sp_DatabaseMaintenance
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Clean old audit logs (older than 1 year)
    DELETE FROM AuditLogs 
    WHERE CreatedAt < DATEADD(YEAR, -1, GETDATE());
    
    -- Clean old notifications (older than 6 months and read)
    DELETE FROM Notifications 
    WHERE CreatedAt < DATEADD(MONTH, -6, GETDATE()) 
    AND IsRead = 1;
    
    -- Update index statistics
    UPDATE STATISTICS Users;
    UPDATE STATISTICS Resources;
    UPDATE STATISTICS Bookings;
    UPDATE STATISTICS BookingItems;
    UPDATE STATISTICS Fines;
    
    -- Log maintenance completion
    INSERT INTO AuditLogs (TableName, RecordId, Action, NewValues, UserId)
    VALUES ('SYSTEM', 0, 'MAINTENANCE', '{"CompletedAt": "' + CONVERT(NVARCHAR(50), GETDATE(), 120) + '"}', 1);
    
    SELECT N'Database maintenance completed successfully' AS Result;
END;

GO

-- =====================================================
-- 15. SCHEDULED JOBS (for automatic maintenance)
-- =====================================================

-- Create a procedure to set up SQL Agent jobs (if available)
CREATE OR ALTER PROCEDURE sp_SetupMaintenanceJobs
AS
BEGIN
    PRINT N'Thiết lập các job bảo trì tự động:';
    PRINT N'1. Job kiểm tra đặt chỗ quá hạn - chạy mỗi giờ';
    PRINT N'2. Job bảo trì database - chạy hàng ngày lúc 2:00 AM';
    PRINT N'3. Job gửi thông báo nhắc nhở - chạy mỗi 30 phút';
    PRINT N'';
    PRINT N'Vui lòng tạo SQL Agent Jobs với lệnh sau:';
    PRINT N'-- Job 1: EXEC sp_ProcessOverdueBookings';
    PRINT N'-- Job 2: EXEC sp_DatabaseMaintenance';
    PRINT N'-- Job 3: Thực hiện gửi email notifications';
END;

GO

-- =====================================================
-- 16. COMPLETION MESSAGE
-- =====================================================

PRINT N'=====================================================';
PRINT N'HUIT Library Management System Database Setup Complete';
PRINT N'=====================================================';
PRINT N'';
PRINT N'Các thành phần đã được tạo:';
PRINT N'✓ 12 bảng dữ liệu chính';
PRINT N'✓ Chỉ mục tối ưu hiệu suất';
PRINT N'✓ Dữ liệu mẫu cho HUIT';
PRINT N'✓ Views thống kê (bao gồm vw_ResourceStatistics)';
PRINT N'✓ Stored procedures quản lý booking và phạt';
PRINT N'✓ Procedures bảo trì tự động';
PRINT N'';
PRINT N'Để sử dụng hệ thống:';
PRINT N'1. Chạy sp_CreateBooking để tạo đặt chỗ mới';
PRINT N'2. Chạy sp_ConfirmBooking để xác nhận đặt chỗ';
PRINT N'3. Chạy sp_ProcessOverdueBookings để xử lý quá hạn';
PRINT N'4. Sử dụng các views để xem thống kê';
PRINT N'';
PRINT N'Hệ thống sẵn sàng phục vụ!';

GO
    TypeName NVARCHAR(100) NOT NULL,
    Template NVARCHAR(MAX), -- Message template
    IsActive BIT DEFAULT 1,
    CreatedAt DATETIME2 DEFAULT GETDATE()
);

-- Notifications
IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='Notifications' AND xtype='U')
CREATE TABLE Notifications (
    NotificationId INT IDENTITY(1,1) PRIMARY KEY,
    UserId INT NOT NULL,
    TypeId INT NOT NULL,
    Title NVARCHAR(200) NOT NULL,
    Message NVARCHAR(MAX) NOT NULL,
    IsRead BIT DEFAULT 0,
    IsSent BIT DEFAULT 0,
    SentAt DATETIME2,
    ReadAt DATETIME2,
    RelatedEntityType NVARCHAR(50), -- Booking, Fine, etc.
    RelatedEntityId INT,
    CreatedAt DATETIME2 DEFAULT GETDATE(),
    FOREIGN KEY (UserId) REFERENCES Users(UserId),
    FOREIGN KEY (TypeId) REFERENCES NotificationTypes(TypeId)
);

GO