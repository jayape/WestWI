# Basic math
1 + 3
4 / 2

# Assignment operators. = is can be used but <- is preferred
a <- 3
a

b = 4
b

# You can also use print
print(a)


# View and remove objects in your environment
objects()

rm(a)
objects()

rm(list = objects())
objects()

# concatenation
a <- c(1,3,5,7,9)
a

a[2]

# sequence
b <- c(1:50)
b
b [35]

# class
class(b)

a <- c(1, 1.0001)
a
class(a)

a <- c(1, "1", 1.0)
a
class(a)

# single or double quotes allowed, but be consistent
a <- c(1, '1', 1.0)
a
class(a)

# Looping and comparisons
if (1 == 1) {
  print("1 = 1")
}

if (1 == 2) {
  print("1 = 2")
} else {
  print ("1 != 2")
}

if (1 == 2) {
  print("1 = 2")
} else if (1 != 1){
  print ("1 != 1")
} else {
  print ("1 must = 1")
}
  

c <- 1
while (c <= 10) {
  print(c)
  c <- c + 1
}

for (i in 1:10) {
  print(i)
}

for (i in 1:10) {
  print(i)
  if (i == 5){
    break
  }
}

# Create and work with other object types
# Lists
l <- list(1, 1.1, '1')
l
length(l)
class(l)
class(l[[1]])
class(l[[2]])
class(l[[3]])
l[[1]]

l2 <- list(1:5, 6.1:10.1, c('a', 'b', 'c', 'd', 'e'))
l2

l2[[1]]
l2[[2]][[3]]

# Matrix
m <- matrix(1:10, nrow=2)
m
class(m)
m <- matrix(1:10, ncol=2)
m
m <- matrix(1:10, ncol=2, byrow=TRUE)
m
m[1,]
m[,2]
m[3,2]

# Data Frame
df <- data.frame(1:10, 1:5)
df
class(df)
head(df, 8)
tail(df)

names(df)
names(df) <- c('Col1', 'Col2')
df
df$Col1
df[,1]
df[,-1]
df[1,]
df[-5,]
df[c(-2,-4),]
attach(df)
Col1

df$Col3 <- c(11:20)
df
Col4 <- c(30:21)
df <- cbind(df,Col4)
df <- rbind(df, c(11,21,31, 41))
dim(df)
df

# Packages
search()
View(installed.packages())
View(available.packages())
install.packages('dplyr', 
                  lib = 'C:/Users/johnp/Documents/R/win-library/3.3',
                  dependencies = TRUE)
library(dplyr, lib.loc = 'C:/Users/johnp/Documents/R/win-library/3.3')
help (package= 'dplyr')
help(arrange)
remove.packages('dplyr')

# Working directory
getwd()
setwd("C:/R Sessions")

# Functions
celcius <- function(f) {
  c <- (f - 32) * 5/9
  
}

howhot <- celcius(75)
howhot

rm(celcius)
source('./MyFunctions.r')

howhot <- celcius(75)
howhot
howhot <- fahrenheit(28)
howhot

# Data sets
library(help = datasets)
mydata <- iris
head(mydata)

# Read data
myCSV <- read.csv('./Data/Chicago2016.csv', header = TRUE)

head(myCSV)

# Read data from a web page
library(XML)

url <- 'http://www.hockey-reference.com/leagues/NHL_2016_standings.html'

tables <- readHTMLTable(url, stringsAsFactors = FALSE)
standings <- tables$standings
View(standings)
mystandings1 <- standings[1:5]
View(mystandings1)

write.csv(mystandings1, './Data/NHL2016.csv', row.names = FALSE)

# Connect to a SQL database
library(RODBC)

myConn <- odbcDriverConnect("driver={SQL Server};
                            server=PERTELL03;
                            database=ProdReportServer;
                            uid=Demoman;
                            pwd=password")


userData <- sqlFetch(myConn, "users")


reportData <- sqlQuery(myConn, "SELECT C.Name, ELS.UserName, ELS.TimeStart, ELS.TimeEnd, ELS.TimeDataRetrieval, 
                       ELS.TimeProcessing, ELS.TimeRendering, ELS.Status, ELS.ByteCount, ELS.[RowCount]
                       FROM Catalog AS C INNER JOIN ExecutionLogStorage AS ELS ON C.ItemID = ELS.ReportID
                       WHERE ELS.TimeStart BETWEEN '5/2/2016' AND '5/3/2016';")

close(myConn)
head(reportData[, c(1,5)])
reportData <- reportData[order(-reportData$TimeDataRetrieval),]
head(reportData[, c(1,5)])
topTen <- head(summary(subset(reportData$Name, reportData$Name != "WakeUpWorld")), 10)
topTen

plot(topTen)


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
df

library(ggplot2)
library(gridExtra)

plot1 <- ggplot(df, aes(x=ReportName, y=AvgDataRetrieval)) + 
                geom_bar(position="dodge", fill= "lightblue",  color = "black", stat="identity") +
                geom_text(aes(label=format(round(df$AvgDataRetrieval / 1000, 2), nsmall = 2)), vjust=0.1, color="black", 
                position=position_dodge(.9), size=5) +
                ggtitle("Average Data Retrieval in Seconds") +
                theme(legend.title = element_text(face="italic", size = 14))

plot2 <- ggplot(df, aes(x=ReportName, y=AvgProcessing)) + 
                geom_bar(position="dodge", fill= "red", color = "black", stat="identity") +
                geom_text(aes(label=format(round(df$AvgProcessing / 1000, 2), nsmall = 2)), vjust=0.1, color="black", 
                position=position_dodge(.9), size=5) +
                ggtitle("Average Time Processing in Seconds") +
                theme(legend.title = element_text(face="italic", size = 14))

plot3 <- ggplot(df, aes(x=ReportName, y=AvgRendering)) + 
                geom_bar(position="dodge", fill= "yellow",color = "black", stat="identity") +
                geom_text(aes(label=format(round(df$AvgRendering / 1000, 2), nsmall = 2)), vjust=0.1, color="black", 
                position=position_dodge(.9), size=5) +
                ggtitle("Average Time Rendering in Seconds") +
                theme(legend.title = element_text(face="italic", size = 14))

plotList <- list(plot1, plot2, plot3)
do.call(grid.arrange, plotList)
