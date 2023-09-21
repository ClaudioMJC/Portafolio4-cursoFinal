CREATE DATABASE CAPAS_JAVA_WEB_2023
GO

USE CAPAS_JAVA_WEB_2023
GO

CREATE TABLE CLIENTES(
	ID_CLIENTE int IDENTITY(1,1) NOT NULL PRIMARY KEY,
	NOMBRE varchar(80) NOT NULL,
	TELEFONO varchar(11) NULL,
	DIRECCION varchar(80) NULL,
)


CREATE TABLE PRODUCTOS(
	ID_PRODUCTO int IDENTITY(1,1) NOT NULL PRIMARY KEY,
	DESCRIPCION varchar(80) NOT NULL,
	PRECIOCOMPRA decimal(10,2) NOT NULL,
	PRECIOVENTA decimal(10,2) NOT NULL,
)

CREATE TABLE ENCABEZADO_FACTURA(
	ID_FACTURA int IDENTITY(1,1) NOT NULL PRIMARY KEY,
	FECHA DATETIME DEFAULT GETDATE(),
	ID_CLIENTE int NOT NULL,
	SUBTOTAL decimal(10,2) NOT NULL,
	IMPUESTO decimal(10,2) NOT NULL,
	MONTODESCUENTO decimal(10,2) NOT NULL,
	ESTADO VARCHAR(20) DEFAULT('PENDIENTE')
)

ALTER TABLE ENCABEZADO_FACTURA ADD CONSTRAINT CHK_ESTADO
CHECK(ESTADO IN('PENDIENTE','CANCELADA','VENCIDA','ANULADA'))

CREATE TABLE DETALLE_FACTURA(
	ID_FACTURA int NOT NULL,
	ID_PRODUCTO int NOT NULL,
	CANTIDAD INT,
	CONSTRAINT PK_DETALLE_FACTURA PRIMARY KEY (ID_FACTURA,ID_PRODUCTO)
)

ALTER TABLE ENCABEZADO_FACTURA ADD CONSTRAINT FK_ENCABEZADO_FACTURA
FOREIGN KEY (ID_CLIENTE) REFERENCES CLIENTES(ID_CLIENTE)

ALTER TABLE DETALLE_FACTURA ADD CONSTRAINT FK_DETALLE_FACTURA
FOREIGN KEY (ID_PRODUCTO) REFERENCES PRODUCTOS(ID_PRODUCTO)

ALTER TABLE DETALLE_FACTURA ADD CONSTRAINT FK_DETALLE_FACTURA_ENCABEZADO
FOREIGN KEY (ID_FACTURA) REFERENCES ENCABEZADO_FACTURA(ID_FACTURA)

/*Datos*/

insert into CLIENTES(NOMBRE,TELEFONO,DIRECCION)
				VALUES	('JOSEGE','8888-8888','SAN MIGUEL'),
						('MARIA','2222-2222','SAN RAMION'),
						('KARLA','3333-3333','PALMARES')
select * from clientes

insert into PRODUCTOS(DESCRIPCION,PRECIOCOMPRA,PRECIOVENTA)
				VALUES	('AROOZ',1000,1200),
						('AZUCAR',900,1100),
						('MANTECA',600,750),
						('CAFE',1600,1750)
select * from PRODUCTOS

insert into ENCABEZADO_FACTURA(ID_CLIENTE,SUBTOTAL, IMPUESTO,MONTODESCUENTO,ESTADO)
				VALUES	(1,0,5,5,'CANCELADA'),
						(2,0,5,5,'PENDIENTE'),
						(1,0,5,5,'VENCIDA')

select * from ENCABEZADO_FACTURA

insert into DETALLE_FACTURA(ID_FACTURA,ID_PRODUCTO, CANTIDAD)
				VALUES	(3,1,5),
						(3,2,5),
						(3,3,5)

select * from DETALLE_FACTURA
go

/************* procedimientos almacenados */
   

--procedimiento #1

CREATE PROCEDURE AnularFactura
    @idFactura INT
