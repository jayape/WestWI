-- 1: Most basic statement
EXECUTE sp_execute_external_script
	@language = N'R',
	@script = N'OutputDataSet <- InputDataSet',
    @input_data_1 = N'SELECT 1 as Col'
WITH RESULT SETS ((col INT));
GO

-- 2: Nothing returned
EXECUTE sp_execute_external_script
	@language = N'R',
	@script = N'myVariable <- 2';
GO

-- 3: Read .csv file and view data types of data set
EXECUTE sp_execute_external_script
	@language = N'R',
	@script = N'
	myData <- read.csv(''C:/R Sessions/Data/NHL2016.csv'', header = TRUE)
	Output <- str(myData)'
WITH RESULT SETS UNDEFINED;
GO

-- 4: Return 1 string from 2 column input
DECLARE @RScript NVARCHAR(MAX) = N' 
	myString <- paste(Input$FirstName, Input$LastName)
	Output <- as.data.frame(myString)' 

DECLARE @SQLScript NVARCHAR(MAX) = N'
	SELECT ''Hello'' AS FirstName, ''World!'' AS LastName'

EXECUTE sp_execute_external_script
	@language=N'R',
	@script = @RScript,
	@input_data_1 = @SQLScript,
	@input_data_1_name = N'Input',
	@output_data_1_name = N'Output'
WITH RESULT SETS ((myPhrase VARCHAR(20)));
GO


-- 5: Set working directory, source a file and use functions
DECLARE @RScript NVARCHAR(MAX) = N' 
	setwd(''C:/R Sessions'')
	source(''MyFunctions.r'')
	howhot <- celcius(Input$FahrenheitTemp)
	Output <- as.data.frame(howhot)' 

DECLARE @SQLScript NVARCHAR(MAX) = N'
	SELECT 75 AS FahrenheitTemp'

EXECUTE sp_execute_external_script
	@language=N'R',
	@script = @RScript,
	@input_data_1 = @SQLScript,
	@input_data_1_name = N'Input',
	@output_data_1_name = N'Output'
WITH RESULT SETS ((convertedTemp NUMERIC(5, 2)));
GO