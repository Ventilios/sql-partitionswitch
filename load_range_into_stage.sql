SET NOCOUNT ON;

DECLARE @StartDate DATETIME = '2019-09-01 00:00:00.000';
DECLARE @EndDate DATETIME;

PRINT @StartDate;

-- Calculate first day of the next month
SELECT @EndDate = dateadd(month, datediff(month, 0, @StartDate)+1, 0) 

SELECT @StartDate, @EndDate;

-- Load data into staging table
INSERT INTO dbo.StageTable2 WITH(TABLOCK) (
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
WHERE eventDate >= dateadd(day, datediff(day, 0, @StartDate), 0)
and eventDate < @EndDate;


--PRINT 'Move partition into final table.'
EXECUTE [dbo].[MovePartitionSF] @StageTable = 'dbo.StageTable2'; 