AS
BEGIN
    DECLARE @estadoFactura VARCHAR(20)

    -- Obtener el estado actual de la factura
    SELECT @estadoFactura = ESTADO
    FROM ENCABEZADO_FACTURA
    WHERE ID_FACTURA = @idFactura

    -- Verificar si la factura está cancelada
    IF @estadoFactura = 'CANCELADA'
    BEGIN
        -- Actualizar el estado de la factura a 'ANULADA'
        UPDATE ENCABEZADO_FACTURA
        SET ESTADO = 'ANULADA'
        WHERE ID_FACTURA = @idFactura

        PRINT 'Factura anulada exitosamente.'
    END
    ELSE
    BEGIN
        PRINT 'La factura no se puede anular. El estado actual es ' + @estadoFactura + '.'
    END
END

EXEC AnularFactura @idFactura = 1
select * from ENCABEZADO_FACTURA
go


--procedimiento #2

CREATE PROCEDURE BuscarCliente
    @NombreCliente VARCHAR(30)
AS
BEGIN
    IF EXISTS (SELECT 1 FROM CLIENTES WHERE NOMBRE = @NombreCliente)
    BEGIN
        PRINT 'El cliente ' + @NombreCliente + ' existe en la base de datos.'
    END
    ELSE
    BEGIN
        PRINT 'El cliente ' + @NombreCliente + ' no existe en la base de datos.'
    END
END

-- Ejecutar el procedimiento para buscar un cliente
EXEC BuscarCliente @NombreCliente = 'Maria'

Select * from CLIENTES
go

--procedimiento #3

-- Crear el procedimiento almacenado para eliminar un cliente
CREATE PROCEDURE EliminarCliente
    @ID_Cliente INT
AS
BEGIN
    -- Verificar si el cliente tiene facturas
    IF EXISTS (SELECT 1 FROM ENCABEZADO_FACTURA WHERE ID_CLIENTE = @ID_Cliente)
    BEGIN
        -- El cliente tiene facturas, no se puede eliminar
        PRINT 'No se puede eliminar el cliente. Tiene facturas asociadas.'
    END
    ELSE
    BEGIN
        -- El cliente no tiene facturas, se puede eliminar
        DELETE FROM CLIENTES WHERE ID_CLIENTE = @ID_Cliente
        PRINT 'Cliente eliminado exitosamente.'
    END
END

-- Ejecutar el procedimiento para eliminar un cliente
EXEC EliminarCliente @ID_Cliente = 2
go

--PROCEDIMIENTO #4

-- Crear el procedimiento almacenado para eliminar un detalle de factura
CREATE PROCEDURE EliminarDetalleFactura
    @ID_Factura INT
AS
BEGIN
    -- Verificar si la factura existe
    IF EXISTS (SELECT 1 FROM ENCABEZADO_FACTURA WHERE ID_FACTURA = @ID_Factura)
    BEGIN
        -- Verificar si la factura está en estado 'PENDIENTE'
        IF EXISTS (SELECT 1 FROM ENCABEZADO_FACTURA WHERE ID_FACTURA = @ID_Factura AND ESTADO = 'PENDIENTE')
        BEGIN
            -- Eliminar todos los detalles de factura para la factura especificada
            DELETE FROM DETALLE_FACTURA WHERE ID_FACTURA = @ID_Factura
            PRINT 'Todos los detalles de factura se eliminaron exitosamente.'
            
            -- Eliminar automáticamente la factura
            DELETE FROM ENCABEZADO_FACTURA WHERE ID_FACTURA = @ID_Factura
            PRINT 'La factura se eliminó automáticamente ya que no tiene detalles.'
        END
        ELSE
        BEGIN
            -- La factura no está en estado 'PENDIENTE', no se pueden eliminar los detalles
            PRINT 'No se pueden eliminar los detalles de factura. La factura no está en estado ''PENDIENTE''.'
        END
    END
    ELSE
    BEGIN
        -- La factura no existe
        PRINT 'No se pueden eliminar los detalles de factura. La factura no existe.'
    END
END

-- Ejecutar el procedimiento para eliminar un detalle de factura
EXEC EliminarDetalleFactura @ID_Factura = 1

select * from ENCABEZADO_FACTURA
go
--PROCEDIMIENTO #5

-- Procedimiento para eliminar una factura pendiente y sus detalles
CREATE PROCEDURE EliminarFactura
    @ID_FACTURA INT
