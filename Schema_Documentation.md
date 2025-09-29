# HUIT Library Management System - Database Schema Documentation
# Tài liệu Mô tả Cơ sở Dữ liệu Hệ thống Quản lý Thư viện HUIT

## Tổng quan Kiến trúc / Architecture Overview

Hệ thống được thiết kế theo mô hình quan hệ với các nguyên tắc:
- **Chuẩn hóa**: Giảm thiểu dự thừa dữ liệu
- **Tính toàn vẹn**: Đảm bảo dữ liệu nhất quán
- **Hiệu suất**: Tối ưu hóa truy vấn với indexes
- **Bảo mật**: Row-level security và mã hóa

## Sơ đồ Quan hệ / Entity Relationship Diagram

```
Users ──┐
        ├── Bookings ── Resources ── ResourceCategories
        │              │
        └── Penalties   ├── EquipmentDetails
                        └── RoomDetails

Departments ── Users
Locations ── Resources
UserRoles ── Users
```

## Chi tiết Bảng / Table Details

### 1. Core Entity Tables

#### Users - Người dùng
**Mục đích**: Lưu thông tin sinh viên, giảng viên, cán bộ

| Column | Type | Description | Business Rules |
|--------|------|-------------|----------------|
| UserID | int IDENTITY | Primary key | Auto-increment |
| UserCode | nvarchar(20) | Mã sinh viên/cán bộ | Unique, required |
| FullName | nvarchar(200) | Họ tên đầy đủ | Required |
| Email | nvarchar(100) | Email | Unique, required |
| PhoneNumber | nvarchar(20) | Số điện thoại | Optional |
| UserType | nvarchar(20) | Loại: Student/Staff/Faculty/Admin | Required |
| DepartmentID | int | Khoa/Phòng ban | FK to Departments |
| RoleID | int | Vai trò hệ thống | FK to UserRoles |
| YearOfStudy | int | Năm học (sinh viên) | Null for non-students |
| IsActive | bit | Trạng thái hoạt động | Default: 1 |

**Indexes**:
- `IX_Users_UserCode` - Unique index on UserCode
- `IX_Users_Email` - Unique index on Email
- `IX_Users_UserType` - Non-clustered index for filtering

**Row-Level Security**: Users can only see their own data unless they are staff+

#### Resources - Tài nguyên
**Mục đích**: Quản lý sách, thiết bị, phòng học

| Column | Type | Description | Business Rules |
|--------|------|-------------|----------------|
| ResourceID | int IDENTITY | Primary key | Auto-increment |
| ResourceCode | nvarchar(50) | Mã tài nguyên | Unique, required |
| Title | nvarchar(500) | Tên/Tiêu đề | Required |
| ResourceType | nvarchar(20) | Book/Equipment/Room | Required |
| CategoryID | int | Danh mục | FK to ResourceCategories |
| LocationID | int | Vị trí | FK to Locations |
| Author | nvarchar(200) | Tác giả (sách) | Optional |
| Publisher | nvarchar(200) | Nhà xuất bản | Optional |
| ISBN | nvarchar(20) | Mã ISBN | Optional |
| CurrentStatus | nvarchar(20) | Available/Borrowed/Maintenance | Default: Available |
| TotalCopies | int | Tổng số bản | Default: 1 |
| AvailableCopies | int | Số bản có sẵn | Default: 1 |

**Business Rules**:
- `AvailableCopies <= TotalCopies`
- `AvailableCopies >= 0`
- Status automatically updated based on availability

**Triggers**:
- `tr_ValidateResourceStatusChange` - Validates status changes
- `tr_AuditResources` - Logs all changes

#### Bookings - Đặt mượn
**Mục đích**: Quản lý các lần mượn/đặt chỗ

