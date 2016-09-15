
-- 01: View number of threads. Default is number of cores
DECLARE @RScript NVARCHAR(MAX) = N'
	myThreads <- getMKLthreads()
	OutputDataSet <- as.data.frame(myThreads)'
	
EXECUTE sp_execute_external_script
	@language=N'R',
	@script = @RScript
WITH RESULT SETS ((Results INT));
GO

-- 02: Change number of threads to 1
DECLARE @RScript NVARCHAR(MAX) = N'
	setMKLthreads(1)
	myThreads <- getMKLthreads()
	OutputDataSet <- as.data.frame(myThreads)'

EXECUTE sp_execute_external_script
	@language=N'R',
	@script = @RScript
WITH RESULT SETS ((Results INT));
GO

-- 03: Same as #2 but we'll see what happens if we set value too high
-- Number will be max and message will show why
DECLARE @RScript NVARCHAR(MAX) = N'
	setMKLthreads(16)
	myThreads <- getMKLthreads()
	OutputDataSet <- as.data.frame(myThreads)'

EXECUTE sp_execute_external_script
	@language=N'R',
	@script = @RScript
WITH RESULT SETS ((Results INT));
GO