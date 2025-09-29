-- HUIT Library Management System
-- Triggers for Data Integrity and Business Rules
-- Ho Chi Minh City University of Industry

USE HUIT_LibraryManagement;
GO

-- =============================================
-- 1. RESOURCE STATUS UPDATE TRIGGERS
-- =============================================

-- Trigger to automatically update resource status when bookings change
CREATE TRIGGER tr_UpdateResourceStatus
ON Bookings
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Handle INSERT and UPDATE
    IF EXISTS (SELECT * FROM inserted)
    BEGIN
        UPDATE r
        SET CurrentStatus = CASE 
            WHEN r.AvailableCopies = 0 THEN 'Borrowed'
            WHEN r.AvailableCopies > 0 THEN 'Available'
            ELSE r.CurrentStatus
        END,
        ModifiedDate = GETDATE()
        FROM Resources r
        INNER JOIN inserted i ON r.ResourceID = i.ResourceID;
    END
    
    -- Handle DELETE
    IF EXISTS (SELECT * FROM deleted) AND NOT EXISTS (SELECT * FROM inserted)
    BEGIN
        UPDATE r
        SET CurrentStatus = CASE 
            WHEN r.AvailableCopies = 0 THEN 'Borrowed'
            WHEN r.AvailableCopies > 0 THEN 'Available'
            ELSE r.CurrentStatus
        END,
        ModifiedDate = GETDATE()
        FROM Resources r
        INNER JOIN deleted d ON r.ResourceID = d.ResourceID;
    END
END
GO

-- Trigger to prevent invalid resource status changes
CREATE TRIGGER tr_ValidateResourceStatusChange
ON Resources
INSTEAD OF UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @ResourceID int, @OldStatus nvarchar(20), @NewStatus nvarchar(20);
    DECLARE @AvailableCopies int, @TotalCopies int;
    
    DECLARE status_cursor CURSOR FOR
    SELECT i.ResourceID, d.CurrentStatus, i.CurrentStatus, i.AvailableCopies, i.TotalCopies
    FROM inserted i
    INNER JOIN deleted d ON i.ResourceID = d.ResourceID;
    
    OPEN status_cursor;
    FETCH NEXT FROM status_cursor INTO @ResourceID, @OldStatus, @NewStatus, @AvailableCopies, @TotalCopies;
    
    WHILE @@FETCH_STATUS = 0
    BEGIN
        -- Validate business rules
        IF @AvailableCopies > @TotalCopies
        BEGIN
            RAISERROR('Available copies cannot exceed total copies', 16, 1);
            ROLLBACK TRANSACTION;
            RETURN;
        END
        
        IF @AvailableCopies < 0
        BEGIN
            RAISERROR('Available copies cannot be negative', 16, 1);
            ROLLBACK TRANSACTION;
            RETURN;
        END
        
        -- Check if status change is valid
        IF @NewStatus = 'Lost' AND EXISTS (
            SELECT 1 FROM Bookings 
            WHERE ResourceID = @ResourceID AND Status = 'Active'
        )
        BEGIN
            RAISERROR('Cannot mark resource as lost while it has active bookings', 16, 1);
            ROLLBACK TRANSACTION;
            RETURN;
        END
        
        FETCH NEXT FROM status_cursor INTO @ResourceID, @OldStatus, @NewStatus, @AvailableCopies, @TotalCopies;
    END
    
    CLOSE status_cursor;
    DEALLOCATE status_cursor;
    
    -- Perform the actual update
    UPDATE r
    SET ResourceCode = i.ResourceCode,
        Title = i.Title,
        ResourceType = i.ResourceType,
        CategoryID = i.CategoryID,
        LocationID = i.LocationID,
        Author = i.Author,
        Publisher = i.Publisher,
        ISBN = i.ISBN,
        PublicationYear = i.PublicationYear,
        Description = i.Description,
        PurchasePrice = i.PurchasePrice,
        PurchaseDate = i.PurchaseDate,
        CurrentStatus = i.CurrentStatus,
        TotalCopies = i.TotalCopies,
        AvailableCopies = i.AvailableCopies,
        IsActive = i.IsActive,
        ModifiedDate = GETDATE()
    FROM Resources r
    INNER JOIN inserted i ON r.ResourceID = i.ResourceID;