| Column | Type | Description | Business Rules |
|--------|------|-------------|----------------|
| BookingID | int IDENTITY | Primary key | Auto-increment |
| BookingCode | nvarchar(50) | Mã đặt mượn | Unique, auto-generated |
| UserID | int | Người mượn | FK to Users |
| ResourceID | int | Tài nguyên | FK to Resources |
| BookingType | nvarchar(20) | Loan/Reservation | Required |
| StartDate | datetime2 | Ngày bắt đầu | Cannot be in past |
| EndDate | datetime2 | Ngày kết thúc | Must be after StartDate |
| ReturnDate | datetime2 | Ngày trả thực tế | Optional |
| Status | nvarchar(20) | Pending/Approved/Active/Completed/Cancelled/Overdue | Default: Pending |

**HUIT Business Rules Applied**:
- Students: Max 14 days for books
- Staff/Faculty: Max 30 days for books
- Equipment: Max 2 hours per session
- Rooms: Max 4 hours per session

**Triggers**:
- `tr_ValidateBookingRules` - Enforces HUIT business rules
- `tr_AuditBookings` - Logs all booking changes

#### Penalties - Phạt
**Mục đích**: Quản lý các khoản phạt theo quy định HUIT

| Column | Type | Description | HUIT Rules |
|--------|------|-------------|------------|
| PenaltyID | int IDENTITY | Primary key | Auto-increment |
| BookingID | int | Đặt mượn liên quan | FK to Bookings |
| UserID | int | Người bị phạt | FK to Users |
| PenaltyType | nvarchar(20) | Late/NoShow/Damage/Lost | Required |
| PenaltyAmount | decimal(10,2) | Số tiền phạt | Per HUIT rules |
| DaysOverdue | int | Số ngày quá hạn | For late penalties |
| Status | nvarchar(20) | Unpaid/Paid/Waived | Default: Unpaid |

**HUIT Penalty Rules**:
- Late return: 5,000đ per day
- No-show: 20,000đ fixed
- Damage/Lost: Based on assessment

### 2. Reference Tables

#### Departments - Khoa/Phòng ban
**Mục đích**: Danh sách các khoa của HUIT

| Department Code | Department Name | Type |
|----------------|-----------------|------|
| CNTT | Khoa Công nghệ Thông tin | Academic |
| CK | Khoa Cơ khí | Academic |
| DTVT | Khoa Điện tử - Viễn thông | Academic |
| THV | Thư viện | Administrative |

#### ResourceCategories - Danh mục tài nguyên
**Mục đích**: Phân loại tài nguyên với quy định riêng

| Category | Type | Max Loan Days | Requires Approval |
|----------|------|---------------|-------------------|
| Sách giáo khoa | Book | 14 | No |
| Máy tính xách tay | Equipment | 0 | Yes |
| Phòng học nhóm | Room | 0 | Yes |

#### Locations - Vị trí
**Mục đích**: Cấu trúc phân cấp vị trí trong thư viện

```
Tầng 1 (F1)
├── Khu tham khảo (F1-REF)
├── Khu tự học (F1-STUDY)
└── Quầy thông tin (F1-INFO)

Tầng 2 (F2)
├── Sách Công nghệ (F2-TECH)
├── Sách Kỹ thuật (F2-ENG)
└── Sách Tin học (F2-IT)
```

### 3. Extended Tables

#### EquipmentDetails - Chi tiết thiết bị
**Mục đích**: Thông tin bổ sung cho thiết bị

| Column | Description | Purpose |
|--------|-------------|---------|
| Brand | Nhãn hiệu | Inventory tracking |
| Model | Mẫu mã | Maintenance |
| SerialNumber | Số sê-ri | Unique identification |
| WarrantyExpiry | Hết bảo hành | Maintenance planning |
| UsageHours | Giờ sử dụng | Wear tracking |

#### RoomDetails - Chi tiết phòng
**Mục đích**: Thông tin bổ sung cho phòng

| Column | Description | Booking Relevance |
|--------|-------------|-------------------|
| Capacity | Sức chứa | Booking limits |
| HasProjector | Có máy chiếu | Feature filtering |
| HasComputers | Có máy tính | Equipment booking |
| HasAircon | Có điều hòa | Comfort features |

