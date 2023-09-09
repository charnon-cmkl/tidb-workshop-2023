# Exercise 4: Query Performance Tuning

## Exercise Overview
In this exercise, we will demonstrate how TiDB support analytics tasks by using various performance tuning processes. This exercise will create three use case scenarios of the TiDB database and will use the performance results to emphasize the benefits of TiDB server in analytical tasks.

## Prerequisites
* Your workstation must run a linux-based operating system (MacOS or Linux).
* Your workstation must be installed with Git client or command line interface and be able to clone the workshop’s files.
* Your workstation must be installed with MySQL command line interface and be able to execute SQL commands.

## Instruction
1. Create and populate a large colletion of mock data records for this exercise.
2. Execute normal query with joining operation, and record the execution performance.
3. Repopulate the data table with the partitioning feature, and execute the same query. Then, record the performance.
4. Configure the data table to use the TiFlash columnar engine and execute some query to report the performance.

## Steps and Solutions
1. To evaluate query performance for analytical tasks, we need a significantly large data collection. We expected that TiDB database can outperform other relational database management systems when it comes to the analytical tasks. In this step, we run the following command to create a table for Marvel comic characters.

```sql
tidb:4000> SOURCE ex4-marvel-table-create-insert.sql;
...
--------------
INSERT INTO Marvel (page_id,name,urlslug,ID,ALIGN,EYE,HAIR,SEX,GSM,ALIVE,APPEARANCES,FIRST_APPEARANCE,Year) 
VALUES (673702,'Yologarch (Earth-616)','\/Yologarch_(Earth-616)',NULL,'Bad Characters',NULL,NULL,NULL,NULL,'Living Characters',NULL,NULL,NULL)
--------------

Query OK, 1 row affected (0.00 sec)
```

2. The previous step populated around 16,000 data records into the `Marvel` Table. Then, we can try analyzing which characters have blond hair using the following command.

```sql
tidb:4000> EXPLAIN SELECT name, EYE, HAIR, ALIVE FROM Marvel WHERE HAIR="Blond Hair";
--------------
EXPLAIN SELECT name, EYE, HAIR, ALIVE FROM Marvel WHERE HAIR="Blond Hair"
--------------

+-------------------------+----------+-----------+---------------+----------------------------------------+
| id                      | estRows  | task      | access object | operator info                          |
+-------------------------+----------+-----------+---------------+----------------------------------------+
| TableReader_7           | 1582.00  | root      |               | data:Selection_6                       |
| └─Selection_6           | 1582.00  | cop[tikv] |               | eq(workshop.marvel.hair, "Blond Hair") |
|   └─TableFullScan_5     | 16376.00 | cop[tikv] | table:Marvel  | keep order:false                       |
+-------------------------+----------+-----------+---------------+----------------------------------------+
3 rows in set (0.00 sec)
```

3. Now, we will populate another table for DC comic characters. We will use the following script to do so.

```sql
tidb:4000> SOURCE ex4-dc-table-create-insert.sql
...
--------------
INSERT INTO DC(page_id,name,urlslug,ID,ALIGN,EYE,HAIR,SEX,GSM,ALIVE,APPEARANCES,FIRST_APPEARANCE,YEAR) VALUES (150660,'Mookie (New Earth)','\/wiki\/Mookie_(New_Earth)','Public Identity','Bad Characters','Blue Eyes','Blond Hair','Male Characters',NULL,'Living Characters',NULL,NULL,NULL)
--------------

Query OK, 1 row affected (0.00 sec)
```

4. We can also analyze the `DC` table and see how TiDB access and scan the table to select the results, by using the following command.

```sql
tidb:4000> EXPLAIN SELECT name, EYE, HAIR, ALIVE FROM Marvel WHERE HAIR="Blond Hair";
--------------
EXPLAIN SELECT name, EYE, HAIR, ALIVE FROM DC WHERE HAIR="Blond Hair"
--------------

+-------------------------+---------+-----------+---------------+------------------------------------+
| id                      | estRows | task      | access object | operator info                      |
+-------------------------+---------+-----------+---------------+------------------------------------+
| TableReader_7           | 744.00  | root      |               | data:Selection_6                   |
| └─Selection_6           | 744.00  | cop[tikv] |               | eq(workshop.dc.hair, "Blond Hair") |
|   └─TableFullScan_5     | 6896.00 | cop[tikv] | table:DC      | keep order:false                   |
+-------------------------+---------+-----------+---------------+------------------------------------+
3 rows in set (0.01 sec)
```

5. The above analyses are small with just filter some columns. However, when analytical tasks become more complicated, it would take much time. For example, we want to find Marvel and DC comic characters that have blond hair and appear in the same year. Let's try to query with joining operation.

