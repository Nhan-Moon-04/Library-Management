# HUIT Library Management System - Installation Guide
# Hướng dẫn Cài đặt Hệ thống Quản lý Thư viện HUIT

## Tổng quan / Overview

Hệ thống quản lý thư viện cho Đại học Công nghiệp TP.HCM (HUIT) được thiết kế để quản lý sách, thiết bị, phòng học và các hoạt động mượn trả theo quy định của HUIT.

The HUIT Library Management System is designed to manage books, equipment, classrooms, and lending activities according to HUIT regulations.

## Yêu cầu Hệ thống / System Requirements

### Database Server
- **SQL Server**: 2019 or later (Express, Standard, or Enterprise)
- **Memory**: Minimum 4GB RAM (8GB recommended)
- **Storage**: Minimum 10GB free space
- **Network**: TCP/IP enabled

### Application Server (if applicable)
- **OS**: Windows Server 2019+ or Windows 10+
- **Framework**: .NET 8.0 or later
- **IIS**: Version 10.0 or later (for web deployment)

## Các bước Cài đặt / Installation Steps

### Bước 1: Chuẩn bị SQL Server / Step 1: Prepare SQL Server

1. **Cài đặt SQL Server**
   ```sql
   -- Ensure SQL Server is installed with these features:
   -- - Database Engine Services
   -- - SQL Server Management Tools
   ```

2. **Kích hoạt TCP/IP Protocol**
   - Mở SQL Server Configuration Manager
   - Enable TCP/IP for SQL Server instance
   - Restart SQL Server service

3. **Tạo Login cho Hệ thống**
   ```sql
   -- Create system login
   CREATE LOGIN [HUIT_LibraryUser] WITH PASSWORD = 'YourSecurePassword123!',
   DEFAULT_DATABASE = [HUIT_LibraryManagement],
   CHECK_EXPIRATION = OFF,
   CHECK_POLICY = OFF;
   ```

### Bước 2: Tạo Database / Step 2: Create Database

1. **Chạy script tạo schema**
   ```bash
   sqlcmd -S YourServerName -E -i "Database_Schema.sql"
   ```
   Hoặc trong SQL Server Management Studio, mở và thực thi file `Database_Schema.sql`

2. **Tạo stored procedures**
   ```bash
   sqlcmd -S YourServerName -E -i "Stored_Procedures.sql"
   ```

3. **Tạo triggers**
   ```bash
   sqlcmd -S YourServerName -E -i "Triggers.sql"
   ```

4. **Cài đặt bảo mật**
   ```bash
   sqlcmd -S YourServerName -E -i "Security_Permissions.sql"
   ```

### Bước 3: Nhập Dữ liệu Mẫu / Step 3: Import Sample Data

```bash
sqlcmd -S YourServerName -E -i "HUIT_Sample_Data.sql"
```

### Bước 4: Cấu hình Bảo mật / Step 4: Configure Security

1. **Tạo database user**
   ```sql
   USE HUIT_LibraryManagement;
   CREATE USER [HUIT_LibraryUser] FOR LOGIN [HUIT_LibraryUser];
   ```

2. **Phân quyền theo vai trò**
   ```sql
   -- For librarians
   ALTER ROLE db_librarian ADD MEMBER [HUIT_LibraryUser];
   
   -- For students (example)
   ALTER ROLE db_student ADD MEMBER [StudentLoginName];
   ```

### Bước 5: Kiểm tra Cài đặt / Step 5: Verify Installation

1. **Kiểm tra tables**
   ```sql
   SELECT TABLE_NAME 
   FROM INFORMATION_SCHEMA.TABLES 
   WHERE TABLE_TYPE = 'BASE TABLE'
   ORDER BY TABLE_NAME;
   ```

2. **Kiểm tra views**
   ```sql
   SELECT * FROM vw_ResourceStatistics;
   SELECT * FROM vw_UserStatistics;
   ```

3. **Test stored procedures**
   ```sql
   EXEC sp_GetAvailableResources 
       @ResourceType = 'Book',
       @StartDate = '2024-01-01',
       @EndDate = '2024-01-15';
   ```

## Cấu hình Connection String

### For .NET Applications
```xml
<connectionStrings>
    <add name="HUITLibrary" 
         connectionString="Server=YourServerName;Database=HUIT_LibraryManagement;User Id=HUIT_LibraryUser;Password=YourPassword;TrustServerCertificate=true;" 
         providerName="System.Data.SqlClient" />
</connectionStrings>
```

