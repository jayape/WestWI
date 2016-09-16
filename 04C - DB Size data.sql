USE DemoDB;
GO

IF EXISTS(SELECT * FROM sys.objects WHERE name = 'PlotDBSize' AND type = 'P')
DROP PROCEDURE dbo.PlotDBSize;
GO

CREATE PROCEDURE PlotDBSize AS

DECLARE @RScript NVARCHAR(MAX) = N'
	library(dplyr)
	library(ggplot2)
	library(gridExtra)
	
	image_file <- tempfile()
	jpeg(filename = image_file, width = 1200, height = 1000)

	db_filtered <- InputDataSet %>% filter(Servername %in% c(''PERTELLSQL1'', ''PERTELLSQL2'', ''PERTELLSQL3'', ''PERTELLSQL4''),
                                           DBName %in% c(''mis_db'', ''darwin_db'',''dialysis_db''),
                                           RunDate >= as.POSIXct(''2015-08-24'')) %>%
                           select(Servername, RunDate, DBName, Name, TotalSize, UsedSpace, FreeSpace)  

	db_filtered$Servername <- factor(db_filtered$Servername)
	db_filtered$DBName <- factor(db_filtered$DBName)
	db_filtered$Name <- factor(db_filtered$Name)
	db_filtered$TotalSize <- (db_filtered$TotalSize / 1024) / 1024
	db_filtered$UsedSpace <- (db_filtered$UsedSpace / 1024) / 1024
	db_filtered$FreeSpace <- (db_filtered$FreeSpace / 1024) / 1024

	plot1 <- ggplot(db_filtered %>% filter(Servername == ''PERTELLSQL1''), 
        aes(x=RunDate, y=UsedSpace)) + 
        geom_line(aes(color = factor(Name))) + 
        scale_color_discrete(name=''DB File'') +
        labs(title = ''Database Growth For PERTELLSQL1'', x = ''Date'', y = ''Used Space (GB)'')

	plot2 <- ggplot(db_filtered %>% filter(Servername == ''PERTELLSQL2''), 
        aes(x=RunDate, y=UsedSpace)) + 
        geom_line(aes(color = factor(Name))) + 
        scale_color_discrete(name=''DB File'') +
        labs(title = ''Database Growth For PERTELLSQL2'', x = ''Date'', y = ''Used Space (GB)'')

	plot3 <- ggplot(db_filtered %>% filter(Servername == ''PERTELLSQL3''), 
        aes(x=RunDate, y=UsedSpace)) + 
        geom_line(aes(color = factor(Name))) + 
        scale_color_discrete(name=''DB File'') +
        labs(title = ''Database Growth For PERTELLSQL3'', x = ''Date'', y = ''Used Space (GB)'')

	plot4 <- ggplot(db_filtered %>% filter(Servername == ''PERTELLSQL4''), 
        aes(x=RunDate, y=UsedSpace)) + 
        geom_line(aes(color = factor(Name))) + 
        scale_color_discrete(name=''DB File'') +
        labs(title = ''Database Growth For PERTELLSQL4'', x = ''Date'', y = ''Used Space (GB)'')

	myPlotList <- list(plot1, plot2, plot3, plot4)

	do.call(grid.arrange, c(myPlotList, list(ncol = 1)))  
	
	dev.off()
	OutputDataSet <- data.frame(data=readBin(file(image_file, "rb"), what=raw(), n=1e6))'

DECLARE @SQLScript NVARCHAR(MAX) = N'SELECT * FROM DBStats'

EXEC sp_execute_external_script
	@language = N'R',
	@script = @RScript,
  	@input_data_1 = @SQLScript
WITH RESULT SETS ((Plot VARBINARY(MAX)));
GO


exec PlotDBSize