```sql
tidb:4000> EXPLAIN SELECT A.name, B.Name, A.HAIR, A.YEAR FROM Marvel AS A JOIN DC AS B ON A.HAIR = B.HAIR and A.YEAR = B.YEAR;

--------------
EXPLAIN SELECT A.name, B.Name, A.HAIR, A.YEAR FROM Marvel AS A JOIN DC AS B ON A.HAIR = B.HAIR and A.YEAR = B.YEAR
--------------

+----------------------------------+-----------+-----------+---------------+-----------------------------------------------------------------------------------------------------------+
| id                               | estRows   | task      | access object | operator info                                                                                             |
+----------------------------------+-----------+-----------+---------------+-----------------------------------------------------------------------------------------------------------+
| Projection_8                     | 999100.46 | root      |               | workshop.marvel.name, workshop.dc.name, workshop.marvel.hair, workshop.marvel.year                        |
| └─Projection_9                   | 999100.46 | root      |               | workshop.marvel.name, workshop.marvel.hair, workshop.marvel.year, workshop.dc.name                        |
|   └─HashJoin_11                  | 999100.46 | root      |               | inner join, equal:[eq(workshop.dc.hair, workshop.marvel.hair) eq(workshop.dc.year, workshop.marvel.year)] |
|     ├─TableReader_14(Build)      | 4575.75   | root      |               | data:Selection_13                                                                                         |
|     │ └─Selection_13             | 4575.75   | cop[tikv] |               | not(isnull(workshop.dc.hair)), not(isnull(workshop.dc.year))                                              |
|     │   └─TableFullScan_12       | 6896.00   | cop[tikv] | table:B       | keep order:false                                                                                          |
|     └─TableReader_17(Probe)      | 11509.21  | root      |               | data:Selection_16                                                                                         |
|       └─Selection_16             | 11509.21  | cop[tikv] |               | not(isnull(workshop.marvel.hair)), not(isnull(workshop.marvel.year))                                      |
|         └─TableFullScan_15       | 16376.00  | cop[tikv] | table:A       | keep order:false                                                                                          |
+----------------------------------+-----------+-----------+---------------+-----------------------------------------------------------------------------------------------------------+
9 rows in set (0.01 sec)

tidb:4000> SELECT A.name, B.Name, A.HAIR, A.YEAR FROM Marvel AS A JOIN DC AS B ON A.HAIR = B.HAIR and A.YEAR = B.YEAR;
...
176791 rows in set (0.09 sec)
```

6. In the previous step, we see that TiDB conduct a full scan on the two tables and do the hash join. The operation take around 0.09 seconds.

7. Then, we will drop the Marvel table and re-populate it again with the partitioning. We would like to see whether it can improve query performance or not. We use the following script to re-populate the table.

```sql
tidb:4000> SOURCE ex4-marvel-table-create-insert-partition.sql
...
CREATE TABLE IF NOT EXISTS Marvel (
    ...
) PARTITION BY HASH (page_id) PARTITIONS 10;
...
--------------
INSERT INTO Marvel (page_id,name,urlslug,ID,ALIGN,EYE,HAIR,SEX,GSM,ALIVE,APPEARANCES,FIRST_APPEARANCE,Year) 
VALUES (673702,'Yologarch (Earth-616)','\/Yologarch_(Earth-616)',NULL,'Bad Characters',NULL,NULL,NULL,NULL,'Living Characters',NULL,NULL,NULL)
--------------

Query OK, 1 row affected (0.00 sec)
```
8. Then, we can redo step 5 to see the performance of the query statement with the hash join. The result is as follows.

```sql
tidb:4000> EXPLAIN SELECT A.name, B.Name, A.HAIR, A.YEAR FROM Marvel AS A JOIN DC AS B ON A.HAIR = B.HAIR and A.YEAR = B.YEAR;
--------------
EXPLAIN SELECT A.name, B.Name, A.HAIR, A.YEAR FROM Marvel AS A JOIN DC AS B ON A.HAIR = B.HAIR and A.YEAR = B.YEAR
--------------

+----------------------------------+-----------+-----------+---------------+-----------------------------------------------------------------------------------------------------------+
| id                               | estRows   | task      | access object | operator info                                                                                             |
+----------------------------------+-----------+-----------+---------------+-----------------------------------------------------------------------------------------------------------+
| Projection_8                     | 999100.46 | root      |               | workshop.marvel.name, workshop.dc.name, workshop.marvel.hair, workshop.marvel.year                        |
| └─Projection_9                   | 999100.46 | root      |               | workshop.marvel.name, workshop.marvel.hair, workshop.marvel.year, workshop.dc.name                        |
|   └─HashJoin_11                  | 999100.46 | root      |               | inner join, equal:[eq(workshop.dc.hair, workshop.marvel.hair) eq(workshop.dc.year, workshop.marvel.year)] |
|     ├─TableReader_14(Build)      | 4575.75   | root      |               | data:Selection_13                                                                                         |
|     │ └─Selection_13             | 4575.75   | cop[tikv] |               | not(isnull(workshop.dc.hair)), not(isnull(workshop.dc.year))                                              |
|     │   └─TableFullScan_12       | 6896.00   | cop[tikv] | table:B       | keep order:false                                                                                          |
|     └─TableReader_17(Probe)      | 11509.21  | root      | partition:all | data:Selection_16                                                                                         |
|       └─Selection_16             | 11509.21  | cop[tikv] |               | not(isnull(workshop.marvel.hair)), not(isnull(workshop.marvel.year))                                      |
|         └─TableFullScan_15       | 16376.00  | cop[tikv] | table:A       | keep order:false                                                                                          |
+----------------------------------+-----------+-----------+---------------+-----------------------------------------------------------------------------------------------------------+
9 rows in set (0.01 sec)

tidb:4000> SELECT A.name, B.Name, A.HAIR, A.YEAR FROM Marvel AS A JOIN DC AS B ON A.HAIR = B.HAIR and A.YEAR = B.YEAR;
...
176791 rows in set (0.12 sec)
```

