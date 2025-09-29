-- HUIT Library Management System
-- Sample Data for Ho Chi Minh City University of Industry
-- Dữ liệu mẫu cho Đại học Công nghiệp TP.HCM

USE HUIT_LibraryManagement;
GO

-- =============================================
-- 1. SYSTEM CONFIGURATION
-- =============================================

INSERT INTO SystemConfig (ConfigKey, ConfigValue, Description) VALUES
('StudentLoanDays', '14', 'Maximum loan days for students'),
('StaffLoanDays', '30', 'Maximum loan days for staff and faculty'),
('EquipmentMaxHours', '2', 'Maximum hours for equipment booking'),
('RoomMaxHours', '4', 'Maximum hours for room booking'),
('LatePenaltyPerDay', '5000', 'Late return penalty amount per day (VND)'),
('NoShowPenalty', '20000', 'No-show penalty amount (VND)'),
('MaxBookRenewals', '1', 'Maximum number of book renewals allowed'),
('PenaltyDueDays', '30', 'Number of days to pay penalty');

-- =============================================
-- 2. USER ROLES
-- =============================================

INSERT INTO UserRoles (RoleName, Description) VALUES
('Student', 'Student user with basic borrowing privileges'),
('Faculty', 'Faculty member with extended borrowing privileges'),
('Staff', 'Administrative staff with extended borrowing privileges'),
('Librarian', 'Library staff with management privileges'),
('Admin', 'System administrator with full privileges');

-- =============================================
-- 3. HUIT DEPARTMENTS/FACULTIES
-- =============================================

INSERT INTO Departments (DepartmentCode, DepartmentName, DepartmentType, Description) VALUES
-- Academic Faculties
('CNTT', N'Khoa Công nghệ Thông tin', 'Academic', N'Faculty of Information Technology'),
('CK', N'Khoa Cơ khí', 'Academic', N'Faculty of Mechanical Engineering'),
('DTVT', N'Khoa Điện tử - Viễn thông', 'Academic', N'Faculty of Electronics and Telecommunications'),
('DH', N'Khoa Điện - Điện tử', 'Academic', N'Faculty of Electrical and Electronic Engineering'),
('HL', N'Khoa Hóa học', 'Academic', N'Faculty of Chemistry'),
('KT', N'Khoa Kinh tế', 'Academic', N'Faculty of Economics'),
('NN', N'Khoa Ngoại ngữ', 'Academic', N'Faculty of Foreign Languages'),
('KHXH', N'Khoa Khoa học Xã hội và Nhân văn', 'Academic', N'Faculty of Social Sciences and Humanities'),
('CN', N'Khoa Công nghệ', 'Academic', N'Faculty of Technology'),
('MT', N'Khoa Môi trường', 'Academic', N'Faculty of Environment'),

-- Administrative Departments
('THV', N'Thư viện', 'Administrative', N'Library Department'),
('CTSV', N'Công tác Sinh viên', 'Administrative', N'Student Affairs Department'),
('KT-TC', N'Kế toán - Tài chính', 'Administrative', N'Accounting and Finance Department'),
('HC-QT', N'Hành chính - Quản trị', 'Administrative', N'Administration Department'),
('KHCN', N'Khoa học Công nghệ', 'Administrative', N'Science and Technology Department');

-- =============================================
-- 4. LOCATIONS WITHIN LIBRARY
-- =============================================

INSERT INTO Locations (LocationCode, LocationName, LocationType, ParentLocationID, Capacity) VALUES
('F1', N'Tầng 1', 'Floor', NULL, NULL),
('F2', N'Tầng 2', 'Floor', NULL, NULL),
('F3', N'Tầng 3', 'Floor', NULL, NULL),
('F4', N'Tầng 4', 'Floor', NULL, NULL);

-- Add location sections after inserting floors
DECLARE @F1ID int = (SELECT LocationID FROM Locations WHERE LocationCode = 'F1');
DECLARE @F2ID int = (SELECT LocationID FROM Locations WHERE LocationCode = 'F2');
DECLARE @F3ID int = (SELECT LocationID FROM Locations WHERE LocationCode = 'F3');
DECLARE @F4ID int = (SELECT LocationID FROM Locations WHERE LocationCode = 'F4');

