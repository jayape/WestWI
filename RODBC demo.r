# My demo of the RODBC package.
# It will connect to a SQL instance to retrieve data,
# manipulate the data a bit, then print out graphs showing
# the space used for 3 databases on 4 servers.

library(RODBC)
library(dplyr)
library(ggplot2)
library(gridExtra)

# Using RODBC to connect to SQL instance
myConn <- odbcDriverConnect('driver={SQL Server};
                            server=PERTELL03;
                            database=PerfDB_DW;
                            uid=sa;
                            pwd=2386J@jp')

# Could have used an existing ODBC connection
myConn2 <- odbcConnect('RDemoConnect', 'RDemo', 'RDemo')

# Load a table into a data frame
db_size <- sqlFetch(myConn, 'TempDBStats')

# Load a data frame based on a query
db_servers <- sqlQuery(myConn, "SELECT ServerID, ServerName, SQLInstance 
                                 FROM DimServers 
                                 WHERE Monitor = 'C'")

# Close the connections when you're finished getting data from the database
close(myConn)
close(myConn2)

# Use dplyr functions to populate a new data frame. 
# %>% is the pipe operator, used to send one command to another
# filter is criteria for what observations to return,
# select is the variables to include
db_filtered <- db_size %>% filter(Servername %in% c('DCICHISQL1\\MISDB', 'DCICHISQL2\\MISDB', 
                                                    'DCICORSQL3\\MISDB', 'DCICORSQL4\\MISDB'),
                                      DBName %in% c('mis_db', 'darwin_db','dialysis_db'),
                                      RunDate >= as.POSIXct('2015-08-24')) %>% 
                           select(Servername, RunDate, DBName, Name, TotalSize, UsedSpace, FreeSpace)  

# Get rid of unneeded factions
db_filtered$Servername <- factor(db_filtered$Servername)
db_filtered$DBName <- factor(db_filtered$DBName)
db_filtered$Name <- factor(db_filtered$Name)

# Convert KB to GB
db_filtered$TotalSize <- (db_filtered$TotalSize / 1024) / 1024
db_filtered$UsedSpace <- (db_filtered$UsedSpace / 1024) / 1024
db_filtered$FreeSpace <- (db_filtered$FreeSpace / 1024) / 1024

head(db_filtered)

# Use ggplot function from ggplot2 package to create a simple line plot with a few modifications
ggplot(db_filtered %>% filter(Servername == 'DCICHISQL1\\MISDB'), 
       aes(x=RunDate, y=UsedSpace)) + 
  geom_line(aes(color = factor(Name))) + 
  scale_color_discrete(name='DB File') +
  #scale_y_continuous(labels = comma) +
  labs(title = 'Database Growth', x = 'Date', y = 'Used Space (GB)')

# Create one image with 4 graphs, one for each servername in db_filtered.
# First assign a graph to different variables 
plot1 <- ggplot(db_filtered %>% filter(Servername == 'DCICHISQL1\\MISDB'), 
        aes(x=RunDate, y=UsedSpace)) + 
        geom_line(aes(color = factor(Name))) + 
        scale_color_discrete(name='DB File') +
        #scale_y_continuous(labels = comma) +
        labs(title = 'Database Growth For DCICHISQL1', x = 'Date', y = 'Used Space (GB)')

plot2 <- ggplot(db_filtered %>% filter(Servername == 'DCICHISQL2\\MISDB'), 
        aes(x=RunDate, y=UsedSpace)) + 
        geom_line(aes(color = factor(Name))) + 
        scale_color_discrete(name='DB File') +
        #scale_y_continuous(labels = comma) +
        labs(title = 'Database Growth For DCICHISQL2', x = 'Date', y = 'Used Space (GB)')

plot3 <- ggplot(db_filtered %>% filter(Servername == 'DCICORSQL3\\MISDB'), 
        aes(x=RunDate, y=UsedSpace)) + 
        geom_line(aes(color = factor(Name))) + 
        scale_color_discrete(name='DB File') +
        #scale_y_continuous(labels = comma) +
        labs(title = 'Database Growth For DCICORSQL3', x = 'Date', y = 'Used Space (GB)')

plot4 <- ggplot(db_filtered %>% filter(Servername == 'DCICORSQL4\\MISDB'), 
        aes(x=RunDate, y=UsedSpace)) + 
        geom_line(aes(color = factor(Name))) + 
        scale_color_discrete(name='DB File') +
        #scale_y_continuous(labels = comma) +
        labs(title = 'Database Growth For DCICORSQL4', x = 'Date', y = 'Used Space (GB)')

# Next add the four graph variables to a list
myPlotList <- list(plot1, plot2, plot3, plot4)

# Finally call a function of the gridExtra package to print all four graphs
do.call(grid.arrange, c(myPlotList, list(ncol = 2))) 
