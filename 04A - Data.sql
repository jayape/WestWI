-- Simple scripts to work with data from database
USE ProdReportServer;
GO

-- 01: Input simple SQL query and send back to output 
DECLARE @RScript NVARCHAR(MAX) = N'
	OutputDataSet <- InputDataSet'

DECLARE @SQLScript NVARCHAR(MAX) = N'
	SELECT 
		CAST(C.Name AS VARCHAR(425)) AS Name, 
		CAST(ELS.UserName AS VARCHAR(260)) AS UserName, 
		ELS.TimeStart, 
		ELS.TimeEnd, 
		ELS.TimeDataRetrieval, 
		ELS.TimeProcessing, 
		ELS.TimeRendering, 
		CAST(ELS.Status AS VARCHAR(40)) AS Status, 
		ELS.ByteCount, 
		ELS.[RowCount]
	FROM Catalog AS C 
	INNER JOIN ExecutionLogStorage AS ELS 
		ON C.ItemID = ELS.ReportID
	WHERE ELS.TimeStart BETWEEN ''5/2/2016'' AND ''5/3/2016'';'

EXECUTE sp_execute_external_script
	@language = N'R',
	@script = @RScript,
	@input_data_1 = @SQLScript
WITH RESULT SETS ((Name VARCHAR(425), UserName VARCHAR(260), TimeStart DATETIME, TimeEnd DATETIME, TimeDataRetrieval INT,
				   TimeProcessing INT, TimeRendering INT, Status VARCHAR(40), ByteCount BIGINT, [RowCount] BIGINT));
GO

-- 02: Input same query but get average times for top ten reports
DECLARE @RScript NVARCHAR(MAX) = N'
	reportData <- InputDataSet

	topTen <- head(summary(subset(reportData$Name, reportData$Name != "WakeUpWorld")), 10)
	filteredNames <- names(topTen)

	filteredReports <- (reportData$Name %in% filteredNames)
	filteredData <- reportData[filteredReports, c(1,5:10)]

	filteredData$Name <- factor(filteredData$Name)
	filteredData$Status <- factor(filteredData$Status)

	d <- data.frame(tapply(filteredData$TimeDataRetrieval, filteredData$Name, mean))
	d <- cbind(d, tapply(filteredData$TimeProcessing, filteredData$Name, mean))
	d <- cbind(d, tapply(filteredData$TimeRendering, filteredData$Name, mean))
	df <- cbind(rownames(d), d)
	names(df) <- c("ReportName", "AvgDataRetrieval", "AvgProcessing", "AvgRendering")

	OutputDataSet <- df'

DECLARE @SQLScript NVARCHAR(MAX) = N'
	SELECT 
		CAST(C.Name AS VARCHAR(425)) AS Name, 
		CAST(ELS.UserName AS VARCHAR(260)) AS UserName, 
		ELS.TimeStart, 
		ELS.TimeEnd, 
		ELS.TimeDataRetrieval, 
		ELS.TimeProcessing, 
		ELS.TimeRendering, 
		CAST(ELS.Status AS VARCHAR(40)) AS Status, 
		ELS.ByteCount, 
		ELS.[RowCount]
	FROM Catalog AS C 
	INNER JOIN ExecutionLogStorage AS ELS 
		ON C.ItemID = ELS.ReportID
	WHERE ELS.TimeStart BETWEEN ''5/2/2016'' AND ''5/3/2016'';
'

EXECUTE sp_execute_external_script
	@language = N'R',
	@script = @RScript,
	@input_data_1 = @SQLScript
WITH RESULT SETS ((ReportName VARCHAR(425), AvgTimeDataRetrieval NUMERIC(10, 5), AvgTimeProcessing NUMERIC(10, 5), AvgTimeRendering NUMERIC(10, 5)));
GO

-- 03: Same as #2 but wrap inside separate procedure.
--     Run the procedure to populate a table,
--     then use, the data in the table to create a plot.

IF EXISTS(SELECT * FROM sys.objects WHERE name = 'TopTenReports' AND type = 'P')
DROP PROCEDURE dbo.TopTenReports;
GO

CREATE PROCEDURE TopTenReports (@StartDate DATETIME, @EndDate DATETIME)
AS

TRUNCATE TABLE dbo.TopTenReportAverages;

DECLARE @RScript NVARCHAR(MAX) = N'
	reportData <- InputDataSet

	topTen <- head(summary(subset(reportData$Name, reportData$Name != "WakeUpWorld")), 10)
	filteredNames <- names(topTen)

	filteredReports <- (reportData$Name %in% filteredNames)
	filteredData <- reportData[filteredReports, c(1,5:10)]

	filteredData$Name <- factor(filteredData$Name)
	filteredData$Status <- factor(filteredData$Status)

	d <- data.frame(tapply(filteredData$TimeDataRetrieval, filteredData$Name, mean))
	d <- cbind(d, tapply(filteredData$TimeProcessing, filteredData$Name, mean))
	d <- cbind(d, tapply(filteredData$TimeRendering, filteredData$Name, mean))
	df <- cbind(rownames(d), d)
	names(df) <- c("ReportName", "AvgDataRetrieval", "AvgProcessing", "AvgRendering")

	OutputDataSet <- df'

