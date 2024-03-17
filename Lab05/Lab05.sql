-- Дополнительные данные
INSERT INTO BOOK_ORDER (BOOK_ID, CUSTOMER_ID, BOOK_CHARACTERISTICS_ID, DATE_OF_ORDER, EDITION, TOTAL_PRICE, STATUS)
VALUES (1, 1, 1, '2023-01-05', 100, 1500.00, N'Создан'),
       (2, 2, 2, '2023-02-10', 200, 2500.00, N'В работе'),
       (3, 3, 3, '2023-03-15', 150, 1800.00, N'Создан'),
       (4, 4, 4, '2023-04-20', 300, 3500.00, N'Готов'),
       (5, 5, 5, '2023-05-25', 250, 2800.00, N'В работе'),
       (1, 1, 1, '2023-06-30', 100, 1500.00, N'Создан'),
       (2, 2, 2, '2023-07-05', 200, 2500.00, N'В работе'),
       (3, 3, 3, '2023-08-10', 150, 1800.00, N'Создан'),
       (4, 4, 4, '2023-09-15', 300, 3500.00, N'Готов'),
       (5, 5, 5, '2023-10-20', 250, 2800.00, N'В работе');

-- Для Джоан Роулинг
INSERT INTO BOOK (NAME, AUTHOR_ID, YEAR_OF_PUBLISHING, GENRE_ID)
VALUES (N'Гарри Поттер и Тайная комната', 1, 1998, 1);
INSERT INTO BOOK (NAME, AUTHOR_ID, YEAR_OF_PUBLISHING, GENRE_ID)
VALUES (N'Гарри Поттер и узник Азкабана', 1, 1999, 1);

-- Для Федора Достоевского
INSERT INTO BOOK (NAME, AUTHOR_ID, YEAR_OF_PUBLISHING, GENRE_ID)
VALUES (N'Идиот', 2, 1869, 2);
INSERT INTO BOOK (NAME, AUTHOR_ID, YEAR_OF_PUBLISHING, GENRE_ID)
VALUES (N'Братья Карамазовы', 2, 1880, 2);

-- Для Эрнеста Хемингуэя
INSERT INTO BOOK (NAME, AUTHOR_ID, YEAR_OF_PUBLISHING, GENRE_ID)
VALUES (N'По ком звонит колокол', 3, 1940, 2);
INSERT INTO BOOK (NAME, AUTHOR_ID, YEAR_OF_PUBLISHING, GENRE_ID)
VALUES (N'И струя пройдет через камень', 3, 1942, 2);

-- Для Льва Толстого
INSERT INTO BOOK (NAME, AUTHOR_ID, YEAR_OF_PUBLISHING, GENRE_ID)
VALUES (N'Анна Каренина', 4, 1877, 2);
INSERT INTO BOOK (NAME, AUTHOR_ID, YEAR_OF_PUBLISHING, GENRE_ID)
VALUES (N'Воскресение', 4, 1899, 2);

-- Для Джорджа Оруэлла
INSERT INTO BOOK (NAME, AUTHOR_ID, YEAR_OF_PUBLISHING, GENRE_ID)
VALUES (N'Скотный двор', 5, 1945, 1);
INSERT INTO BOOK (NAME, AUTHOR_ID, YEAR_OF_PUBLISHING, GENRE_ID)
VALUES (N'Партия', 5, 1949, 1);


-- Вычисление итогов выпуска продукции определенного направления помесячно, за квартал, за полгода, за год.

SELECT YEAR(DATE_OF_ORDER)  AS YEAR,
       MONTH(DATE_OF_ORDER) AS MONTH,
       COUNT(*)             AS TOTAL_BOOKS_ORDERED
FROM BOOK_ORDER
GROUP BY YEAR(DATE_OF_ORDER), MONTH(DATE_OF_ORDER)
ORDER BY YEAR, MONTH;

SELECT DATEPART(YEAR, DATE_OF_ORDER)    AS YEAR,
       DATEPART(QUARTER, DATE_OF_ORDER) AS QUARTER,
       COUNT(*)                         AS TOTAL_BOOKS_ORDERED
FROM BOOK_ORDER
GROUP BY DATEPART(YEAR, DATE_OF_ORDER), DATEPART(QUARTER, DATE_OF_ORDER)
ORDER BY YEAR, QUARTER;

SELECT DATEPART(YEAR, DATE_OF_ORDER)    AS YEAR,
       DATEPART(QUARTER, DATE_OF_ORDER) AS QUARTER,
       COUNT(*)                         AS TOTAL_BOOKS_ORDERED
FROM BOOK_ORDER
GROUP BY DATEPART(YEAR, DATE_OF_ORDER), DATEPART(QUARTER, DATE_OF_ORDER)
ORDER BY YEAR, QUARTER;

SELECT YEAR(DATE_OF_ORDER)                     AS YEAR,
       CEILING(MONTH(DATE_OF_ORDER) * 1.0 / 6) AS HALFYEAR,
       COUNT(*)                                AS TOTAL_BOOKS_ORDERED
FROM BOOK_ORDER
GROUP BY YEAR(DATE_OF_ORDER), CEILING(MONTH(DATE_OF_ORDER) * 1.0 / 6)
ORDER BY YEAR, HALFYEAR;

