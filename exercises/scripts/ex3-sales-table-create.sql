USE Workshop;
DROP TABLE IF EXISTS Sales, Sales_backup;
CREATE TABLE IF NOT EXISTS Sales (
    ID BIGINT(20) NOT NULL AUTO_RANDOM,
    Buyer_Name CHAR(50) NOT NULL,
    Product_Name CHAR(100) NOT NULL,
    PRIMARY KEY (ID)
);
