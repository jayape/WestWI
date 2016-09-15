USE NHLStats;
GO

-- 1: Create procedure to grab data. Execute and insert into database table
IF EXISTS (SELECT * FROM sys.objects WHERE NAME = 'GetCHI2016' AND type = 'P')
DROP PROCEDURE dbo.GetCHI2016;
GO
 
CREATE PROCEDURE dbo.GetCHI2016 AS

DECLARE @RScript NVARCHAR(MAX) = N'
	library(XML)

	url <- "http://www.hockey-reference.com/teams/CHI/2016_games.html"

	tables <- readHTMLTable(url, stringsAsFactors = FALSE)
	temp <- tables$games
	names(temp) <- c("GP", "Date", "Time", "Loc", "Opponent", "GF", "GA", "Result", "OT", "W", "L", "OL", "Streak", "Blank1", 
					"tS", "tPIM", "tPPG", "tPPO", "tSHG", "Blank2", "oS","oPIM", "oPPG", "oPPO", "oSHG", "Att", "LOG", "Notes")
	temp <- subset(temp, temp$GP  != "GP" & temp$Date != "Cumulative" & temp$Date != "Team" & temp$Result != "")
	temp <- temp[, c(1, 2, 4:9, 15:19, 21:27)]

	temp$GP <- as.integer(temp$GP)
	temp$Date <- as.POSIXct(temp$Date)
	temp$Loc <- as.character(temp$Loc)
	temp$Loc[temp$Loc == "@"] <- "A"
	temp$Loc[temp$Loc == ""] <- "H"
	temp$Loc <- as.factor(temp$Loc)
	temp$GF <- as.integer(temp$GF)
	temp$GA <- as.integer(temp$GA)
	temp$Result <- as.factor(temp$Result)
	temp$OT[temp$OT == ""] <- "REG"
	temp$OT <- as.factor(temp$OT)
	temp$tS <- as.integer(temp$tS)
	temp$tPIM <- as.integer(temp$tPIM)
	temp$tPPG <- as.integer(temp$tPPG)
	temp$tPPO <- as.integer(temp$tPPO)
	temp$tSHG <- as.integer(temp$tSHG)
	temp$oS <- as.integer(temp$oS)
	temp$oPIM <- as.integer(temp$oPIM)
	temp$oPPG <- as.integer(temp$oPPG)
	temp$oPPO <- as.integer(temp$oPPO)
	temp$oSHG <- as.integer(temp$oSHG)
	temp$Att <- gsub("[[:punct:]]","", temp[, 19])
	temp$Att <- as.integer(temp$Att)
	temp$diff <- temp$GF - temp$GA

	chi2016 <- temp'

DECLARE @SQLScript NVARCHAR(MAX) = N''

EXEC sp_execute_external_script
	@language = N'R',
	@script = @RScript,
  	@input_data_1 = @SQLScript,
	@output_data_1_name = N'chi2016'
WITH RESULT SETS ((GP TINYINT, [Date] DATE, Loc CHAR(1), Opponent CHAR(100), GF TINYINT, GA TINYINT, [Result] CHAR(1), OT CHAR(3), tS TINYINT, tPIM TINYINT, tPPG TINYINT, 
				   tPPO TINYINT, tSH TINYINT, oS TINYINT, oPIM TINYINT, oPPG TINYINT, oPPO TINYINT, oSHG TINYINT, Att INT, [LOG] CHAR(4), diff SMALLINT));
GO


-- 02: Create procedure for basic graph
IF EXISTS (SELECT * FROM sys.objects WHERE NAME = 'PlotGoals' AND type = 'P')
DROP PROCEDURE dbo.PlotGoals;
GO

CREATE PROCEDURE dbo.PlotGoals AS

