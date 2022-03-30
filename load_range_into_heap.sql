---------------------------------------------------------------------------------------
-- Load range into heap partitioned table, create aligned clustered index after loading
---------------------------------------------------------------------------------------
SET NOCOUNT ON;

/*
-- Initial stage table without clustered index
*/
if object_id('dbo.StageTable') is not null 
	drop table StageTable
go 

create table StageTable (
	id uniqueidentifier not null, 
	eventDate datetime not null,
	c2 int, 
	c3 varchar(50),
	c4 bigint
	,c6 varbinary(512)
  
)
on [ps_SFbyDate](eventDate)


-- Drop primary key on the STAGE table or create a fresh table
if object_id('PK_state') is not null 
	ALTER TABLE dbo.StageTable DROP CONSTRAINT PK_state;
GO 


-- Load data
DECLARE @StartDate DATETIME = '2019-02-01 00:00:00.000';
DECLARE @BeginDateTime DATETIME; 
DECLARE @EndDateTime DATETIME; 

PRINT @StartDate;

-- Calculate first day of the next month
SELECT	@BeginDateTime = dateadd(day, datediff(day, 0, @StartDate), 0),
		@EndDateTime = dateadd(month, datediff(month, 0, @StartDate)+1, 0) -- < 2019-05-01 00:00:00.000
		
SELECT @BeginDateTime, @EndDateTime;

-- Load data into staging table
-- WARNING: TABLOCK will not support parallel loading on a CLUSTERED INDEX!
INSERT INTO dbo.StageTable WITH(TABLOCK) (
	[id]
	,[eventDate]
	,[c2]
	,[c3]
	,[c4]
	,[c6]
)
SELECT [id]
	,[eventDate]
	,[c2]
	,[c3]
	,[c4]
	,[c6]
FROM [dbo].[tClus]
WHERE eventDate >= @BeginDateTime
and eventDate < @EndDateTime;


-- Create Clustered index
ALTER TABLE dbo.StageTable 
ADD CONSTRAINT [PK_state] PRIMARY KEY CLUSTERED (id, eventDate)
ON [ps_SFbyDate](eventDate);
GO


--PRINT 'Move partition into final table.'
EXECUTE [dbo].[MovePartitionSF];