### For appsettings.json (.NET Core/8)
```json
{
  "ConnectionStrings": {
    "DefaultConnection": "Server=YourServerName;Database=HUIT_LibraryManagement;User Id=HUIT_LibraryUser;Password=YourPassword;TrustServerCertificate=true;"
  }
}
```

## Quy định Nghiệp vụ HUIT / HUIT Business Rules

### Thời gian Mượn / Loan Periods
- **Sinh viên (Students)**: 14 ngày cho sách / 14 days for books
- **Cán bộ (Staff/Faculty)**: 30 ngày cho sách / 30 days for books
- **Phòng học (Classrooms)**: Tối đa 2-4 tiếng/lần / Maximum 2-4 hours per session
- **Thiết bị (Equipment)**: Tối đa 2 tiếng/lần, cần duyệt / Maximum 2 hours per session, requires approval

### Phạt / Penalties
- **Trả muộn (Late return)**: 5,000đ/ngày / 5,000 VND per day
- **Không đến (No-show)**: 20,000đ / 20,000 VND
- **Hư hỏng (Damage)**: Theo mức độ / Based on severity

### Gia hạn / Extensions
- **Sách (Books)**: Tối đa 1 lần / Maximum 1 extension
- **Thiết bị và Phòng**: Không được gia hạn / No extensions allowed

## Maintenance và Backup

### Backup tự động / Automatic Backup
```sql
-- Schedule this procedure to run daily
EXEC sp_DatabaseMaintenance 
    @MaintenanceType = 'Backup',
    @ExecutedBy = 1; -- Admin user ID
```

### Bảo trì định kỳ / Regular Maintenance
```sql
-- Weekly statistics update
EXEC sp_DatabaseMaintenance 
    @MaintenanceType = 'UpdateStats',
    @ExecutedBy = 1;

-- Monthly index rebuild
EXEC sp_DatabaseMaintenance 
    @MaintenanceType = 'RebuildIndexes',
    @ExecutedBy = 1;

-- Quarterly log cleanup
EXEC sp_DatabaseMaintenance 
    @MaintenanceType = 'CleanupLogs',
    @ExecutedBy = 1;
```

## Troubleshooting

### Lỗi thường gặp / Common Issues

1. **Connection timeout**
   - Kiểm tra SQL Server service đang chạy
   - Verify firewall settings (port 1433)
   - Check network connectivity

2. **Permission denied**
   ```sql
   -- Check user permissions
   SELECT 
       dp.state_desc,
       dp.permission_name,
       dp.class_desc,
       o.name as object_name
   FROM sys.database_permissions dp
   LEFT JOIN sys.objects o ON dp.major_id = o.object_id
   WHERE dp.grantee_principal_id = USER_ID('HUIT_LibraryUser');
   ```

3. **RLS blocking access**
   ```sql
   -- Temporarily disable RLS for troubleshooting
   ALTER TABLE Users DISABLE ROW LEVEL SECURITY;
   -- Remember to re-enable after fixing
   ALTER TABLE Users ENABLE ROW LEVEL SECURITY;
   ```

### Performance Tuning

1. **Monitor query performance**
   ```sql
   -- Check slow queries
   SELECT TOP 10
       qs.total_elapsed_time / qs.execution_count AS avg_elapsed_time,
       qs.total_worker_time / qs.execution_count AS avg_cpu_time,
       qs.execution_count,
       SUBSTRING(qt.text, qs.statement_start_offset/2+1,
           (CASE WHEN qs.statement_end_offset = -1
                 THEN LEN(CONVERT(nvarchar(max), qt.text)) * 2
                 ELSE qs.statement_end_offset END - qs.statement_start_offset)/2 + 1) AS query_text
   FROM sys.dm_exec_query_stats AS qs
   CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) AS qt
   ORDER BY avg_elapsed_time DESC;
   ```

2. **Index usage statistics**
   ```sql
   SELECT 
       i.name AS IndexName,
       ius.user_seeks,
       ius.user_scans,
       ius.user_lookups,
       ius.user_updates
   FROM sys.indexes i
   LEFT JOIN sys.dm_db_index_usage_stats ius ON i.object_id = ius.object_id AND i.index_id = ius.index_id
   WHERE i.object_id = OBJECT_ID('Resources');
   ```

## Support và Liên hệ / Support and Contact

- **Technical Support**: Liên hệ bộ phận IT của HUIT
- **Documentation**: Tham khảo thêm trong thư mục `/docs`
- **Updates**: Kiểm tra updates định kỳ

---

© 2024 HUIT Library Management System
Developed for Ho Chi Minh City University of Industry