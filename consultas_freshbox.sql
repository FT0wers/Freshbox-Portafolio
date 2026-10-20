-- ============================================================
-- EXAMEN INTEGRADOR – FreshBox Chile
-- Consultas SQL (SQLite)
-- Base de datos: freshbox_corregido.db
-- Fabián Torres
-- ============================================================

-- Q1: Ingresos totales por producto (solo pedidos entregados)
SELECT productos.nombre AS Producto,
       SUM(cantidad_kg * precio_kg) AS Ingreso_Total
FROM pedidos
JOIN productos ON pedidos.id_producto = productos.id_producto
WHERE estado = 'Entregado'
GROUP BY productos.nombre
ORDER BY Ingreso_Total DESC;

-- Q2: Clientes con más de 3 pedidos
SELECT clientes.nombre AS Cliente,
       COUNT(*) AS Total_Pedidos
FROM pedidos
JOIN clientes ON pedidos.id_cliente = clientes.id_cliente
GROUP BY clientes.nombre
HAVING Total_Pedidos > 3
ORDER BY Total_Pedidos DESC;

-- Q3: Margen promedio por repartidor (solo entregas calificadas)
SELECT repartidores.nombre AS Repartidor,
       ROUND(AVG((cantidad_kg * precio_kg) - ((productos.costo_kg * pedidos.cantidad_kg) + pedidos.costo_flete))) AS Margen_Promedio,
       AVG(calidad_entrega) AS Calificacion_Promedio
FROM pedidos
JOIN repartidores ON pedidos.id_repartidor = repartidores.id_repartidor
JOIN productos   ON pedidos.id_producto   = productos.id_producto
WHERE estado = 'Entregado' AND calidad_entrega > 0
GROUP BY repartidores.nombre
ORDER BY Margen_Promedio DESC;

-- Q4: Pedidos con margen negativo
SELECT pedidos.id_pedido,
       clientes.nombre  AS Cliente,
       productos.nombre AS Producto,
       (cantidad_kg * precio_kg) AS Ingreso,
       ((productos.costo_kg * pedidos.cantidad_kg) + pedidos.costo_flete) AS Costo_Total,
       ((cantidad_kg * precio_kg) - ((productos.costo_kg * pedidos.cantidad_kg) + pedidos.costo_flete)) AS Margen
FROM pedidos
JOIN clientes  ON pedidos.id_cliente  = clientes.id_cliente
JOIN productos ON pedidos.id_producto = productos.id_producto
WHERE estado = 'Entregado'
  AND ((cantidad_kg * precio_kg) - ((productos.costo_kg * pedidos.cantidad_kg) + pedidos.costo_flete)) < 0
ORDER BY Margen ASC;

-- Q5: Producto más vendido por mes
SELECT strftime('%Y-%m', fecha) AS Mes,
       productos.nombre AS Producto,
       SUM(cantidad_kg) AS Total_Kg
FROM pedidos
JOIN productos ON pedidos.id_producto = productos.id_producto
WHERE estado = 'Entregado'
GROUP BY Mes, productos.nombre
HAVING Total_Kg = (
    SELECT MAX(sub.Total_Kg)
    FROM (SELECT strftime('%Y-%m', fecha) AS Mes2,
                 id_producto,
                 SUM(cantidad_kg) AS Total_Kg
          FROM pedidos
          WHERE estado = 'Entregado'
          GROUP BY Mes2, id_producto) sub
    WHERE sub.Mes2 = strftime('%Y-%m', pedidos.fecha)
)
ORDER BY Mes;

-- Q6: Repartidores que no cumplen meta de calidad
SELECT repartidores.nombre AS Repartidor,
       ROUND(AVG(calidad_entrega), 2) AS Calificacion_Promedio,
       metas.meta_calidad
FROM pedidos
JOIN repartidores ON pedidos.id_repartidor = repartidores.id_repartidor
JOIN metas        ON pedidos.id_repartidor = metas.id_repartidor
WHERE estado = 'Entregado' AND calidad_entrega > 0
GROUP BY repartidores.nombre, metas.meta_calidad
HAVING Calificacion_Promedio < metas.meta_calidad
ORDER BY Calificacion_Promedio ASC;

-- Q7: Pedidos individuales con ingreso superior al promedio (CORREGIDA)
-- Corrección: se cambia GROUP BY id_cliente por pedidos individuales.
-- Se agrega JOIN con clientes y se filtra por estado 'Entregado'.
SELECT pedidos.id_pedido,
       clientes.nombre  AS Cliente,
       productos.nombre AS Producto,
       (cantidad_kg * precio_kg) AS Ingreso
FROM pedidos
JOIN clientes  ON pedidos.id_cliente  = clientes.id_cliente
JOIN productos ON pedidos.id_producto = productos.id_producto
WHERE (cantidad_kg * precio_kg) > (
        SELECT AVG(cantidad_kg * precio_kg)
        FROM pedidos
        WHERE estado = 'Entregado'
      )
  AND estado = 'Entregado'
ORDER BY Ingreso DESC;

-- Q8: Ranking de clientes por ingreso total (con número de pedidos)
SELECT clientes.nombre AS Cliente,
       COUNT(*) AS Total_Pedidos,
       SUM(cantidad_kg * precio_kg) AS Ingreso_Total,
       RANK() OVER (ORDER BY SUM(cantidad_kg * precio_kg) DESC) AS Ranking
FROM pedidos
JOIN clientes ON pedidos.id_cliente = clientes.id_cliente
WHERE estado = 'Entregado'
GROUP BY clientes.nombre
ORDER BY Ranking;

-- Q9: Distribución de pedidos por estado
SELECT estado,
       COUNT(*) AS Total_Pedidos,
       ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM pedidos), 1) AS Porcentaje
FROM pedidos
GROUP BY estado
ORDER BY Total_Pedidos DESC;

-- Q10: Resumen por ejecutivo comercial (CORREGIDA)
-- Corrección: se agrega COUNT(*) AS total_pedidos para medir volumen de operación.
SELECT clientes.ejecutivo                  AS Ejecutivo,
       COUNT(DISTINCT pedidos.id_cliente)  AS Cantidad_Clientes,
       COUNT(*)                            AS Total_Pedidos,
       SUM(cantidad_kg * precio_kg)        AS Ingreso_Total,
       ROUND(AVG((cantidad_kg * precio_kg) - ((productos.costo_kg * pedidos.cantidad_kg) + pedidos.costo_flete))) AS Margen_Promedio,
       AVG(calidad_entrega)                AS Calificacion_Promedio
FROM pedidos
JOIN clientes  ON pedidos.id_cliente  = clientes.id_cliente
JOIN productos ON pedidos.id_producto = productos.id_producto
WHERE estado = 'Entregado' AND calidad_entrega > 0
GROUP BY clientes.ejecutivo
ORDER BY Ingreso_Total DESC;