INSERT INTO Locations (LocationCode, LocationName, LocationType, ParentLocationID, Capacity) VALUES
-- Floor 1 - Reference and Study Areas
('F1-REF', N'Khu tham khảo', 'Section', @F1ID, 50),
('F1-STUDY', N'Khu tự học', 'Section', @F1ID, 100),
('F1-INFO', N'Quầy thông tin', 'Section', @F1ID, 10),

-- Floor 2 - Technology and Engineering Books
('F2-TECH', N'Sách Công nghệ', 'Section', @F2ID, 200),
('F2-ENG', N'Sách Kỹ thuật', 'Section', @F2ID, 150),
('F2-IT', N'Sách Tin học', 'Section', @F2ID, 180),

-- Floor 3 - General Books and Periodicals
('F3-GEN', N'Sách tổng quát', 'Section', @F3ID, 250),
('F3-JOUR', N'Tạp chí khoa học', 'Section', @F3ID, 100),
('F3-LANG', N'Sách ngoại ngữ', 'Section', @F3ID, 120),

-- Floor 4 - Equipment and Meeting Rooms
('F4-EQUIP', N'Khu thiết bị', 'Section', @F4ID, 30),
('F4-MEET', N'Phòng họp', 'Section', @F4ID, 20),
('F4-LAB', N'Phòng thí nghiệm', 'Section', @F4ID, 15);

-- =============================================
-- 5. RESOURCE CATEGORIES
-- =============================================

INSERT INTO ResourceCategories (CategoryName, CategoryType, Description, MaxLoanDays, MaxRenewals, RequiresApproval) VALUES
-- Book Categories
(N'Sách giáo khoa', 'Book', N'Textbooks for courses', 14, 1, 0),
(N'Sách tham khảo', 'Book', N'Reference books', 7, 0, 0),
(N'Sách chuyên ngành', 'Book', N'Specialized subject books', 14, 1, 0),
(N'Tạp chí khoa học', 'Book', N'Scientific journals', 3, 0, 0),
(N'Luận văn thạc sĩ', 'Book', N'Master theses', 7, 0, 1),
(N'Luận án tiến sĩ', 'Book', N'PhD dissertations', 7, 0, 1),

-- Equipment Categories
(N'Máy tính xách tay', 'Equipment', N'Laptops for student use', 0, 0, 1),
(N'Máy chiếu', 'Equipment', N'Projectors for presentations', 0, 0, 1),
(N'Thiết bị thí nghiệm', 'Equipment', N'Laboratory equipment', 0, 0, 1),
(N'Camera kỹ thuật số', 'Equipment', N'Digital cameras', 0, 0, 1),

-- Room Categories
(N'Phòng học nhóm', 'Room', N'Group study rooms', 0, 0, 1),
(N'Phòng họp', 'Room', N'Meeting rooms', 0, 0, 1),
(N'Phòng thuyết trình', 'Room', N'Presentation rooms', 0, 0, 1),
(N'Phòng thí nghiệm', 'Room', N'Laboratory rooms', 0, 0, 1);

-- =============================================
-- 6. SAMPLE USERS (STUDENTS, FACULTY, STAFF)
-- =============================================

-- Get department and role IDs for reference
DECLARE @CNTT_ID int = (SELECT DepartmentID FROM Departments WHERE DepartmentCode = 'CNTT');
DECLARE @CK_ID int = (SELECT DepartmentID FROM Departments WHERE DepartmentCode = 'CK');
DECLARE @DTVT_ID int = (SELECT DepartmentID FROM Departments WHERE DepartmentCode = 'DTVT');
DECLARE @KT_ID int = (SELECT DepartmentID FROM Departments WHERE DepartmentCode = 'KT');
DECLARE @THV_ID int = (SELECT DepartmentID FROM Departments WHERE DepartmentCode = 'THV');

DECLARE @StudentRole int = (SELECT RoleID FROM UserRoles WHERE RoleName = 'Student');
DECLARE @FacultyRole int = (SELECT RoleID FROM UserRoles WHERE RoleName = 'Faculty');
DECLARE @StaffRole int = (SELECT RoleID FROM UserRoles WHERE RoleName = 'Staff');
DECLARE @LibrarianRole int = (SELECT RoleID FROM UserRoles WHERE RoleName = 'Librarian');