END
GO

-- =============================================
-- 2. AUTOMATIC AUDIT LOG TRIGGERS
-- =============================================

-- Audit trigger for Users table
CREATE TRIGGER tr_AuditUsers
ON Users
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Handle INSERT
    IF EXISTS (SELECT * FROM inserted) AND NOT EXISTS (SELECT * FROM deleted)
    BEGIN
        INSERT INTO AuditLogs (TableName, RecordID, Action, NewValues, UserID)
        SELECT 'Users', UserID, 'INSERT', 
               'UserCode: ' + UserCode + ', Name: ' + FullName + ', Type: ' + UserType,
               UserID
        FROM inserted;
    END
    
    -- Handle UPDATE
    IF EXISTS (SELECT * FROM inserted) AND EXISTS (SELECT * FROM deleted)
    BEGIN
        INSERT INTO AuditLogs (TableName, RecordID, Action, OldValues, NewValues, UserID)
        SELECT 'Users', i.UserID, 'UPDATE',
               'UserCode: ' + d.UserCode + ', Name: ' + d.FullName + ', Type: ' + d.UserType + ', Active: ' + CAST(d.IsActive as nvarchar(5)),
               'UserCode: ' + i.UserCode + ', Name: ' + i.FullName + ', Type: ' + i.UserType + ', Active: ' + CAST(i.IsActive as nvarchar(5)),
               i.UserID
        FROM inserted i
        INNER JOIN deleted d ON i.UserID = d.UserID;
    END
    
    -- Handle DELETE
    IF EXISTS (SELECT * FROM deleted) AND NOT EXISTS (SELECT * FROM inserted)
    BEGIN
        INSERT INTO AuditLogs (TableName, RecordID, Action, OldValues)
        SELECT 'Users', UserID, 'DELETE',
               'UserCode: ' + UserCode + ', Name: ' + FullName + ', Type: ' + UserType
        FROM deleted;
    END
END
GO

-- Audit trigger for Resources table
CREATE TRIGGER tr_AuditResources
ON Resources
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Handle INSERT
    IF EXISTS (SELECT * FROM inserted) AND NOT EXISTS (SELECT * FROM deleted)
    BEGIN
        INSERT INTO AuditLogs (TableName, RecordID, Action, NewValues)
        SELECT 'Resources', ResourceID, 'INSERT',
               'Code: ' + ResourceCode + ', Title: ' + Title + ', Type: ' + ResourceType + ', Status: ' + CurrentStatus
        FROM inserted;
    END
    
    -- Handle UPDATE
    IF EXISTS (SELECT * FROM inserted) AND EXISTS (SELECT * FROM deleted)
    BEGIN
        INSERT INTO AuditLogs (TableName, RecordID, Action, OldValues, NewValues)
        SELECT 'Resources', i.ResourceID, 'UPDATE',
               'Code: ' + d.ResourceCode + ', Status: ' + d.CurrentStatus + ', Available: ' + CAST(d.AvailableCopies as nvarchar(10)),
               'Code: ' + i.ResourceCode + ', Status: ' + i.CurrentStatus + ', Available: ' + CAST(i.AvailableCopies as nvarchar(10))
        FROM inserted i
        INNER JOIN deleted d ON i.ResourceID = d.ResourceID;
    END
    
    -- Handle DELETE
    IF EXISTS (SELECT * FROM deleted) AND NOT EXISTS (SELECT * FROM inserted)
    BEGIN
        INSERT INTO AuditLogs (TableName, RecordID, Action, OldValues)
        SELECT 'Resources', ResourceID, 'DELETE',
               'Code: ' + ResourceCode + ', Title: ' + Title + ', Type: ' + ResourceType
        FROM deleted;
    END
END
GO