### 4. System Tables

#### AuditLogs - Nhật ký kiểm toán
**Mục đích**: Theo dõi mọi thay đổi trong hệ thống

| Column | Type | Description |
|--------|------|-------------|
| LogID | int IDENTITY | Primary key |
| TableName | nvarchar(100) | Bảng bị thay đổi |
| RecordID | int | ID record |
| Action | nvarchar(20) | INSERT/UPDATE/DELETE |
| OldValues | nvarchar(max) | Giá trị cũ |
| NewValues | nvarchar(max) | Giá trị mới |
| UserID | int | Người thực hiện |
| LogDate | datetime2 | Thời gian |

**Automatic Triggers**: All main tables have audit triggers

#### SystemConfig - Cấu hình hệ thống
**Mục đích**: Lưu trữ tham số cấu hình

| Config Key | Default Value | Description |
|------------|---------------|-------------|
| StudentLoanDays | 14 | Số ngày mượn sách cho sinh viên |
| StaffLoanDays | 30 | Số ngày mượn sách cho cán bộ |
| EquipmentMaxHours | 2 | Giờ tối đa mượn thiết bị |
| LatePenaltyPerDay | 5000 | Phạt trễ hạn mỗi ngày |

## Views - Khung nhìn

### 1. Reporting Views

#### vw_ResourceStatistics - Thống kê tài nguyên
```sql
SELECT 
    ResourceType,
    CategoryName,
    TotalResources,
    AvailableCopies,
    UtilizationRate,
    ResourcesInMaintenance
FROM vw_ResourceStatistics;
```

**Mục đích**: Báo cáo tình trạng sử dụng tài nguyên

#### vw_UserStatistics - Thống kê người dùng
```sql
SELECT 
    UserType,
    DepartmentName,
    TotalUsers,
    ActiveBookings,
    UnpaidPenalties
FROM vw_UserStatistics;
```

**Mục đích**: Thống kê hoạt động người dùng

#### vw_PenaltyFinancialReport - Báo cáo tài chính phạt
```sql
SELECT 
    Year, Month,
    PenaltyType,
    TotalAmount,
    CollectionRate
FROM vw_PenaltyFinancialReport
WHERE Year = 2024;
```

**Mục đích**: Báo cáo thu chi từ phạt

### 2. Security Views

#### vw_SecureUserInfo - Thông tin người dùng an toàn
**Mục đích**: Hiển thị thông tin người dùng với bảo mật
- Email và SĐT được che dấu nếu không phải chủ sở hữu
- Chỉ staff+ mới thấy đầy đủ thông tin

## Stored Procedures - Thủ tục lưu trữ

### 1. Business Operations

#### sp_ApproveBooking - Duyệt đặt mượn
```sql
EXEC sp_ApproveBooking 
    @BookingID = 1,
    @ApprovedBy = 10,
    @Notes = N'Đã kiểm tra điều kiện';
```

**Chức năng**: 
- Kiểm tra business rules HUIT
- Cập nhật trạng thái booking
- Giảm số lượng available

#### sp_CheckInOut - Nhận/Trả tài nguyên
```sql
EXEC sp_CheckInOut 
    @BookingID = 1,
    @Action = 'CheckOut',
    @ProcessedBy = 10;
```

**Chức năng**: 
- CheckIn: Kích hoạt booking
- CheckOut: Hoàn thành và tính phạt nếu trễ

#### sp_ExtendBooking - Gia hạn
```sql
EXEC sp_ExtendBooking 
    @BookingID = 1,
    @NewEndDate = '2024-02-01',
    @RequestedBy = 5,
    @Reason = N'Cần thêm thời gian nghiên cứu';
```

**Business Rules**: 
- Chỉ sách mới được gia hạn
- Tối đa 1 lần gia hạn
- Chỉ người mượn mới được gia hạn

### 2. Utility Procedures

