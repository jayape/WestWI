-- Simple scripts to work with data from database
USE AdventureWorks2016CTP3;
GO

-- 01: Input simple SQL query and send back to output 
DECLARE @RScript NVARCHAR(MAX) = N'
	OutputDataSet <- InputDataSet'

DECLARE @SQLScript NVARCHAR(MAX) = N'
	SELECT soh.CustomerID, soh.OrderDate, sod.UnitPrice
	FROM Sales.SalesOrderHeader AS soh
	INNER JOIN Sales.SalesOrderDetail AS sod ON soh.SalesOrderID = sod.SalesOrderID
	WHERE YEAR(soh.OrderDate) = 2013'

EXECUTE sp_execute_external_script
	@language = N'R',
	@script = @RScript,
	@input_data_1 = @SQLScript
WITH RESULT SETS ((CustomerID VARCHAR(20), OrderDate DATETIME, AvgUnitPrice MONEY));
GO

-- 02: Input same query but get average unit price by customer id
DECLARE @RScript NVARCHAR(MAX) = N'
	df <- InputDataSet
	df$CustomerID <- as.factor(df$CustomerID)
	col1 <- levels(df$CustomerID)
	col2 <- tapply(df$UnitPrice, df$CustomerID, mean)
	OutputDataSet <- data.frame(col1, col2)'

DECLARE @SQLScript NVARCHAR(MAX) = N'
	SELECT soh.CustomerID, soh.OrderDate, sod.UnitPrice
	FROM Sales.SalesOrderHeader AS soh
	INNER JOIN Sales.SalesOrderDetail AS sod ON soh.SalesOrderID = sod.SalesOrderID
	WHERE YEAR(soh.OrderDate) = 2013'

EXECUTE sp_execute_external_script
	@language = N'R',
	@script = @RScript,
	@input_data_1 = @SQLScript
WITH RESULT SETS ((CustomerID VARCHAR(20), AvgUnitPrice MONEY));
GO

-- 03: Same as #2 but get average of unit price by month
DECLARE @RScript NVARCHAR(MAX) = N'
	df <- InputDataSet
	df$month <- factor(format(df$OrderDate, "%B"), levels = month.name)
	col1 <- levels(df$month)
	col2 <- tapply(df$UnitPrice, df$month, mean)
	OutputDataSet <- data.frame(col1, col2)'

DECLARE @SQLScript NVARCHAR(MAX) = N'
	SELECT soh.CustomerID, soh.OrderDate, sod.UnitPrice
	FROM Sales.SalesOrderHeader AS soh
	INNER JOIN Sales.SalesOrderDetail AS sod ON soh.SalesOrderID = sod.SalesOrderID
	WHERE YEAR(soh.OrderDate) = 2013'

EXECUTE sp_execute_external_script
	@language = N'R',
	@script = @RScript,
	@input_data_1 = @SQLScript
WITH RESULT SETS (([Month] VARCHAR(20), AvgUnitPrice MONEY));
GO


-- 04: Create simple plot with monthly averages
USE AdventureWorks2016CTP3;
GO

IF EXISTS(SELECT 1 FROM sys.objects WHERE name = 'PlotMonthlyAverage')
DROP PROCEDURE dbo.PlotMonthlyAverage;
GO

CREATE PROCEDURE dbo.PlotMonthlyAverage
AS

DECLARE @RScript NVARCHAR(MAX) = N'
	library(ggplot2)
	image_file <- tempfile()
	jpeg(filename = image_file, width = 500, height = 500)
	
	df <- InputDataSet
	df$month <- factor(format(df$OrderDate, "%B"), levels = month.name)
	col1 <- levels(df$month)
	col2 <- tapply(df$UnitPrice, df$month, mean)
	monthAvg <- data.frame(col1, col2)
	names(monthAvg) <- c("Month", "AvgUnitPrice")
	
	print(ggplot(monthAvg, aes(x=Month, y=AvgUnitPrice)) + geom_bar(stat="identity", fill="lightblue", colour="black"))
	dev.off()
	OutputDataSet <- data.frame(data=readBin(file(image_file, "rb"), what=raw(), n=1e6))'

DECLARE @SQLScript NVARCHAR(MAX) = N'
	SELECT soh.CustomerID, soh.OrderDate, sod.UnitPrice
	FROM Sales.SalesOrderHeader AS soh
	INNER JOIN Sales.SalesOrderDetail AS sod ON soh.SalesOrderID = sod.SalesOrderID
	WHERE YEAR(soh.OrderDate) = 2013'

EXECUTE sp_execute_external_script
	@language = N'R',
	@script = @RScript,
	@input_data_1 = @SQLScript
WITH RESULT SETS ((BarPlot VARBINARY(MAX)))
GO


-- Execute procedure to view results
EXEC dbo.PlotMonthlyAverage;
GO