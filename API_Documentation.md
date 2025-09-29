# HUIT Library Management System - API Documentation
# Tài liệu API Hệ thống Quản lý Thư viện HUIT

## Tổng quan / Overview

Tài liệu này mô tả các stored procedures và functions của hệ thống, bao gồm parameters, return values, và ví dụ sử dụng.

This document describes the stored procedures and functions of the system, including parameters, return values, and usage examples.

## Authentication và Authorization

Tất cả các procedures đều sử dụng row-level security và role-based access control. Người dùng phải được authenticate và có quyền phù hợp.

All procedures use row-level security and role-based access control. Users must be authenticated and have appropriate permissions.

---

## 1. Booking Management Procedures

### sp_ApproveBooking
**Mục đích**: Duyệt yêu cầu đặt mượn tài nguyên

#### Parameters
| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| @BookingID | int | Yes | ID của booking cần duyệt |
| @ApprovedBy | int | Yes | ID của người duyệt |
| @Notes | nvarchar(1000) | No | Ghi chú thêm |

#### Return Values
| Result | Message | Description |
|--------|---------|-------------|
| SUCCESS | Booking approved successfully | Duyệt thành công |
| ERROR | Business rule violation | Vi phạm quy định nghiệp vụ |

#### Business Rules Validated
- **Students**: Sách tối đa 14 ngày
- **Staff/Faculty**: Sách tối đa 30 ngày  
- **Equipment**: Tối đa 2 giờ, cần approval
- **Rooms**: Tối đa 4 giờ, kiểm tra conflict

#### Example Usage
```sql
-- Duyệt booking sách cho sinh viên
EXEC sp_ApproveBooking 
    @BookingID = 1,
    @ApprovedBy = 10,
    @Notes = N'Đã xác minh thông tin sinh viên';

-- Expected Result:
-- Result: SUCCESS
-- Message: Booking approved successfully
```

#### Error Scenarios
```sql
-- Thiết bị vượt quá 2 giờ
EXEC sp_ApproveBooking @BookingID = 2, @ApprovedBy = 10;
-- Error: Equipment booking exceeds maximum allowed hours (2 hours)

-- Phòng đã được đặt
EXEC sp_ApproveBooking @BookingID = 3, @ApprovedBy = 10;
-- Error: Room already booked for the requested time slot
```

---

### sp_CheckInOut
**Mục đích**: Xử lý nhận/trả tài nguyên

#### Parameters
| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| @BookingID | int | Yes | ID của booking |
| @Action | nvarchar(10) | Yes | 'CheckIn' hoặc 'CheckOut' |
| @ProcessedBy | int | Yes | ID người xử lý |
| @Notes | nvarchar(1000) | No | Ghi chú |

#### Return Values
| Action | Success Message | Late Return Message |
|--------|----------------|---------------------|
| CheckIn | Check-in successful | N/A |
| CheckOut | Check-out completed successfully | Check-out completed with late penalty: X VND |

#### HUIT Penalty Rules Applied
- **Late return**: 5,000đ per day (theo quy định HUIT)
- **Automatic calculation**: System tự động tính số ngày trễ

#### Example Usage
```sql
-- Check-in (nhận tài nguyên)
EXEC sp_CheckInOut 
    @BookingID = 1,
    @Action = 'CheckIn',
    @ProcessedBy = 10,
    @Notes = N'Đã kiểm tra tình trạng thiết bị';

-- Check-out (trả tài nguyên)
EXEC sp_CheckInOut 
    @BookingID = 1,
    @Action = 'CheckOut',
    @ProcessedBy = 10,
    @Notes = N'Thiết bị trong tình trạng tốt';

-- Late return example
EXEC sp_CheckInOut 
    @BookingID = 2,
    @Action = 'CheckOut',
    @ProcessedBy = 10;
-- Result: SUCCESS
-- Message: Check-out completed with late penalty: 15000 VND
```

---

### sp_ExtendBooking
**Mục đích**: Gia hạn thời gian mượn (chỉ áp dụng cho sách)

#### Parameters
| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| @BookingID | int | Yes | ID của booking cần gia hạn |
| @NewEndDate | datetime2 | Yes | Ngày kết thúc mới |
| @RequestedBy | int | Yes | ID người yêu cầu gia hạn |
| @Reason | nvarchar(500) | Yes | Lý do gia hạn |