-- Sample Students
INSERT INTO Users (UserCode, FullName, Email, PhoneNumber, UserType, DepartmentID, RoleID, YearOfStudy) VALUES
-- IT Students
('2021600001', N'Nguyễn Văn An', 'an.nv2021@student.huit.edu.vn', '0901234567', 'Student', @CNTT_ID, @StudentRole, 3),
('2021600002', N'Trần Thị Bích', 'bich.tt2021@student.huit.edu.vn', '0901234568', 'Student', @CNTT_ID, @StudentRole, 3),
('2022600001', N'Lê Hoàng Minh', 'minh.lh2022@student.huit.edu.vn', '0901234569', 'Student', @CNTT_ID, @StudentRole, 2),
('2023600001', N'Phạm Thị Lan', 'lan.pt2023@student.huit.edu.vn', '0901234570', 'Student', @CNTT_ID, @StudentRole, 1),

-- Mechanical Engineering Students
('2021610001', N'Võ Văn Đức', 'duc.vv2021@student.huit.edu.vn', '0901234571', 'Student', @CK_ID, @StudentRole, 3),
('2022610001', N'Ngô Thị Hương', 'huong.nt2022@student.huit.edu.vn', '0901234572', 'Student', @CK_ID, @StudentRole, 2),

-- Electronics Students
('2021620001', N'Đặng Văn Thắng', 'thang.dv2021@student.huit.edu.vn', '0901234573', 'Student', @DTVT_ID, @StudentRole, 3),
('2022620001', N'Hoàng Thị Mai', 'mai.ht2022@student.huit.edu.vn', '0901234574', 'Student', @DTVT_ID, @StudentRole, 2),

-- Economics Students
('2021630001', N'Bùi Văn Nam', 'nam.bv2021@student.huit.edu.vn', '0901234575', 'Student', @KT_ID, @StudentRole, 3),
('2023630001', N'Lý Thị Oanh', 'oanh.lt2023@student.huit.edu.vn', '0901234576', 'Student', @KT_ID, @StudentRole, 1);

-- Sample Faculty
INSERT INTO Users (UserCode, FullName, Email, PhoneNumber, UserType, DepartmentID, RoleID) VALUES
('GV001', N'TS. Nguyễn Minh Tuấn', 'tuan.nm@huit.edu.vn', '0281234567', 'Faculty', @CNTT_ID, @FacultyRole),
('GV002', N'PGS.TS. Trần Văn Hùng', 'hung.tv@huit.edu.vn', '0281234568', 'Faculty', @CK_ID, @FacultyRole),
('GV003', N'ThS. Lê Thị Nga', 'nga.lt@huit.edu.vn', '0281234569', 'Faculty', @DTVT_ID, @FacultyRole),
('GV004', N'TS. Phạm Quốc Bảo', 'bao.pq@huit.edu.vn', '0281234570', 'Faculty', @KT_ID, @FacultyRole);

-- Sample Staff
INSERT INTO Users (UserCode, FullName, Email, PhoneNumber, UserType, DepartmentID, RoleID) VALUES
('CB001', N'Nguyễn Thị Thu Hà', 'ha.ntt@huit.edu.vn', '0281234571', 'Staff', @THV_ID, @LibrarianRole),
('CB002', N'Trần Văn Sơn', 'son.tv@huit.edu.vn', '0281234572', 'Staff', @THV_ID, @LibrarianRole),
('CB003', N'Lê Thị Linh', 'linh.lt@huit.edu.vn', '0281234573', 'Staff', @THV_ID, @StaffRole);

-- =============================================
-- 7. SAMPLE RESOURCES (BOOKS, EQUIPMENT, ROOMS)
-- =============================================