AS
BEGIN
    -- Verificar si la factura existe y está pendiente
    IF EXISTS (SELECT 1 FROM ENCABEZADO_FACTURA WHERE ID_FACTURA = @ID_FACTURA AND ESTADO = 'PENDIENTE')
    BEGIN
        -- Eliminar los detalles de la factura
        DELETE FROM DETALLE_FACTURA WHERE ID_FACTURA = @ID_FACTURA;

        -- Eliminar la factura
        DELETE FROM ENCABEZADO_FACTURA WHERE ID_FACTURA = @ID_FACTURA;
        
        PRINT 'Factura eliminada correctamente.';
    END
    ELSE
    BEGIN
        PRINT 'La factura no existe o no está pendiente y no puede ser eliminada.';
    END
END

-- Ejemplo: Eliminar la factura con ID_FACTURA 1
EXEC EliminarFactura @ID_FACTURA = 1;
GO

--PROCEDIMIENTO #6

-- Procedimiento para insertar o modificar un cliente
CREATE PROCEDURE InsertarModificarCliente
    @NOMBRE VARCHAR(80),
    @TELEFONO VARCHAR(11) = NULL,
    @DIRECCION VARCHAR(80) = NULL
AS
BEGIN
    -- Verificar si el cliente ya existe
    IF EXISTS (SELECT 1 FROM CLIENTES WHERE NOMBRE = @NOMBRE)
    BEGIN
        -- El cliente ya existe, actualizar sus datos
        UPDATE CLIENTES
        SET TELEFONO = ISNULL(@TELEFONO, TELEFONO),
            DIRECCION = ISNULL(@DIRECCION, DIRECCION)
        WHERE NOMBRE = @NOMBRE;

        PRINT 'Cliente actualizado correctamente.';
    END
    ELSE
    BEGIN
        -- El cliente no existe, insertar un nuevo cliente
        INSERT INTO CLIENTES (NOMBRE, TELEFONO, DIRECCION)
        VALUES (@NOMBRE, @TELEFONO, @DIRECCION);

        PRINT 'Cliente insertado correctamente.';
    END
END

-- Ejemplo de Insertar o modificar un cliente
EXEC InsertarModificarCliente @NOMBRE = 'JOSEGE', @TELEFONO = '12345678', @DIRECCION = 'Naranjo';


select * from CLIENTES

go

--Procedimiento #7 

-- Procedimiento para agregar un detalle de factura
CREATE PROCEDURE AgregarDetalleFactura
    @ID_FACTURA INT,
    @ID_PRODUCTO INT,
    @CANTIDAD INT
AS
BEGIN
    -- Verificar si la factura existe y está pendiente
    IF EXISTS (SELECT 1 FROM ENCABEZADO_FACTURA WHERE ID_FACTURA = @ID_FACTURA AND ESTADO = 'PENDIENTE')
    BEGIN
        -- Verificar si ya existe un detalle para el producto en la factura
        IF EXISTS (SELECT 1 FROM DETALLE_FACTURA WHERE ID_FACTURA = @ID_FACTURA AND ID_PRODUCTO = @ID_PRODUCTO)
        BEGIN
            -- El detalle ya existe, modificar la cantidad
            UPDATE DETALLE_FACTURA
            SET CANTIDAD = CANTIDAD + @CANTIDAD
            WHERE ID_FACTURA = @ID_FACTURA AND ID_PRODUCTO = @ID_PRODUCTO;

            PRINT 'Cantidad del producto actualizada en el detalle de factura.';
        END
        ELSE
        BEGIN
            -- El detalle no existe, insertar un nuevo detalle
            INSERT INTO DETALLE_FACTURA (ID_FACTURA, ID_PRODUCTO, CANTIDAD)
            VALUES (@ID_FACTURA, @ID_PRODUCTO, @CANTIDAD);

            PRINT 'Detalle de factura insertado correctamente.';
        END
    END
    ELSE
    BEGIN
        PRINT 'No se puede agregar un detalle a la factura. La factura no está pendiente.';
    END
END

-- Ejemplo de ejecución: Agregar o modificar un detalle de factura
EXEC AgregarDetalleFactura @ID_FACTURA = 2, @ID_PRODUCTO = 1, @CANTIDAD = 10;
 select * from PRODUCTOS
 select * from DETALLE_FACTURA 
   select * from ENCABEZADO_FACTURA
    select * from CLIENTES
GO



--PROCEDIMIENTO 8 


-- Procedimiento para guardar un producto nuevo o modificarlo si ya existe
CREATE PROCEDURE GUARDARPRODUCTO
    @ID_PRODUCTO INT OUTPUT,
    @DESCRIPCION VARCHAR(80),
    @PRECIOCOMPRA DECIMAL(10,2),
    @PRECIOVENTA DECIMAL(10,2)