DECLARE @RScript nvarchar(max) = N'
	image_file <- tempfile()
	jpeg(filename = image_file, width = 500, height = 500)
			
	par(mfrow=c(2,2))
	hist(chi2016$GF[chi2016$Loc == "H"], freq=F, col = "lightblue", main = "Home Goals Scored", xlab = "Number of Goals")
	curve(dnorm(x, mean(chi2016$GF[chi2016$Loc == "H"]), sd(chi2016$GF[chi2016$Loc == "H"])), add=T)
	hist(chi2016$GA[chi2016$Loc == "H"], freq=F, col = "orangered", main = "Home Goals Allowed", xlab = "Number of Goals")
	curve(dnorm(x, mean(chi2016$GA[chi2016$Loc == "H"]), sd(chi2016$GA[chi2016$Loc == "H"])), add=T)
	hist(chi2016$GF[chi2016$Loc == "A"], freq=F, col = "lightblue", main = "Away Goals Scored", xlab = "Number of Goals")
	curve(dnorm(x, mean(chi2016$GF[chi2016$Loc == "A"]), sd(chi2016$GF[chi2016$Loc == "A"])), add=T)
	hist(chi2016$GA[chi2016$Loc == "A"], freq=F, col = "orangered", main = "Away Goals Allowed", xlab = "Number of Goals")
	curve(dnorm(x, mean(chi2016$GA[chi2016$Loc == "A"]), sd(chi2016$GA[chi2016$Loc == "A"])), add=T)
		
	dev.off()
	OutputDataSet <- data.frame(data=readBin(file(image_file, "rb"), what=raw(), n=1e6))'

DECLARE @SQLScript nvarchar(max) = '
	SELECT Loc, GF, GA
	FROM dbo.CHI2016'

EXEC sp_execute_external_script
	@language = N'R',
	@script = @RScript,
	@input_data_1 = @SQLScript,
	@input_data_1_name = N'chi2016'
WITH RESULT SETS ((Plot VARBINARY(MAX)));
GO

-- 3: Create summary data procedure
IF EXISTS (SELECT * FROM sys.objects WHERE NAME = 'SummarizeCHI2016' AND type = 'P')
DROP PROCEDURE dbo.SummarizeCHI2016;
GO
 
CREATE PROCEDURE dbo.SummarizeCHI2016 AS

DECLARE @RScript NVARCHAR(MAX) = N'
	c <- data.frame(table(chi2016$Loc, chi2016$Result == "L"))
	names(c) <- c("Loc", "Result", "Count")
	c$Result <- as.character(c$Result)
	c$Result[c$Result == "FALSE"] <- "W"
	c$Result[c$Result == "TRUE"] <- "L"
	c$Result <- as.factor(c$Result)

	d <- rbind(colSums(subset(chi2016[, c(5, 6, 9:18,21)], chi2016$Loc == "A" & chi2016$Result == "W")))
	d <- rbind(d, colSums(subset(chi2016[, c(5, 6, 9:18,21)], chi2016$Loc == "H" & chi2016$Result == "W")))
	d <- rbind(d, colSums(subset(chi2016[, c(5, 6, 9:18,21)], chi2016$Loc == "A" & chi2016$Result == "L")))
	d <- rbind(d, colSums(subset(chi2016[, c(5, 6, 9:18,21)], chi2016$Loc == "H" & chi2016$Result == "L")))
	
	t <- cbind(table(chi2016$Loc), c)
	names(t) <- c("Var1", "GP", "Loc", "Result", "Count")

	df <- cbind(t[, c(2:5)], d)

	df$GFAvg <- df$GF / df$ Count
	df$GAAvg <- df$GA / df$ Count
	df$AvgDiff <- df$GFAvg - df$GAAvg
	df$Pct <- df$Count / df$GP
	df$PP <- df$tPPG / df$tPPO
	df$PK <- 1 - (df$oPPG / df$oPPO)'

DECLARE @SQLScript NVARCHAR(MAX) = N'
	SELECT * FROM dbo.CHI2016'

EXEC sp_execute_external_script
	@language = N'R',
	@script = @RScript,
  	@input_data_1 = @SQLScript,
	@input_data_1_name = N'chi2016',
	@output_data_1_name = N'df'
WITH RESULT SETS ((GP TINYINT, Loc CHAR(1), [Result] CHAR(1), [Count] TINYINT, GF SMALLINT, GA SMALLINT,  tS SMALLINT, tPIM SMALLINT, tPPG SMALLINT, 
				   tPPO SMALLINT, tSH SMALLINT, oS SMALLINT, oPIM SMALLINT, oPPG SMALLINT, oPPO SMALLINT, oSHG SMALLINT, diff SMALLINT, 
				   GFAvg DECIMAL(7, 6), GAAvg DECIMAL(7, 6), AvgDiff DECIMAL(7, 6), Pct DECIMAL(7, 6), PP DECIMAL(7, 6), PK DECIMAL(7, 6)));
GO

-- 4: Create summary data graph procedure
IF EXISTS (SELECT * FROM sys.objects WHERE NAME = 'SummarizeCHI2016Graphs' AND type = 'P')
DROP PROCEDURE dbo.SummarizeCHI2016Graphs;
GO
 
CREATE PROCEDURE dbo.SummarizeCHI2016Graphs AS

