-- HUIT Library Management System
-- Stored Procedures for Business Operations
-- Ho Chi Minh City University of Industry

USE HUIT_LibraryManagement;
GO

-- =============================================
-- 1. BOOKING APPROVAL PROCEDURE
-- =============================================
CREATE PROCEDURE sp_ApproveBooking
    @BookingID int,
    @ApprovedBy int,
    @Notes nvarchar(1000) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @ResourceID int, @StartDate datetime2, @EndDate datetime2;
    DECLARE @AvailableCopies int, @ResourceType nvarchar(20);
    DECLARE @UserType nvarchar(20), @UserID int;
    
    BEGIN TRY
        BEGIN TRANSACTION;
        
        -- Get booking details
        SELECT @ResourceID = ResourceID, @StartDate = StartDate, @EndDate = EndDate, @UserID = UserID
        FROM Bookings 
        WHERE BookingID = @BookingID AND Status = 'Pending';
        
        IF @ResourceID IS NULL
        BEGIN
            RAISERROR('Booking not found or already processed', 16, 1);
            RETURN;
        END
        
        -- Get resource and user details
        SELECT @AvailableCopies = AvailableCopies, @ResourceType = ResourceType
        FROM Resources 
        WHERE ResourceID = @ResourceID;
        
        SELECT @UserType = UserType
        FROM Users 
        WHERE UserID = @UserID;
        
        -- Check availability
        IF @AvailableCopies <= 0
        BEGIN
            RAISERROR('Resource not available', 16, 1);
            ROLLBACK TRANSACTION;
            RETURN;
        END
        
        -- Equipment requires special approval
        IF @ResourceType = 'Equipment'
        BEGIN
            DECLARE @MaxHours int = 2; -- HUIT rule: equipment max 2 hours
            DECLARE @BookingHours int = DATEDIFF(HOUR, @StartDate, @EndDate);
            
            IF @BookingHours > @MaxHours
            BEGIN
                RAISERROR('Equipment booking exceeds maximum allowed hours (2 hours)', 16, 1);
                ROLLBACK TRANSACTION;
                RETURN;
            END
        END
        
        -- Room booking validation
        IF @ResourceType = 'Room'
        BEGIN
            DECLARE @MaxRoomHours int = 4; -- HUIT rule: rooms max 2-4 hours
            DECLARE @RoomBookingHours int = DATEDIFF(HOUR, @StartDate, @EndDate);
            
            IF @RoomBookingHours > @MaxRoomHours
            BEGIN
                RAISERROR('Room booking exceeds maximum allowed hours (4 hours)', 16, 1);
                ROLLBACK TRANSACTION;
                RETURN;
            END
            
            -- Check for conflicts
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
                RAISERROR('Room already booked for the requested time slot', 16, 1);
                ROLLBACK TRANSACTION;
                RETURN;
            END
        END
        
        -- Book loan period validation
        IF @ResourceType = 'Book'
        BEGIN
            DECLARE @MaxDays int;
            SET @MaxDays = CASE 
                WHEN @UserType = 'Student' THEN 14  -- HUIT rule: students 14 days
                WHEN @UserType IN ('Staff', 'Faculty') THEN 30  -- HUIT rule: staff 30 days
                ELSE 14
            END;
            
            DECLARE @BookingDays int = DATEDIFF(DAY, @StartDate, @EndDate);
            
            IF @BookingDays > @MaxDays
            BEGIN
                RAISERROR('Book loan period exceeds maximum allowed days', 16, 1);
                ROLLBACK TRANSACTION;
                RETURN;
            END
        END
        
        -- Approve booking
        UPDATE Bookings 
        SET Status = 'Approved',
            ApprovedBy = @ApprovedBy,
            ApprovalDate = GETDATE(),
            Notes = COALESCE(@Notes, Notes)
        WHERE BookingID = @BookingID;
        
        -- Update resource availability
        UPDATE Resources 
        SET AvailableCopies = AvailableCopies - 1,
            CurrentStatus = CASE WHEN AvailableCopies - 1 = 0 THEN 'Borrowed' ELSE CurrentStatus END,
            ModifiedDate = GETDATE()
        WHERE ResourceID = @ResourceID;
        
        COMMIT TRANSACTION;
        
        SELECT 'SUCCESS' as Result, 'Booking approved successfully' as Message;
        
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;
        
        DECLARE @ErrorMessage nvarchar(4000) = ERROR_MESSAGE();
        DECLARE @ErrorSeverity int = ERROR_SEVERITY();
        DECLARE @ErrorState int = ERROR_STATE();
        
        RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);
    END CATCH
