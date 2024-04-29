-- Создайте таблицу Report, содержащую два столбца – id и XML-столбец в базе данных SQL Server.
CREATE TABLE Report
(
    id       NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    xml_data XMLTYPE
);


-- Создайте процедуру генерации XML. XML должен включать данные из как минимум 3 соединенных таблиц,
-- различные промежуточные итоги и штамп времени.

CREATE OR REPLACE PROCEDURE GENERATE_XML_REPORT(GeneratedXML OUT XMLTYPE)
    IS
BEGIN
    SELECT XMLElement("Data",
                      XMLForest(
                                      SYSTIMESTAMP AS "Timestamp",
                                      XMLAgg(
                                              XMLElement("Book",
                                                         XMLForest(
                                                                 b.NAME AS "BookName",
                                                                 a.FIRST_NAME || ' ' || a.LAST_NAME AS "AuthorName",
                                                                 g.NAME AS "Genre",
                                                                 bc.COVER_TYPE AS "CoverType",
                                                                 bc.PAPER_TYPE AS "PaperType",
                                                                 bc.BINDING_TYPE AS "BindingType",
                                                                 bc.NUMBER_OF_PAGES AS "NumberOfPages",
                                                                 bc.PAPER_SIZE AS "PaperSize"
                                                             )
                                                  )
                                          ) AS "Books",
                                      XMLAgg(
                                              XMLElement("Customer",
                                                         XMLForest(
                                                                 c.FIRST_NAME AS "CustomerFirstName",
                                                                 c.LAST_NAME AS "CustomerLastName",
                                                                 c.PATRONYMIC AS "CustomerPatronymic",
                                                                 c.PHONE_NUMBER AS "CustomerPhoneNumber",
                                                                 c.EMAIL AS "CustomerEmail",
                                                                 c.TYPE AS "CustomerType"
                                                             )
                                                  )
                                          ) AS "Customers",
                                      XMLAgg(
                                              XMLElement("Order",
                                                         XMLForest(
                                                                 bo.DATE_OF_ORDER AS "DateOfOrder",
                                                                 bo.EDITION AS "Edition",
                                                                 bo.TOTAL_PRICE AS "TotalPrice",
                                                                 bo.STATUS AS "Status"
                                                             )
                                                  )
                                          ) AS "Orders"
                          )
               )
    INTO GeneratedXML
    FROM DUAL
             CROSS JOIN
         BOOK b
             JOIN
         AUTHOR a ON b.AUTHOR_ID = a.ID
             JOIN
         GENRE g ON b.GENRE_ID = g.ID
             JOIN
         BOOK_CHARACTERISTICS bc ON b.ID = bc.ID
             JOIN
         BOOK_ORDER bo ON bo.ID = bc.ID
             JOIN
         CUSTOMER c ON c.ID = bo.CUSTOMER_ID;
END;

-- Создайте процедуру вставки этого XML в таблицу Report.
CREATE OR REPLACE PROCEDURE INSERT_XML_INTO_REPORT
    IS
    ReportXML XMLTYPE;
BEGIN
    GENERATE_XML_REPORT(ReportXML);
    INSERT INTO Report (xml_data) VALUES (ReportXML);
    COMMIT;
END;

BEGIN
    INSERT_XML_INTO_REPORT();
END;

SELECT *
FROM REPORT;


-- Создайте индекс над XML-столбцом в таблице Report.
CREATE INDEX XML_INDEX on Report (extractvalue(XML_DATA, '/Data/Books/Book[0]/BookName/text()'));

SELECT *
FROM REPORT
WHERE EXTRACTVALUE(XML_DATA, '/Data/Books/Book[0]/BookName/text()') = 'Преступление и наказание';



-- Создайте процедуру извлечения значений элементов и/или
-- атрибутов из XML -столбца в таблице Report (параметр – значение атрибута или элемента).
CREATE OR REPLACE PROCEDURE GET_XML_VALUE(
    p_id IN NUMBER,
    p_xpath IN VARCHAR2,
    p_result OUT VARCHAR2
)
IS
BEGIN
    SELECT EXTRACTVALUE(xml_data, p_xpath)
    INTO p_result
    FROM Report
    WHERE id = p_id;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        p_result := NULL;
END GET_XML_VALUE;



DECLARE
    v_result VARCHAR2(100);
BEGIN
    GET_XML_VALUE(1, '/Data/Books/Book[1]/BookName/text()', v_result);
    DBMS_OUTPUT.PUT_LINE('Book Name: ' || v_result);
END;

