CREATE OR REPLACE FUNCTION GET_AUTHORS_AND_BOOKS(
    p_StartDate IN NUMBER,
    p_EndDate IN NUMBER
)
    RETURN SYS_REFCURSOR
    IS
    v_cursor SYS_REFCURSOR;
BEGIN
    OPEN v_cursor FOR
        SELECT A.ID                               AS AuthorID,
               A.FIRST_NAME || ' ' || A.LAST_NAME AS AuthorName,
               B.ID                               AS BookID,
               B.NAME                             AS BookName,
               B.YEAR_OF_PUBLISHING
        FROM AUTHOR A
                 INNER JOIN
             BOOK B ON A.ID = B.AUTHOR_ID
        WHERE B.YEAR_OF_PUBLISHING BETWEEN p_StartDate AND p_EndDate;

    RETURN v_cursor;
END;


CREATE OR REPLACE DIRECTORY IMPORT_DIR AS 'C:\import_dir';
GRANT READ, WRITE ON DIRECTORY IMPORT_DIR TO EDITION_ADMIN;

DECLARE
    result_cursor      SYS_REFCURSOR;
    author_id          NUMBER;
    author_name        NVARCHAR2(100);
    book_id            NUMBER;
    book_name          NVARCHAR2(100);
    year_of_publishing NUMBER;
    file_handle        UTL_FILE.FILE_TYPE;
BEGIN
    result_cursor := EDITION_ADMIN.GET_AUTHORS_AND_BOOKS(1940, 1955);

    file_handle := UTL_FILE.FOPEN('IMPORT_DIR', 'import.txt', 'W');

    LOOP
        FETCH result_cursor INTO author_id, author_name, book_id, book_name, year_of_publishing;
        EXIT WHEN result_cursor%NOTFOUND;

        UTL_FILE.PUT_LINE(file_handle, author_id || ',' || author_name || ',' || book_id || ',' || book_name || ',' ||
                                       year_of_publishing);
    END LOOP;

    CLOSE result_cursor;
    UTL_FILE.FCLOSE(file_handle);
END;

CREATE TABLE AUTHOR_COPY (
    ID INT PRIMARY KEY,
    FIRST_NAME NVARCHAR2(50) NOT NULL,
    LAST_NAME NVARCHAR2(50) NOT NULL,
    PATRONYMIC NVARCHAR2(50) NOT NULL,
    COUNTRY NVARCHAR2(50) NOT NULL
);

--sqlldr edition_admin/qwerty1234@localhost:1521/edition control=control.ctl log=export.log

SELECT * FROM AUTHOR_COPY;
--DELETE FROM AUTHOR_COPY;