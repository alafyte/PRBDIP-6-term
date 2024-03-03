-- 6.	Определите тип пространственных данных во всех таблицах.
SELECT DISTINCT SUBSTRING(geom.STAsText(), 1, CHARINDEX(' ', geom.STAsText() + ' ') - 1) as GeometryType
FROM NE_110M_LAND;

-- 7.	Определите SRID.
SELECT DISTINCT GEOM.STSrid AS SRID
FROM NE_110M_LAND;

-- 8.	Определите атрибутивные столбцы.
SELECT COLUMN_NAME
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'NE_110M_LAND';

-- 9.	Верните описания пространственных объектов в формате WKT.
SELECT geom.STAsText() AS wkt_description
FROM NE_110M_LAND;

-- 10.1. Нахождение пересечения пространственных объектов
SELECT A.geom.STIntersection(B.geom) AS intersection_geom
FROM (SELECT id, geom.MakeValid() AS geom
      FROM ne_110m_land) A,
     (SELECT id, geom.MakeValid() AS geom
      FROM ne_110m_land) B
WHERE A.id <> B.id
  AND A.geom.STIntersects(B.geom) = 1;


-- 10.2. Нахождение координат вершин пространственного объекта
DECLARE @geom geometry, @id int = 49;
SET @geom = (SELECT geom.STAsText() AS vertice
             FROM ne_110m_land
             WHERE id = @id);
SELECT @geom.STAsText() AS vertices;

-- 10.3. Нахождение площади пространственных объектов
SELECT id, geom.MakeValid().STArea() AS area
FROM ne_110m_land;


-- 11.	Создайте пространственный объект в виде точки (1) /линии (2) /полигона (3).
-- 12.	Найдите, в какие пространственные объекты попадают созданные вами объекты.
DECLARE @point geometry;
DECLARE @line geometry;
DECLARE @polygon geometry;
DECLARE @rel_line NVARCHAR(100);
DECLARE @rel_polygon NVARCHAR(100);
DECLARE @rel_line_polygon NVARCHAR(100);

SET @point = geometry::STPointFromText('POINT(15 10)', 0);
SET @line = geometry::STLineFromText('LINESTRING(0 0, 10 10, 20 25, 50 60)', 0);
SET @polygon = geometry::STPolyFromText('POLYGON((0 0, 20 0, 20 30, 0 30, 0 0))', 0);

SET @rel_line = CASE WHEN @point.STIntersects(@line) = 1 THEN 'Intersects' ELSE 'Does not intersect' END;
SET @rel_polygon = CASE WHEN @point.STIntersects(@polygon) = 1 THEN 'Intersects' ELSE 'Does not intersect' END;
SET @rel_line_polygon = CASE WHEN @line.STIntersects(@polygon) = 1 THEN 'Intersects' ELSE 'Does not intersect' END;

PRINT 'Point Intersects Line: ' + @rel_line;
PRINT 'Point Intersects Polygon: ' + @rel_polygon;
PRINT 'Line Intersects Polygon: ' + @rel_line_polygon;

-- 13.	Продемонстрируйте индексирование пространственных объектов.
CREATE SPATIAL INDEX spatial_index_land
    ON ne_110m_land (geom)
    USING GEOMETRY_GRID
    WITH (
    BOUNDING_BOX = (-180, -189, 180, 180)
    );

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
    FROM ne_110m_land
    WHERE geom.MakeValid().STIntersects(@v_Point) = 1;
END;

GO

BEGIN
    DECLARE @v_polygon INT;
    EXEC GetPolygonFromPoint 30, 40, @v_polygon OUTPUT;
    PRINT 'Polygon: ' + CAST(@v_polygon AS VARCHAR)
END

