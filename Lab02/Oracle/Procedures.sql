CREATE OR REPLACE PROCEDURE ADD_BOOK(
    Name IN NVARCHAR2,
    AuthorID IN INT,
    YearOfPublishing IN INT,
    GenreID IN INT
)
AS
    author_count INT;
BEGIN
    SELECT COUNT(*)
    INTO author_count
    FROM AUTHOR
    WHERE ID = AuthorID;

    IF author_count = 0 THEN
        RAISE_APPLICATION_ERROR(-20001, 'Автор с указанным ID не существует.');
    END IF;

    INSERT INTO BOOK (NAME, AUTHOR_ID, YEAR_OF_PUBLISHING, GENRE_ID)
    VALUES (Name, AuthorID, YearOfPublishing, GenreID);
END ADD_BOOK;

CREATE OR REPLACE PROCEDURE DELETE_BOOK(
    BookID IN INT
)
AS
    book_count INT;
BEGIN
    SELECT COUNT(*)
    INTO book_count
    FROM BOOK
    WHERE ID = BookID;
    IF book_count = 0 THEN
        RAISE_APPLICATION_ERROR(-20002, 'Книга с указанным ID не существует.');
    END IF;

    DELETE
    FROM BOOK
    WHERE ID = BookID;
END DELETE_BOOK;

CREATE OR REPLACE PROCEDURE UPDATE_ORDER_STATUS(
    OrderID IN INT,
    NewStatus IN VARCHAR2
)
AS
    order_count INT;
BEGIN
    SELECT COUNT(*)
    INTO order_count
    FROM BOOK_ORDER
    WHERE ID = OrderID;
    IF order_count = 0 THEN
        RAISE_APPLICATION_ERROR(-20004, 'Заказ с указанным ID не существует.');
    END IF;

    UPDATE BOOK_ORDER
    SET STATUS = NewStatus
    WHERE ID = OrderID;
END UPDATE_ORDER_STATUS;

