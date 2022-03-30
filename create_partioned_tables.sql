------------------------------------------------------------------------------------------
-- Create Partitioning function 
------------------------------------------------------------------------------------------
declare @lastDateId datetime =  {ts '2019-01-01 00:00:00'}
declare @maxDateId datetime =  dateadd(year,1,{ts '2019-01-01 00:00:00'})

CREATE PARTITION FUNCTION [pf_SFByDate](datetime) 
AS RANGE RIGHT FOR VALUES (@lastDateid)

-- Add 1 partition per day
while @lastDateId < @maxDateid
Begin
 set @lastDateId=@lastDateId+1

 Alter partition function [pf_SFByDate]()
	split range (@LastDateid)
End

------------------------------------------------------------------------------------------
-- Create Partitioning Scheme 
------------------------------------------------------------------------------------------
CREATE PARTITION SCHEME [ps_SFbyDate] 
AS PARTITION [pf_SFByDate]  ALL TO ([PRIMARY])
GO


------------------------------------------------------------------------------------------
-- Create Source table tClus
------------------------------------------------------------------------------------------
if object_id('dbo.tClus') is not null 
	drop table dbo.tClus;
go 

create table dbo.tClus(id uniqueidentifier, 
eventDate datetime,
c2 int, 
c3 varchar(50),
c4 bigint
,c6 varbinary(512)
 CONSTRAINT [PK_tClus] PRIMARY KEY CLUSTERED 
(
	[ID] ASC,
	eventDate ASC
)
)
on [ps_SFbyDate](eventDate)


------------------------------------------------------------------------------------------
-- Populate partitoned table
------------------------------------------------------------------------------------------
-- insert millions of rows
-- 50 million rows in 22 min
insert into dbo.tClus
select
 newid()
,dateadd(second,(RAND(checksum(newid())) * 31535999),  {ts '2019-01-01 00:00:00.000'})
,convert(int,rand(checksum(newid())) * 2147483647 )
,REPLICATE(char(convert(int,rand(checksum(newid())) * 256)),convert(int,rand(checksum(newid())) * 50))
,convert(bigint,rand(checksum(newid())) * 9223372036854775807 )
, HASHBYTES('SHA2_256', REPLICATE(char(convert(int,rand(checksum(newid())) * 256)),convert(int,rand(checksum(newid())) * 1024)))
from (select top 1000 1 x from sys.all_columns) tt1
cross join (select top 1000 1 x from sys.all_columns) tt2
go 50


------------------------------------------------------------------------------------------
-- Create partitioned target tables
------------------------------------------------------------------------------------------

-- First Stage table
if object_id('dbo.StageTable') is not null 
	drop table StageTable
go 

create table StageTable(
	id uniqueidentifier, 
	eventDate datetime,
	c2 int, 
	c3 varchar(50),
	c4 bigint
	,c6 varbinary(512)
    CONSTRAINT [PK_state] PRIMARY KEY CLUSTERED 
	(
		[ID] ASC,
		eventDate ASC
	)
)
on [ps_SFbyDate](eventDate)

-- Second Stage table
if object_id('dbo.StageTable2') is not null 
	drop table StageTable2
go 

create table StageTable2 (
	id uniqueidentifier, 
	eventDate datetime,
	c2 int, 
	c3 varchar(50),
	c4 bigint
	,c6 varbinary(512)
	 CONSTRAINT [PK_state2] PRIMARY KEY CLUSTERED 
	(
		[ID] ASC,
		eventDate ASC
	)
)
on [ps_SFbyDate](eventDate)


-- Final table used to switch data into
if object_id('dbo.FinalTable') is not null 
	drop table FinalTable
go 

create table FinalTable(
	id uniqueidentifier, 
	eventDate datetime,
	c2 int, 
	c3 varchar(50),
	c4 bigint
	,c6 varbinary(512)
	 CONSTRAINT [PK_final] PRIMARY KEY CLUSTERED 
	(
		[ID] ASC,
		eventDate ASC
	)
)
on [ps_SFbyDate](eventDate)


--------------------------------------------------------------------------------
-- Scripts to check partition row count
--------------------------------------------------------------------------------
SELECT * 
FROM sys.dm_db_partition_stats AS pstats
WHERE pstats.object_id = OBJECT_ID('FinalTable')
	--AND index_id = 0 -- Heap
	AND index_id = 1 -- Clustered
	AND pstats.row_count > 0

	
SELECT * 
FROM sys.dm_db_partition_stats AS pstats
WHERE pstats.object_id = OBJECT_ID('StageTable')
	--AND index_id = 0 -- Heap
	AND index_id = 1 -- Clustered
	AND pstats.row_count > 0

		
SELECT * 
FROM sys.dm_db_partition_stats AS pstats
WHERE pstats.object_id = OBJECT_ID('StageTable2')
	--AND index_id = 0 -- Heap
	AND index_id = 1 -- Clustered
	AND pstats.row_count > 0