AS
BEGIN
    -- Verificar si el producto ya existe
    IF EXISTS (SELECT 1 FROM PRODUCTOS WHERE DESCRIPCION = @DESCRIPCION)
    BEGIN
        -- El producto ya existe, actualizar sus datos
        UPDATE PRODUCTOS
        SET PRECIOCOMPRA = @PRECIOCOMPRA,
            PRECIOVENTA = @PRECIOVENTA
        WHERE DESCRIPCION = @DESCRIPCION;

        -- Obtener el ID_PRODUCTO del producto actualizado
        SELECT @ID_PRODUCTO = ID_PRODUCTO
        FROM PRODUCTOS
        WHERE DESCRIPCION = @DESCRIPCION;

        PRINT 'Producto actualizado correctamente.';
    END
    ELSE
    BEGIN
        -- El producto no existe, insertar un nuevo producto
        INSERT INTO PRODUCTOS (DESCRIPCION, PRECIOCOMPRA, PRECIOVENTA)
        VALUES (@DESCRIPCION, @PRECIOCOMPRA, @PRECIOVENTA);

        -- Obtener el ID_PRODUCTO del nuevo producto
        SET @ID_PRODUCTO = SCOPE_IDENTITY();

        PRINT 'Nuevo producto insertado correctamente.';
    END
END

-- Ejemplo de ejecución: Guardar un producto nuevo o modificarlo
DECLARE @ID_PRODUCT INT;
EXEC GUARDARPRODUCTO @ID_PRODUCT OUTPUT, @DESCRIPCION = 'AROOZ', @PRECIOCOMPRA = 1100, @PRECIOVENTA = 1300;

 select * from PRODUCTOS
 GO

 --PROCEDIMIENTO #9

 CREATE PROCEDURE GuardarModificarFactura
(
    @ID_FACTURA INT,
    @ID_CLIENTE INT,
    @SUBTOTAL DECIMAL(10,2),
    @IMPUESTO DECIMAL(10,2),
    @MONTODESCUENTO DECIMAL(10,2),
    @ESTADO VARCHAR(20)
)
AS
BEGIN
    -- Verificar si la factura existe y está pendiente
    IF EXISTS (SELECT 1 FROM ENCABEZADO_FACTURA WHERE ID_FACTURA = @ID_FACTURA AND ESTADO = 'PENDIENTE')
    BEGIN
        -- Modificar la factura existente
        UPDATE ENCABEZADO_FACTURA
        SET ID_CLIENTE = @ID_CLIENTE,
            SUBTOTAL = @SUBTOTAL,
            IMPUESTO = @IMPUESTO,
            MONTODESCUENTO = @MONTODESCUENTO,
            ESTADO = @ESTADO
        WHERE ID_FACTURA = @ID_FACTURA;
        
        PRINT 'Factura modificada exitosamente.';
    END
    ELSE
    BEGIN
        PRINT 'No se puede modificar la factura. La factura no existe o no está pendiente.';
    END
END


---------------------------------------------------------------------------------------
DECLARE @ID_FACTURA1 INT = 1; -- Reemplaza con el ID de la factura que deseas modificar
DECLARE @ID_CLIENTE1 INT = 2; -- Reemplaza con el nuevo ID de cliente
DECLARE @SUBTOTAL1 DECIMAL(10, 2) = 5000.00; -- Reemplaza con el nuevo subtotal
DECLARE @IMPUESTO1 DECIMAL(10, 2) = 10.00; -- Reemplaza con el nuevo impuesto
DECLARE @MONTODESCUENTO1 DECIMAL(10, 2) = 20.00; -- Reemplaza con el nuevo monto de descuento
DECLARE @ESTADO1 VARCHAR(20) = 'PENDIENTE'; -- Reemplaza con el nuevo estado

-- Ejecutar el procedimiento almacenado
EXEC GuardarModificarFactura 
    @ID_FACTURA1,
    @ID_CLIENTE1,
    @SUBTOTAL1,
    @IMPUESTO1,
    @MONTODESCUENTO1,
    @ESTADO1;


 select * from PRODUCTOS
 select * from DETALLE_FACTURA 
   select * from ENCABEZADO_FACTURA
    select * from CLIENTES