-- Get category IDs
DECLARE @BookCategory int = (SELECT CategoryID FROM ResourceCategories WHERE CategoryName = N'Sách giáo khoa');
DECLARE @RefBookCategory int = (SELECT CategoryID FROM ResourceCategories WHERE CategoryName = N'Sách tham khảo');
DECLARE @SpecializedCategory int = (SELECT CategoryID FROM ResourceCategories WHERE CategoryName = N'Sách chuyên ngành');
DECLARE @JournalCategory int = (SELECT CategoryID FROM ResourceCategories WHERE CategoryName = N'Tạp chí khoa học');
DECLARE @LaptopCategory int = (SELECT CategoryID FROM ResourceCategories WHERE CategoryName = N'Máy tính xách tay');
DECLARE @ProjectorCategory int = (SELECT CategoryID FROM ResourceCategories WHERE CategoryName = N'Máy chiếu');
DECLARE @StudyRoomCategory int = (SELECT CategoryID FROM ResourceCategories WHERE CategoryName = N'Phòng học nhóm');
DECLARE @MeetingRoomCategory int = (SELECT CategoryID FROM ResourceCategories WHERE CategoryName = N'Phòng họp');

-- Get location IDs
DECLARE @ITSection int = (SELECT LocationID FROM Locations WHERE LocationCode = 'F2-IT');
DECLARE @TechSection int = (SELECT LocationID FROM Locations WHERE LocationCode = 'F2-TECH');
DECLARE @EquipSection int = (SELECT LocationID FROM Locations WHERE LocationCode = 'F4-EQUIP');
DECLARE @MeetSection int = (SELECT LocationID FROM Locations WHERE LocationCode = 'F4-MEET');

-- Sample Books - IT and Technology
INSERT INTO Resources (ResourceCode, Title, ResourceType, CategoryID, LocationID, Author, Publisher, ISBN, PublicationYear, Description, TotalCopies, AvailableCopies) VALUES
-- Programming Books
('IT001', N'Lập trình C++ cơ bản và nâng cao', 'Book', @BookCategory, @ITSection, N'Phạm Văn Ất', N'NXB Khoa học và Kỹ thuật', '9786041234567', 2023, N'Sách giáo khoa lập trình C++ cho sinh viên CNTT', 5, 5),
('IT002', N'Cơ sở dữ liệu và SQL Server', 'Book', @BookCategory, @ITSection, N'Nguyễn Minh Tuấn', N'NXB Đại học Quốc gia', '9786041234568', 2022, N'Giáo trình cơ sở dữ liệu', 3, 3),
('IT003', N'Mạng máy tính và Internet', 'Book', @SpecializedCategory, @ITSection, N'Trần Đức Khoa', N'NXB Thông tin và Truyền thông', '9786041234569', 2023, N'Kiến thức về mạng máy tính', 4, 4),
('IT004', N'Trí tuệ nhân tạo và Machine Learning', 'Book', @SpecializedCategory, @ITSection, N'Lê Văn Minh', N'NXB Khoa học tự nhiên', '9786041234570', 2024, N'AI và ML cho sinh viên', 2, 2),

-- Engineering Books
('ENG001', N'Cơ học kỹ thuật', 'Book', @BookCategory, @TechSection, N'Vũ Văn Hùng', N'NXB Khoa học và Kỹ thuật', '9786041234571', 2022, N'Giáo trình cơ học kỹ thuật', 6, 6),
('ENG002', N'Vẽ kỹ thuật và CAD', 'Book', @BookCategory, @TechSection, N'Đỗ Thị Lan', N'NXB Xây dựng', '9786041234572', 2023, N'Sách vẽ kỹ thuật với CAD', 4, 4),
('ENG003', N'Kỹ thuật điện tử', 'Book', @SpecializedCategory, @TechSection, N'Nguyễn Xuân Phúc', N'NXB Đại học Quốc gia', '9786041234573', 2023, N'Giáo trình điện tử cơ bản', 5, 5),

-- Reference Books
('REF001', N'Từ điển Anh-Việt chuyên ngành CNTT', 'Book', @RefBookCategory, @ITSection, N'Oxford University', N'NXB Oxford', '9786041234574', 2023, N'Từ điển chuyên ngành', 2, 2),
('REF002', N'Cẩm nang kỹ sư cơ khí', 'Book', @RefBookCategory, @TechSection, N'Marks Standard', N'NXB Khoa học', '9786041234575', 2022, N'Cẩm nang tra cứu', 3, 3);

