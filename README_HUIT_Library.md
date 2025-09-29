# HUIT Library Management System

## Ho Chi Minh City University of Industry and Trade - Library Database System

### Tổng quan
Hệ thống quản lý thư viện hoàn chỉnh được thiết kế riêng cho Đại học Công nghiệp TP.HCM (HUIT) với đầy đủ tính năng quản lý sách, phòng học, thiết bị, và hệ thống đặt chỗ thông minh.

### Các tính năng chính

#### ✅ Đã triển khai hoàn chỉnh:
- **Quản lý tài nguyên**: Sách, phòng học, thiết bị
- **Hệ thống booking**: Đặt chỗ với validation HUIT
- **Quản lý phạt**: Hệ thống phạt linh hoạt và tự động
- **Audit logging**: Ghi log chi tiết mọi hoạt động
- **Notification system**: Thông báo tự động
- **Performance optimization**: Indexes và tối ưu hiệu suất

### Cấu trúc Database

#### Bảng chính:
1. **SystemConfiguration** - Cấu hình hệ thống
2. **Users & UserRoles** - Quản lý người dùng và phân quyền
3. **Faculties** - Các khoa tại HUIT
4. **Resources & Categories** - Quản lý tài nguyên
5. **Bookings & BookingItems** - Hệ thống đặt chỗ
6. **Fines & FineTypes** - Quản lý phạt
7. **AuditLogs** - Ghi log hoạt động
8. **Notifications** - Hệ thống thông báo

#### Views thống kê (Bao gồm vw_ResourceStatistics từ dòng 1105):
- `vw_ResourceStatistics` - Thống kê chi tiết tài nguyên
- `vw_UserActivityStatistics` - Thống kê hoạt động người dùng
- `vw_FacultyStatistics` - Thống kê theo khoa
- `vw_DailyUsageStatistics` - Thống kê sử dụng hàng ngày

#### Stored Procedures:
- `sp_CreateBooking` - Tạo đặt chỗ mới với validation HUIT
- `sp_ConfirmBooking` - Xác nhận đặt chỗ
- `sp_IssueFine` - Tạo phạt
- `sp_PayFine` - Thanh toán phạt
- `sp_ProcessOverdueBookings` - Xử lý đặt chỗ quá hạn
- `sp_DatabaseMaintenance` - Bảo trì database

### Dữ liệu mẫu HUIT

#### Các khoa:
- **CNTT** - Công nghệ Thông tin
- **CK** - Cơ khí
- **DDT** - Điện - Điện tử
- **KT** - Kinh tế
- **HOA** - Hóa học
- **XD** - Xây dựng

#### Người dùng mẫu:
- Admin, Thủ thư, Giảng viên, Sinh viên với mã số thực tế HUIT
- Email theo định dạng @huit.edu.vn và @student.huit.edu.vn

#### Tài nguyên mẫu:
- Sách chuyên ngành theo từng khoa
- Phòng học nhóm, phòng hội thảo, phòng máy tính
- Thiết bị: máy chiếu, laptop, micro

### Cài đặt và Sử dụng

#### 1. Triển khai Database:
```sql
-- Chạy file chính để tạo toàn bộ hệ thống
sqlcmd -S [server] -d master -i HUIT_Library_Database_System.sql

-- Kiểm tra với test script
sqlcmd -S [server] -d HUIT_LibraryDB -i Test_HUIT_Database.sql
```

#### 2. Sử dụng các chức năng chính:

##### Tạo đặt chỗ mới:
```sql
DECLARE @BookingId INT, @ErrorMessage NVARCHAR(500);
EXEC sp_CreateBooking 
    @UserId = 4, -- ID sinh viên
    @ResourceIds = '1,2,3', -- Danh sách ID tài nguyên
    @StartTime = '2024-01-15 09:00:00',
    @EndTime = '2024-01-22 09:00:00',
    @Purpose = N'Nghiên cứu đồ án',
    @BookingId = @BookingId OUTPUT,
    @ErrorMessage = @ErrorMessage OUTPUT;
```

##### Xem thống kê tài nguyên:
```sql
SELECT * FROM vw_ResourceStatistics
WHERE CategoryType = 'BOOK'
ORDER BY TotalBookings DESC;
```

##### Xem hoạt động người dùng:
```sql
SELECT * FROM vw_UserActivityStatistics
WHERE FacultyName = N'Công nghệ Thông tin'
ORDER BY TotalBookings DESC;
```

#### 3. Bảo trì tự động:
```sql
-- Xử lý đặt chỗ quá hạn (chạy hàng giờ)
EXEC sp_ProcessOverdueBookings;

-- Bảo trì database (chạy hàng ngày)
EXEC sp_DatabaseMaintenance;
```

### Quy tắc và Validation HUIT

#### Giới hạn đặt chỗ:
- Tối đa 7 ngày đặt trước
- Tối đa 5 sách/người dùng
- Không được đặt chỗ khi có phạt > 100,000 VND

#### Hệ thống phạt:
- **Trễ hạn**: 5,000 VND/giờ
- **Hư hỏng**: 50,000 VND
- **Mất tài liệu**: 200,000 VND  
- **Không đến**: 10,000 VND

#### Thời gian hoạt động:
- Thư viện: 07:00 - 22:00
- Bảo trì hệ thống: 02:00 - 03:00

### Bảo mật và Phân quyền

#### Roles hệ thống:
- **ADMIN**: Toàn quyền hệ thống
- **LIBRARIAN**: Quản lý bookings, resources, fines, reports
- **FACULTY**: Tạo bookings, xem resources
- **STAFF**: Tạo bookings, xem resources  
- **STUDENT**: Chỉ booking của mình, xem resources

### Hỗ trợ và Bảo trì

#### Monitoring:
- Tất cả hoạt động được ghi log trong `AuditLogs`
- Thông báo tự động qua `Notifications`
- Thống kê real-time qua các Views

#### Backup và Recovery:
```sql
-- Backup database
BACKUP DATABASE HUIT_LibraryDB 
TO DISK = 'C:\Backup\HUIT_LibraryDB.bak'

-- Kiểm tra tính toàn vẹn
DBCC CHECKDB('HUIT_LibraryDB')
```

### Liên hệ

**Phát triển bởi**: HUIT IT Team  
**Version**: 1.0.0  
**Ngày**: 2024-01-01  
**Hỗ trợ**: library@huit.edu.vn  

---

*Hệ thống được thiết kế đặc biệt cho HUIT với đầy đủ tính năng và dữ liệu mẫu phù hợp với môi trường giáo dục đại học.*