-- Audit trigger for Bookings table
CREATE TRIGGER tr_AuditBookings
ON Bookings
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Handle INSERT
    IF EXISTS (SELECT * FROM inserted) AND NOT EXISTS (SELECT * FROM deleted)
    BEGIN
        INSERT INTO AuditLogs (TableName, RecordID, Action, NewValues, UserID)
        SELECT 'Bookings', BookingID, 'INSERT',
               'Code: ' + BookingCode + ', Status: ' + Status + ', Type: ' + BookingType,
               UserID
        FROM inserted;
    END
    
    -- Handle UPDATE
    IF EXISTS (SELECT * FROM inserted) AND EXISTS (SELECT * FROM deleted)
    BEGIN
        INSERT INTO AuditLogs (TableName, RecordID, Action, OldValues, NewValues, UserID)
        SELECT 'Bookings', i.BookingID, 'UPDATE',
               'Status: ' + d.Status + ', End: ' + CONVERT(nvarchar(20), d.EndDate, 120),
               'Status: ' + i.Status + ', End: ' + CONVERT(nvarchar(20), i.EndDate, 120),
               i.UserID
        FROM inserted i
        INNER JOIN deleted d ON i.BookingID = d.BookingID;
    END
    
    -- Handle DELETE
    IF EXISTS (SELECT * FROM deleted) AND NOT EXISTS (SELECT * FROM inserted)
    BEGIN
        INSERT INTO AuditLogs (TableName, RecordID, Action, OldValues, UserID)
        SELECT 'Bookings', BookingID, 'DELETE',
               'Code: ' + BookingCode + ', Status: ' + Status + ', Type: ' + BookingType,
               UserID
        FROM deleted;
    END
END
GO

-- =============================================
-- 3. BUSINESS RULE VALIDATION TRIGGERS
-- =============================================

