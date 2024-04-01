CREATE TABLE EMPLOYEE
(
    ID         INT GENERATED ALWAYS AS IDENTITY (START WITH 1 INCREMENT BY 1) PRIMARY KEY,
    FIRST_NAME NVARCHAR2(50) NOT NULL,
    LAST_NAME  NVARCHAR2(50) NOT NULL,
    POSITION   NVARCHAR2(50) NOT NULL
);


CREATE TABLE EMPLOYEE_WORKLOAD
(
    ID          INT GENERATED ALWAYS AS IDENTITY (START WITH 1 INCREMENT BY 1) PRIMARY KEY,
    EMPLOYEE_ID INT NOT NULL,
    YEAR        INT NOT NULL,
    MONTH       INT NOT NULL,
    WORKLOAD    INT NOT NULL,
    CONSTRAINT FK_EMPLOYEE_ID FOREIGN KEY (EMPLOYEE_ID) REFERENCES EMPLOYEE (ID)
);

INSERT INTO EMPLOYEE (FIRST_NAME, LAST_NAME, POSITION)
VALUES ('Иван', 'Иванов', 'Менеджер');
INSERT INTO EMPLOYEE (FIRST_NAME, LAST_NAME, POSITION)
VALUES ('Петр', 'Петров', 'Редактор');
INSERT INTO EMPLOYEE (FIRST_NAME, LAST_NAME, POSITION)
VALUES ('Анна', 'Сидорова', 'Дизайнер');
INSERT INTO EMPLOYEE (FIRST_NAME, LAST_NAME, POSITION)
VALUES ('Елена', 'Козлова', 'Корректор');
INSERT INTO EMPLOYEE (FIRST_NAME, LAST_NAME, POSITION)
VALUES ('Сергей', 'Семенов', 'Иллюстратор');
INSERT INTO EMPLOYEE (FIRST_NAME, LAST_NAME, POSITION)
VALUES ('Мария', 'Федорова', 'Копирайтер');
INSERT INTO EMPLOYEE (FIRST_NAME, LAST_NAME, POSITION)
VALUES ('Алексей', 'Николаев', 'Редактор');
INSERT INTO EMPLOYEE (FIRST_NAME, LAST_NAME, POSITION)
VALUES ('Татьяна', 'Иванова', 'Менеджер');
INSERT INTO EMPLOYEE (FIRST_NAME, LAST_NAME, POSITION)
VALUES ('Дмитрий', 'Петров', 'Иллюстратор');
INSERT INTO EMPLOYEE (FIRST_NAME, LAST_NAME, POSITION)
VALUES ('Ольга', 'Сидорова', 'Корректор');

INSERT INTO EMPLOYEE_WORKLOAD (EMPLOYEE_ID, YEAR, MONTH, WORKLOAD)
SELECT E.ID                               AS EMPLOYEE_ID,
       EXTRACT(YEAR FROM SYSDATE) - 1     AS YEAR,
       MONTHS.MONTH_NUMBER                AS MONTH,
       FLOOR(DBMS_RANDOM.VALUE(100, 201)) AS NUMBER_OF_BOOKS
FROM EMPLOYEE E
         CROSS JOIN
         (SELECT LEVEL AS MONTH_NUMBER FROM DUAL CONNECT BY LEVEL <= 12) MONTHS;

-- Постройте при помощи конструкции MODEL запросы, которые разрабатывают план: работ для каждого
-- сотрудника на следующий год, увеличивая количество выпускаемых книг на 1% по
-- сравнению с аналогичным месяцем прошлого года.

SELECT *
FROM (SELECT e.ID                                                                                   AS EMPLOYEE_ID,
             e.FIRST_NAME || ' ' || e.LAST_NAME                                                     AS EMPLOYEE_NAME,
             TO_CHAR(TO_DATE(ew.YEAR || '-' || ew.MONTH, 'YYYY-MM') + INTERVAL '1' YEAR, 'YYYY-MM') AS MONTH,
             COALESCE(SUM(ew.WORKLOAD), 0)                                                          AS WORKLOAD
      FROM EMPLOYEE e
               LEFT JOIN EMPLOYEE_WORKLOAD ew ON e.ID = ew.EMPLOYEE_ID
      WHERE ew.YEAR = EXTRACT(YEAR FROM SYSDATE) - 1
      GROUP BY e.ID, e.FIRST_NAME, e.LAST_NAME,
               TO_CHAR(TO_DATE(ew.YEAR || '-' || ew.MONTH, 'YYYY-MM') + INTERVAL '1' YEAR, 'YYYY-MM'))
    MODEL
        PARTITION BY (EMPLOYEE_ID)
        DIMENSION BY (TO_NUMBER(SUBSTR(month, 6)) AS MONTH_NUM)
        MEASURES (WORKLOAD)
        RULES (
        WORKLOAD[FOR MONTH_NUM FROM 1 TO 12 INCREMENT 1] = WORKLOAD[CV()] * 1.01
        )
ORDER BY EMPLOYEE_ID, MONTH_NUM;


-- Найдите при помощи конструкции MATCH_RECOGNIZE() данные, которые соответствуют шаблону:
-- Падение, рост, падение тиражей для каждого автора
SELECT *
FROM (SELECT AUTHOR_ID,
             BO.DATE_OF_ORDER,
             BO.EDITION,
             ROW_NUMBER() OVER (PARTITION BY A.ID ORDER BY BO.DATE_OF_ORDER) AS RN
      FROM AUTHOR A
               JOIN BOOK B ON A.ID = B.AUTHOR_ID
               JOIN BOOK_ORDER BO ON B.ID = BO.BOOK_ID) OrderedOrders
         MATCH_RECOGNIZE (
             PARTITION BY AUTHOR_ID
             ORDER BY DATE_OF_ORDER
             MEASURES
                 FIRST(STRT.EDITION) AS FIRST_DOWN_EDITION,
                 FIRST(UP.EDITION) AS FIRST_UP,
                 LAST(DOWN.EDITION) AS LAST_EDITION
             PATTERN (STRT UP DOWN)
             DEFINE
                 DOWN AS EDITION < PREV(EDITION),
                 UP AS EDITION > PREV(EDITION)
             ) MR;
