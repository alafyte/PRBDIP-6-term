-- Дополнительные данные
INSERT INTO BOOK_ORDER (BOOK_ID, CUSTOMER_ID, BOOK_CHARACTERISTICS_ID, DATE_OF_ORDER, EDITION, TOTAL_PRICE, STATUS)
VALUES (1, 1, 1, TO_DATE('2023-01-05', 'YYYY-MM-DD'), 100, 1500.00, 'Создан');

INSERT INTO BOOK_ORDER (BOOK_ID, CUSTOMER_ID, BOOK_CHARACTERISTICS_ID, DATE_OF_ORDER, EDITION, TOTAL_PRICE, STATUS)
VALUES (2, 2, 2, TO_DATE('2023-02-10', 'YYYY-MM-DD'), 200, 2500.00, 'В работе');

INSERT INTO BOOK_ORDER (BOOK_ID, CUSTOMER_ID, BOOK_CHARACTERISTICS_ID, DATE_OF_ORDER, EDITION, TOTAL_PRICE, STATUS)
VALUES (3, 3, 3, TO_DATE('2023-03-15', 'YYYY-MM-DD'), 150, 1800.00, 'Создан');

INSERT INTO BOOK_ORDER (BOOK_ID, CUSTOMER_ID, BOOK_CHARACTERISTICS_ID, DATE_OF_ORDER, EDITION, TOTAL_PRICE, STATUS)
VALUES (4, 4, 4, TO_DATE('2023-04-20', 'YYYY-MM-DD'), 300, 3500.00, 'Готов');

INSERT INTO BOOK_ORDER (BOOK_ID, CUSTOMER_ID, BOOK_CHARACTERISTICS_ID, DATE_OF_ORDER, EDITION, TOTAL_PRICE, STATUS)
VALUES (6, 5, 5, TO_DATE('2023-05-25', 'YYYY-MM-DD'), 250, 2800.00, 'В работе');

INSERT INTO BOOK_ORDER (BOOK_ID, CUSTOMER_ID, BOOK_CHARACTERISTICS_ID, DATE_OF_ORDER, EDITION, TOTAL_PRICE, STATUS)
VALUES (1, 1, 1, TO_DATE('2023-06-30', 'YYYY-MM-DD'), 100, 1500.00, 'Создан');

INSERT INTO BOOK_ORDER (BOOK_ID, CUSTOMER_ID, BOOK_CHARACTERISTICS_ID, DATE_OF_ORDER, EDITION, TOTAL_PRICE, STATUS)
VALUES (2, 2, 2, TO_DATE('2023-07-05', 'YYYY-MM-DD'), 200, 2500.00, 'В работе');

INSERT INTO BOOK_ORDER (BOOK_ID, CUSTOMER_ID, BOOK_CHARACTERISTICS_ID, DATE_OF_ORDER, EDITION, TOTAL_PRICE, STATUS)
VALUES (3, 3, 3, TO_DATE('2023-08-10', 'YYYY-MM-DD'), 150, 1800.00, 'Создан');

INSERT INTO BOOK_ORDER (BOOK_ID, CUSTOMER_ID, BOOK_CHARACTERISTICS_ID, DATE_OF_ORDER, EDITION, TOTAL_PRICE, STATUS)
VALUES (4, 4, 4, TO_DATE('2023-09-15', 'YYYY-MM-DD'), 300, 3500.00, 'Готов');

INSERT INTO BOOK_ORDER (BOOK_ID, CUSTOMER_ID, BOOK_CHARACTERISTICS_ID, DATE_OF_ORDER, EDITION, TOTAL_PRICE, STATUS)
VALUES (6, 5, 5, TO_DATE('2023-10-20', 'YYYY-MM-DD'), 250, 2800.00, 'В работе');


-- Для Джоан Роулинг
INSERT INTO BOOK (NAME, AUTHOR_ID, YEAR_OF_PUBLISHING, GENRE_ID)
VALUES ('Гарри Поттер и Тайная комната', 1, 1998, 1);
INSERT INTO BOOK (NAME, AUTHOR_ID, YEAR_OF_PUBLISHING, GENRE_ID)
VALUES ('Гарри Поттер и узник Азкабана', 1, 1999, 1);

-- Для Федора Достоевского
INSERT INTO BOOK (NAME, AUTHOR_ID, YEAR_OF_PUBLISHING, GENRE_ID)
VALUES ('Идиот', 2, 1869, 2);
INSERT INTO BOOK (NAME, AUTHOR_ID, YEAR_OF_PUBLISHING, GENRE_ID)
VALUES ('Братья Карамазовы', 2, 1880, 2);

-- Для Эрнеста Хемингуэя
INSERT INTO BOOK (NAME, AUTHOR_ID, YEAR_OF_PUBLISHING, GENRE_ID)
VALUES ('По ком звонит колокол', 3, 1940, 2);
INSERT INTO BOOK (NAME, AUTHOR_ID, YEAR_OF_PUBLISHING, GENRE_ID)
VALUES ('И струя пройдет через камень', 3, 1942, 2);

-- Для Льва Толстого
INSERT INTO BOOK (NAME, AUTHOR_ID, YEAR_OF_PUBLISHING, GENRE_ID)
VALUES ('Анна Каренина', 4, 1877, 2);
INSERT INTO BOOK (NAME, AUTHOR_ID, YEAR_OF_PUBLISHING, GENRE_ID)
VALUES ('Воскресение', 4, 1899, 2);

