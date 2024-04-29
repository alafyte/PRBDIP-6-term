-- Создайте таблицу Report, содержащую два столбца – id и XML-столбец в базе данных SQL Server.
CREATE TABLE Report
(
    id       INT PRIMARY KEY IDENTITY (1, 1),
    xml_data XML
);

-- Создайте процедуру генерации XML. XML должен включать данные из как минимум 3 соединенных таблиц,
-- различные промежуточные итоги и штамп времени.

CREATE OR ALTER PROCEDURE GENERATE_XML_REPORT @GeneratedXML XML OUT
AS
BEGIN
    SET @GeneratedXML = (SELECT GETDATE() AS Timestamp,
                                (SELECT b.NAME                                 AS BookName,
                                        CONCAT(a.FIRST_NAME, ' ', a.LAST_NAME) AS AuthorName,
                                        g.NAME                                 AS Genre,
                                        bc.COVER_TYPE                          AS CoverType,
                                        bc.PAPER_TYPE                          AS PaperType,
                                        bc.BINDING_TYPE                        AS BindingType,
                                        bc.NUMBER_OF_PAGES                     AS NumberOfPages,
                                        bc.PAPER_SIZE                          AS PaperSize
                                 FROM BOOK b
                                          INNER JOIN AUTHOR a ON b.AUTHOR_ID = a.ID
                                          INNER JOIN GENRE g ON b.GENRE_ID = g.ID
                                          INNER JOIN BOOK_CHARACTERISTICS bc ON b.ID = bc.ID
                                 FOR XML PATH('Book'), TYPE),
                                (SELECT c.FIRST_NAME   AS CustomerFirstName,
                                        c.LAST_NAME    AS CustomerLastName,
                                        c.PATRONYMIC   AS CustomerPatronymic,
                                        c.PHONE_NUMBER AS CustomerPhoneNumber,
                                        c.EMAIL        AS CustomerEmail,
                                        c.TYPE         AS CustomerType
                                 FROM CUSTOMER c
                                 FOR XML PATH('Customer'), TYPE),
                                (SELECT bo.DATE_OF_ORDER AS DateOfOrder,
                                        bo.EDITION       AS Edition,
                                        bo.TOTAL_PRICE   AS TotalPrice,
                                        bo.STATUS        AS Status
                                 FROM BOOK_ORDER bo
                                 FOR XML PATH('Order'), TYPE)
                         FOR XML PATH('Data'), ROOT('Report'), TYPE);
END;

-- Создайте процедуру вставки этого XML в таблицу Report.
GO
CREATE OR ALTER PROCEDURE INSERT_XML_INTO_REPORT
AS
BEGIN
    DECLARE @ReportXML XML;
    EXEC GENERATE_XML_REPORT @GeneratedXML = @ReportXML OUT;
    SELECT @ReportXML AS GeneratedXML;

    SELECT @ReportXML;
    INSERT INTO Report (xml_data)
    VALUES (@ReportXML);
END;

GO
EXEC INSERT_XML_INTO_REPORT;

SELECT * FROM Report;
GO

-- Создайте индекс над XML-столбцом в таблице Report.
CREATE PRIMARY XML INDEX IDX_XML_PRIMARY ON REPORT(xml_data);
CREATE XML INDEX IDX_XML_SECONDARY ON REPORT(xml_data)
USING XML INDEX IDX_XML_PRIMARY FOR PATH;
GO

SELECT
    R.id,
    M.C.value('(/Report/Data/Book/BookName/text())[1]', 'nvarchar(max)') AS VALUE
FROM
    REPORT R
OUTER APPLY
    R.xml_data.nodes('/row') AS M(C);



-- Создайте процедуру извлечения значений элементов и/или
-- атрибутов из XML -столбца в таблице Report (параметр – значение атрибута или элемента).

CREATE OR ALTER PROCEDURE GET_XML_ATTRIBUTE_VALUE
    @NODE_NAME NVARCHAR(MAX)
AS
BEGIN
    DECLARE @sql NVARCHAR(MAX);
    SET @sql = '
        SELECT
            R.id,
            M.C.value(''(' + @NODE_NAME + ')[1]'', ''nvarchar(max)'') AS VALUE
        FROM
            REPORT R
        OUTER APPLY
            R.xml_data.nodes(''/row'') AS M(C)';

    EXEC sp_executesql @sql;
END;
GO


EXEC GET_XML_ATTRIBUTE_VALUE '/Report/Data/Book/BookName/text()';