END
GO

-- =============================================
-- 2. CHECK-IN/CHECK-OUT PROCEDURE
-- =============================================
CREATE PROCEDURE sp_CheckInOut
    @BookingID int,
    @Action nvarchar(10), -- 'CheckIn' or 'CheckOut'
    @ProcessedBy int,
    @Notes nvarchar(1000) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @ResourceID int, @UserID int, @EndDate datetime2, @ResourceType nvarchar(20);
    
    BEGIN TRY
        BEGIN TRANSACTION;
        
        SELECT @ResourceID = ResourceID, @UserID = UserID, @EndDate = EndDate, @ResourceType = r.ResourceType
        FROM Bookings b
        INNER JOIN Resources r ON b.ResourceID = r.ResourceID
        WHERE BookingID = @BookingID;
        
        IF @ResourceID IS NULL
        BEGIN
            RAISERROR('Booking not found', 16, 1);
            RETURN;
        END
        
        IF @Action = 'CheckIn'
        BEGIN
            -- Update booking to active
            UPDATE Bookings 
            SET Status = 'Active',
                Notes = COALESCE(@Notes, Notes)
            WHERE BookingID = @BookingID AND Status = 'Approved';
            
            IF @@ROWCOUNT = 0
            BEGIN
                RAISERROR('Booking is not in approved status', 16, 1);
                ROLLBACK TRANSACTION;
                RETURN;
            END
            
            SELECT 'SUCCESS' as Result, 'Check-in successful' as Message;
        END
        ELSE IF @Action = 'CheckOut'
        BEGIN
            -- Check for late return
            DECLARE @IsLate bit = 0;
            DECLARE @DaysLate int = 0;
            
            IF GETDATE() > @EndDate
            BEGIN
                SET @IsLate = 1;
                SET @DaysLate = DATEDIFF(DAY, @EndDate, GETDATE());
            END
            
            -- Update booking to completed
            UPDATE Bookings 
            SET Status = CASE WHEN @IsLate = 1 THEN 'Overdue' ELSE 'Completed' END,
                ReturnDate = GETDATE(),
                Notes = COALESCE(@Notes, Notes)
            WHERE BookingID = @BookingID AND Status = 'Active';
            
            IF @@ROWCOUNT = 0
            BEGIN
                RAISERROR('Booking is not in active status', 16, 1);
                ROLLBACK TRANSACTION;
                RETURN;
            END
            
            -- Update resource availability
            UPDATE Resources 
            SET AvailableCopies = AvailableCopies + 1,
                CurrentStatus = 'Available',
                ModifiedDate = GETDATE()
            WHERE ResourceID = @ResourceID;
            
            -- Create penalty for late return
            IF @IsLate = 1
            BEGIN
                DECLARE @PenaltyAmount decimal(10,2);
                SET @PenaltyAmount = @DaysLate * 5000; -- HUIT rule: 5000đ per day late
                
                INSERT INTO Penalties (BookingID, UserID, PenaltyType, PenaltyAmount, DaysOverdue, Description, DueDate)
                VALUES (@BookingID, @UserID, 'Late', @PenaltyAmount, @DaysLate, 
                        'Late return penalty: ' + CAST(@DaysLate as nvarchar(10)) + ' days late',
                        DATEADD(DAY, 30, GETDATE()));
            END
            
            SELECT 'SUCCESS' as Result, 
                   CASE WHEN @IsLate = 1 
                        THEN 'Check-out completed with late penalty: ' + CAST(@PenaltyAmount as nvarchar(20)) + ' VND'
                        ELSE 'Check-out completed successfully' 
                   END as Message;
        END
        ELSE
        BEGIN
            RAISERROR('Invalid action. Use CheckIn or CheckOut', 16, 1);
            ROLLBACK TRANSACTION;
            RETURN;
        END
        
        COMMIT TRANSACTION;
        
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;
        
        DECLARE @ErrorMessage nvarchar(4000) = ERROR_MESSAGE();
        DECLARE @ErrorSeverity int = ERROR_SEVERITY();
        DECLARE @ErrorState int = ERROR_STATE();
        
        RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);
    END CATCH
END
GO

