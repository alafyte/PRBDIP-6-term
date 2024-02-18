create type ORDER_RECORD is object
(
    ID                      INT,
    BOOK_ID                 INT,
    CUSTOMER_ID             INT,
    BOOK_CHARACTERISTICS_ID INT,
    DATE_OF_ORDER           DATE,
    EDITION                 INT,
    TOTAL_PRICE             DECIMAL(10, 2),
    STATUS                  VARCHAR2(20)
);

create or replace type ORDER_TABLE is table of ORDER_RECORD;