ALTER TABLE GENRE
    ADD (PARENT_ID INT);



CREATE OR REPLACE PROCEDURE GET_SUBGENRES(
    p_genre_id INT,
    p_level INT DEFAULT 1
) AS
BEGIN
    FOR subgenre_rec IN (
        SELECT ID, NAME
        FROM GENRE
        WHERE PARENT_ID = p_genre_id
        )
        LOOP
            DBMS_OUTPUT.PUT_LINE('Level ' || p_level || ':');
            DBMS_OUTPUT.PUT_LINE('Subgenre ID: ' || subgenre_rec.ID || ', Name: ' || subgenre_rec.NAME);
            GET_SUBGENRES(subgenre_rec.ID, p_level + 1);
        END LOOP;
END;


CREATE OR REPLACE PROCEDURE ADD_SUBGENRE(
    p_name NVARCHAR2,
    p_parent_id INT
) AS
    v_parent_age_rating NVARCHAR2(10);
BEGIN
    SELECT AGE_RATING
    INTO v_parent_age_rating
    FROM GENRE
    WHERE ID = p_parent_id;

    INSERT INTO GENRE (NAME, AGE_RATING, PARENT_ID)
    VALUES (p_name, v_parent_age_rating, p_parent_id);

    COMMIT;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        DBMS_OUTPUT.PUT_LINE('Parent node with ID ' || p_parent_id || ' does not exist.');
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('An error occurred: ' || SQLERRM);

END;

CREATE OR REPLACE PROCEDURE MOVE_GENRE_BRANCH(
    p_old_parent_id INT,
    p_new_parent_id INT
) AS
BEGIN
    UPDATE GENRE
    SET AGE_RATING = (SELECT AGE_RATING FROM GENRE WHERE ID = p_new_parent_id)
    WHERE PARENT_ID = p_old_parent_id;

    UPDATE GENRE
    SET PARENT_ID = p_new_parent_id
    WHERE PARENT_ID = p_old_parent_id;
    COMMIT;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        DBMS_OUTPUT.PUT_LINE('Parent node with ID ' || p_old_parent_id || ' does not exist.');
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('An error occurred: ' || SQLERRM);
END;



BEGIN
    ADD_SUBGENRE('Киберпанк', 1);
    ADD_SUBGENRE('Космическая опера', 1);
    ADD_SUBGENRE('Альтернативная история', 1);

    ADD_SUBGENRE('Стимпанк', 21);
    ADD_SUBGENRE('Биопанк', 21);

-- Роман
    ADD_SUBGENRE('Исторический роман', 2);
    ADD_SUBGENRE('Любовный роман', 2);
    ADD_SUBGENRE('Психологический роман', 2);

-- Детектив
    ADD_SUBGENRE('Полицейский детектив', 3);
    ADD_SUBGENRE('Шпионский детектив', 3);
    ADD_SUBGENRE('Юридический детектив', 3);

-- Приключения
    ADD_SUBGENRE('Пиратские приключения', 4);
    ADD_SUBGENRE('Археологические приключения', 4);
    ADD_SUBGENRE('Путешествия в неизведанные земли', 4);

-- Фэнтези
    ADD_SUBGENRE('Эпическое фэнтези', 5);
    ADD_SUBGENRE('Мифическое фэнтези', 5);
    ADD_SUBGENRE('Темное фэнтези', 5);

END;

begin
    GET_SUBGENRES(1);
end;


INSERT INTO GENRE (NAME, AGE_RATING, PARENT_ID)
VALUES (N'Тестовый жанр', '6+', null);
INSERT INTO GENRE (NAME, AGE_RATING, PARENT_ID)
VALUES (N'Тестовый жанр 2', '18+', null);

BEGIN
    ADD_SUBGENRE('Тестовый поджанр', 38);
END;

BEGIN
    ADD_SUBGENRE('Тестовый подподжанр', 40);
END;

BEGIN
    GET_SUBGENRES(38);
    DBMS_OUTPUT.PUT_LINE('------------------');
    GET_SUBGENRES(40);
END;

BEGIN
    MOVE_GENRE_BRANCH(40, 38);
END;

BEGIN
    MOVE_GENRE_BRANCH(38, 39);
END;