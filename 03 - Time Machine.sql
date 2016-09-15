
-- 01: View installed package info
DECLARE @RScript NVARCHAR(MAX) = N'
	InstalledPackages <- installed.packages();	
	PackageInfo <- InstalledPackages[,c(1:3)];
	OutputDataSet <- as.data.frame(PackageInfo);'

EXECUTE sp_execute_external_script
	@language=N'R',
	@script = @RScript
WITH RESULT SETS ((PackageName NVARCHAR(250), LibraryPath NVARCHAR(100), PackageVersion NVARCHAR(25)));
GO

-- 02: View default library path
DECLARE @RScript NVARCHAR(MAX) = N'
 	OutputDataSet <- as.data.frame(.libPaths())'

EXECUTE sp_execute_external_script
	@language=N'R',
	@script = @RScript
WITH RESULT SETS ((RSessionsPath VARCHAR(250)));
GO

-- 03: Set checkpoint and view the new library path for the session
DECLARE @RScript NVARCHAR(MAX) = N'
 	library(checkpoint)
	checkpoint(''2016-06-07'', "3.2.2", checkpointLocation = "C:\\R Sessions", verbose = TRUE)
	OutputDataSet <- as.data.frame(.libPaths())'

EXECUTE sp_execute_external_script
	@language=N'R',
	@script = @RScript
WITH RESULT SETS ((RSessionsPath VARCHAR(250)));
GO