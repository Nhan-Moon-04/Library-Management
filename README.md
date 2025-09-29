# HUIT Library Management System
# Hệ thống Quản lý Thư viện Đại học Công nghiệp TP.HCM

## 📚 Tổng quan / Overview

Hệ thống quản lý thư viện toàn diện cho Đại học Công nghiệp TP.HCM (HUIT), được thiết kế để quản lý sách, thiết bị, phòng học và các hoạt động mượn trả theo đúng quy định của HUIT.

A comprehensive library management system for Ho Chi Minh City University of Industry (HUIT), designed to manage books, equipment, classrooms, and lending activities according to HUIT regulations.

## 🎯 Tính năng Chính / Key Features

### ✅ Hoàn thành / Completed

- **Quản lý Tài nguyên / Resource Management**
  - Sách, thiết bị, phòng học / Books, equipment, classrooms
  - Phân loại theo danh mục / Category-based classification
  - Theo dõi vị trí và trạng thái / Location and status tracking

- **Hệ thống Đặt mượn / Booking System**
  - Quy định mượn theo HUIT / HUIT lending rules
  - Sinh viên: 14 ngày sách / Students: 14 days for books
  - Cán bộ: 30 ngày sách / Staff: 30 days for books
  - Thiết bị: 2 tiếng/lần / Equipment: 2 hours per session
  - Phòng: 2-4 tiếng/lần / Rooms: 2-4 hours per session

- **Quản lý Phạt / Penalty Management**
  - Trả muộn: 5,000đ/ngày / Late return: 5,000 VND/day
  - Không đến: 20,000đ / No-show: 20,000 VND
  - Hư hỏng: theo mức độ / Damage: based on severity

- **Báo cáo và Thống kê / Reports & Statistics**
  - Thống kê tài nguyên / Resource statistics
  - Báo cáo người dùng / User reports
  - Báo cáo tài chính phạt / Financial penalty reports
  - Thống kê sử dụng theo thời gian / Usage reports by time

- **Bảo mật / Security**
  - Row-level security (RLS)
  - Role-based access control
  - Mã hóa dữ liệu nhạy cảm / Sensitive data encryption
  - Audit logging tự động / Automatic audit logging

## 🏗️ Kiến trúc Hệ thống / System Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Application   │    │   Web Layer     │    │  Database Layer │
│     Layer       │───▶│   (ASP.NET)     │───▶│   (SQL Server)  │
└─────────────────┘    └─────────────────┘    └─────────────────┘
                                                       │
                       ┌─────────────────────────────────┼─────────────────────────────────┐
                       │                                 │                                 │
              ┌─────────▼──────────┐           ┌─────────▼──────────┐           ┌─────────▼──────────┐
              │    Core Tables     │           │ Business Logic     │           │   Security &       │
              │  - Users           │           │ - Stored Procs     │           │   Audit System     │
              │  - Resources       │           │ - Triggers         │           │ - RLS Policies     │
              │  - Bookings        │           │ - Views            │           │ - Audit Logs       │
              │  - Penalties       │           │ - Functions        │           │ - Encryption       │
              └────────────────────┘           └────────────────────┘           └────────────────────┘
```

## 📋 Quy định HUIT / HUIT Regulations

### Thời gian Mượn / Loan Periods
- **Sinh viên (Students)**: 14 ngày cho sách / 14 days for books
- **Cán bộ/Giảng viên (Staff/Faculty)**: 30 ngày cho sách / 30 days for books
- **Phòng học (Classrooms)**: Tối đa 2-4 tiếng/lần / Maximum 2-4 hours per session
- **Thiết bị (Equipment)**: Tối đa 2 tiếng/lần, cần duyệt / Maximum 2 hours per session, requires approval

### Phạt / Penalties
- **Trả muộn (Late return)**: 5,000đ/ngày / 5,000 VND per day
- **Không đến (No-show)**: 20,000đ / 20,000 VND
- **Hư hỏng (Damage)**: Theo mức độ / Based on severity

### Gia hạn / Extensions
- **Sách (Books)**: Tối đa 1 lần / Maximum 1 extension
- **Thiết bị và Phòng**: Không được gia hạn / No extensions allowed

## 🚀 Cài đặt Nhanh / Quick Installation

### 1. Yêu cầu Hệ thống / System Requirements
- SQL Server 2019+ (Express, Standard, or Enterprise)
- .NET 8.0+
- Windows Server 2019+ or Windows 10+

### 2. Triển khai Database / Database Deployment
```bash
# Option 1: Quick deployment (recommended)
sqlcmd -S YourServerName -E -i "Deploy_Complete_System.sql"

# Option 2: Step by step
sqlcmd -S YourServerName -E -i "Database_Schema.sql"
sqlcmd -S YourServerName -E -i "Stored_Procedures.sql"
sqlcmd -S YourServerName -E -i "Triggers.sql"
sqlcmd -S YourServerName -E -i "Security_Permissions.sql"
sqlcmd -S YourServerName -E -i "HUIT_Sample_Data.sql"
```

### 3. Cấu hình Connection String
```json
{
  "ConnectionStrings": {
    "DefaultConnection": "Server=YourServerName;Database=HUIT_LibraryManagement;Integrated Security=true;TrustServerCertificate=true;"
  }
}
```

## 📁 Cấu trúc Project / Project Structure

```
HUIT_LibraryManagement/
├── 📄 Database_Schema.sql          # Cơ sở dữ liệu chính / Main database schema
├── 📄 Stored_Procedures.sql        # Thủ tục lưu trữ / Business logic procedures
├── 📄 Triggers.sql                 # Triggers bảo toàn dữ liệu / Data integrity triggers
├── 📄 Security_Permissions.sql     # Bảo mật và phân quyền / Security & permissions
├── 📄 HUIT_Sample_Data.sql         # Dữ liệu mẫu HUIT / HUIT sample data
├── 📄 Deploy_Complete_System.sql   # Script triển khai tổng thể / Complete deployment
├── 📖 Installation_Guide.md        # Hướng dẫn cài đặt / Installation guide
├── 📖 Schema_Documentation.md      # Tài liệu schema / Schema documentation
├── 📖 API_Documentation.md         # Tài liệu API / API documentation
└── 📖 README.md                   # File này / This file
```

## 🔧 API và Stored Procedures

### Booking Management
```sql
-- Duyệt booking / Approve booking
EXEC sp_ApproveBooking @BookingID = 1, @ApprovedBy = 10;