#### HUIT Extension Rules
- **Books only**: Chỉ sách mới được gia hạn
- **Maximum 1 extension**: Tối đa 1 lần gia hạn
- **Self-service**: Chỉ người mượn mới được gia hạn
- **Total period limits**:
  - Students: 28 days total (14 + 14)
  - Staff/Faculty: 60 days total (30 + 30)

#### Example Usage
```sql
-- Gia hạn sách cho sinh viên
EXEC sp_ExtendBooking 
    @BookingID = 1,
    @NewEndDate = '2024-02-15 23:59:59',
    @RequestedBy = 5,
    @Reason = N'Cần thêm thời gian để hoàn thành bài tập lớn';

-- Error case: Equipment extension
EXEC sp_ExtendBooking 
    @BookingID = 2,
    @NewEndDate = '2024-01-20 12:00:00',
    @RequestedBy = 5,
    @Reason = N'Cần thêm thời gian';
-- Error: Extensions are only allowed for book loans
```

---

### sp_CancelBooking
**Mục đích**: Hủy đặt mượn

#### Parameters
| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| @BookingID | int | Yes | ID của booking cần hủy |
| @CancelledBy | int | Yes | ID người hủy |
| @Reason | nvarchar(500) | Yes | Lý do hủy |

#### No-Show Penalty Rules (HUIT)
- **Before start time**: Không phạt
- **After start time**: Phạt no-show 20,000đ

#### Example Usage
```sql
-- Hủy booking trước giờ bắt đầu
EXEC sp_CancelBooking 
    @BookingID = 1,
    @CancelledBy = 5,
    @Reason = N'Có việc đột xuất không thể đến';

-- Hủy booking sau giờ bắt đầu (có phạt)
EXEC sp_CancelBooking 
    @BookingID = 2,
    @CancelledBy = 5,
    @Reason = N'Quên lịch học';
-- Result: SUCCESS
-- Message: Booking cancelled with no-show penalty: 20,000 VND
```

---

## 2. Financial Management Procedures

### sp_PayPenalty
**Mục đích**: Thanh toán phạt

#### Parameters
| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| @PenaltyID | int | Yes | ID của penalty cần thanh toán |
| @PaidBy | int | Yes | ID người thanh toán |
| @PaymentMethod | nvarchar(50) | Yes | Phương thức thanh toán |
| @PaymentReference | nvarchar(100) | No | Mã tham chiếu thanh toán |

#### Payment Methods
- `Cash` - Tiền mặt
- `BankTransfer` - Chuyển khoản
- `MobilePay` - Ví điện tử
- `StudentCard` - Thẻ sinh viên

#### Example Usage
```sql
-- Thanh toán phạt bằng tiền mặt
EXEC sp_PayPenalty 
    @PenaltyID = 1,
    @PaidBy = 10,
    @PaymentMethod = 'Cash';

-- Thanh toán qua chuyển khoản
EXEC sp_PayPenalty 
    @PenaltyID = 2,
    @PaidBy = 10,
    @PaymentMethod = 'BankTransfer',
    @PaymentReference = 'TXN123456789';
```

---

## 3. System Maintenance Procedures

### sp_DatabaseMaintenance
**Mục đích**: Bảo trì và sao lưu hệ thống

#### Parameters
| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| @MaintenanceType | nvarchar(50) | Yes | Loại bảo trì |
| @ExecutedBy | int | Yes | ID người thực hiện |

#### Maintenance Types
| Type | Description | Frequency | Permissions |
|------|-------------|-----------|-------------|
| `Backup` | Sao lưu database | Daily | db_librarian+ |
| `UpdateStats` | Cập nhật thống kê | Weekly | db_librarian+ |
| `RebuildIndexes` | Xây dựng lại indexes | Monthly | db_admin |
| `CleanupLogs` | Dọn dẹp logs cũ | Quarterly | db_admin |

#### Example Usage
```sql
-- Sao lưu hàng ngày
EXEC sp_DatabaseMaintenance 
    @MaintenanceType = 'Backup',
    @ExecutedBy = 1;
-- Result: Database backup completed successfully to: C:\DatabaseBackups\HUIT_LibraryManagement_20240115_143022.bak

-- Cập nhật thống kê
EXEC sp_DatabaseMaintenance 
    @MaintenanceType = 'UpdateStats',
    @ExecutedBy = 1;
-- Result: Database statistics updated successfully

-- Xây dựng lại indexes
EXEC sp_DatabaseMaintenance 
    @MaintenanceType = 'RebuildIndexes',
    @ExecutedBy = 1;
-- Result: Database indexes rebuilt successfully
```