-- Equipment
INSERT INTO Resources (ResourceCode, Title, ResourceType, CategoryID, LocationID, Description, PurchasePrice, PurchaseDate, TotalCopies, AvailableCopies) VALUES
('LAPTOP001', N'Dell Inspiron 15 3000', 'Equipment', @LaptopCategory, @EquipSection, N'Laptop cho sinh viên mượn học tập', 15000000, '2023-01-15', 1, 1),
('LAPTOP002', N'HP Pavilion 14', 'Equipment', @LaptopCategory, @EquipSection, N'Laptop cho sinh viên mượn học tập', 16000000, '2023-02-20', 1, 1),
('LAPTOP003', N'Asus VivoBook 15', 'Equipment', @LaptopCategory, @EquipSection, N'Laptop cho sinh viên mượn học tập', 14500000, '2023-03-10', 1, 1),
('PROJ001', N'Epson EB-W06', 'Equipment', @ProjectorCategory, @EquipSection, N'Máy chiếu cho thuyết trình', 8000000, '2022-12-05', 1, 1),
('PROJ002', N'Canon LV-WX320', 'Equipment', @ProjectorCategory, @EquipSection, N'Máy chiếu di động', 9500000, '2023-01-20', 1, 1);

-- Equipment Details
INSERT INTO EquipmentDetails (EquipmentID, Brand, Model, SerialNumber, WarrantyExpiry, MaxUsageHours) VALUES
((SELECT ResourceID FROM Resources WHERE ResourceCode = 'LAPTOP001'), 'Dell', 'Inspiron 15 3000', 'DL001-2023', '2025-01-15', 8),
((SELECT ResourceID FROM Resources WHERE ResourceCode = 'LAPTOP002'), 'HP', 'Pavilion 14', 'HP002-2023', '2025-02-20', 8),
((SELECT ResourceID FROM Resources WHERE ResourceCode = 'LAPTOP003'), 'Asus', 'VivoBook 15', 'AS003-2023', '2025-03-10', 8),
((SELECT ResourceID FROM Resources WHERE ResourceCode = 'PROJ001'), 'Epson', 'EB-W06', 'EP001-2022', '2024-12-05', 6),
((SELECT ResourceID FROM Resources WHERE ResourceCode = 'PROJ002'), 'Canon', 'LV-WX320', 'CN002-2023', '2025-01-20', 6);

-- Rooms
INSERT INTO Resources (ResourceCode, Title, ResourceType, CategoryID, LocationID, Description, TotalCopies, AvailableCopies) VALUES
('ROOM401', N'Phòng học nhóm 401', 'Room', @StudyRoomCategory, @MeetSection, N'Phòng học nhóm 8 người, có bảng trắng', 1, 1),
('ROOM402', N'Phòng học nhóm 402', 'Room', @StudyRoomCategory, @MeetSection, N'Phòng học nhóm 10 người, có máy chiếu', 1, 1),
('ROOM403', N'Phòng học nhóm 403', 'Room', @StudyRoomCategory, @MeetSection, N'Phòng học nhóm 6 người', 1, 1),
('MEET401', N'Phòng họp lớn A', 'Room', @MeetingRoomCategory, @MeetSection, N'Phòng họp 20 người, đầy đủ tiện nghi', 1, 1),
('MEET402', N'Phòng họp nhỏ B', 'Room', @MeetingRoomCategory, @MeetSection, N'Phòng họp 10 người, có TV thông minh', 1, 1);

-- Room Details
INSERT INTO RoomDetails (RoomID, RoomNumber, Floor, Capacity, RoomType, HasProjector, HasComputers, HasWhiteboard, HasAircon) VALUES
((SELECT ResourceID FROM Resources WHERE ResourceCode = 'ROOM401'), '401', 4, 8, 'Study', 0, 0, 1, 1),
((SELECT ResourceID FROM Resources WHERE ResourceCode = 'ROOM402'), '402', 4, 10, 'Study', 1, 0, 1, 1),
((SELECT ResourceID FROM Resources WHERE ResourceCode = 'ROOM403'), '403', 4, 6, 'Study', 0, 0, 1, 1),
((SELECT ResourceID FROM Resources WHERE ResourceCode = 'MEET401'), '401A', 4, 20, 'Meeting', 1, 1, 1, 1),
((SELECT ResourceID FROM Resources WHERE ResourceCode = 'MEET402'), '401B', 4, 10, 'Meeting', 1, 0, 1, 1);