-- Trigger to validate booking business rules
CREATE TRIGGER tr_ValidateBookingRules
ON Bookings
INSTEAD OF INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @UserID int, @ResourceID int, @StartDate datetime2, @EndDate datetime2;
    DECLARE @UserType nvarchar(20), @ResourceType nvarchar(20);
    DECLARE @BookingID int, @Status nvarchar(20);
    
    -- Handle INSERT
    IF NOT EXISTS (SELECT * FROM deleted)
    BEGIN
        DECLARE insert_cursor CURSOR FOR
        SELECT UserID, ResourceID, StartDate, EndDate, Status
        FROM inserted;
        
        OPEN insert_cursor;
        FETCH NEXT FROM insert_cursor INTO @UserID, @ResourceID, @StartDate, @EndDate, @Status;
        
        WHILE @@FETCH_STATUS = 0
        BEGIN
            -- Get user and resource types
            SELECT @UserType = UserType FROM Users WHERE UserID = @UserID;
            SELECT @ResourceType = ResourceType FROM Resources WHERE ResourceID = @ResourceID;
            
            -- Validate booking period based on HUIT rules
            DECLARE @BookingDays int = DATEDIFF(DAY, @StartDate, @EndDate);
            DECLARE @BookingHours int = DATEDIFF(HOUR, @StartDate, @EndDate);
            
            IF @ResourceType = 'Book'
            BEGIN
                DECLARE @MaxBookDays int = CASE 
                    WHEN @UserType = 'Student' THEN 14
                    WHEN @UserType IN ('Staff', 'Faculty') THEN 30
                    ELSE 14
                END;
                
                IF @BookingDays > @MaxBookDays
                BEGIN
                    RAISERROR('Book loan period exceeds maximum allowed for user type', 16, 1);
                    RETURN;
                END
            END
            ELSE IF @ResourceType = 'Equipment'
            BEGIN
                IF @BookingHours > 2
                BEGIN
                    RAISERROR('Equipment booking exceeds maximum 2 hours allowed', 16, 1);
                    RETURN;
                END
            END
            ELSE IF @ResourceType = 'Room'
            BEGIN
                IF @BookingHours > 4
                BEGIN
                    RAISERROR('Room booking exceeds maximum 4 hours allowed', 16, 1);
                    RETURN;
                END
                
                -- Check for room conflicts
                IF EXISTS (
                    SELECT 1 FROM Bookings 
                    WHERE ResourceID = @ResourceID 
                    AND Status IN ('Approved', 'Active')
                    AND (
                        (@StartDate BETWEEN StartDate AND EndDate) OR
                        (@EndDate BETWEEN StartDate AND EndDate) OR
                        (StartDate BETWEEN @StartDate AND @EndDate)
                    )
                )
                BEGIN
                    RAISERROR('Room is already booked for the requested time period', 16, 1);
                    RETURN;
                END
            END
            
            -- Validate start date is not in the past
            IF @StartDate < GETDATE()
            BEGIN
                RAISERROR('Booking start date cannot be in the past', 16, 1);
                RETURN;
            END
            
            -- Validate end date is after start date
            IF @EndDate <= @StartDate
            BEGIN
                RAISERROR('Booking end date must be after start date', 16, 1);
                RETURN;
            END
            
            -- Check user penalties - users with unpaid penalties cannot make new bookings
            IF EXISTS (
                SELECT 1 FROM Penalties 
                WHERE UserID = @UserID AND Status = 'Unpaid'
            )
            BEGIN
                RAISERROR('User has unpaid penalties and cannot make new bookings', 16, 1);
                RETURN;
            END
            
            FETCH NEXT FROM insert_cursor INTO @UserID, @ResourceID, @StartDate, @EndDate, @Status;
        END
        
        CLOSE insert_cursor;
        DEALLOCATE insert_cursor;
        
        -- Perform the actual insert
        INSERT INTO Bookings (BookingCode, UserID, ResourceID, BookingType, RequestDate, StartDate, EndDate, Status, Purpose, Notes)
        SELECT BookingCode, UserID, ResourceID, BookingType, RequestDate, StartDate, EndDate, Status, Purpose, Notes
        FROM inserted;
    END
    
    -- Handle UPDATE
    IF EXISTS (SELECT * FROM deleted)
    BEGIN
        DECLARE update_cursor CURSOR FOR
        SELECT i.BookingID, i.UserID, i.ResourceID, i.StartDate, i.EndDate, i.Status
        FROM inserted i
        INNER JOIN deleted d ON i.BookingID = d.BookingID;
        
        OPEN update_cursor;
        FETCH NEXT FROM update_cursor INTO @BookingID, @UserID, @ResourceID, @StartDate, @EndDate, @Status;
        
        WHILE @@FETCH_STATUS = 0
        BEGIN
            -- Similar validation for updates (simplified for key rules)
            IF @EndDate <= @StartDate
            BEGIN
                RAISERROR('Booking end date must be after start date', 16, 1);
                RETURN;
            END
            
            FETCH NEXT FROM update_cursor INTO @BookingID, @UserID, @ResourceID, @StartDate, @EndDate, @Status;
        END
        
        CLOSE update_cursor;
        DEALLOCATE update_cursor;
        
        -- Perform the actual update
        UPDATE b
        SET BookingCode = i.BookingCode,
            UserID = i.UserID,
            ResourceID = i.ResourceID,
            BookingType = i.BookingType,
            RequestDate = i.RequestDate,
            StartDate = i.StartDate,
            EndDate = i.EndDate,
            ReturnDate = i.ReturnDate,
            Status = i.Status,
            ApprovedBy = i.ApprovedBy,
            ApprovalDate = i.ApprovalDate,
            Purpose = i.Purpose,
            Notes = i.Notes
        FROM Bookings b
        INNER JOIN inserted i ON b.BookingID = i.BookingID;
    END
END
GO

