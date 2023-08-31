INSERT INTO Sales (Buyer_name, Product_Name) 
    VALUES ("Barbara, Thomas", "Cornflakes");

INSERT INTO Sales (Buyer_name, Product_Name)
    VALUES ("Wang, Charlie", "Hair Shampoo");

INSERT INTO Sales (Buyer_name, Product_Name)
    VALUES ("Barbara, Thomas", "Body Soap");

SELECT COUNT(*), NOW() FROM Sales;

SELECT VARIABLE_NAME,
    VARIABLE_VALUE,
    COMMENT
FROM MYSQL.TIDB
WHERE VARIABLE_NAME = "tikv_gc_safe_point";

DROP TABLE Sales;

SELECT COUNT(*) FROM Sales;

FLASHBACK TABLE Sales TO Sales_backup;

SELECT COUNT(*) FROM Sales_backup;

SELECT ID, Buyer_Name, Product_Name FROM Sales_backup;