-- =============================================
-- 8. SAMPLE BOOKINGS
-- =============================================

-- Get user and resource IDs for sample bookings
DECLARE @Student1 int = (SELECT UserID FROM Users WHERE UserCode = '2021600001');
DECLARE @Student2 int = (SELECT UserID FROM Users WHERE UserCode = '2021600002');
DECLARE @Faculty1 int = (SELECT UserID FROM Users WHERE UserCode = 'GV001');
DECLARE @Librarian1 int = (SELECT UserID FROM Users WHERE UserCode = 'CB001');

DECLARE @Book1 int = (SELECT ResourceID FROM Resources WHERE ResourceCode = 'IT001');
DECLARE @Book2 int = (SELECT ResourceID FROM Resources WHERE ResourceCode = 'ENG001');
DECLARE @Laptop1 int = (SELECT ResourceID FROM Resources WHERE ResourceCode = 'LAPTOP001');
DECLARE @Room1 int = (SELECT ResourceID FROM Resources WHERE ResourceCode = 'ROOM401');

-- Sample bookings
INSERT INTO Bookings (BookingCode, UserID, ResourceID, BookingType, StartDate, EndDate, Status, Purpose, ApprovedBy, ApprovalDate) VALUES
-- Approved book loans
('BOOK001', @Student1, @Book1, 'Loan', DATEADD(DAY, -5, GETDATE()), DATEADD(DAY, 9, GETDATE()), 'Active', N'Học tập môn Lập trình C++', @Librarian1, DATEADD(DAY, -5, GETDATE())),
('BOOK002', @Faculty1, @Book2, 'Loan', DATEADD(DAY, -10, GETDATE()), DATEADD(DAY, 20, GETDATE()), 'Active', N'Nghiên cứu và giảng dạy', @Librarian1, DATEADD(DAY, -10, GETDATE())),

-- Pending equipment booking
('EQUIP001', @Student2, @Laptop1, 'Reservation', DATEADD(HOUR, 2, GETDATE()), DATEADD(HOUR, 4, GETDATE()), 'Pending', N'Làm bài tập lập trình'),

-- Approved room booking
('ROOM001', @Student1, @Room1, 'Reservation', DATEADD(HOUR, 1, GETDATE()), DATEADD(HOUR, 3, GETDATE()), 'Approved', N'Họp nhóm làm đồ án', @Librarian1, GETDATE());

-- Update resource availability based on active bookings
UPDATE Resources SET AvailableCopies = AvailableCopies - 1 WHERE ResourceID IN (@Book1, @Book2);

-- =============================================
-- 9. SAMPLE PENALTIES (FOR DEMONSTRATION)
-- =============================================

-- Sample late return penalty (for a completed booking)
INSERT INTO Penalties (BookingID, UserID, PenaltyType, PenaltyAmount, DaysOverdue, Description, DueDate, Status) VALUES
((SELECT TOP 1 BookingID FROM Bookings WHERE Status = 'Active' AND UserID = @Student1), 
 @Student1, 'Late', 15000, 3, N'Trả sách muộn 3 ngày', DATEADD(DAY, 30, GETDATE()), 'Unpaid');

PRINT 'Sample data for HUIT Library Management System has been successfully inserted!';
PRINT 'Dữ liệu mẫu cho Hệ thống Quản lý Thư viện HUIT đã được chèn thành công!';

-- Display summary
SELECT 
    'Users' as DataType, COUNT(*) as RecordCount 
FROM Users
UNION ALL
SELECT 
    'Resources' as DataType, COUNT(*) as RecordCount 
FROM Resources
UNION ALL
SELECT 
    'Bookings' as DataType, COUNT(*) as RecordCount 
FROM Bookings
UNION ALL
SELECT 
    'Departments' as DataType, COUNT(*) as RecordCount 
FROM Departments
UNION ALL
SELECT 
    'Penalties' as DataType, COUNT(*) as RecordCount 
FROM Penalties;

GO