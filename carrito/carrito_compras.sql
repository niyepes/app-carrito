-- 0. Función y trigger para mantener fecha_actualizacion al modificar
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.fecha_actualizacion = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 1. Perfiles de Usuario
CREATE TABLE perfiles (
  id_perfil   BIGSERIAL PRIMARY KEY,
  nombre      VARCHAR(50) NOT NULL UNIQUE,
  descripcion VARCHAR(255)
);

-- 2. Usuarios
CREATE TABLE usuarios (
  id_usuario         BIGSERIAL PRIMARY KEY,
  nombre             VARCHAR(100) NOT NULL,
  email              VARCHAR(150) NOT NULL UNIQUE,
  password           VARCHAR(255) NOT NULL,
  id_perfil          BIGINT NOT NULL REFERENCES perfiles(id_perfil),
  fecha_registro     TIMESTAMP NOT NULL DEFAULT NOW(),
  fecha_actualizacion TIMESTAMP NOT NULL DEFAULT NOW(),
  estado             CHAR(1)    NOT NULL DEFAULT 'A'
);
-- trigger de actualización
CREATE TRIGGER trg_usuarios_updated_at
  BEFORE UPDATE ON usuarios
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- 3. Productos
CREATE TABLE productos (
  id_producto        BIGSERIAL PRIMARY KEY,
  nombre             VARCHAR(150) NOT NULL,
  descripcion        TEXT,
  precio             NUMERIC(10,2) NOT NULL,
  stock              INT NOT NULL,
  fecha_registro     TIMESTAMP NOT NULL DEFAULT NOW(),
  fecha_actualizacion TIMESTAMP NOT NULL DEFAULT NOW(),
  estado             CHAR(1)    NOT NULL DEFAULT 'A'
);
CREATE TRIGGER trg_productos_updated_at
  BEFORE UPDATE ON productos
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- 4. Carritos
CREATE TABLE carritos (
  id_carrito         BIGSERIAL PRIMARY KEY,
  id_usuario         BIGINT NOT NULL REFERENCES usuarios(id_usuario),
  fecha_registro     TIMESTAMP NOT NULL DEFAULT NOW(),
  fecha_actualizacion TIMESTAMP NOT NULL DEFAULT NOW(),
  estado             CHAR(1)    NOT NULL DEFAULT 'A'
);
CREATE TRIGGER trg_carritos_updated_at
  BEFORE UPDATE ON carritos
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- 4. Detalle de Carrito
CREATE TABLE carrito_detalles (
  id_detalle_carrito BIGSERIAL PRIMARY KEY,
  id_carrito         BIGINT     NOT NULL REFERENCES carritos(id_carrito),
  id_producto        BIGINT     NOT NULL REFERENCES productos(id_producto),
  cantidad           INT        NOT NULL,
  precio_unitario    NUMERIC(10,2) NOT NULL,
  precio_igv         NUMERIC(10,2) NOT NULL,
  precio_total       NUMERIC(10,2) NOT NULL
);

-- 5. Direcciones de Usuario
CREATE TABLE direcciones (
  id_direccion    BIGSERIAL PRIMARY KEY,
  id_usuario      BIGINT    NOT NULL REFERENCES usuarios(id_usuario),
  direccion       TEXT      NOT NULL,
  pais            VARCHAR(100),
  ciudad          VARCHAR(100),
  codigo_postal   VARCHAR(20),
  es_predeterminada BOOLEAN DEFAULT FALSE,
  estado          CHAR(1)   NOT NULL DEFAULT 'A'
);

-- 6. Métodos de Pago
CREATE TABLE metodos_pago (
  id_metodo_pago   BIGSERIAL PRIMARY KEY,
  descripcion      VARCHAR(100),
  estado           CHAR(1)   NOT NULL DEFAULT 'A'
);

-- 7. Métodos de Pago de Usuarios
CREATE TABLE metodos_pago_usuario (
  id_metodo_pago_usuario BIGSERIAL PRIMARY KEY,
  id_usuario             BIGINT  NOT NULL REFERENCES usuarios(id_usuario) ON DELETE CASCADE,
  id_metodo_pago         BIGINT  NOT NULL REFERENCES metodos_pago(id_metodo_pago),
  datos                  JSON    NOT NULL,
  estado                 CHAR(1) NOT NULL DEFAULT 'A'
);

-- 8. Compras
CREATE TABLE compras (
  id_compra               BIGSERIAL PRIMARY KEY,
  id_usuario              BIGINT    NOT NULL REFERENCES usuarios(id_usuario),
  fecha_pedido            TIMESTAMP  NOT NULL DEFAULT NOW(),
  sub_total               NUMERIC(10,2) NOT NULL,
  iva                     NUMERIC(10,2) NOT NULL,
  total                   NUMERIC(10,2) NOT NULL,
  id_direccion            BIGINT    NOT NULL REFERENCES direcciones(id_direccion),
  id_metodo_pago_usuario  BIGINT    NOT NULL REFERENCES metodos_pago_usuario(id_metodo_pago_usuario),
  estado                  CHAR(1)   NOT NULL DEFAULT 'A'
);

-- 9. Detalles de Compra
CREATE TABLE compra_detalles (
  id_compra_detalle BIGSERIAL PRIMARY KEY,
  id_compra         BIGINT    NOT NULL REFERENCES compras(id_compra) ON DELETE CASCADE,
  id_producto       BIGINT    NOT NULL REFERENCES productos(id_producto),
  cantidad          INT       NOT NULL,
  precio_unitario   NUMERIC(10,2) NOT NULL,
  precio_igv        NUMERIC(10,2) NOT NULL,
  precio_total      NUMERIC(10,2) NOT NULL
);

CREATE TABLE pagos (
  id_pago                   BIGSERIAL PRIMARY KEY,
  id_compra                 BIGINT    NOT NULL
     REFERENCES compras(id_compra) ON DELETE CASCADE,
  id_metodo_pago_usuario    BIGINT    NOT NULL
     REFERENCES metodos_pago_usuario(id_metodo_pago_usuario),
  monto                     NUMERIC(10,2) NOT NULL,
  fecha_pago                TIMESTAMP NOT NULL DEFAULT NOW(),
  referencia_externa        VARCHAR(255),
  estado                    CHAR(1)    NOT NULL DEFAULT 'P'
);
