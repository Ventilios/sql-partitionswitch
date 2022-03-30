SET NOCOUNT ON;

DECLARE @StartDate DATETIME = '2019-01-01 00:00:00.000';
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

--PRINT 'Move partition into final table.'
EXECUTE [dbo].[MovePartitionSF];
