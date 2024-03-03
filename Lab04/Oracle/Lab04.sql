-- 6.	Определите тип пространственных данных во всех таблицах.
SELECT CASE
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
FROM NE_110M_LAND;


-- 7.	Определите SRID.
SELECT COLUMN_NAME,
       SRID
FROM USER_SDO_GEOM_METADATA
WHERE TABLE_NAME = 'NE_110M_LAND';

-- 8.	Определите атрибутивные столбцы.
SELECT COLUMN_NAME
FROM USER_TAB_COLUMNS
WHERE TABLE_NAME = 'NE_110M_LAND';

-- 9.	Верните описания пространственных объектов в формате WKT.
SELECT SDO_UTIL.TO_WKTGEOMETRY(geom) AS wkt_description
FROM NE_110M_LAND;

-- 10.1. Нахождение пересечения пространственных объектов
SELECT SDO_GEOM.SDO_INTERSECTION(a.geom, b.geom, 0.005) AS intersection_geom
FROM NE_110M_LAND a,
     NE_110M_LAND b
WHERE a.id <> b.id
  AND SDO_RELATE(a.geom, b.geom, 'mask=anyinteract') = 'TRUE';

-- 10.2. Нахождение координат вершин пространственного объекта
SELECT SDO_UTIL.TO_WKTGEOMETRY(geom) AS vertices
FROM NE_110M_LAND;

-- 10.3. Нахождение площади пространственных объектов
SELECT SDO_GEOM.SDO_AREA(geom, 0.005) AS area
FROM NE_110M_LAND;

-- 11.	Создайте пространственный объект в виде точки (1) /линии (2) /полигона (3).
-- 12.	Найдите, в какие пространственные объекты попадают созданные вами объекты.

DECLARE
    point       SDO_GEOMETRY;
    line        SDO_GEOMETRY;
    polygon     SDO_GEOMETRY;
    rel_line    VARCHAR2(100);
    rel_polygon VARCHAR2(100);
    rel_line_polygon VARCHAR2(100);
BEGIN
    point := SDO_GEOMETRY(2001, NULL, SDO_POINT_TYPE(15, 10, NULL), NULL, NULL);
    line := SDO_GEOMETRY(2002, NULL, NULL, SDO_ELEM_INFO_ARRAY(1, 2, 1),
                         SDO_ORDINATE_ARRAY(0, 0, 10, 10, 20, 25, 50, 60));
    polygon := SDO_GEOMETRY(2003, NULL, NULL, SDO_ELEM_INFO_ARRAY(1, 1003, 1),
                            SDO_ORDINATE_ARRAY(0, 0, 20, 0, 20, 30, 0, 30, 0, 0));

    SELECT SDO_RELATE(point, line, 'mask=anyinteract') INTO rel_line FROM DUAL;
    SELECT SDO_RELATE(point, polygon, 'mask=anyinteract') INTO rel_polygon FROM DUAL;
    SELECT SDO_RELATE(line, polygon, 'mask=anyinteract') INTO rel_line_polygon FROM DUAL;

    DBMS_OUTPUT.PUT_LINE('Point Intersects Line: ' || rel_line);
    DBMS_OUTPUT.PUT_LINE('Point Intersects Polygon: ' || rel_polygon);
    DBMS_OUTPUT.PUT_LINE('Line Intersects Polygon: ' || rel_line_polygon);
END;

-- 13.	Продемонстрируйте индексирование пространственных объектов.
-- drop index spatial_index_land;
CREATE INDEX spatial_index_land
ON NE_110M_LAND(GEOM)
INDEXTYPE IS MDSYS.SPATIAL_INDEX
PARAMETERS('layer_gtype=MULTIPOLYGON');


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
        SELECT ID INTO p_Polygon
        FROM ne_110m_land
        WHERE SDO_RELATE(geom, v_Point, 'mask=contains') = 'TRUE' AND ROWNUM = 1;
    END;
END;

DECLARE
    v_ResultPolygon INT;
BEGIN
    GetPolygonFromPoint(30, 40, v_ResultPolygon);
    DBMS_OUTPUT.PUT_LINE('Polygon: ' || v_ResultPolygon);
END;