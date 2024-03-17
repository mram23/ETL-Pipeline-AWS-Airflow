-- Para crear la tabla zillowdata
CREATE TABLE IF NOT EXISTS zillowdata(bathrooms NUMERIC,
bedrooms NUMERIC, 
city VARCHAR(255), 
homeStatus VARCHAR(255),
homeType VARCHAR(255), 
livingArea NUMERIC,
price NUMERIC,
rentZestimate NUMERIC,
zipcode INT
);

-- Para visualizar toda la tabla
SELECT * FROM zillowdata;

-- Para tener un conteo de los registros cargados
SELECT COUNT(*) FROM zillowdata;

-- Para ver un promedio de costos de la propiedades según la ciudad
SELECT city, COUNT(*) AS num_properties, AVG(price) AS avg_price
FROM zillowdata
GROUP BY city;

-- Ordenamos las propiedades en venta por el precio de mayor a menor
SELECT * FROM zillowdata
WHERE homeStatus = 'FOR_SALE'
ORDER BY price DESC;

-- Para ver propiedades en venta dentro de un rango de precio
SELECT *FROM zillowdata
WHERE homeStatus = 'FOR_SALE'
  AND price BETWEEN 500000 AND 1000000
  AND city = 'Houston';

-- Vemos algunas datos estadísticos del número de cuartos, se hace la evaluación según cada cantidad de cuarto
-- Aquí podemos notar la diferencia de precio entre ciudades
SELECT bedrooms, city,
    COUNT(*) AS num_properties,
    AVG(price) AS avg_price,
    MIN(price) AS min_price,
    MAX(price) AS max_price
FROM zillowdata
WHERE city IN ('Houston', 'Miami')
GROUP BY bedrooms, city
ORDER BY bedrooms, city;

-- Para obtener el tamaño total del almacenamiento utilizado por todas las tablas en el esquema público
SELECT SUM(size) AS total_size
FROM SVV_TABLE_INFO
WHERE schema = 'public';
