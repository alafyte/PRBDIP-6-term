-- 2. Создать объектные типы данных по своему варианту, реализовав:
-- a. Дополнительный конструктор;
-- b. Метод сравнения типа MAP или ORDER;
-- c. Функцию, как метод экземпляра;
-- d. Процедуру. как метод экземпляра.

CREATE OR REPLACE TYPE BookType AS OBJECT
(
    ID                 INT,
    NAME               NVARCHAR2(100),
    AUTHOR_ID          NUMBER,
    YEAR_OF_PUBLISHING NUMBER,

    CONSTRUCTOR FUNCTION BookType(SELF IN OUT NOCOPY BookType, ID INT, NAME NVARCHAR2, AUTHOR_ID NUMBER,
                                  YEAR_OF_PUBLISHING NUMBER) RETURN SELF AS RESULT,
    ORDER MEMBER FUNCTION Compare(other IN BookType) RETURN INT,
    MEMBER FUNCTION GetBookInfo RETURN NVARCHAR2,
    MEMBER PROCEDURE PrintBookInfo
);


CREATE OR REPLACE TYPE BODY BookType AS
    CONSTRUCTOR FUNCTION BookType(SELF IN OUT NOCOPY BookType, ID INT, NAME NVARCHAR2, AUTHOR_ID NUMBER,
                                  YEAR_OF_PUBLISHING NUMBER) RETURN SELF AS RESULT IS
    BEGIN
        SELF.ID := ID;
        SELF.NAME := NAME;
        SELF.AUTHOR_ID := AUTHOR_ID;
        SELF.YEAR_OF_PUBLISHING := YEAR_OF_PUBLISHING;
        RETURN;
    END;

    ORDER MEMBER FUNCTION Compare(other IN BookType) RETURN INT IS
    BEGIN
        IF (self.YEAR_OF_PUBLISHING > other.YEAR_OF_PUBLISHING) THEN
            RETURN 1;
        ELSIF (self.YEAR_OF_PUBLISHING < other.YEAR_OF_PUBLISHING) THEN
            RETURN -1;
        ELSE
            RETURN 0;
        END IF;
    END;

    MEMBER FUNCTION GetBookInfo RETURN NVARCHAR2 IS
    BEGIN
        RETURN 'Book ID: ' || TO_CHAR(self.ID) || ', Title: ' || self.NAME || ', Author ID: ' ||
               TO_CHAR(self.AUTHOR_ID) || ', Published Year: ' ||
               TO_CHAR(self.YEAR_OF_PUBLISHING);
    END;

    MEMBER PROCEDURE PrintBookInfo IS
    BEGIN
        DBMS_OUTPUT.PUT_LINE(GetBookInfo);
    END;
END;


CREATE OR REPLACE TYPE AuthorType AS OBJECT
(
    ID         NUMBER,
    FIRST_NAME NVARCHAR2(50),
    LAST_NAME  NVARCHAR2(50),
    PATRONYMIC NVARCHAR2(50),
    COUNTRY    NVARCHAR2(50),

    CONSTRUCTOR FUNCTION AuthorType(SELF IN OUT NOCOPY AuthorType, ID INT, FIRST_NAME NVARCHAR2, LAST_NAME NVARCHAR2,
                                    PATRONYMIC NVARCHAR2, COUNTRY NVARCHAR2) RETURN SELF AS RESULT,
    MEMBER FUNCTION GetAuthorInfo RETURN NVARCHAR2 DETERMINISTIC,
    MEMBER PROCEDURE PrintAuthorInfo,
    ORDER MEMBER FUNCTION Compare(other IN AuthorType) RETURN INT
);


