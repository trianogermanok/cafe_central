-- Creación de la base de datos
DROP DATABASE IF EXISTS cafe_central;
CREATE DATABASE cafe_central;
USE cafe_central;

-- Creación de tablas
CREATE TABLE clientes (
    cliente_id INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    apellido VARCHAR(100) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    telefono VARCHAR(15),
    direccion VARCHAR(255),
    ciudad VARCHAR(100),
    estado VARCHAR(100),
    codigo_postal VARCHAR(10),
    fecha_registro DATETIME DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE productos (
    producto_id INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    descripcion TEXT,
    precio DECIMAL(10, 2) NOT NULL,
    categoria ENUM('Bebida', 'Alimento') NOT NULL,
    stock INT NOT NULL
);

CREATE TABLE ordenes (
    orden_id INT AUTO_INCREMENT PRIMARY KEY,
    cliente_id INT,
    fecha_orden DATETIME DEFAULT CURRENT_TIMESTAMP,
    total DECIMAL(10, 2),
    FOREIGN KEY (cliente_id) REFERENCES clientes(cliente_id)
);

CREATE TABLE detalles_orden (
    detalle_id INT AUTO_INCREMENT PRIMARY KEY,
    orden_id INT,
    producto_id INT,
    cantidad INT NOT NULL,
    precio_unitario DECIMAL(10, 2),
    FOREIGN KEY (orden_id) REFERENCES ordenes(orden_id),
    FOREIGN KEY (producto_id) REFERENCES productos(producto_id)
);

CREATE TABLE pagos (
    pago_id INT AUTO_INCREMENT PRIMARY KEY,
    orden_id INT,
    fecha_pago DATETIME DEFAULT CURRENT_TIMESTAMP,
    monto DECIMAL(10, 2) NOT NULL,
    metodo_pago VARCHAR(50),
    FOREIGN KEY (orden_id) REFERENCES ordenes(orden_id)
);

-- Inserción de datos de ejemplo
INSERT INTO clientes (nombre, apellido, email, telefono, direccion, ciudad, estado, codigo_postal) VALUES
('Ana', 'García', 'ana.garcia@example.com', '555-1234', 'Calle Falsa 123', 'Ciudad', 'Estado', '12345'),
('Luis', 'Martínez', 'luis.martinez@example.com', '555-5678', 'Avenida Siempre Viva 456', 'Ciudad', 'Estado', '54321');

INSERT INTO productos (nombre, descripcion, precio, categoria, stock) VALUES
('Café Espresso', 'Café fuerte y concentrado', 2.50, 'Bebida', 50),
('Capuchino', 'Café con leche y espuma', 3.00, 'Bebida', 30),
('Tostado', 'Tostado de jamón y queso', 4.50, 'Alimento', 20),
('Croissant', 'Croissant de mantequilla', 2.00, 'Alimento', 40);

-- Creación de una orden y sus detalles
INSERT INTO ordenes (cliente_id, total) VALUES (1, 7.50);

INSERT INTO detalles_orden (orden_id, producto_id, cantidad, precio_unitario) VALUES
(1, 1, 1, 2.50),
(1, 3, 1, 4.50);

-- Inserción de pago
INSERT INTO pagos (orden_id, monto, metodo_pago) VALUES (1, 7.50, 'Tarjeta de Crédito');

-- Vistas e informes
-- Vista para mostrar el resumen de órdenes por cliente
CREATE VIEW resumen_ordenes_cliente AS
SELECT c.nombre AS cliente_nombre, c.apellido AS cliente_apellido, o.orden_id, o.fecha_orden, o.total
FROM clientes c
JOIN ordenes o ON c.cliente_id = o.cliente_id;

-- Vista para mostrar el resumen de productos vendidos por orden
CREATE VIEW resumen_productos_orden AS
SELECT o.orden_id, p.nombre AS producto_nombre, do.cantidad, do.precio_unitario
FROM ordenes o
JOIN detalles_orden do ON o.orden_id = do.orden_id
JOIN productos p ON do.producto_id = p.producto_id;

-- Trigger para actualizar el stock de productos después de una inserción en detalles_orden
DELIMITER //
CREATE TRIGGER actualizar_stock_producto
AFTER INSERT ON detalles_orden
FOR EACH ROW
BEGIN
    UPDATE productos
    SET stock = stock - NEW.cantidad
    WHERE producto_id = NEW.producto_id;
END//
DELIMITER ;

-- Procedimientos almacenados
-- Procedimiento para registrar una nueva orden
DELIMITER //
CREATE PROCEDURE registrar_orden(
    IN p_cliente_id INT,
    IN p_producto_id INT,
    IN p_cantidad INT,
    OUT p_orden_id INT
)
BEGIN
    DECLARE v_precio_unitario DECIMAL(10,2);
    DECLARE v_total DECIMAL(10,2);

    -- Obtener el precio unitario del producto
    SELECT precio INTO v_precio_unitario FROM productos WHERE producto_id = p_producto_id;

    -- Calcular el total
    SET v_total = v_precio_unitario * p_cantidad;

    -- Insertar la orden
    INSERT INTO ordenes (cliente_id, total) VALUES (p_cliente_id, v_total);

    -- Obtener el ID de la orden generada
    SET p_orden_id = LAST_INSERT_ID();

    -- Insertar el detalle de la orden
    INSERT INTO detalles_orden (orden_id, producto_id, cantidad, precio_unitario) 
    VALUES (p_orden_id, p_producto_id, p_cantidad, v_precio_unitario);

    -- Actualizar el stock del producto
    UPDATE productos
    SET stock = stock - p_cantidad
    WHERE producto_id = p_producto_id;
END//
DELIMITER ;

-- Procedimiento almacenado adicional
DELIMITER //
CREATE PROCEDURE actualizar_precio_producto(
    IN p_producto_id INT,
    IN p_nuevo_precio DECIMAL(10, 2)
)
BEGIN
    UPDATE productos
    SET precio = p_nuevo_precio
    WHERE producto_id = p_producto_id;
END//
DELIMITER ;

-- Función almacenada
DELIMITER //
CREATE FUNCTION obtener_total_ventas_por_cliente(p_cliente_id INT) RETURNS DECIMAL(10, 2)
BEGIN
    DECLARE total_ventas DECIMAL(10, 2);
    SELECT SUM(o.total) INTO total_ventas
    FROM ordenes o
    WHERE o.cliente_id = p_cliente_id;
    RETURN IFNULL(total_ventas, 0);
END//
DELIMITER ;