#### sp_GetAvailableResources - Tài nguyên có sẵn
```sql
EXEC sp_GetAvailableResources 
    @ResourceType = 'Book',
    @StartDate = '2024-01-15',
    @EndDate = '2024-01-30',
    @CategoryID = 1;
```

#### sp_DatabaseMaintenance - Bảo trì hệ thống
```sql
EXEC sp_DatabaseMaintenance 
    @MaintenanceType = 'Backup',
    @ExecutedBy = 1;
```

**Maintenance Types**:
- `Backup`: Sao lưu database
- `UpdateStats`: Cập nhật thống kê
- `RebuildIndexes`: Xây dựng lại indexes
- `CleanupLogs`: Dọn dẹp logs cũ

## Triggers - Kích hoạt

### 1. Data Integrity Triggers

#### tr_ValidateBookingRules
**Kích hoạt**: INSTEAD OF INSERT, UPDATE on Bookings
**Chức năng**: 
- Kiểm tra thời gian mượn theo quy định HUIT
- Validate conflicts cho phòng
- Kiểm tra penalty chưa thanh toán

#### tr_ValidateResourceStatusChange
**Kích hoạt**: INSTEAD OF UPDATE on Resources
**Chức năng**: 
- AvailableCopies <= TotalCopies
- Không cho phép xóa resource có booking active

### 2. Audit Triggers

#### tr_AuditUsers, tr_AuditResources, tr_AuditBookings
**Kích hoạt**: AFTER INSERT, UPDATE, DELETE
**Chức năng**: Tự động ghi log mọi thay đổi vào AuditLogs

### 3. Business Logic Triggers

#### tr_UpdateResourceStatus
**Kích hoạt**: AFTER INSERT, UPDATE, DELETE on Bookings
**Chức năng**: Tự động cập nhật trạng thái resource

## Security Model - Mô hình Bảo mật

### 1. Role-Based Access Control

| Role | Permissions | Description |
|------|-------------|-------------|
| db_student | SELECT, limited INSERT/UPDATE | Sinh viên - chỉ quản lý booking của mình |
| db_faculty | Extended SELECT, INSERT/UPDATE | Giảng viên - quyền mở rộng |
| db_staff | Most tables CRUD | Cán bộ - quản lý hành chính |
| db_librarian | Full operational access | Thủ thư - toàn quyền hoạt động |
| db_admin | CONTROL | Admin - toàn quyền hệ thống |

### 2. Row-Level Security (RLS)

**Tables with RLS**:
- `Users`: Chỉ thấy thông tin của mình
- `Bookings`: Chỉ thấy booking của mình  
- `Penalties`: Chỉ thấy penalty của mình
- `AuditLogs`: Chỉ staff+ mới thấy

### 3. Data Encryption

**Sensitive Data**: 
- Phone numbers
- Personal information
- Financial data

**Encryption Functions**:
- `fn_EncryptData()`: Mã hóa dữ liệu
- `fn_DecryptData()`: Giải mã dữ liệu

## Performance Optimization

### 1. Indexing Strategy

**Clustered Indexes**: Primary keys (Identity columns)

**Non-Clustered Indexes**:
- Frequently searched columns (UserCode, ResourceCode)
- Foreign keys
- Status columns
- Date columns for reporting

### 2. Partitioning Strategy

**Large Tables**: AuditLogs, Bookings
**Partition Key**: Date-based partitioning by month/year

### 3. Query Optimization

**Common Patterns**:
- Use appropriate indexes
- Avoid SELECT *
- Use EXISTS instead of IN for subqueries
- Limit result sets with WHERE clauses

## Backup and Maintenance

### Daily Tasks
- Automated backup via `sp_DatabaseMaintenance`
- Check for overdue bookings
- Monitor system performance

### Weekly Tasks
- Update statistics
- Check index fragmentation
- Review audit logs

### Monthly Tasks
- Rebuild fragmented indexes
- Archive old audit logs
- Performance review

---

© 2024 HUIT Library Management System
Database Schema Documentation v1.0