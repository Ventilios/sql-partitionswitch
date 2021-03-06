SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[MovePartitionSF] (@FinalTable VARCHAR(50) = 'FinalTable', @StageTable VARCHAR(50) = 'StageTable')
AS
BEGIN

	DECLARE @Partition INT,
			@DynamicSQL NVARCHAR(500)

	CheckForExistingData:
		SELECT @Partition = COALESCE(MIN(pstats.partition_number),0)
		FROM sys.dm_db_partition_stats AS pstats
		WHERE pstats.object_id = OBJECT_ID(@StageTable)
		  --AND index_id = 0 -- Heap
		  AND index_id = 1 -- Clustered
		  AND pstats.row_count > 0

	IF @Partition > 0
	BEGIN
		SELECT @DynamicSQL = 'ALTER TABLE ' + @StageTable + ' SWITCH PARTITION ' + CONVERT(VARCHAR(10),@Partition) + ' TO ' + @FinalTable + ' PARTITION '  + CONVERT(VARCHAR(10),@Partition)
		EXEC sp_executesql @DynamicSQL

		GOTO CheckForExistingData;
	END
END