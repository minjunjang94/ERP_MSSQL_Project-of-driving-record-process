IF EXISTS (SELECT * FROM Sysobjects where Name = 'minjun_TACCarDriveRecord' AND xtype = 'U' )
    Drop table minjun_TACCarDriveRecord

CREATE TABLE minjun_TACCarDriveRecord
(
    CompanySeq		INT 	 NOT NULL, 
    CarSeq		INT 	 NOT NULL, 
    CarSerl		INT 	 NOT NULL, 
    DeptSeq		INT 	 NULL, 
    EmpSeq		INT 	 NULL, 
    CarDate		NVARCHAR(8) 	 NULL, 
    OrderSeq		INT 	 NULL, 
    UMDriveKind		INT 	 NULL, 
    UMStartGroup		INT 	 NULL, 
    StartPlace		NVARCHAR(100) 	 NULL, 
    StartAddr		NVARCHAR(200) 	 NULL, 
    UMArriveGroup		INT 	 NULL, 
    ArrivePlace		NVARCHAR(100) 	 NULL, 
    ArriveAddr		NVARCHAR(200) 	 NULL, 
    BeforeKm		DECIMAL(19,5) 	 NULL, 
    AfterKm		DECIMAL(19,5) 	 NULL, 
    WorkKm		DECIMAL(19,5) 	 NULL, 
    Remark		NVARCHAR(200) 	 NULL, 
    LastUserSeq		INT 	 NULL, 
    LastDateTime		DATETIME 	 NULL, 
CONSTRAINT PKminjun_TACCarDriveRecord PRIMARY KEY CLUSTERED (CompanySeq ASC, CarSeq ASC, CarSerl ASC)

)


IF EXISTS (SELECT * FROM Sysobjects where Name = 'minjun_TACCarDriveRecordLog' AND xtype = 'U' )
    Drop table minjun_TACCarDriveRecordLog

CREATE TABLE minjun_TACCarDriveRecordLog
(
    LogSeq		INT IDENTITY(1,1) NOT NULL, 
    LogUserSeq		INT NOT NULL, 
    LogDateTime		DATETIME NOT NULL, 
    LogType		NCHAR(1) NOT NULL, 
    LogPgmSeq		INT NULL, 
    CompanySeq		INT 	 NOT NULL, 
    CarSeq		INT 	 NOT NULL, 
    CarSerl		INT 	 NOT NULL, 
    DeptSeq		INT 	 NULL, 
    EmpSeq		INT 	 NULL, 
    CarDate		NVARCHAR(8) 	 NULL, 
    OrderSeq		INT 	 NULL, 
    UMDriveKind		INT 	 NULL, 
    UMStartGroup		INT 	 NULL, 
    StartPlace		NVARCHAR(100) 	 NULL, 
    StartAddr		NVARCHAR(200) 	 NULL, 
    UMArriveGroup		INT 	 NULL, 
    ArrivePlace		NVARCHAR(100) 	 NULL, 
    ArriveAddr		NVARCHAR(200) 	 NULL, 
    BeforeKm		DECIMAL(19,5) 	 NULL, 
    AfterKm		DECIMAL(19,5) 	 NULL, 
    WorkKm		DECIMAL(19,5) 	 NULL, 
    Remark		NVARCHAR(200) 	 NULL, 
    LastUserSeq		INT 	 NULL, 
    LastDateTime		DATETIME 	 NULL
)

CREATE UNIQUE CLUSTERED INDEX IDXTempminjun_TACCarDriveRecordLog ON minjun_TACCarDriveRecordLog (LogSeq)
go