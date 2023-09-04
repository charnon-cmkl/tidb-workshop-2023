USE Workshop;

SELECT ID, Buyer_Name, Product_Name, 'Current Data' FROM Sales_backup;

SELECT SLEEP(5);

UPDATE Sales_backup SET Buyer_Name = "Angelina, Christ" WHERE ID = 1729382256910270467;

SELECT ID, Buyer_Name, 'Updated Data' FROM Sales_backup;

SELECT ID, Buyer_Name, 'Past Data' FROM Sales_backup AS OF TIMESTAMP(CURRENT_TIMESTAMP() - INTERVAL '3' MINUTE);

SELECT NOW(),
    VARIABLE_VALUE
FROM mysql.tidb
WHERE variable_name = "tikv_gc_safe_point";