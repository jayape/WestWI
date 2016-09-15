USE ProdReportServer;
GO

IF EXISTS(SELECT * FROM sys.objects WHERE name = 'TwoInOne' AND type = 'P')
DROP PROCEDURE dbo.TwoInOne;
GO

CREATE PROCEDURE dbo.TwoInOne
AS

DECLARE @plot	VARBINARY(MAX)

DECLARE @RScript NVARCHAR(MAX) = N'
	library(ggplot2)
	library(gridExtra)

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
	names(df) <- c("ReportName", "AvgTimeDataRetrieval", "AvgTimeProcessing", "AvgTimeRendering")

	image_file <- tempfile()
	jpeg(filename = image_file, width = 500, height = 500)

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
	
	plotbin <- readBin(file(image_file, "rb"), what=raw(), n=1e6)
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
	@input_data_1 = @SQLScript,
	@parallel = 1,
	@params = N'@plotbin varbinary(max) OUTPUT',
	@plotbin = @plot OUTPUT
WITH RESULT SETS ((ReportName VARCHAR(425), AvgTimeDataRetrieval NUMERIC(20, 5), AvgTimeProcessing NUMERIC(20, 5), AvgTimeRendering NUMERIC(20, 5)));

TRUNCATE TABLE dbo.Plots

INSERT INTO dbo.Plots
SELECT @plot AS plot;

GO

EXECUTE dbo.TwoInOne 
SELECT * FROM dbo.Plots