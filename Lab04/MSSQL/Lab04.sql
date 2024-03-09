-- 6.	Определите тип пространственных данных во всех таблицах.
SELECT DISTINCT SUBSTRING(geom.STAsText(), 1, CHARINDEX(' ', geom.STAsText() + ' ') - 1) as GeometryType
FROM world_countries;

-- 7.	Определите SRID.
SELECT DISTINCT GEOM.STSrid AS SRID
FROM world_countries;

-- 8.	Определите атрибутивные столбцы.
SELECT COLUMN_NAME
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'world_countries';

-- 9.	Верните описания пространственных объектов в формате WKT.
SELECT geom.STAsText() AS wkt_description
FROM world_countries;

-- 10.1. Нахождение пересечения пространственных объектов
SELECT A.geom.STIntersection(B.geom) AS intersection_geom
FROM (SELECT id, geom.MakeValid() AS geom
      FROM world_countries) A,
     (SELECT id, geom.MakeValid() AS geom
      FROM world_countries) B
WHERE A.id <> B.id
  AND A.geom.STIntersects(B.geom) = 1;


-- 10.2. Нахождение координат вершин пространственного объекта
DECLARE @geom geometry, @id int = 49;
SET @geom = (SELECT geom.STAsText() AS vertice
             FROM world_countries
             WHERE id = @id);
SELECT @geom.STAsText() AS vertices;

-- 10.3. Нахождение площади пространственных объектов
SELECT id, geom.MakeValid().STArea() AS area
FROM world_countries;


-- 11.	Создайте пространственный объект в виде точки (1) /линии (2) /полигона (3).
-- 12.	Найдите, в какие пространственные объекты попадают созданные вами объекты.
DECLARE @point geometry;
DECLARE @line geometry;
DECLARE @polygon geometry;

SET @point = geometry::STPointFromText('POINT(15 10)', 4326);
SET @line = geometry::STLineFromText('LINESTRING(0 0, 10 10, 20 25, 50 60)', 4326);
SET @polygon = geometry::STPolyFromText('POLYGON((0 0, 20 0, 20 30, 0 30, 0 0))', 4326);

SELECT @point;
SELECT @line ;
SELECT @polygon;

SELECT country FROM world_countries WHERE geom.STIntersects(@point) = 1;
SELECT country FROM world_countries WHERE geom.STIntersects(@line) = 1;
SELECT country FROM world_countries WHERE geom.STIntersects(@polygon) = 1;


-- 13.	Продемонстрируйте индексирование пространственных объектов.
CREATE SPATIAL INDEX spatial_index_land
    ON world_countries (geom)
    USING GEOMETRY_GRID
    WITH (
    BOUNDING_BOX = (-180, -189, 180, 180)
    );

--DROP INDEX spatial_index_land ON world_countries

DECLARE @rect geometry;
SET @rect = geometry::STGeomFromText('POLYGON((-10 -10, 10 -10, 10 10, -10 10, -10 -10))', 4326);
SELECT @rect;
SELECT country, geom
FROM world_countries
WHERE geom.STIntersects(@rect) = 1;


-- 14. Разработайте хранимую процедуру, которая принимает координаты точки и возвращает пространственный объект,
-- в который эта точка попадает.

CREATE OR ALTER PROCEDURE GetPolygonFromPoint @p_X FLOAT,
                                              @p_Y FLOAT,
                                              @p_Polygon INT OUTPUT
AS
BEGIN
    DECLARE @v_Point GEOMETRY;
    SET @v_Point =
            GEOMETRY::STPointFromText('POINT(' + CAST(30 AS VARCHAR(20)) + ' ' + CAST(40 AS VARCHAR(20)) + ')',
                                      4326);

    SELECT TOP 1 @p_Polygon = ID
    FROM world_countries
    WHERE geom.MakeValid().STIntersects(@v_Point) = 1;
END;

GO

BEGIN
    DECLARE @v_polygon INT;
    EXEC GetPolygonFromPoint 30, 40, @v_polygon OUTPUT;
    SELECT geom FROM world_countries where id = @v_polygon;
END

