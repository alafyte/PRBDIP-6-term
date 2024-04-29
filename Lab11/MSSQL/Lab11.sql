CREATE FUNCTION GET_AUTHORS_AND_BOOKS(
    @StartDate INT,
    @EndDate INT
)
    RETURNS TABLE
        AS
        RETURN
            (
                SELECT A.ID                             AS AUTHOR_ID,
                       A.FIRST_NAME + ' ' + A.LAST_NAME AS AUTHOR_NAME,
                       B.ID                             AS BOOK_ID,
                       B.NAME                           AS BOOK_NAME,
                       B.YEAR_OF_PUBLISHING AS YEAR_OF_PUBLISHING
                FROM AUTHOR A
                         INNER JOIN
                     BOOK B ON A.ID = B.AUTHOR_ID
                WHERE B.YEAR_OF_PUBLISHING BETWEEN @StartDate AND @EndDate
            );

GO


SELECT *
FROM GET_AUTHORS_AND_BOOKS(1940, 1955);


CREATE DATABASE EDITION_COPY;
USE EDITION_COPY;

CREATE TABLE AUTHOR (
    ID INT PRIMARY KEY,
    FIRST_NAME NVARCHAR(50) NOT NULL,
    LAST_NAME NVARCHAR(50) NOT NULL,
    PATRONYMIC NVARCHAR(50) NOT NULL,
    COUNTRY NVARCHAR(50) NOT NULL
);

SELECT * FROM AUTHOR;
