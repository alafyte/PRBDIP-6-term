-- 6.	Определите тип пространственных данных во всех таблицах.
SELECT DISTINCT CASE
                    SDO_GEOMETRY.GET_GTYPE(GEOM)
                    WHEN 0 THEN 'UNKNOWN_GEOMETRY'
                    WHEN 1 THEN 'POINT'
                    WHEN 2 THEN 'LINE or CURVE'
                    WHEN 3 THEN 'POLYGON or SURFACE'
                    WHEN 4 THEN 'COLLECTION'
                    WHEN 5 THEN 'MULTIPOINT'
                    WHEN 6 THEN 'MULTILINE or MULTICURVE'
                    WHEN 7 THEN 'MULTIPOLYGON or MULTISURFACE'
                    WHEN 8 THEN 'SOLID'
                    WHEN 9 THEN 'MULTISOLID'
                    ELSE 'UNKNOWN'
                    END AS geometry_type
FROM WORLD_COUNTRIES;


-- 7.	Определите SRID.
SELECT SRID
FROM USER_SDO_GEOM_METADATA
WHERE TABLE_NAME = 'WORLD_COUNTRIES';

-- 8.	Определите атрибутивные столбцы.
SELECT COLUMN_NAME
FROM USER_TAB_COLUMNS
WHERE TABLE_NAME = 'WORLD_COUNTRIES';

-- 9.	Верните описания пространственных объектов в формате WKT.
SELECT SDO_UTIL.TO_WKTGEOMETRY(geom) AS wkt_description
FROM WORLD_COUNTRIES;

-- 10.1. Нахождение пересечения пространственных объектов
SELECT a."country"
FROM WORLD_COUNTRIES a,
     WORLD_COUNTRIES b
WHERE a.id <> b.id
  AND SDO_RELATE(a.geom, b.geom, 'mask=anyinteract') = 'TRUE';


-- 10.2. Нахождение координат вершин пространственного объекта
SELECT SDO_UTIL.TO_WKTGEOMETRY(geom) AS vertices
FROM WORLD_COUNTRIES;

-- 10.3. Нахождение площади пространственных объектов
SELECT SDO_GEOM.SDO_AREA(geom, 0.005) AS area
FROM WORLD_COUNTRIES;

-- 11.	Создайте пространственный объект в виде точки (1) /линии (2) /полигона (3).
-- 12.	Найдите, в какие пространственные объекты попадают созданные вами объекты.
SELECT SDO_GEOMETRY(2002, 4326, NULL, SDO_ELEM_INFO_ARRAY(1, 2, 1),
                    SDO_ORDINATE_ARRAY(0, 0, 10, 10, 20, 25, 50, 60))
FROM DUAL;
SELECT SDO_GEOMETRY(2001, 4326, SDO_POINT_TYPE(15, 10, NULL), NULL, NULL)
FROM DUAL;
SELECT SDO_GEOMETRY(2003, 4326, NULL, SDO_ELEM_INFO_ARRAY(1, 1003, 1),
                    SDO_ORDINATE_ARRAY(0, 0, 20, 0, 20, 30, 0, 30, 0, 0))
FROM DUAL;

DECLARE
    point   SDO_GEOMETRY;
    line    SDO_GEOMETRY;
    polygon SDO_GEOMETRY;
BEGIN
    point := SDO_GEOMETRY(2001, 4326, SDO_POINT_TYPE(15, 10, NULL), NULL, NULL);
    line := SDO_GEOMETRY(2002, 4326, NULL, SDO_ELEM_INFO_ARRAY(1, 2, 1),
                         SDO_ORDINATE_ARRAY(0, 0, 10, 10, 20, 25, 50, 60));
    polygon := SDO_GEOMETRY(2003, 4326, NULL, SDO_ELEM_INFO_ARRAY(1, 1003, 1),
                            SDO_ORDINATE_ARRAY(0, 0, 20, 0, 20, 30, 0, 30, 0, 0));
    FOR country_rec IN (SELECT * FROM WORLD_COUNTRIES WHERE SDO_RELATE(GEOM, point, 'mask=anyinteract') = 'TRUE')
        LOOP
            DBMS_OUTPUT.PUT_LINE('Country: ' || country_rec."country");
        END LOOP;
    FOR country_rec IN (SELECT * FROM WORLD_COUNTRIES WHERE SDO_RELATE(GEOM, line, 'mask=anyinteract') = 'TRUE')
        LOOP
            DBMS_OUTPUT.PUT_LINE('Countries by line : ' || country_rec."country");
        END LOOP;
    FOR country_rec IN (SELECT * FROM WORLD_COUNTRIES WHERE SDO_RELATE(GEOM, polygon, 'mask=anyinteract') = 'TRUE')
        LOOP
            DBMS_OUTPUT.PUT_LINE('Countries by polygon: ' || country_rec."country");
        END LOOP;
END;

-- 13.	Продемонстрируйте индексирование пространственных объектов.
-- drop index spatial_index_land;
CREATE INDEX spatial_index_land
    ON WORLD_COUNTRIES (GEOM)
    INDEXTYPE IS MDSYS.SPATIAL_INDEX
    PARAMETERS ('layer_gtype=MULTIPOLYGON');

SELECT "country" FROM world_countries WHERE SDO_RELATE(geom, SDO_GEOMETRY(2003, 4326, NULL, SDO_ELEM_INFO_ARRAY(1, 1003, 1),
                    SDO_ORDINATE_ARRAY(-10, -10, 10, -10, 10, 10, -10, 10, -10, -10)), 'mask=anyinteract') = 'TRUE';


-- 14. Разработайте хранимую процедуру, которая принимает координаты точки и возвращает пространственный объект,
-- в который эта точка попадает.

CREATE OR REPLACE PROCEDURE GetPolygonFromPoint(
    p_X NUMBER,
    p_Y NUMBER,
    p_Polygon OUT INT
)
AS
BEGIN
    DECLARE
        v_Point SDO_GEOMETRY := SDO_GEOMETRY(
                2001,
                4326,
                SDO_POINT_TYPE(p_X, p_Y, NULL),
                NULL,
                NULL
            );
    BEGIN
        SELECT id
        INTO p_Polygon
        FROM WORLD_COUNTRIES
        WHERE SDO_RELATE(geom, v_Point, 'mask=contains') = 'TRUE'
          AND ROWNUM = 1;
    END;
END;

DECLARE
    v_ResultPolygon INT;
    v_ResultCountry varchar2(2047);
BEGIN
    GetPolygonFromPoint(30, 40, v_ResultPolygon);
    SELECT "country" INTO v_ResultCountry FROM WORLD_COUNTRIES WHERE id = 362;
    DBMS_OUTPUT.PUT_LINE('Country: ' || v_ResultCountry);
END;