CREATE OR REPLACE TYPE BODY AuthorType AS
    CONSTRUCTOR FUNCTION AuthorType(SELF IN OUT NOCOPY AuthorType, ID INT, FIRST_NAME NVARCHAR2, LAST_NAME NVARCHAR2,
                                    PATRONYMIC NVARCHAR2, COUNTRY NVARCHAR2) RETURN SELF AS RESULT IS
    BEGIN
        SELF.ID := ID;
        SELF.FIRST_NAME := FIRST_NAME;
        SELF.LAST_NAME := LAST_NAME;
        SELF.PATRONYMIC := PATRONYMIC;
        SELF.COUNTRY := COUNTRY;
        RETURN;
    END;


    MEMBER FUNCTION GetAuthorInfo RETURN NVARCHAR2 DETERMINISTIC IS
    BEGIN
        RETURN self.FIRST_NAME || ' ' || self.LAST_NAME || ' ' || self.PATRONYMIC;
    END ;

    MEMBER PROCEDURE PrintAuthorInfo IS
    BEGIN
        DBMS_OUTPUT.PUT_LINE(GetAuthorInfo);
    END;

    ORDER MEMBER FUNCTION Compare(other IN AuthorType) RETURN INT IS
    BEGIN
        IF (self.LAST_NAME > other.LAST_NAME) THEN
            RETURN 1;
        ELSIF (self.LAST_NAME < other.LAST_NAME) THEN
            RETURN -1;
        ELSE
            RETURN 0;
        END IF;
    END Compare;
END;

DECLARE
    book      BOOKTYPE := BookType(100, 'Test', 2, 2004);
    book2     BOOKTYPE := BookType(101, 'Book 2', 2, 2003);
    book_info NVARCHAR2(4000);
BEGIN
    book_info := book.GETBOOKINFO();
    DBMS_OUTPUT.PUT_LINE(book_info);

    book.PRINTBOOKINFO();

    IF book > book2 THEN
        DBMS_OUTPUT.PUT_LINE('book > book2 ');
    ELSIF book = book2 THEN
        DBMS_OUTPUT.PUT_LINE('book = book2 ');
    ELSE
        DBMS_OUTPUT.PUT_LINE('book < book2 ');
    END IF;
end;

-- 3. Скопировать данные из реляционных таблиц в объектные.

CREATE TABLE BookTable OF BookType
(
    PRIMARY KEY (ID)
);

CREATE TABLE AuthorTable OF AuthorType
(
    PRIMARY KEY (ID)
);

BEGIN
    FOR book_rec IN (SELECT * FROM BOOK)
        LOOP
            INSERT INTO BookTable
            VALUES (BookType(
                    book_rec.ID,
                    book_rec.NAME,
                    book_rec.AUTHOR_ID,
                    book_rec.YEAR_OF_PUBLISHING
                ));
        END LOOP;

    FOR author_rec IN (SELECT * FROM AUTHOR)
        LOOP
            INSERT INTO AuthorTable
            VALUES (AuthorType(
                    author_rec.ID,
                    author_rec.FIRST_NAME,
                    author_rec.LAST_NAME,
                    author_rec.PATRONYMIC,
                    author_rec.COUNTRY
                ));
        END LOOP;
END;

-- 4. Продемонстрировать применение объектных представлений.
CREATE OR REPLACE VIEW BookView AS
SELECT a.ID, a.FIRST_NAME, a.LAST_NAME, a.PATRONYMIC, b.NAME, b.YEAR_OF_PUBLISHING
FROM BOOKTABLE b
         JOIN AUTHORTABLE a ON b.AUTHOR_ID = a.ID
ORDER BY a.ID, b.YEAR_OF_PUBLISHING;

SELECT *
FROM BOOKVIEW;

-- 5. Продемонстрировать применение индексов для индексирования по атрибуту и по методу в объектной таблице.

CREATE TABLE AUTHOR_INDEX(
  author AUTHORTYPE
);

BEGIN
    FOR i IN 1..1000
        LOOP
            INSERT INTO AUTHOR_INDEX (author) VALUES (AuthorType(i, 'FirstName ' || i, 'LastName ' || i, 'Patronymic ' || i, 'Belarus'));
        END LOOP;
END;

BEGIN
    FOR i IN 1..1000
        LOOP
            INSERT INTO BookTable (ID, NAME, AUTHOR_ID, YEAR_OF_PUBLISHING) VALUES (100 + i, 'Book ' || i, 1, 2004);
        END LOOP;
END;


CREATE INDEX idx_book_name ON BookTable (NAME);
CREATE BITMAP INDEX idx_full_name ON AUTHOR_INDEX (author.GETAUTHORINFO());

SELECT *
FROM BookTable
WHERE NAME = 'Book 44';

SELECT *
FROM AUTHOR_INDEX a
WHERE a.author.GetAuthorInfo() = 'FirstName 10 LastName 10 Patronymic 10';



