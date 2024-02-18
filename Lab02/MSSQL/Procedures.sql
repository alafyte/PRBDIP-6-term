CREATE PROCEDURE ADD_BOOK @Name NVARCHAR(100),
                          @AuthorID INT,
                          @YearOfPublishing INT,
                          @GenreID INT
AS
BEGIN
    IF NOT EXISTS (SELECT 1 FROM AUTHOR WHERE ID = @AuthorID)
        BEGIN
            RAISERROR (N'Автор с указанным ID не существует.', 16, 1);
        END

    INSERT INTO BOOK (NAME, AUTHOR_ID, YEAR_OF_PUBLISHING, GENRE_ID)
    VALUES (@Name, @AuthorID, @YearOfPublishing, @GenreID);
END;

    CREATE PROCEDURE DELETE_BOOK @BookID INT
    AS
    BEGIN
        IF NOT EXISTS (SELECT 1 FROM BOOK WHERE ID = @BookID)
            BEGIN
                RAISERROR (N'Книга с указанным ID не существует.', 16, 1);
            END

        DELETE FROM BOOK WHERE ID = @BookID;
    END;


CREATE PROCEDURE GET_CUSTOMER_ORDERS
    @CustomerID INT
AS
BEGIN
    IF NOT EXISTS (SELECT 1 FROM CUSTOMER WHERE ID = @CustomerID)
    BEGIN
        RAISERROR (N'Клиент с указанным ID не существует.', 16, 1);
    END

    SELECT * FROM BOOK_ORDER WHERE CUSTOMER_ID = @CustomerID;
END;

CREATE PROCEDURE UPDATE_ORDER_STATUS
    @OrderID INT,
    @NewStatus VARCHAR(20)
AS
BEGIN
    IF NOT EXISTS (SELECT 1 FROM BOOK_ORDER WHERE ID = @OrderID)
    BEGIN
        RAISERROR (N'Заказ с указанным ID не существует.', 16, 1);
    END

    UPDATE BOOK_ORDER SET STATUS = @NewStatus WHERE ID = @OrderID;
END;
