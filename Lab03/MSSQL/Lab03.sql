USE EDITION;

ALTER TABLE GENRE
    ADD NODE hierarchyid;

-- Создать процедуру, которая отобразит все подчиненные узлы с указанием уровня иерархии (параметр – значение узла).
CREATE OR ALTER PROCEDURE GET_SUBGENRES (
    @Node hierarchyid
) AS
BEGIN
    SELECT
        @Node.ToString() AS NodePath,
        @Node.GetLevel() AS NodeLevel,
        ID,
        NAME,
        AGE_RATING
    FROM
        GENRE
    WHERE
        NODE = @Node;

    WITH RecursiveSubgenres AS (
        SELECT
            NODE,
            ID,
            NAME,
            AGE_RATING,
            1 AS NodeLevel
        FROM
            GENRE
        WHERE
            NODE.GetAncestor(1) = @Node
        UNION ALL
        SELECT
            g.NODE,
            g.ID,
            g.NAME,
            g.AGE_RATING,
            rs.NodeLevel + 1 AS NodeLevel
        FROM
            GENRE g
        INNER JOIN
            RecursiveSubgenres rs ON g.NODE.GetAncestor(1) = rs.NODE
    )
    SELECT
        NODE.ToString() AS NodePath,
        NodeLevel,
        ID,
        NAME,
        AGE_RATING
    FROM
        RecursiveSubgenres;
END;


go
-- Создать процедуру, которая добавит подчиненный узел (параметр – значение родительского узла).
CREATE OR ALTER PROCEDURE ADD_SUBGENRE @Name NVARCHAR(MAX),
                                       @HID hierarchyid
AS
BEGIN
    DECLARE @LCV hierarchyid;
    DECLARE @ParentAgeRating NVARCHAR(10);

    BEGIN TRANSACTION;

    SELECT @LCV = MAX(NODE)
    FROM GENRE
    WHERE NODE.GetAncestor(1) = @HID;
    SELECT @ParentAgeRating = AGE_RATING
    FROM GENRE
    WHERE NODE = @HID;

    INSERT INTO GENRE (NAME, AGE_RATING, NODE)
    VALUES (@Name, @ParentAgeRating, @HID.GetDescendant(@LCV, NULL));
    COMMIT;
END;

go
-- Создать процедуру, которая переместит всех подчиненных (первый параметр – значение родительского узла, подчиненные которого будут перемещаться, второй параметр – значение нового родительского узла).
CREATE OR ALTER PROCEDURE MOVE_GENRE_BRANCH @ANCESTOR_OLD hierarchyid,
                                            @ANCESTOR_NEW hierarchyid
AS
BEGIN
    DECLARE @HID_DESCENDANT hierarchyid;
    DECLARE @HID_NEW hierarchyid;
    DECLARE @ParentRating NVARCHAR(10);

    DECLARE CURSOR_DESCENDANT CURSOR FOR
        SELECT NODE
        FROM GENRE
        WHERE NODE.GetAncestor(1) = @ANCESTOR_OLD;

    OPEN CURSOR_DESCENDANT;
    FETCH NEXT FROM CURSOR_DESCENDANT INTO @HID_DESCENDANT;

    SELECT @ParentRating = AGE_RATING
    FROM GENRE
    WHERE NODE = @ANCESTOR_NEW;

    WHILE @@FETCH_STATUS = 0
        BEGIN
            DECLARE @Retry INT = 0;
            DECLARE @MaxRetry INT = 3;

            WHILE @Retry < @MaxRetry
                BEGIN
                    BEGIN TRY
                        SELECT @HID_NEW = @ANCESTOR_NEW.GetDescendant(MAX(NODE), NULL)
                        FROM GENRE
                        WHERE NODE.GetAncestor(1) = @ANCESTOR_NEW;


                        UPDATE GENRE
                        SET NODE       = NODE.GetReparentedValue(@HID_DESCENDANT, @HID_NEW),
                            AGE_RATING = @ParentRating
                        WHERE NODE.IsDescendantOf(@HID_DESCENDANT) = 1;


                        BREAK;
                    END TRY
                    BEGIN CATCH
                        SET @Retry += 1;

                        IF @Retry = @MaxRetry
                            BEGIN
                                THROW;
                            END;
                    END CATCH;
                END;

            FETCH NEXT FROM CURSOR_DESCENDANT INTO @HID_DESCENDANT;
        END;

    CLOSE CURSOR_DESCENDANT;
    DEALLOCATE CURSOR_DESCENDANT;
END;


go
-- Добавление корневых элементов
UPDATE GENRE SET NODE = '/1/' WHERE ID = 1;
UPDATE GENRE SET NODE = '/2/' WHERE ID = 2;
UPDATE GENRE SET NODE = '/3/' WHERE ID = 3;
UPDATE GENRE SET NODE = '/4/' WHERE ID = 4;
UPDATE GENRE SET NODE = '/5/' WHERE ID = 5;

SELECT NODE FROM GENRE;


-- Фантастика
EXEC ADD_SUBGENRE N'Киберпанк', '/1/';
EXEC ADD_SUBGENRE N'Космическая опера', '/1/';
EXEC ADD_SUBGENRE N'Альтернативная история', '/1/';

EXEC ADD_SUBGENRE N'Стимпанк', '/1/1/';
EXEC ADD_SUBGENRE N'Биопанк', '/1/1/';

-- Роман
EXEC ADD_SUBGENRE N'Исторический роман', '/2/';
EXEC ADD_SUBGENRE N'Любовный роман', '/2/';
EXEC ADD_SUBGENRE N'Психологический роман', '/2/';

-- Детектив
EXEC ADD_SUBGENRE N'Полицейский детектив', '/3/';
EXEC ADD_SUBGENRE N'Шпионский детектив', '/3/';
EXEC ADD_SUBGENRE N'Юридический детектив', '/3/';

-- Приключения
EXEC ADD_SUBGENRE N'Пиратские приключения', '/4/';
EXEC ADD_SUBGENRE N'Археологические приключения', '/4/';
EXEC ADD_SUBGENRE N'Путешествия в неизведанные земли', '/4/';

-- Фэнтези
EXEC ADD_SUBGENRE N'Эпическое фэнтези', '/5/';
EXEC ADD_SUBGENRE N'Мифическое фэнтези', '/5/';
EXEC ADD_SUBGENRE N'Темное фэнтези', '/5/';


EXEC GET_SUBGENRES '/';
EXEC GET_SUBGENRES '/1/';
EXEC GET_SUBGENRES '/1/1/';

INSERT INTO GENRE (NAME, AGE_RATING, NODE)
VALUES (N'Тестовый жанр', '6+', '/6/');
INSERT INTO GENRE (NAME, AGE_RATING, NODE)
VALUES (N'Тестовый жанр 2', '18+', '/7/');
EXEC ADD_SUBGENRE N'Тестовый поджанр', '/6/';
EXEC ADD_SUBGENRE N'Тестовый подподжанр', '/6/1/';


EXEC GET_SUBGENRES '/6/';
EXEC GET_SUBGENRES '/6/1/';
EXEC GET_SUBGENRES '/7/';


EXEC MOVE_GENRE_BRANCH '/6/1/', '/6/';
EXEC MOVE_GENRE_BRANCH '/6/', '/7/';