-- Check-in/out
EXEC sp_CheckInOut @BookingID = 1, @Action = 'CheckIn', @ProcessedBy = 10;

-- Gia hạn / Extend booking
EXEC sp_ExtendBooking @BookingID = 1, @NewEndDate = '2024-02-01', @RequestedBy = 5, @Reason = N'Cần thêm thời gian';

-- Hủy booking / Cancel booking
EXEC sp_CancelBooking @BookingID = 1, @CancelledBy = 5, @Reason = N'Có việc đột xuất';
```

### Financial Management
```sql
-- Thanh toán phạt / Pay penalty
EXEC sp_PayPenalty @PenaltyID = 1, @PaidBy = 10, @PaymentMethod = 'Cash';
```

### System Utilities
```sql
-- Tìm tài nguyên có sẵn / Find available resources
EXEC sp_GetAvailableResources @ResourceType = 'Book', @StartDate = '2024-01-15', @EndDate = '2024-01-29';

-- Lịch sử mượn / Booking history
EXEC sp_GetUserBookingHistory @UserID = 5;

-- Bảo trì hệ thống / System maintenance
EXEC sp_DatabaseMaintenance @MaintenanceType = 'Backup', @ExecutedBy = 1;
```

## 📊 Báo cáo và Views / Reports and Views

### Thống kê Tài nguyên / Resource Statistics
```sql
SELECT * FROM vw_ResourceStatistics;
```

### Thống kê Người dùng / User Statistics
```sql
SELECT * FROM vw_UserStatistics WHERE DepartmentName = N'Khoa Công nghệ Thông tin';
```

### Báo cáo Tài chính / Financial Reports
```sql
SELECT * FROM vw_PenaltyFinancialReport WHERE Year = 2024;
```

## 🔒 Bảo mật / Security

### Vai trò Hệ thống / System Roles
- **db_student**: Sinh viên - quyền cơ bản / Students - basic privileges
- **db_faculty**: Giảng viên - quyền mở rộng / Faculty - extended privileges  
- **db_staff**: Cán bộ - quyền quản lý / Staff - management privileges
- **db_librarian**: Thủ thư - toàn quyền hoạt động / Librarians - full operational access
- **db_admin**: Quản trị viên - toàn quyền hệ thống / Administrators - full system access

### Row-Level Security
- Users chỉ thấy dữ liệu của mình / Users only see their own data
- Staff+ có thể thấy tất cả / Staff+ can see all data
- Audit logs chỉ cho staff+ / Audit logs for staff+ only

## 🎓 Dữ liệu Mẫu HUIT / HUIT Sample Data

Hệ thống bao gồm dữ liệu mẫu cho các khoa của HUIT:

- **Khoa Công nghệ Thông tin (CNTT)** / Faculty of Information Technology
- **Khoa Cơ khí (CK)** / Faculty of Mechanical Engineering  
- **Khoa Điện tử - Viễn thông (DTVT)** / Faculty of Electronics and Telecommunications
- **Khoa Kinh tế (KT)** / Faculty of Economics
- **Thư viện (THV)** / Library Department

## 🛠️ Bảo trì / Maintenance

### Tác vụ Hàng ngày / Daily Tasks
```sql
EXEC sp_DatabaseMaintenance @MaintenanceType = 'Backup', @ExecutedBy = 1;
```

### Tác vụ Hàng tuần / Weekly Tasks
```sql
EXEC sp_DatabaseMaintenance @MaintenanceType = 'UpdateStats', @ExecutedBy = 1;
```

### Tác vụ Hàng tháng / Monthly Tasks
```sql
EXEC sp_DatabaseMaintenance @MaintenanceType = 'RebuildIndexes', @ExecutedBy = 1;
```

## 📝 Tài liệu / Documentation

- **[Installation Guide](Installation_Guide.md)**: Hướng dẫn cài đặt chi tiết
- **[Schema Documentation](Schema_Documentation.md)**: Tài liệu database schema
- **[API Documentation](API_Documentation.md)**: Tài liệu API và stored procedures

## 🤝 Đóng góp / Contributing

Hệ thống được phát triển cho HUIT với các quy định cụ thể. Mọi đóng góp cần tuân thủ:
- Quy định nghiệp vụ của HUIT
- Coding standards và best practices
- Bảo mật và audit requirements

## 📞 Hỗ trợ / Support

- **Technical Issues**: Liên hệ bộ phận IT của HUIT
- **Business Rules**: Liên hệ thư viện HUIT
- **Documentation**: Tham khảo các file .md trong project

## 📄 License

© 2024 HUIT Library Management System
Developed for Ho Chi Minh City University of Industry

---

**Chú ý**: Hệ thống này được thiết kế riêng cho HUIT và tuân thủ các quy định cụ thể của trường. Việc sử dụng cho mục đích khác cần được điều chỉnh phù hợp.

**Note**: This system is specifically designed for HUIT and follows the university's specific regulations. Usage for other purposes may require appropriate modifications.