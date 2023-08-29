# Exercise 2 : DDL Features

## Exercise Overview
In this exercise, we will allow you to explore how the Database Definition Language (DDL) works with the TiDB server. You will have the opportunity to experiment with common SQL commands to create table schemas, modify them, and manage tables using the flashback command. Additionally, we will guide you through the usage of constraints that aid in auto-increment and randomness.

## Prerequisite
* Your workstation must run a linux-based operating system (MacOS or Linux).
* Your workstation must be installed with Git client or command line interface and be able to clone the workshop’s files.
* Your workstation must be installed with MySQL command line interface and be able to execute SQL commands.

## Instruction
1. Connect to the TiDB server and create tables for data importing.
2. Review and use the provided SQL command to populate mock-up data into the created table.
3. Review and use the TiUP Lightning to logically import the given CSV file into TiDB database.
4. Review the output of the constraint defined.

## Steps and Solutions
1. While the TiDB server is running, connect to it via port 4000 using the `./connect-4000.sh` script.

```console
$ ./connect-4000.sh
...
Reading history-file /Users/chnpat/.mysql_history
Type 'help;' or '\h' for help. Type '\c' to clear the current input statement.

tidb:4000> 
```

2. Create a database user that is allowed to do the data importing task and have sufficient privilege to do so. The following SQL command is used to create a database user and grant some privileges.
```sql
tidb:4000> CREATE USER imp@'%' IDENTIFIED BY 'q1w2e3R4_';
GRANT ALL PRIVILEGES ON *.* TO imp@'%';
```

3. Review and make sure that you understand the provided `CREATE DATABASE` command.

```sql
tidb:4000> SYSTEM cat ex2-hrd-database-create.sql

DROP DATABASE IF EXISTS Workshop;
CREATE DATABASE IF NOT EXISTS Workshop;
```

4. Then, execute the `CREATE DATABASE` command to create a database for our workshop.

```sql
tidb:4000> SOURCE ex2-hrd-database-create.sql
--------------
DROP DATABASE IF EXISTS Workshop
--------------

Query OK, 0 rows affected (0.01 sec)

--------------
CREATE DATABASE IF NOT EXISTS Workshop
--------------

Query OK, 0 rows affected (1.06 sec)
```

5. Review and make sure that you understand the provided `CREATE TABLE` command.

```sql
tidb:4000> SYSTEM cat ex2-hrd-table-create.sql

USE Workshop;
DROP TABLE `Employee` IF EXISTS;
CREATE TABLE `Employee` (
    `ID` BIGINT(20) NOT NULL AUTO_INCREMENT,
    `Employee_Name` CHAR(40) NOT NULL DEFAULT '',
    `EmpID` BIGINT(20) NOT NULL,
    `MarriedID` INT(5) NOT NULL, 
    `MaritalStatusID` INT(5) NOT NULL,
    `GenderID` INT(5) NOT NULL,
    `EmpStatusID` INT(5) NOT NULL,
    `DeptID` INT(5) NOT NULL,
    `PerfScoreID` INT(5) NOT NULL,
    `FromDiversityJobFairID` INT(5) NOT NULL,
    `Salary` INT(10) NOT NULL,
    `Termd` INT(5) NOT NULL,
    `PositionID` INT(10) NOT NULL,
    `Position` CHAR(40) NOT NULL,
    `State` CHAR(10) NOT NULL,
    `Zip` INT(5) NOT NULL,
    `DOB` DATE NOT NULL,
    `Sex` CHAR(2) NOT NULL,
    `MaritalDesc` CHAR(10) NOT NULL,
    `CitizenDesc` CHAR(20) NOT NULL,
    `HispanicLatino` CHAR(3) NOT NULL,
    `RaceDesc` CHAR(32) NOT NULL,
    `DateofHire` DATE NOT NULL,
    `DateofTermination` DATE,
    `TermReason` CHAR(32) NOT NULL,
    `EmploymentStatus` CHAR(22) NOT NULL,
    `Department` CHAR(20) NOT NULL,
    `ManagerName` CHAR(18) NOT NULL,
    `ManagerID` INT(10),
    `RecruitmentSource` CHAR(23) NOT NULL,
    `PerformanceScore` CHAR(17) NOT NULL,
    `EngagementSurvey` FLOAT(4,2) NOT NULL,
    `EmpSatisfaction` INT(10) NOT NULL,
    `SpecialProjectsCount` INT(10)  NOT NULL,
    `LastPerformanceReview_Date` DATE  NOT NULL, 
    `DaysLateLast30` INT(19)  NOT NULL,
    `Absences` INT(10) NOT NULL,
    PRIMARY KEY (`ID`) /*T![clustered_index] CLUSTERED */,
    KEY `Employee_Name` (`Employee_Name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin AUTO_INCREMENT=40510553;
