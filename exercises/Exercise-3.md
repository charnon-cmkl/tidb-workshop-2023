# Exercise 3 : Flashback Table and AUTO_RANDOM constraints

## Exercise Overview
In this exercise, we will introduce some features of TiDB server that allow users to flashback data tables/queries when discarding some modifications and set data sharding based on random primary key with `AUTO_RANDOM` constraint.

## Prerequisites
* Your workstation must run a linux-based operating system (MacOS or Linux).
* Your workstation must be installed with Git client or command line interface and be able to clone the workshop’s files.
* Your workstation must be installed with MySQL command line interface and be able to execute SQL commands.

## Instruction
1. Create a test table with the `AUTO_RANDOM` constraint and populate a set of test data. Then, check how it generates records randomly.
2. Perform an update to the table and attempt to retrieve the previous version with the `flashback` command.
3. Perform timely queries with the `AS OF` statement to flashback a query and check the results.

## Steps and Solutions
1. While the TiDB server is running, connect to the TiDB server command line using the `connect-4000.sh` script.

```console
$ ./connect-4000.sh
...
tidb:4000>
```

2. Review and make sure that you understand the SQL command to create a test table with the `AUTO_RANDOM` constraint.

```sql
tidb:4000> SYSTEM cat ex2-sales-table-create.sql

USE Workshop;
DROP TABLE IF EXISTS Sales, Sales_backup;
CREATE TABLE IF NOT EXISTS Sales (
    ID BIGINT(20) NOT NULL AUTO_RANDOM,
    Buyer_Name CHAR(50) NOT NULL,
    Product_Name CHAR(100) NOT NULL,
    PRIMARY KEY (ID)
);
```

3. Execute the creating table script to prepare the `Sales` table using the following command.

```sql
tidb:4000> SOURCE ex3-sales-table-create.sql
...
Database changed
--------------
DROP TABLE IF EXISTS Sales, Sales_backup
--------------

Query OK, 0 rows affected, 1 warning (8.08 sec)

--------------
CREATE TABLE IF NOT EXISTS Sales (
    ID BIGINT(20) NOT NULL AUTO_RANDOM,
    Buyer_Name CHAR(50) NOT NULL,
    Product_Name CHAR(100) NOT NULL,
    PRIMARY KEY (ID)
)
--------------

Query OK, 0 rows affected, 1 warning (1.06 sec)
```

4. Then, we will attempt to populate three records into the `Sales` table before dropping the table, and use the flashback command to retrieve it back. Let's check the script to make sure you understand how it works.

```sql
tidb:4000> SYSTEM cat ex3-sales-table-insert-fb.sql
```

We execute three SQL `INSERT` commands to populate three data records into the `Sales` table. Note that the `Buyer_Name` field refers to the `Employee` field of the `Employee` table for further exersices on analytical queries. However, we did not specify any foreign keys for now.

```sql
INSERT INTO Sales (Buyer_Name, Product_Name) 
    VALUES ("Barbara, Thomas", "Cornflakes");

INSERT INTO Sales (Buyer_Name, Product_Name)
    VALUES ("Wang, Charlie", "Hair Shampoo");

INSERT INTO Sales (Buyer_Name, Product_Name)
    VALUES ("Barbara, Thomas", "Body Soap");
```

Then, we use the following `SELECT` command to check whether the `INSERT` commands work correctly or not. We expect three records in the table.

```sql
SELECT COUNT(*), NOW() FROM Sales;
```

After that, we will use the followng `SELECT` command to check the database variable on the safe point. We expect to see that how long we can have until the `FLASHBACK` command will not work.

```sql
SELECT VARIABLE_NAME,
    VARIABLE_VALUE,
    COMMENT
FROM MYSQL.TIDB
WHERE VARIABLE_NAME = "tikv_gc_safe_point";
```

Since we make sure that the `FLASHBACK` command is still working in the given period of time, we can drop the `Sales` table and then use another `SELECT` command to ensure that the table is really dropped.

```sql
DROP TABLE Sales;
SELECT COUNT(*) FROM Sales;
```

Finally, we can use the `FLASHBACK` command to flash back the dropped `Sales` table and put it in the `Sales_backup` table. We can then query the `Sales_backup` table to check the value. Note that we can see that the `ID` field is automatically and randomly generated (with collision-free).

```sql
FLASHBACK TABLE Sales TO Sales_backup;
SELECT COUNT(*) FROM Sales_backup;
SELECT ID, Buyer_Name, Product_Name FROM Sales_backup;
```

5. Execute the script to see the actual results.

```sql
tidb:4000> SOURCE ex3-sales-table-insert-fb.sql
--------------
INSERT INTO Sales (Buyer_name, Product_Name) 
    VALUES ("Barbara, Thomas", "Cornflakes")
--------------

Query OK, 1 row affected (0.00 sec)

--------------
INSERT INTO Sales (Buyer_name, Product_Name)
    VALUES ("Wang, Charlie", "Hair Shampoo")
--------------

Query OK, 1 row affected (0.00 sec)

--------------
INSERT INTO Sales (Buyer_name, Product_Name)
    VALUES ("Barbara, Thomas", "Body Soap")
--------------

Query OK, 1 row affected (0.00 sec)

--------------
SELECT COUNT(*), NOW() FROM Sales
--------------

+----------+---------------------+
| COUNT(*) | NOW()               |
+----------+---------------------+
|        3 | 2023-08-31 14:24:26 |
+----------+---------------------+
1 row in set (0.01 sec)

--------------
SELECT VARIABLE_NAME,
    VARIABLE_VALUE,
    COMMENT
FROM MYSQL.TIDB
WHERE VARIABLE_NAME = "tikv_gc_safe_point"
--------------

+--------------------+-----------------------------+--------------------------------------------------------------+
| VARIABLE_NAME      | VARIABLE_VALUE              | COMMENT                                                      |
+--------------------+-----------------------------+--------------------------------------------------------------+
| tikv_gc_safe_point | 20230831-10:37:12.758 +0700 | All versions after safe point can be accessed. (DO NOT EDIT) |
+--------------------+-----------------------------+--------------------------------------------------------------+
1 row in set (0.00 sec)

--------------
DROP TABLE Sales
--------------

Query OK, 0 rows affected (2.07 sec)

--------------
SELECT COUNT(*) FROM Sales
--------------

ERROR 1146 (42S02): Table 'workshop.Sales' does not exist
--------------
FLASHBACK TABLE Sales TO Sales_backup
--------------

Query OK, 0 rows affected (2.06 sec)

--------------
SELECT COUNT(*) FROM Sales_backup
--------------

+----------+
| COUNT(*) |
+----------+
|        3 |
+----------+
1 row in set (0.00 sec)

--------------
SELECT ID, Buyer_Name, Product_Name FROM Sales_backup
--------------

+---------------------+-----------------+--------------+
| ID                  | Buyer_Name      | Product_Name |
+---------------------+-----------------+--------------+
| 1729382256910270467 | Barbara, Thomas | Body Soap    |
| 2594073385365405697 | Barbara, Thomas | Cornflakes   |
| 8935141660703064066 | Wang, Charlie   | Hair Shampoo |
+---------------------+-----------------+--------------+
3 rows in set (0.01 sec)
```