-- Для Джорджа Оруэлла
INSERT INTO BOOK (NAME, AUTHOR_ID, YEAR_OF_PUBLISHING, GENRE_ID)
VALUES ('Скотный двор', 6, 1945, 1);
INSERT INTO BOOK (NAME, AUTHOR_ID, YEAR_OF_PUBLISHING, GENRE_ID)
VALUES ('Партия', 6, 1949, 1);

-- Вычисление итогов выпуска продукции определенного направления помесячно, за квартал, за полгода, за год.

SELECT EXTRACT(YEAR FROM DATE_OF_ORDER)                                         AS YEAR,
       CASE WHEN EXTRACT(MONTH FROM DATE_OF_ORDER) <= 6 THEN 'H1' ELSE 'H2' END AS HALF_YEAR,
       CASE
           WHEN EXTRACT(MONTH FROM DATE_OF_ORDER) <= 3
               THEN 'Q1'
           WHEN EXTRACT(MONTH FROM DATE_OF_ORDER) <= 6
               THEN 'Q2'
           WHEN EXTRACT(MONTH FROM DATE_OF_ORDER) <= 9
               THEN 'Q3'
           ELSE 'Q4'
           END                                                                  AS QUARTER,
       TO_CHAR(DATE_OF_ORDER, 'month')                                          AS MONTH,
       SUM(EDITION) OVER (PARTITION BY EXTRACT(MONTH FROM DATE_OF_ORDER))       AS MONTH_TOTAL,
       SUM(EDITION) OVER (PARTITION BY EXTRACT(YEAR FROM DATE_OF_ORDER),
           CASE
               WHEN EXTRACT(MONTH FROM DATE_OF_ORDER) <= 3
                   THEN 1
               WHEN EXTRACT(MONTH FROM DATE_OF_ORDER) <= 6
                   THEN 2
               WHEN EXTRACT(MONTH FROM DATE_OF_ORDER) <= 9
                   THEN 3
               ELSE 4
               END)                                                             AS QUARTER_TOTAL,
       SUM(EDITION) OVER (PARTITION BY EXTRACT(YEAR FROM DATE_OF_ORDER),
           CASE
               WHEN EXTRACT(MONTH FROM DATE_OF_ORDER) <= 6 THEN 1
               ELSE 2 END)                                                      AS HALF_YEAR_TOTAL,
       SUM(EDITION) OVER (PARTITION BY EXTRACT(YEAR FROM DATE_OF_ORDER))        AS YEAR_TOTAL
FROM BOOK_ORDER
ORDER BY YEAR, EXTRACT(MONTH FROM DATE_OF_ORDER);

-- Вычисление итогов выпуска продукции определенного направления за определенный период:
-- •	объем выпуска;
-- •	сравнение с общим объемом выпуска (в %);
-- •	сравнение с пиковыми значениями объема выпуска (в %).

SELECT EXTRACT(YEAR FROM DATE_OF_ORDER)                                                    AS YEAR,
       TOTAL_BY_YEAR,
       PEAK_IN_YEAR,
       EDITION,
       RATIO_TO_REPORT(EDITION) OVER (PARTITION BY EXTRACT(YEAR FROM DATE_OF_ORDER)) * 100 AS PERCENT_OF_TOTAL,
       ROUND(EDITION / (PEAK_IN_YEAR) * 100, 2)                                            AS PERCENT_OF_PEAK
FROM (SELECT EDITION,
             DATE_OF_ORDER,
             MAX(EDITION) OVER (PARTITION BY EXTRACT(YEAR FROM DATE_OF_ORDER)) AS PEAK_IN_YEAR,
             SUM(EDITION) OVER (PARTITION BY EXTRACT(YEAR FROM DATE_OF_ORDER)) AS TOTAL_BY_YEAR
      FROM BOOK_ORDER
      WHERE EXTRACT(YEAR FROM DATE_OF_ORDER) = '2023');

-- Вернуть для каждого автора количество изданных книг за последние 6 месяцев помесячно.
SELECT A.FIRST_NAME || ' ' || A.LAST_NAME                                      AS AUTHOR,
       TO_CHAR(DATE_OF_ORDER, 'Month')                                         AS MONTH,
       SUM(EDITION) OVER (PARTITION BY A.ID, TO_CHAR(DATE_OF_ORDER, 'Month')) AS BOOKS_PUBLISHED_LAST_6_MONTHS
FROM BOOK B
         JOIN
     AUTHOR A ON B.AUTHOR_ID = A.ID
         JOIN BOOK_ORDER BO on B.ID = BO.BOOK_ID
WHERE BO.DATE_OF_ORDER >= ADD_MONTHS(SYSDATE, -6)
ORDER BY AUTHOR, TO_CHAR(DATE_OF_ORDER, 'Month');


-- Какой жанр пользовался наибольшей популярностью для определенного автора? Вернуть для всех авторов.
WITH AuthorGenreRank AS (SELECT A.FIRST_NAME,
                                A.LAST_NAME,
                                G.NAME                                                 AS GENRE,
                                RANK() OVER (PARTITION BY A.ID ORDER BY COUNT(*) DESC) AS GENRE_RANK
                         FROM AUTHOR A
                                  JOIN
                              BOOK B ON A.ID = B.AUTHOR_ID
                                  JOIN
                              GENRE G ON B.GENRE_ID = G.ID
                         GROUP BY A.ID, A.FIRST_NAME, A.LAST_NAME, G.NAME)
SELECT FIRST_NAME,
       LAST_NAME,
       GENRE
FROM AuthorGenreRank
WHERE GENRE_RANK = 1;