9. It can be seen that partitioning may not be much helpful for query performance tuning. 

10. We can then enable the TiFlash columnar storage to support the analytical tasks (which should be better than TiKV store that we are currently used). The following command will be used to enable the TiFlash storage for each table.

```sql
tidb:4000> ALTER TABLE Marvel SET TIFLASH REPLICA 1;
--------------
ALTER TABLE Marvel SET TIFLASH REPLICA 1
--------------

Query OK, 0 rows affected (3.99 sec)

tidb:4000> ALTER TABLE DC SET TIFLASH REPLICA 1;
--------------
ALTER TABLE DC SET TIFLASH REPLICA 1
--------------

Query OK, 0 rows affected (1.00 sec)
```

11. We can use the following command to check how TiDB server store the `Marvel` and `DC` tables. You may see that, in the task column, TiFlash has been used instead of TiKV.

```sql
tidb:4000> EXPLAIN ANALYZE SELECT A.name, B.Name, A.HAIR, A.YEAR FROM Marvel AS A JOIN DC AS B ON A.HAIR = B.HAIR and A.YEAR = B.YEAR;

+----------------------------------+-----------+---------+--------------+---------------+-------------------------------------------------------------------------------------------------------------------------------------------------->
| id                               | estRows   | actRows | task         | access object | execution info                                                                                                                                   >
+----------------------------------+-----------+---------+--------------+---------------+-------------------------------------------------------------------------------------------------------------------------------------------------->
| Projection_8                     | 999100.46 | 176791  | root         |               | time:265.3ms, loops:177, Concurrency:5                                                                                                           >
| └─Projection_10                  | 999100.46 | 176791  | root         |               | time:264.8ms, loops:177, Concurrency:5                                                                                                           >
|   └─HashJoin_14                  | 999100.46 | 176791  | root         |               | time:264.5ms, loops:177, build_hash_table:{total:236.6ms, fetch:235.5ms, build:1.06ms}, probe:{concurrency:5, total:1.31s, max:264.7ms, probe:126>
|     ├─TableReader_28(Build)      | 4575.75   | 4584    | root         |               | time:235.5ms, loops:6, cop_task: {num: 1, max: 236.1ms, proc_keys: 0, rpc_num: 1, rpc_time: 236.1ms, copr_cache_hit_ratio: 0.00, distsql_concurre>
|     │ └─Selection_27             | 4575.75   | 4584    | cop[tiflash] |               | tiflash_task:{time:15.4ms, loops:1, threads:1}                                                                                                   >
|     │   └─TableFullScan_26       | 6896.00   | 6896    | cop[tiflash] | table:B       | tiflash_task:{time:14.7ms, loops:1, threads:1}, tiflash_scan:{dtfile:{total_scanned_packs:1, total_skipped_packs:0, total_scanned_rows:6896, tota>
|     └─TableReader_34(Probe)      | 11509.21  | 11558   | root         | partition:all | time:235.1ms, loops:21, cop_task: {num: 10, max: 236ms, min: 231.3ms, avg: 234.1ms, p95: 236ms, rpc_num: 10, rpc_time: 2.34s, copr_cache_hit_rati>
|       └─Selection_33             | 11509.21  | 11558   | cop[tiflash] |               | tiflash_task:{proc max:34.7ms, min:12.2ms, avg: 16.4ms, p80:16.8ms, p95:34.7ms, iters:10, tasks:10, threads:10}                                  >
|         └─TableFullScan_32       | 16376.00  | 16376   | cop[tiflash] | table:A       | tiflash_task:{proc max:34.5ms, min:12.1ms, avg: 16.2ms, p80:16.7ms, p95:34.5ms, iters:10, tasks:10, threads:10}, tiflash_scan:{dtfile:{total_scan>
+----------------------------------+-----------+---------+--------------+---------------+-------------------------------------------------------------------------------------------------------------------------------------------------->
```
12. We then execute the same query again and we found that the execution time is reduced. This is a small dataset, but if we have a signifcantly larger table (for example, more than 100,000 records), the results may be significantly different. 
```sql
tidb:4000> SELECT A.name, B.Name, A.HAIR, A.YEAR FROM Marvel AS A JOIN DC AS B ON A.HAIR = B.HAIR and A.YEAR = B.YEAR;
...
176791 rows in set (0.08 sec)
```