-- Trigger to validate penalty business rules
CREATE TRIGGER tr_ValidatePenaltyRules
ON Penalties
INSTEAD OF INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Validate penalty amounts based on HUIT rules
    DECLARE @PenaltyType nvarchar(20), @PenaltyAmount decimal(10,2);
    DECLARE @DaysOverdue int;
    
    DECLARE penalty_cursor CURSOR FOR
    SELECT PenaltyType, PenaltyAmount, DaysOverdue
    FROM inserted;
    
    OPEN penalty_cursor;
    FETCH NEXT FROM penalty_cursor INTO @PenaltyType, @PenaltyAmount, @DaysOverdue;
    
    WHILE @@FETCH_STATUS = 0
    BEGIN
        IF @PenaltyType = 'Late'
        BEGIN
            DECLARE @ExpectedAmount decimal(10,2) = @DaysOverdue * 5000; -- 5000đ per day
            
            IF @PenaltyAmount != @ExpectedAmount
            BEGIN
                RAISERROR('Late penalty amount does not match HUIT rules (5000đ per day)', 16, 1);
                RETURN;
            END
        END
        ELSE IF @PenaltyType = 'NoShow'
        BEGIN
            IF @PenaltyAmount != 20000 -- Fixed 20,000đ no-show penalty
            BEGIN
                RAISERROR('No-show penalty amount does not match HUIT rules (20,000đ)', 16, 1);
                RETURN;
            END
        END
        
        FETCH NEXT FROM penalty_cursor INTO @PenaltyType, @PenaltyAmount, @DaysOverdue;
    END
    
    CLOSE penalty_cursor;
    DEALLOCATE penalty_cursor;
    
    -- Handle INSERT
    IF NOT EXISTS (SELECT * FROM deleted)
    BEGIN
        INSERT INTO Penalties (BookingID, UserID, PenaltyType, PenaltyAmount, DaysOverdue, Description, IssueDate, DueDate, Status)
        SELECT BookingID, UserID, PenaltyType, PenaltyAmount, DaysOverdue, Description, IssueDate, DueDate, Status
        FROM inserted;
    END
    ELSE
    BEGIN
        -- Handle UPDATE
        UPDATE p
        SET BookingID = i.BookingID,
            UserID = i.UserID,
            PenaltyType = i.PenaltyType,
            PenaltyAmount = i.PenaltyAmount,
            DaysOverdue = i.DaysOverdue,
            Description = i.Description,
            IssueDate = i.IssueDate,
            DueDate = i.DueDate,
            PaidDate = i.PaidDate,
            Status = i.Status,
            PaidBy = i.PaidBy,
            PaymentMethod = i.PaymentMethod
        FROM Penalties p
        INNER JOIN inserted i ON p.PenaltyID = i.PenaltyID;
    END
END
GO

-- =============================================
-- 4. SYSTEM MAINTENANCE TRIGGERS
-- =============================================

-- Trigger to automatically update ModifiedDate on key tables
CREATE TRIGGER tr_UpdateModifiedDate_Departments
ON Departments
BEFORE UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    
    UPDATE d
    SET ModifiedDate = GETDATE()
    FROM Departments d
    INNER JOIN inserted i ON d.DepartmentID = i.DepartmentID;
END
GO

CREATE TRIGGER tr_UpdateModifiedDate_Users
ON Users
BEFORE UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    
    UPDATE u
    SET ModifiedDate = GETDATE()
    FROM Users u
    INNER JOIN inserted i ON u.UserID = i.UserID;
END
GO

-- Trigger to prevent deletion of resources with active bookings
CREATE TRIGGER tr_PreventResourceDeletion
ON Resources
INSTEAD OF DELETE
AS
BEGIN
    SET NOCOUNT ON;
    
    IF EXISTS (
        SELECT 1 FROM deleted d
        INNER JOIN Bookings b ON d.ResourceID = b.ResourceID
        WHERE b.Status IN ('Approved', 'Active')
    )
    BEGIN
        RAISERROR('Cannot delete resources with active bookings', 16, 1);
        RETURN;
    END
    
    -- Mark as inactive instead of deleting
    UPDATE Resources
    SET IsActive = 0,
        ModifiedDate = GETDATE()
    WHERE ResourceID IN (SELECT ResourceID FROM deleted);
END
GO

-- Trigger to prevent deletion of users with active bookings or unpaid penalties
CREATE TRIGGER tr_PreventUserDeletion
ON Users
INSTEAD OF DELETE
AS
BEGIN
    SET NOCOUNT ON;
    
    IF EXISTS (
        SELECT 1 FROM deleted d
        WHERE EXISTS (
            SELECT 1 FROM Bookings b 
            WHERE b.UserID = d.UserID AND b.Status IN ('Approved', 'Active')
        )
        OR EXISTS (
            SELECT 1 FROM Penalties p 
            WHERE p.UserID = d.UserID AND p.Status = 'Unpaid'
        )
    )
    BEGIN
        RAISERROR('Cannot delete users with active bookings or unpaid penalties', 16, 1);
        RETURN;
    END
    
    -- Mark as inactive instead of deleting
    UPDATE Users
    SET IsActive = 0,
        ModifiedDate = GETDATE()
    WHERE UserID IN (SELECT UserID FROM deleted);
END
GO

PRINT 'All triggers created successfully for HUIT Library Management System';