---

## 4. Utility Procedures

### sp_GetAvailableResources
**Mục đích**: Lấy danh sách tài nguyên có sẵn

#### Parameters
| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| @ResourceType | nvarchar(20) | No | Book/Equipment/Room |
| @StartDate | datetime2 | Yes | Ngày bắt đầu sử dụng |
| @EndDate | datetime2 | Yes | Ngày kết thúc sử dụng |
| @CategoryID | int | No | ID danh mục |

#### Return Columns
| Column | Type | Description |
|--------|------|-------------|
| ResourceID | int | ID tài nguyên |
| ResourceCode | nvarchar(50) | Mã tài nguyên |
| Title | nvarchar(500) | Tên tài nguyên |
| ResourceType | nvarchar(20) | Loại tài nguyên |
| CategoryName | nvarchar(100) | Tên danh mục |
| AvailableCopies | int | Số lượng có sẵn |
| LocationName | nvarchar(100) | Vị trí |

#### Example Usage
```sql
-- Tìm sách có sẵn trong 2 tuần
EXEC sp_GetAvailableResources 
    @ResourceType = 'Book',
    @StartDate = '2024-01-15',
    @EndDate = '2024-01-29';

-- Tìm phòng học có sẵn hôm nay
EXEC sp_GetAvailableResources 
    @ResourceType = 'Room',
    @StartDate = '2024-01-15 08:00:00',
    @EndDate = '2024-01-15 17:00:00';

-- Tìm laptop trong danh mục thiết bị
EXEC sp_GetAvailableResources 
    @ResourceType = 'Equipment',
    @StartDate = '2024-01-15 09:00:00',
    @EndDate = '2024-01-15 11:00:00',
    @CategoryID = 7; -- Máy tính xách tay
```

---

### sp_GetUserBookingHistory
**Mục đích**: Lấy lịch sử mượn của người dùng

#### Parameters
| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| @UserID | int | Yes | ID người dùng |
| @StartDate | datetime2 | No | Ngày bắt đầu lọc |
| @EndDate | datetime2 | No | Ngày kết thúc lọc |

#### Return Columns
| Column | Type | Description |
|--------|------|-------------|
| BookingID | int | ID booking |
| BookingCode | nvarchar(50) | Mã booking |
| Title | nvarchar(500) | Tên tài nguyên |
| ResourceType | nvarchar(20) | Loại tài nguyên |
| StartDate | datetime2 | Ngày bắt đầu |
| EndDate | datetime2 | Ngày kết thúc |
| ReturnDate | datetime2 | Ngày trả thực tế |
| Status | nvarchar(20) | Trạng thái |
| PenaltyAmount | decimal(10,2) | Số tiền phạt |
| PenaltyStatus | nvarchar(20) | Trạng thái phạt |

#### Example Usage
```sql
-- Lịch sử mượn của sinh viên
EXEC sp_GetUserBookingHistory @UserID = 5;

-- Lịch sử mượn trong tháng 12/2023
EXEC sp_GetUserBookingHistory 
    @UserID = 5,
    @StartDate = '2023-12-01',
    @EndDate = '2023-12-31';
```

---

## 5. Views for Reporting

### vw_ResourceStatistics
**Mục đích**: Thống kê tình trạng tài nguyên

#### Usage Examples
```sql
-- Thống kê tổng quan
SELECT * FROM vw_ResourceStatistics;

-- Thống kê theo loại tài nguyên
SELECT 
    ResourceType,
    SUM(TotalResources) as TotalCount,
    AVG(UtilizationRate) as AvgUtilization
FROM vw_ResourceStatistics
GROUP BY ResourceType;

-- Tài nguyên có tỷ lệ sử dụng cao
SELECT TOP 10 *
FROM vw_ResourceStatistics
WHERE UtilizationRate > 80
ORDER BY UtilizationRate DESC;
```

### vw_UserStatistics
**Mục đích**: Thống kê hoạt động người dùng

