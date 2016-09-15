USE master;

IF EXISTS(SELECT * FROM sys.databases WHERE name = 'NHLStats')
DROP DATABASE NHLStats;

CREATE DATABASE NHLStats ON PRIMARY 
(NAME = N'NHLStats', FILENAME = N'C:\SQL2016\Data\NHLStats.mdf' , SIZE = 4096KB , MAXSIZE = UNLIMITED, FILEGROWTH = 1024KB )
 LOG ON 
(NAME = N'NHLStats_log', FILENAME = N'C:\SQL2016\Data\NHLStats_log.ldf' , SIZE = 1024KB , MAXSIZE = 2048GB , FILEGROWTH = 1024KB);
GO

USE NHLStats;
GO

CREATE TABLE dbo.CHI2016(
	GP tinyint NULL,
	Date date NULL,
	Loc char(1) NULL,
	Opponent varchar(100) NULL,
	GF tinyint NULL,
	GA tinyint NULL,
	Result char(1) NULL,
	OT char(3) NULL,
	tS tinyint NULL,
	tPIM tinyint NULL,
	tPPG tinyint NULL,
	tPPO tinyint NULL,
	tSHG tinyint NULL,
	oS tinyint NULL,
	oPIM tinyint NULL,
	oPPG tinyint NULL,
	oPPO tinyint NULL,
	oSHG tinyint NULL,
	Att int NULL,
	[LOG] char(4) NULL,
	diff smallint NULL
);
GO

USE ProdReportServer;
GO

IF EXISTS(SELECT * FROM sys.objects WHERE name = 'TopTenReportAverages' AND type = 'U')
DROP TABLE dbo.TopTenReportAverages;
GO

CREATE TABLE dbo.TopTenReportAverages (
	ReportName	VARCHAR(425),
	AvgTimeDataRetrieval	NUMERIC(20, 5),
	AvgTimeProcessing	NUMERIC(20, 5),
	AvgTimeRendering NUMERIC(20, 5));
GO

IF EXISTS(SELECT * FROM sys.objects WHERE name = 'Plots' AND type = 'U')
DROP TABLE dbo.Plots;
GO

CREATE TABLE dbo.Plots (
	plot	VARBINARY(MAX));
GO

USE master;
GO

IF EXISTS (SELECT loginname FROM master.dbo.syslogins WHERE name = 'RDemo')
DROP LOGIN RDemo;

CREATE LOGIN RDemo WITH PASSWORD= 'Rdemo', CHECK_EXPIRATION = OFF, CHECK_POLICY = OFF; 

DROP USER IF EXISTS RDemo;
CREATE USER RDemo FOR LOGIN RDemo WITH DEFAULT_SCHEMA = dbo;
GRANT EXECUTE ANY EXTERNAL SCRIPT TO RDemo;
GO

--USE AdventureWorks2016CTP3;
--GO

--DROP USER IF EXISTS RDemo;
--CREATE USER RDemo FOR LOGIN RDemo WITH DEFAULT_SCHEMA = dbo;
--ALTER ROLE db_datareader ADD MEMBER RDemo;
--ALTER ROLE db_ddladmin ADD MEMBER RDemo;
--GRANT EXECUTE ON SCHEMA::dbo TO RDemo;
--GRANT EXECUTE ANY EXTERNAL SCRIPT TO RDemo;
--GO

USE NHLStats;
GO

DROP USER IF EXISTS RDemo;
CREATE USER RDemo FOR LOGIN RDemo WITH DEFAULT_SCHEMA = dbo;
ALTER ROLE db_datawriter ADD MEMBER RDemo;
ALTER ROLE db_datareader ADD MEMBER RDemo;
ALTER ROLE db_ddladmin ADD MEMBER RDemo;
GRANT EXECUTE ON SCHEMA::dbo TO RDemo;
GRANT EXECUTE ANY EXTERNAL SCRIPT TO RDemo;
GO


USE ProdReportServer;
GO

DROP USER IF EXISTS RDemo;
CREATE USER RDemo FOR LOGIN RDemo WITH DEFAULT_SCHEMA = dbo;
ALTER ROLE db_datawriter ADD MEMBER RDemo;
ALTER ROLE db_datareader ADD MEMBER RDemo;
ALTER ROLE db_ddladmin ADD MEMBER RDemo;
GRANT EXECUTE ON SCHEMA::dbo TO RDemo;
GRANT EXECUTE ANY EXTERNAL SCRIPT TO RDemo;
GO