-- =============================================
-- 3. BOOKING EXTENSION PROCEDURE
-- =============================================
CREATE PROCEDURE sp_ExtendBooking
    @BookingID int,
    @NewEndDate datetime2,
    @RequestedBy int,
    @Reason nvarchar(500)
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @CurrentEndDate datetime2, @UserID int, @ResourceType nvarchar(20), @UserType nvarchar(20);
    DECLARE @MaxExtensions int, @CurrentExtensions int;
    
    BEGIN TRY
        BEGIN TRANSACTION;
        
        SELECT @CurrentEndDate = b.EndDate, @UserID = b.UserID, @ResourceType = r.ResourceType, @UserType = u.UserType
        FROM Bookings b
        INNER JOIN Resources r ON b.ResourceID = r.ResourceID
        INNER JOIN Users u ON b.UserID = u.UserID
        WHERE b.BookingID = @BookingID AND b.Status = 'Active';
        
        IF @CurrentEndDate IS NULL
        BEGIN
            RAISERROR('Booking not found or not active', 16, 1);
            RETURN;
        END
        
        -- Check if user requesting extension is the same as the borrower
        IF @RequestedBy != @UserID
        BEGIN
            RAISERROR('Only the original borrower can request extension', 16, 1);
            ROLLBACK TRANSACTION;
            RETURN;
        END
        
        -- Extension rules based on resource type and user type
        IF @ResourceType = 'Book'
        BEGIN
            SET @MaxExtensions = 1; -- HUIT rule: max 1 extension for books
            
            -- Check current extensions (simplified - count previous extensions)
            SELECT @CurrentExtensions = COUNT(*)
            FROM AuditLogs 
            WHERE TableName = 'Bookings' AND RecordID = @BookingID 
            AND NewValues LIKE '%Extension%';
            
            IF @CurrentExtensions >= @MaxExtensions
            BEGIN
                RAISERROR('Maximum number of extensions reached', 16, 1);
                ROLLBACK TRANSACTION;
                RETURN;
            END
            
            -- Validate extension period
            DECLARE @MaxTotalDays int = CASE 
                WHEN @UserType = 'Student' THEN 28  -- 14 + 14 days extension
                WHEN @UserType IN ('Staff', 'Faculty') THEN 60  -- 30 + 30 days extension
                ELSE 28
            END;
            
            DECLARE @TotalDays int = DATEDIFF(DAY, GETDATE(), @NewEndDate);
            
            IF @TotalDays > @MaxTotalDays
            BEGIN
                RAISERROR('Extension period exceeds maximum allowed', 16, 1);
                ROLLBACK TRANSACTION;
                RETURN;
            END
        END
        ELSE
        BEGIN
            RAISERROR('Extensions are only allowed for book loans', 16, 1);
            ROLLBANK TRANSACTION;
            RETURN;
        END
        
        -- Update booking
        UPDATE Bookings 
        SET EndDate = @NewEndDate,
            Notes = COALESCE(Notes + '; ', '') + 'Extended until ' + CONVERT(nvarchar(20), @NewEndDate, 120) + ' - Reason: ' + @Reason
        WHERE BookingID = @BookingID;
        
        COMMIT TRANSACTION;
        
        SELECT 'SUCCESS' as Result, 'Booking extended successfully until ' + CONVERT(nvarchar(20), @NewEndDate, 120) as Message;
        
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;
        
        DECLARE @ErrorMessage nvarchar(4000) = ERROR_MESSAGE();
        DECLARE @ErrorSeverity int = ERROR_SEVERITY();
        DECLARE @ErrorState int = ERROR_STATE();
        
        RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);
    END CATCH
END
GO