```

6. Then, execute the `CREATE TABLE` command to initiate a new table with the predefined table schema. Please note that we predefined the table schema based on the mock data. You can see there are some constraints used, such as `PRIMARY KEY` or `AUTO_INCREMENT`.

```sql
tidb:4000> SOURCE ex2-hrd-table-create.sql
...
Query OK, 0 rows affected (1.08 sec)
```

7. Now, we will try to populate the table data using simple `INSERT` SQL command.

```sql
tidb:4000> SYSTEM cat ex2-hrd-table-insert.sql
...
INSERT INTO `Employee`(ID,Employee_Name,EmpID,MarriedID,MaritalStatusID,GenderID,EmpStatusID,DeptID,PerfScoreID,FromDiversityJobFairID,Salary,Termd,PositionID,Position,State,Zip,DOB,Sex,MaritalDesc,CitizenDesc,HispanicLatino,RaceDesc,DateofHire,DateofTermination,TermReason,EmploymentStatus,Department,ManagerName,ManagerID,RecruitmentSource,PerformanceScore,EngagementSurvey,EmpSatisfaction,SpecialProjectsCount,LastPerformanceReview_Date,DaysLateLast30,Absences) VALUES (309,'Zhou, Julia',10043,0,0,0,1,3,3,0,89292,0,9,'Data Analyst','MA',2148,'1979-02-24','F','Single','US Citizen','No','White','2015-03-30',NULL,'N/A-StillEmployed','Active','IT/IS','Simon Roup',4.0,'Employee Referral','Fully Meets',5.0,3,5,'2019-02-01',0,11);
INSERT INTO `Employee`(ID,Employee_Name,EmpID,MarriedID,MaritalStatusID,GenderID,EmpStatusID,DeptID,PerfScoreID,FromDiversityJobFairID,Salary,Termd,PositionID,Position,State,Zip,DOB,Sex,MaritalDesc,CitizenDesc,HispanicLatino,RaceDesc,DateofHire,DateofTermination,TermReason,EmploymentStatus,Department,ManagerName,ManagerID,RecruitmentSource,PerformanceScore,EngagementSurvey,EmpSatisfaction,SpecialProjectsCount,LastPerformanceReview_Date,DaysLateLast30,Absences) VALUES (310,'Zima, Colleen',10271,0,4,0,1,5,3,0,45046,0,19,'Production Technician I','MA',1730,'1978-08-17','F','Widowed','US Citizen','No','Asian','2014-09-29',NULL,'N/A-StillEmployed','Active','Production','David Stanley',14.0,'LinkedIn','Fully Meets',4.5,5,0,'2019-01-30',0,2);
```

```sql
tidb:4000> SOURCE ex2-hrd-table-insert.sql
...
--------------
INSERT INTO `Employee`(ID,Employee_Name,EmpID,MarriedID,MaritalStatusID,GenderID,EmpStatusID,DeptID,PerfScoreID,FromDiversityJobFairID,Salary,Termd,PositionID,Position,State,Zip,DOB,Sex,MaritalDesc,CitizenDesc,HispanicLatino,RaceDesc,DateofHire,DateofTermination,TermReason,EmploymentStatus,Department,ManagerName,ManagerID,RecruitmentSource,PerformanceScore,EngagementSurvey,EmpSatisfaction,SpecialProjectsCount,LastPerformanceReview_Date,DaysLateLast30,Absences) VALUES (310,'Zima, Colleen',10271,0,4,0,1,5,3,0,45046,0,19,'Production Technician I','MA',1730,'1978-08-17','F','Widowed','US Citizen','No','Asian','2014-09-29',NULL,'N/A-StillEmployed','Active','Production','David Stanley',14.0,'LinkedIn','Fully Meets',4.5,5,0,'2019-01-30',0,2)
--------------

Query OK, 1 row affected (0.00 sec)
```

8. Make sure that the mock data is populated as we expected by querying the top 5 records using the following command.

```sql
tidb:4000> SELECT ID, Employee_Name, DOB FROM Employee LIMIT 5;
--------------
SELECT ID, Employee_Name, DOB FROM Employee LIMIT 5
--------------

+----+------------------+------------+
| ID | Employee_Name    | DOB        |
+----+------------------+------------+
|  3 | Alagbe,Trina     | 1988-09-27 |
|  5 | Anderson, Linda  | 1977-05-22 |
|  6 | Andreola, Colby  | 1979-05-24 |
|  7 | Athwal, Sam      | 1983-02-18 |
|  8 | Bachiochi, Linda | 1970-02-11 |
+----+------------------+------------+
5 rows in set (0.00 sec)

tidb:4000> EXIT;
Bye
```

9. Now, we will try to import the mock data from the given CSV file using the TiUP lightning, which is a tool that handles data importing tasks. In order to use the TiUP lightning tool, we have to prepare a configuration file (`.toml`) as follows.

```console
$ cat ex2-hrd-table-import.toml

[lightning]
# Log
level = "info"
file = "tidb-lightning-workshop.log"
table-concurrency = 1
index-concurrency = 1
region-concurrency = 1
io-concurrency = 1
max-error = 0
task-info-schema-name = "lightning_task_info"
meta-schema-name = "lightning_metadata"

[tikv-importer]
backend = "local"
incremental-import = false
sorted-kv-dir = "../stage/sorted-kv-dir-1"

[mydumper]
data-source-dir = "./misc/HRDataset"
filter = ['*.*', '!mysql.*', '!sys.*', '!INFORMATION_SCHEMA.*', '!PERFORMANCE_SCHEMA.*', '!METRICS_SCHEMA.*', '!INSPECTION_SCHEMA.*']
strict-format = true

[mydumper.csv]
separator = ','
delimiter = '"'
terminator = ''
header = true
not-null = false
null = '\N'
backslash-escape = true
trim-last-separator = false

[tidb]
host = "127.0.0.1"
port = 4000
user = "imp"
password = "q1w2e3R4_"
status-port = 10080
pd-addr = "127.0.0.1:2379"
```

10. Then, execute the TiUP lightning utility to import the mock data from the CSV file into the TiDB database using the following command.

```console
$ tiup tidb-lightning:v6.5.1 --config ./misc/ex2-hrd-table-import.toml
...

```