#### Usage Examples
```sql
-- Thống kê theo khoa
SELECT 
    DepartmentName,
    UserType,
    TotalUsers,
    SUM(ActiveBookings) as TotalActiveBookings
FROM vw_UserStatistics
GROUP BY DepartmentName, UserType
ORDER BY DepartmentName, UserType;

-- Người dùng có phạt chưa thanh toán
SELECT *
FROM vw_UserStatistics
WHERE UnpaidPenalties > 0
ORDER BY UnpaidAmount DESC;
```

### vw_PenaltyFinancialReport
**Mục đích**: Báo cáo tài chính phạt

#### Usage Examples
```sql
-- Báo cáo thu phạt theo tháng
SELECT 
    Year, Month,
    SUM(TotalAmount) as MonthlyTotal,
    SUM(PaidAmount) as MonthlyCollected,
    AVG(CollectionRate) as AvgCollectionRate
FROM vw_PenaltyFinancialReport
WHERE Year = 2024
GROUP BY Year, Month
ORDER BY Year, Month;

-- Top các loại phạt
SELECT 
    PenaltyType,
    SUM(TotalAmount) as TotalPenalties,
    AVG(CollectionRate) as AvgCollectionRate
FROM vw_PenaltyFinancialReport
GROUP BY PenaltyType
ORDER BY TotalPenalties DESC;
```

---

## 6. Error Handling

### Common Error Codes
| Error Message | Cause | Solution |
|---------------|-------|----------|
| Booking not found | Invalid BookingID | Check BookingID exists |
| Permission denied | Insufficient privileges | Use account with proper role |
| Resource not available | No copies available | Check availability first |
| User has unpaid penalties | Outstanding fines | Pay penalties first |
| Booking period exceeds maximum | HUIT rule violation | Adjust booking period |

### Error Response Format
```sql
-- Success Response
Result: SUCCESS
Message: Operation completed successfully

-- Error Response
Msg 50000, Level 16, State 1, Procedure sp_ProcedureName
Error message describing the issue
```

---

## 7. Security Considerations

### Role Requirements
| Operation | Minimum Role | Notes |
|-----------|-------------|-------|
| View own bookings | db_student | RLS enforced |
| Create bookings | db_student | Own bookings only |
| Approve bookings | db_staff | Business workflow |
| System maintenance | db_librarian | Critical operations |
| User management | db_admin | Full privileges |

### Audit Trail
All procedures automatically log activities to `AuditLogs` table:
- User performing action
- Timestamp
- Before/after values
- IP address (if available)

### Data Privacy
- Personal information protected by RLS
- Phone numbers and emails masked for non-owners
- Sensitive data encrypted at rest

---

## 8. Performance Guidelines

### Best Practices
1. **Use appropriate indexes**: All procedures leverage existing indexes
2. **Limit result sets**: Use date ranges and filters
3. **Avoid SELECT \***: Specify required columns
4. **Use transactions**: All procedures use proper transaction handling

### Monitoring
```sql
-- Check procedure execution times
SELECT 
    object_name(object_id) as ProcedureName,
    execution_count,
    total_elapsed_time / execution_count as avg_elapsed_time_ms
FROM sys.dm_exec_procedure_stats
WHERE object_name(object_id) LIKE 'sp_%'
ORDER BY avg_elapsed_time_ms DESC;
```

---

## 9. Testing Examples

### Complete Workflow Test
```sql
-- 1. Get available resources
EXEC sp_GetAvailableResources 
    @ResourceType = 'Book',
    @StartDate = '2024-01-15',
    @EndDate = '2024-01-29';

-- 2. Create booking (manual INSERT for testing)
INSERT INTO Bookings (BookingCode, UserID, ResourceID, BookingType, StartDate, EndDate, Purpose)
VALUES ('TEST001', 5, 1, 'Loan', '2024-01-15', '2024-01-29', N'Test booking');

-- 3. Approve booking
EXEC sp_ApproveBooking 
    @BookingID = @@IDENTITY,
    @ApprovedBy = 10;

-- 4. Check in
EXEC sp_CheckInOut 
    @BookingID = @@IDENTITY,
    @Action = 'CheckIn',
    @ProcessedBy = 10;

-- 5. Check out
EXEC sp_CheckInOut 
    @BookingID = @@IDENTITY,
    @Action = 'CheckOut',
    @ProcessedBy = 10;
```

---

© 2024 HUIT Library Management System
API Documentation v1.0