-- =============================================
-- 4. BOOKING CANCELLATION PROCEDURE
-- =============================================
CREATE PROCEDURE sp_CancelBooking
    @BookingID int,
    @CancelledBy int,
    @Reason nvarchar(500)
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @ResourceID int, @UserID int, @Status nvarchar(20), @StartDate datetime2;
    
    BEGIN TRY
        BEGIN TRANSACTION;
        
        SELECT @ResourceID = ResourceID, @UserID = UserID, @Status = Status, @StartDate = StartDate
        FROM Bookings 
        WHERE BookingID = @BookingID;
        
        IF @ResourceID IS NULL
        BEGIN
            RAISERROR('Booking not found', 16, 1);
            RETURN;
        END
        
        IF @Status NOT IN ('Pending', 'Approved')
        BEGIN
            RAISERROR('Can only cancel pending or approved bookings', 16, 1);
            ROLLBACK TRANSACTION;
            RETURN;
        END
        
        -- Check if cancellation is too late (no-show penalty)
        DECLARE @ApplyNoShowPenalty bit = 0;
        IF @Status = 'Approved' AND GETDATE() > @StartDate
        BEGIN
            SET @ApplyNoShowPenalty = 1;
        END
        
        -- Update booking status
        UPDATE Bookings 
        SET Status = 'Cancelled',
            Notes = COALESCE(Notes + '; ', '') + 'Cancelled by user - Reason: ' + @Reason
        WHERE BookingID = @BookingID;
        
        -- Return resource availability if was approved
        IF @Status = 'Approved'
        BEGIN
            UPDATE Resources 
            SET AvailableCopies = AvailableCopies + 1,
                CurrentStatus = 'Available',
                ModifiedDate = GETDATE()
            WHERE ResourceID = @ResourceID;
        END
        
        -- Apply no-show penalty if applicable
        IF @ApplyNoShowPenalty = 1
        BEGIN
            DECLARE @NoShowPenalty decimal(10,2) = 20000; -- HUIT rule: 20,000đ no-show penalty
            
            INSERT INTO Penalties (BookingID, UserID, PenaltyType, PenaltyAmount, Description, DueDate)
            VALUES (@BookingID, @UserID, 'NoShow', @NoShowPenalty, 
                    'No-show penalty for cancelled booking after start time',
                    DATEADD(DAY, 30, GETDATE()));
        END
        
        COMMIT TRANSACTION;
        
        SELECT 'SUCCESS' as Result, 
               CASE WHEN @ApplyNoShowPenalty = 1 
                    THEN 'Booking cancelled with no-show penalty: 20,000 VND'
                    ELSE 'Booking cancelled successfully' 
               END as Message;
        
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;
        
        DECLARE @ErrorMessage nvarchar(4000) = ERROR_MESSAGE();
        DECLARE @ErrorSeverity int = ERROR_SEVERITY();
        DECLARE @ErrorState int = ERROR_STATE();
        
        RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);
    END CATCH
END
GO

-- =============================================
-- 5. PENALTY PAYMENT PROCEDURE
-- =============================================
CREATE PROCEDURE sp_PayPenalty
    @PenaltyID int,
    @PaidBy int,
    @PaymentMethod nvarchar(50),
    @PaymentReference nvarchar(100) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @PenaltyAmount decimal(10,2), @UserID int, @Status nvarchar(20);
    
    BEGIN TRY
        BEGIN TRANSACTION;
        
        SELECT @PenaltyAmount = PenaltyAmount, @UserID = UserID, @Status = Status
        FROM Penalties 
        WHERE PenaltyID = @PenaltyID;
        
        IF @PenaltyAmount IS NULL
        BEGIN
            RAISERROR('Penalty not found', 16, 1);
            RETURN;
        END
        
        IF @Status != 'Unpaid'
        BEGIN
            RAISERROR('Penalty is already paid or waived', 16, 1);
            ROLLBACK TRANSACTION;
            RETURN;
        END
        
        -- Update penalty status
        UPDATE Penalties 
        SET Status = 'Paid',
            PaidDate = GETDATE(),
            PaidBy = @PaidBy,
            PaymentMethod = @PaymentMethod,
            Description = COALESCE(Description + '; ', '') + 'Payment ref: ' + COALESCE(@PaymentReference, 'N/A')
        WHERE PenaltyID = @PenaltyID;
        
        COMMIT TRANSACTION;
        
        SELECT 'SUCCESS' as Result, 
               'Penalty paid successfully. Amount: ' + CAST(@PenaltyAmount as nvarchar(20)) + ' VND' as Message;
        
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;
        
        DECLARE @ErrorMessage nvarchar(4000) = ERROR_MESSAGE();
        DECLARE @ErrorSeverity int = ERROR_SEVERITY();
        DECLARE @ErrorState int = ERROR_STATE();
        
        RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);
    END CATCH
END
GO