SELECT YEAR(DATE_OF_ORDER) AS YEAR,
       COUNT(*)            AS TOTAL_BOOKS_ORDERED
FROM BOOK_ORDER
GROUP BY YEAR(DATE_OF_ORDER)
ORDER BY YEAR;

-- Вычисление итогов выпуска продукции определенного направления за определенный период:
-- •	объем выпуска;
-- •	сравнение с общим объемом выпуска (в %);
-- •	сравнение с пиковыми значениями объема выпуска (в %).

DECLARE @TotalBooksProduced INT;
DECLARE @TotalBooksSold INT;
DECLARE @ProductionPercentage DECIMAL(5, 2);
DECLARE @PeakProductionPercentage DECIMAL(5, 2);

WITH ProductionStats
         AS (SELECT COUNT(CASE WHEN YEAR(DATE_OF_ORDER) = 2023 AND STATUS = N'Готов' THEN 1 END) AS TotalBooksProduced,
                    COUNT(*)                                                                     AS TotalBooksSold
             FROM BOOK_ORDER)
SELECT @TotalBooksProduced = TotalBooksProduced,
       @TotalBooksSold = TotalBooksSold
FROM ProductionStats;

PRINT N'Книг издано за 2023: ' + CAST(@TotalBooksProduced AS VARCHAR);
PRINT N'Всего книг издано: ' + CAST(@TotalBooksSold AS VARCHAR);

SET @ProductionPercentage = (@TotalBooksProduced * 1.0 / @TotalBooksSold) * 100;

PRINT N'Процент от общего выпуска: ' + CAST(@ProductionPercentage AS VARCHAR) + '%';

WITH YearStats AS (SELECT YEAR(DATE_OF_ORDER)                    AS OrderYear,
                          COUNT(*) * 1.0 / @TotalBooksSold * 100 AS YearPercentage
                   FROM BOOK_ORDER
                   GROUP BY YEAR(DATE_OF_ORDER))
SELECT @PeakProductionPercentage = MAX(YearPercentage)
FROM YearStats;

PRINT N'Пиковый процент выпуска: ' + CAST(@PeakProductionPercentage AS VARCHAR) + '%';

IF @ProductionPercentage > @PeakProductionPercentage
    PRINT N'Продано больше пикового';
ELSE
    IF @ProductionPercentage < @PeakProductionPercentage
        PRINT N'Продано меньше пикового';
    ELSE
        PRINT N'Продажи на пике';


-- 5.	Продемонстрируйте применение функции ранжирования ROW_NUMBER() для разбиения результатов запроса на страницы (по 20 строк на каждую страницу).

WITH NumberedGenres AS (SELECT ID,
                               NAME,
                               AGE_RATING,
                               ROW_NUMBER() OVER (ORDER BY id) AS RowNum
                        FROM GENRE)
SELECT ID, NAME, AGE_RATING, RowNum
FROM NumberedGenres
--WHERE RowNum > 20;
WHERE RowNum BETWEEN 1 AND 20;

-- Продемонстрируйте применение функции ранжирования ROW_NUMBER() для удаления дубликатов.

INSERT INTO GENRE (NAME, AGE_RATING, NODE)
VALUES (N'Роман', '16+', '/6/');

WITH NumberedGenres AS (SELECT ID,
                               NAME,
                               AGE_RATING,
                               ROW_NUMBER() OVER (PARTITION BY NAME ORDER BY ID) AS RowNum
                        FROM GENRE)
DELETE
FROM NumberedGenres
WHERE RowNum > 1;

-- Вернуть для каждого автора количество изданных книг за последние 6 месяцев помесячно.
SELECT A.FIRST_NAME,
       A.LAST_NAME,
       BO.DATE_OF_ORDER AS DATE_OF_PUBLISHING,
       COUNT(*)         AS TOTAL_BOOKS_PUBLISHED
FROM AUTHOR A
         JOIN
     BOOK B ON A.ID = B.AUTHOR_ID
         JOIN
     BOOK_ORDER BO ON B.ID = BO.BOOK_ID
WHERE BO.DATE_OF_ORDER >= DATEADD(MONTH, -6, GETDATE())
GROUP BY A.FIRST_NAME,
         A.LAST_NAME,
         BO.DATE_OF_ORDER
ORDER BY A.LAST_NAME,
         A.FIRST_NAME,
         DATE_OF_PUBLISHING;

-- Найдите при помощи аналитических функций: Какой жанр пользовался наибольшей популярностью для определенного автора? Вернуть для всех авторов.
WITH AuthorGenreRank AS (SELECT A.FIRST_NAME,
                                A.LAST_NAME,
                                G.NAME                                                 AS GENRE,
                                COUNT(*)                                               AS BOOK_COUNT,
                                RANK() OVER (PARTITION BY A.ID ORDER BY COUNT(*) DESC) AS GENRE_RANK
                         FROM AUTHOR A
                                  JOIN
                              BOOK B ON A.ID = B.AUTHOR_ID
                                  JOIN
                              GENRE G ON B.GENRE_ID = G.ID
                         GROUP BY A.ID, A.FIRST_NAME, A.LAST_NAME, G.NAME)
SELECT FIRST_NAME,
       LAST_NAME,
       GENRE,
       BOOK_COUNT
FROM AuthorGenreRank
WHERE GENRE_RANK = 1;