DECLARE @SQLScript NVARCHAR(MAX) = N'
	SELECT 
		CAST(C.Name AS VARCHAR(425)) AS Name, 
		CAST(ELS.UserName AS VARCHAR(260)) AS UserName, 
		ELS.TimeStart, 
		ELS.TimeEnd, 
		ELS.TimeDataRetrieval, 
		ELS.TimeProcessing, 
		ELS.TimeRendering, 
		CAST(ELS.Status AS VARCHAR(40)) AS Status, 
		ELS.ByteCount, 
		ELS.[RowCount]
	FROM Catalog AS C 
	INNER JOIN ExecutionLogStorage AS ELS 
		ON C.ItemID = ELS.ReportID
	WHERE ELS.TimeStart BETWEEN ''' + CAST(@StartDate AS VARCHAR(12)) + ''' AND ''' + CAST(@EndDate AS VARCHAR(12)) + ''';'

EXECUTE sp_execute_external_script
	@language = N'R',
	@script = @RScript,
	@input_data_1 = @SQLScript
WITH RESULT SETS ((ReportName VARCHAR(425), AvgTimeDataRetrieval NUMERIC(10, 5), AvgTimeProcessing NUMERIC(10, 5), AvgTimeRendering NUMERIC(10, 5)));
GO


INSERT INTO dbo.TopTenReportAverages
EXEC dbo.TopTenReports '5/2/2016', '5/3/2016'
GO

SELECT * FROM dbo.TopTenReportAverages

-- Create procedure for plotting averages

IF EXISTS(SELECT * FROM sys.objects WHERE name = 'TopTenReportAveragesPlot' AND type = 'P')
DROP PROCEDURE dbo.TopTenReportAveragesPlot;
GO

CREATE PROCEDURE dbo.TopTenReportAveragesPlot (@StartDate DATETIME, @EndDate DATETIME)
AS

INSERT INTO dbo.TopTenReportAverages
EXEC dbo.TopTenReports @StartDate, @EndDate;

DECLARE @RScript NVARCHAR(MAX) = N'
	library(ggplot2)
	library(gridExtra)

	image_file <- tempfile()
	jpeg(filename = image_file, width = 1000, height = 1500)

	df <- InputDataSet

	plot1 <- ggplot(df, aes(x=ReportName, y=AvgTimeDataRetrieval)) + 
			 geom_bar(position="dodge", fill= "lightblue",  color = "black", stat="identity") +
             geom_text(aes(label=format(round(df$AvgTimeDataRetrieval / 1000, 2), nsmall = 2)), vjust=0.1, color="black", 
                           position=position_dodge(.9), size=5) +
             ggtitle("Average Data Retrieval in Seconds") +
             theme(legend.title = element_text(face="italic", size = 14))

	plot2 <- ggplot(df, aes(x=ReportName, y=AvgTimeProcessing)) + 
             geom_bar(position="dodge", fill= "red", color = "black", stat="identity") +
             geom_text(aes(label=format(round(df$AvgTimeProcessing / 1000, 2), nsmall = 2)), vjust=0.1, color="black", 
                           position=position_dodge(.9), size=5) +
             ggtitle("Average Time Processing in Seconds") +
             theme(legend.title = element_text(face="italic", size = 14))

	plot3 <- ggplot(df, aes(x=ReportName, y=AvgTimeRendering)) + 
             geom_bar(position="dodge", fill= "yellow",color = "black", stat="identity") +
             geom_text(aes(label=format(round(df$AvgTimeRendering / 1000, 2), nsmall = 2)), vjust=0.1, color="black", 
                           position=position_dodge(.9), size=5) +
             ggtitle("Average Time Rendering in Seconds") +
             theme(legend.title = element_text(face="italic", size = 14))

	plotList <- list(plot1, plot2, plot3)
	do.call(grid.arrange, plotList)
	
	dev.off()
	OutputDataSet <- data.frame(data=readBin(file(image_file, "rb"), what=raw(), n=1e6))'

DECLARE @SQLScript NVARCHAR(MAX) = N'
	SELECT * FROM dbo.TopTenReportAverages'

EXECUTE sp_execute_external_script
	@language = N'R',
	@script = @RScript,
	@input_data_1 = @SQLScript
WITH RESULT SETS((Plot varbinary(max)));
GO

-- Execute procedure to view results
EXEC dbo.TopTenReportAveragesPlot '5/2/2016', '5/3/2016';
GO