-- =============================================
-- 6. BACKUP AND MAINTENANCE PROCEDURE
-- =============================================
CREATE PROCEDURE sp_DatabaseMaintenance
    @MaintenanceType nvarchar(50), -- 'Backup', 'UpdateStats', 'RebuildIndexes', 'CleanupLogs'
    @ExecutedBy int
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @StartTime datetime2 = GETDATE();
    DECLARE @Message nvarchar(1000);
    
    BEGIN TRY
        IF @MaintenanceType = 'Backup'
        BEGIN
            DECLARE @BackupPath nvarchar(500) = 'C:\DatabaseBackups\HUIT_LibraryManagement_' + 
                FORMAT(GETDATE(), 'yyyyMMdd_HHmmss') + '.bak';
            
            BACKUP DATABASE HUIT_LibraryManagement 
            TO DISK = @BackupPath
            WITH FORMAT, INIT, NAME = 'HUIT Library Management - Full Database Backup';
            
            SET @Message = 'Database backup completed successfully to: ' + @BackupPath;
        END
        ELSE IF @MaintenanceType = 'UpdateStats'
        BEGIN
            UPDATE STATISTICS Users;
            UPDATE STATISTICS Resources;
            UPDATE STATISTICS Bookings;
            UPDATE STATISTICS Penalties;
            UPDATE STATISTICS AuditLogs;
            
            SET @Message = 'Database statistics updated successfully';
        END
        ELSE IF @MaintenanceType = 'RebuildIndexes'
        BEGIN
            ALTER INDEX ALL ON Users REBUILD;
            ALTER INDEX ALL ON Resources REBUILD;
            ALTER INDEX ALL ON Bookings REBUILD;
            ALTER INDEX ALL ON Penalties REBUILD;
            
            SET @Message = 'Database indexes rebuilt successfully';
        END
        ELSE IF @MaintenanceType = 'CleanupLogs'
        BEGIN
            -- Clean up audit logs older than 1 year
            DELETE FROM AuditLogs 
            WHERE LogDate < DATEADD(YEAR, -1, GETDATE());
            
            DECLARE @DeletedRows int = @@ROWCOUNT;
            SET @Message = 'Cleanup completed. Deleted ' + CAST(@DeletedRows as nvarchar(10)) + ' old audit log records';
        END
        ELSE
        BEGIN
            RAISERROR('Invalid maintenance type', 16, 1);
            RETURN;
        END
        
        -- Log maintenance activity
        INSERT INTO AuditLogs (TableName, RecordID, Action, NewValues, UserID)
        VALUES ('SystemMaintenance', 0, 'MAINTENANCE', 
                'Type: ' + @MaintenanceType + '; Duration: ' + 
                CAST(DATEDIFF(SECOND, @StartTime, GETDATE()) as nvarchar(10)) + ' seconds; ' + @Message,
                @ExecutedBy);
        
        SELECT 'SUCCESS' as Result, @Message as Message;
        
    END TRY
    BEGIN CATCH
        DECLARE @ErrorMessage nvarchar(4000) = ERROR_MESSAGE();
        DECLARE @ErrorSeverity int = ERROR_SEVERITY();
        DECLARE @ErrorState int = ERROR_STATE();
        
        RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);
    END CATCH
END
GO

-- =============================================
-- 7. UTILITY PROCEDURES
-- =============================================

-- Get available resources for booking
CREATE PROCEDURE sp_GetAvailableResources
    @ResourceType nvarchar(20) = NULL,
    @StartDate datetime2,
    @EndDate datetime2,
    @CategoryID int = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    SELECT 
        r.ResourceID,
        r.ResourceCode,
        r.Title,
        r.ResourceType,
        rc.CategoryName,
        r.AvailableCopies,
        l.LocationName,
        r.Description
    FROM Resources r
    INNER JOIN ResourceCategories rc ON r.CategoryID = rc.CategoryID
    LEFT JOIN Locations l ON r.LocationID = l.LocationID
    WHERE r.IsActive = 1
    AND r.AvailableCopies > 0
    AND (@ResourceType IS NULL OR r.ResourceType = @ResourceType)
    AND (@CategoryID IS NULL OR r.CategoryID = @CategoryID)
    AND NOT EXISTS (
        SELECT 1 FROM Bookings b
        WHERE b.ResourceID = r.ResourceID
        AND b.Status IN ('Approved', 'Active')
        AND (
            (@StartDate BETWEEN b.StartDate AND b.EndDate) OR
            (@EndDate BETWEEN b.StartDate AND b.EndDate) OR
            (b.StartDate BETWEEN @StartDate AND @EndDate)
        )
    )
    ORDER BY r.ResourceType, rc.CategoryName, r.Title;
END
GO

-- Get user booking history
CREATE PROCEDURE sp_GetUserBookingHistory
    @UserID int,
    @StartDate datetime2 = NULL,
    @EndDate datetime2 = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    SELECT 
        b.BookingID,
        b.BookingCode,
        r.Title,
        r.ResourceType,
        rc.CategoryName,
        b.StartDate,
        b.EndDate,
        b.ReturnDate,
        b.Status,
        COALESCE(p.PenaltyAmount, 0) as PenaltyAmount,
        p.Status as PenaltyStatus
    FROM Bookings b
    INNER JOIN Resources r ON b.ResourceID = r.ResourceID
    INNER JOIN ResourceCategories rc ON r.CategoryID = rc.CategoryID
    LEFT JOIN Penalties p ON b.BookingID = p.BookingID
    WHERE b.UserID = @UserID
    AND (@StartDate IS NULL OR b.StartDate >= @StartDate)
    AND (@EndDate IS NULL OR b.StartDate <= @EndDate)
    ORDER BY b.StartDate DESC;
END
GO