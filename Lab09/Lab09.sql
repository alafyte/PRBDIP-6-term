-- Продемонстрировать обработку данных из объектных таблиц при помощи коллекций следующим образом по варианту (в каждом варианте первая таблица t1, вторая – t2):
-- a.	Создать коллекцию на основе t1, далее K1, для нее как атрибут – вложенную коллекцию на основе t2, далее К2;
-- b.	Выяснить, является ли членом коллекции К1 какой-то произвольный элемент;
-- c.	Найти пустые коллекции К1;

DECLARE
    TYPE BookTypeCollection IS TABLE OF BookType INDEX BY PLS_INTEGER;
    TYPE AuthorTypeCollection IS TABLE OF AuthorType INDEX BY PLS_INTEGER;
    TYPE BookAuthorCollection IS TABLE OF AuthorTypeCollection INDEX BY PLS_INTEGER;

    K1                BookTypeCollection;
    K2                BookAuthorCollection;
    empty_collections VARCHAR2(1000);
    is_member         BOOLEAN;

    TYPE NewBookCollection IS TABLE OF VARCHAR2(100);
    NewBooks          NewBookCollection := NewBookCollection();
BEGIN
    FOR rec IN (SELECT * FROM BookTable)
        LOOP
            K1(rec.ID) := BOOKTYPE(rec.ID, rec.NAME, rec.AUTHOR_ID, rec.YEAR_OF_PUBLISHING);
        END LOOP;


    FOR i IN K1.FIRST .. K1.LAST
        LOOP
            BEGIN
                FOR rec IN (SELECT * FROM AuthorTable WHERE ID = K1(i).AUTHOR_ID)
                    LOOP
                                K2(i)(rec.ID) :=
                                AUTHORTYPE(rec.ID, rec.FIRST_NAME, rec.LAST_NAME, rec.PATRONYMIC, rec.COUNTRY);
                    END LOOP;
            EXCEPTION
                WHEN NO_DATA_FOUND THEN
                    NULL;
            END;
        END LOOP;

    is_member := K1.EXISTS(1);

    DBMS_OUTPUT.PUT_LINE('Is member in K1: ' || CASE WHEN is_member THEN 'yes' ELSE 'no' END);


    empty_collections := '';
    FOR i IN K1.FIRST .. K1.LAST
        LOOP
            IF K2.EXISTS(i) THEN
                IF K2(i).COUNT = 0 THEN
                    empty_collections := empty_collections || i || ', ';
                END IF;
            ELSE
                empty_collections := empty_collections || i || ', ';
            END IF;
        END LOOP;


    DBMS_OUTPUT.PUT_LINE('Empty collections in K1: ' || empty_collections);

    -- Преобразовать коллекцию к другому виду (к коллекции другого типа, к реляционным данным).

    FOR i IN K1.FIRST .. K1.LAST
        LOOP
            BEGIN
                NewBooks.EXTEND;
                NewBooks(i) :=
                            K1(i).ID || ', ' || K1(i).NAME || ', ' || K1(i).AUTHOR_ID || ', ' ||
                            K1(i).YEAR_OF_PUBLISHING;
            EXCEPTION
                WHEN NO_DATA_FOUND THEN
                    NULL;
            END;
        END LOOP;


    FOR i IN 1 .. NewBooks.COUNT
        LOOP
            DBMS_OUTPUT.PUT_LINE('New Book: ' || NewBooks(i));
        END LOOP;
END;


-- Продемонстрировать применение BULK операций на примере своих коллекций.
CREATE TABLE NewBookTable
(
    ID                 INT,
    NAME               NVARCHAR2(100),
    AUTHOR_ID          NUMBER,
    YEAR_OF_PUBLISHING NUMBER,
    CONSTRAINT pk_new_book PRIMARY KEY (ID)
);

-- DROP TABLE NewBookTable

DECLARE
    TYPE BookTypeCollection IS TABLE OF BookType INDEX BY PLS_INTEGER;
    K1 BookTypeCollection;
BEGIN
    FOR rec IN (SELECT * FROM BookTable)
        LOOP
            K1(rec.ID) := BOOKTYPE(rec.ID, rec.NAME, rec.AUTHOR_ID, rec.YEAR_OF_PUBLISHING);
        END LOOP;

    BEGIN
        FORALL i IN K1.FIRST .. K1.LAST
            INSERT INTO NewBookTable (ID, NAME, AUTHOR_ID, YEAR_OF_PUBLISHING)
            VALUES (K1(i).ID, K1(i).NAME, K1(i).AUTHOR_ID, K1(i).YEAR_OF_PUBLISHING);
    EXCEPTION WHEN OTHERS THEN
            NULL;
    END;
END;

SELECT * FROM NewBookTable;