DECLARE @RScript NVARCHAR(MAX) = N'
	library(gridExtra)
	library(ggplot2)

	image_file <- tempfile()
	jpeg(filename = image_file, width = 500, height = 500)

	c <- data.frame(table(chi2016$Loc, chi2016$Result == "L"))
	names(c) <- c("Loc", "Result", "Count")
	c$Result <- as.character(c$Result)
	c$Result[c$Result == "FALSE"] <- "W"
	c$Result[c$Result == "TRUE"] <- "L"
	c$Result <- as.factor(c$Result)

	d <- rbind(colSums(subset(chi2016[, c(5, 6, 9:18,21)], chi2016$Loc == "A" & chi2016$Result == "W")))
	d <- rbind(d, colSums(subset(chi2016[, c(5, 6, 9:18,21)], chi2016$Loc == "H" & chi2016$Result == "W")))
	d <- rbind(d, colSums(subset(chi2016[, c(5, 6, 9:18,21)], chi2016$Loc == "A" & chi2016$Result == "L")))
	d <- rbind(d, colSums(subset(chi2016[, c(5, 6, 9:18,21)], chi2016$Loc == "H" & chi2016$Result == "L")))
	
	t <- cbind(table(chi2016$Loc), c)
	names(t) <- c("Var1", "GP", "Loc", "Result", "Count")

	df <- cbind(t[, c(2:5)], d)

	df$GFAvg <- df$GF / df$ Count
	df$GAAvg <- df$GA / df$ Count
	df$AvgDiff <- df$GFAvg - df$GAAvg
	df$Pct <- df$Count / df$GP
	df$PP <- df$tPPG / df$tPPO
	df$PK <- 1 - (df$oPPG / df$oPPO)

	plot1 <- ggplot(df, aes(x=Result, y=GFAvg, fill=Loc)) + 
            geom_bar(position="dodge", color = "black", stat="identity") +
            geom_text(aes(label=format(round(df$GFAvg, 2), nsmall = 2)), vjust=1.5, color="black", 
                          position=position_dodge(.9), size=3) +
            ggtitle("Average Goals Scored") +
            theme(legend.title = element_text(face="italic", size = 14))

	plot2 <- ggplot(df, aes(x=Result, y=GAAvg, fill=Loc)) + 
            geom_bar(position="dodge", color = "black", stat="identity") +
            geom_text(aes(label=format(round(df$GAAvg, 2), nsmall = 2)), vjust=1.5, color="black", 
                          position=position_dodge(.9), size=3) +
            ggtitle("Average Goals Allowed") +
            theme(legend.title = element_text(face="italic", size = 14))

	plot3 <- ggplot(df, aes(x=Result, y=PP, fill=Loc)) + 
            geom_bar(position="dodge", color = "black", stat="identity") +
            geom_text(aes(label=format(round(df$PP, 2), nsmall = 2)), vjust=1.5, color="black", 
                          position=position_dodge(.9), size=3) +
            ggtitle("Average PP Percentage") +
            theme(legend.title = element_text(face="italic", size = 14))

	plot4 <- ggplot(df, aes(x=Result, y=PK, fill=Loc)) + 
            geom_bar(position="dodge", color = "black", stat="identity") +
            geom_text(aes(label=format(round(df$PK, 2), nsmall = 2)), vjust=1.5, color="black", 
                          position=position_dodge(.9), size=3) +
            ggtitle("Average PK Percentage") +
            theme(legend.title = element_text(face="italic", size = 14))

	plotList <- list(plot1, plot2, plot3, plot4)
	do.call(grid.arrange, plotList)

	dev.off()
	dfg <- data.frame(data=readBin(file(image_file, "rb"), what=raw(), n=1e6))'

DECLARE @SQLScript NVARCHAR(MAX) = N'
	SELECT * FROM dbo.CHI2016'

EXEC sp_execute_external_script
	@language = N'R',
	@script = @RScript,
  	@input_data_1 = @SQLScript,
	@input_data_1_name = N'chi2016',
	@output_data_1_name = N'dfg'
WITH RESULT SETS ((Plot VARBINARY(MAX)));
GO


-- 05: Use first procedure to populate data for other procedures.
-- Delete data from previous runs if you haven't recreated the database of procedure.
TRUNCATE TABLE dbo.CHI2016;
GO

INSERT INTO dbo.CHI2016
EXEC dbo.GetCHI2016;
GO

SELECT * FROM dbo.CHI2016;

EXEC dbo.SummarizeCHI2016;