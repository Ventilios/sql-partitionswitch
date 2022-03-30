SET NOCOUNT ON;

DECLARE @StartDate DATE = '2019-02-01 00:00:00.000'
DECLARE @EndDate DATE = '2019-02-28 00:00:00.000'
DECLARE @BeginDateTime DATETIME; 
DECLARE @EndDateTime DATETIME; 

WHILE (@StartDate <= @EndDate)
BEGIN
	PRINT @StartDate;

	SELECT	@BeginDateTime = dateadd(day, datediff(day, 0, @StartDate), 0),
			@EndDateTime = dateadd(day, datediff(day, 0, @StartDate)+1, 0);

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
	WHERE eventDate >= @BeginDateTime -- 2019-02-01 00:00:00.000
	and eventDate < @EndDateTime; -- 2019-02-02 00:00:00.000
	
	-- Move partition into final table
	EXECUTE [dbo].[MovePartitionSF];

	-- Next day
	set @StartDate = DATEADD(day, 1, @StartDate);
END;

