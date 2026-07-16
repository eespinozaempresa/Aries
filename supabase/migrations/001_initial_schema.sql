-- ============================================================
-- Aries ERP — Esquema inicial multi-empresa
-- Compatible con Supabase (PostgreSQL 15+)
-- ============================================================

-- FUNCIÓN: actualiza updated_at automáticamente
CREATE OR REPLACE FUNCTION set_updated_at()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN NEW.updated_at = now(); RETURN NEW; END;
$$;

-- ============================================================
-- GRUPO 1: Empresa, Usuarios, Auditoría
-- ============================================================

CREATE TABLE empresas (
  id          UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
  codigo      VARCHAR(10)  UNIQUE NOT NULL,
  nombre      VARCHAR(100) NOT NULL,
  ruc         VARCHAR(11),
  direccion   VARCHAR(100),
  activo      BOOLEAN      DEFAULT true,
  created_at  TIMESTAMPTZ  DEFAULT now()
);

CREATE TABLE parametros (
  id                    UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
  codigo_empresa        VARCHAR(10)  NOT NULL UNIQUE REFERENCES empresas(codigo),
  igv                   NUMERIC(5,2) NOT NULL DEFAULT 18.00,
  tiempo_financiamiento INT          NOT NULL DEFAULT 30,
  updated_at            TIMESTAMPTZ  DEFAULT now()
);

CREATE TABLE usuarios (
  id              UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  codigo_empresa  VARCHAR(10) NOT NULL REFERENCES empresas(codigo),
  codigo          VARCHAR(10) NOT NULL,
  nombre          VARCHAR(80) NOT NULL,
  dni             VARCHAR(12),
  email           VARCHAR(100),
  password_hash   TEXT        NOT NULL,
  nivel           VARCHAR(20) NOT NULL DEFAULT 'operador',
  activo          BOOLEAN     DEFAULT true,
  created_at      TIMESTAMPTZ DEFAULT now(),
  updated_at      TIMESTAMPTZ DEFAULT now(),
  UNIQUE(codigo_empresa, codigo)
);
CREATE TRIGGER trg_usuarios_upd BEFORE UPDATE ON usuarios
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TABLE refresh_tokens (
  id          UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  usuario_id  UUID        NOT NULL REFERENCES usuarios(id) ON DELETE CASCADE,
  token_hash  TEXT        NOT NULL,
  expires_at  TIMESTAMPTZ NOT NULL,
  revocado    BOOLEAN     DEFAULT false,
  created_at  TIMESTAMPTZ DEFAULT now()
);
CREATE INDEX idx_rt_usuario ON refresh_tokens(usuario_id, revocado);

CREATE TABLE auditoria_sesiones (
  id             BIGSERIAL   PRIMARY KEY,
  codigo_empresa VARCHAR(10) NOT NULL,
  usuario_id     UUID        NOT NULL REFERENCES usuarios(id),
  tipo           VARCHAR(10) NOT NULL CHECK (tipo IN ('LOGIN','LOGOUT')),
  fecha_hora     TIMESTAMPTZ DEFAULT now(),
  ip             VARCHAR(45),
  dispositivo    VARCHAR(100)
);
CREATE INDEX idx_audit ON auditoria_sesiones(codigo_empresa, usuario_id, fecha_hora);

CREATE TABLE tipo_cambio (
  id             UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
  codigo_empresa VARCHAR(10)  NOT NULL REFERENCES empresas(codigo),
  fecha          DATE         NOT NULL,
  tipo_cambio    NUMERIC(8,4) NOT NULL,
  codigo_usuario VARCHAR(10),
  created_at     TIMESTAMPTZ  DEFAULT now(),
  UNIQUE(codigo_empresa, fecha)
);

-- ============================================================
-- GRUPO 2: Tablas base
-- ============================================================

CREATE TABLE lineas (
  id             UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  codigo_empresa VARCHAR(10) NOT NULL REFERENCES empresas(codigo),
  codigo         VARCHAR(5)  NOT NULL,
  descripcion    VARCHAR(50) NOT NULL,
  activo         BOOLEAN     DEFAULT true,
  UNIQUE(codigo_empresa, codigo)
);

CREATE TABLE medidas (
  id             UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  codigo_empresa VARCHAR(10) NOT NULL REFERENCES empresas(codigo),
  codigo         VARCHAR(5)  NOT NULL,
  descripcion    VARCHAR(30) NOT NULL,
  activo         BOOLEAN     DEFAULT true,
  UNIQUE(codigo_empresa, codigo)
);

CREATE TABLE bancos (
  id             UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  codigo_empresa VARCHAR(10) NOT NULL REFERENCES empresas(codigo),
  codigo         VARCHAR(5)  NOT NULL,
  descripcion    VARCHAR(50) NOT NULL,
  activo         BOOLEAN     DEFAULT true,
  UNIQUE(codigo_empresa, codigo)
);

CREATE TABLE documentos (
  id               UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  codigo_empresa   VARCHAR(10) NOT NULL REFERENCES empresas(codigo),
  codigo           VARCHAR(5)  NOT NULL,
  descripcion      VARCHAR(50) NOT NULL,
  abreviatura      VARCHAR(5),
  numero_siguiente BIGINT      NOT NULL DEFAULT 1,
  aplica_igv       BOOLEAN     DEFAULT false,
  tipo             VARCHAR(15),
  activo           BOOLEAN     DEFAULT true,
  UNIQUE(codigo_empresa, codigo)
);

CREATE TABLE marcas (
  id             UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  codigo_empresa VARCHAR(10) NOT NULL REFERENCES empresas(codigo),
  codigo         VARCHAR(5)  NOT NULL,
  descripcion    VARCHAR(30) NOT NULL,
  activo         BOOLEAN     DEFAULT true,
  UNIQUE(codigo_empresa, codigo)
);

-- ============================================================
-- GRUPO 3: Maestros
-- ============================================================

CREATE TABLE articulos (
  id                 UUID          PRIMARY KEY DEFAULT gen_random_uuid(),
  codigo_empresa     VARCHAR(10)   NOT NULL REFERENCES empresas(codigo),
  codigo             VARCHAR(10)   NOT NULL,
  codigo_linea       VARCHAR(5),
  codigo_medida      VARCHAR(5),
  codigo_marca       VARCHAR(5),
  descripcion        VARCHAR(150)  NOT NULL,
  precio_compra_base NUMERIC(12,4) DEFAULT 0,
  igv_compra         NUMERIC(12,4) DEFAULT 0,
  precio_compra      NUMERIC(12,4) DEFAULT 0,
  utilidad_pct       NUMERIC(8,2)  DEFAULT 0,
  precio_venta_base  NUMERIC(12,4) DEFAULT 0,
  igv_venta          NUMERIC(12,4) DEFAULT 0,
  precio_venta       NUMERIC(12,4) DEFAULT 0,
  fecha_registro     DATE,
  fecha_vencimiento  DATE,
  stock_minimo       NUMERIC(14,4) DEFAULT 0,
  stock_maximo       NUMERIC(14,4) DEFAULT 0,
  codigo_barras      VARCHAR(50),
  pendiente          BOOLEAN       DEFAULT false,
  activo             BOOLEAN       DEFAULT true,
  created_at         TIMESTAMPTZ   DEFAULT now(),
  updated_at         TIMESTAMPTZ   DEFAULT now(),
  UNIQUE(codigo_empresa, codigo)
);
CREATE INDEX idx_art_desc   ON articulos(codigo_empresa, descripcion);
CREATE INDEX idx_art_barras ON articulos(codigo_empresa, codigo_barras);
CREATE TRIGGER trg_art_upd BEFORE UPDATE ON articulos
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TABLE clientes (
  id             UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
  codigo_empresa VARCHAR(10)  NOT NULL REFERENCES empresas(codigo),
  codigo         VARCHAR(10)  NOT NULL,
  razon_social   VARCHAR(100) NOT NULL,
  direccion      VARCHAR(100),
  ruc_dni        VARCHAR(15),
  telefono       VARCHAR(20),
  celular        VARCHAR(20),
  email          VARCHAR(100),
  activo         BOOLEAN      DEFAULT true,
  created_at     TIMESTAMPTZ  DEFAULT now(),
  updated_at     TIMESTAMPTZ  DEFAULT now(),
  UNIQUE(codigo_empresa, codigo)
);
CREATE INDEX idx_cli_ruc    ON clientes(codigo_empresa, ruc_dni);
CREATE INDEX idx_cli_razsoc ON clientes(codigo_empresa, razon_social);
CREATE TRIGGER trg_cli_upd BEFORE UPDATE ON clientes
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TABLE proveedores (
  id             UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
  codigo_empresa VARCHAR(10)  NOT NULL REFERENCES empresas(codigo),
  codigo         VARCHAR(10)  NOT NULL,
  razon_social   VARCHAR(100) NOT NULL,
  direccion      VARCHAR(100),
  ruc_dni        VARCHAR(15),
  telefono       VARCHAR(20),
  celular        VARCHAR(20),
  email          VARCHAR(100),
  activo         BOOLEAN      DEFAULT true,
  created_at     TIMESTAMPTZ  DEFAULT now(),
  updated_at     TIMESTAMPTZ  DEFAULT now(),
  UNIQUE(codigo_empresa, codigo)
);
CREATE INDEX idx_prov_ruc    ON proveedores(codigo_empresa, ruc_dni);
CREATE INDEX idx_prov_razsoc ON proveedores(codigo_empresa, razon_social);
CREATE TRIGGER trg_prov_upd BEFORE UPDATE ON proveedores
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TABLE almacenes (
  id             UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  codigo_empresa VARCHAR(10) NOT NULL REFERENCES empresas(codigo),
  codigo         VARCHAR(5)  NOT NULL,
  abreviatura    VARCHAR(15),
  descripcion    VARCHAR(60) NOT NULL,
  ubicacion      VARCHAR(80),
  tipo           VARCHAR(15) DEFAULT 'ALMACEN',
  activo         BOOLEAN     DEFAULT true,
  UNIQUE(codigo_empresa, codigo)
);

CREATE TABLE stock (
  id                  UUID          PRIMARY KEY DEFAULT gen_random_uuid(),
  codigo_empresa      VARCHAR(10)   NOT NULL REFERENCES empresas(codigo),
  codigo_almacen      VARCHAR(5)    NOT NULL,
  codigo_articulo     VARCHAR(10)   NOT NULL,
  stock_inicial       NUMERIC(14,4) DEFAULT 0,
  stock_compras       NUMERIC(14,4) DEFAULT 0,
  stock_ventas        NUMERIC(14,4) DEFAULT 0,
  stock_entradas      NUMERIC(14,4) DEFAULT 0,
  stock_salidas       NUMERIC(14,4) DEFAULT 0,
  stock_traslados_in  NUMERIC(14,4) DEFAULT 0,
  stock_traslados_out NUMERIC(14,4) DEFAULT 0,
  costo_promedio      NUMERIC(14,6) DEFAULT 0,
  importe_total       NUMERIC(14,2) DEFAULT 0,
  fecha_actualizacion DATE,
  UNIQUE(codigo_empresa, codigo_almacen, codigo_articulo)
);

-- ============================================================
-- GRUPO 4: Almacén — Movimientos & Kardex
-- ============================================================

CREATE TABLE movimientos_almacen (
  id                    UUID          PRIMARY KEY DEFAULT gen_random_uuid(),
  codigo_empresa        VARCHAR(10)   NOT NULL REFERENCES empresas(codigo),
  codigo_documento      VARCHAR(5)    NOT NULL,
  numero_documento      VARCHAR(15)   NOT NULL,
  fecha                 DATE          NOT NULL,
  tipo                  VARCHAR(10)   NOT NULL CHECK (tipo IN ('INGRESO','SALIDA','TRASLADO')),
  codigo_almacen_origen VARCHAR(5)    NOT NULL,
  codigo_almacen_dest   VARCHAR(5),
  observacion           VARCHAR(100),
  concepto              VARCHAR(100),
  codigo_usuario        VARCHAR(10)   NOT NULL,
  total                 NUMERIC(14,2) DEFAULT 0,
  anulado               BOOLEAN       DEFAULT false,
  created_at            TIMESTAMPTZ   DEFAULT now(),
  UNIQUE(codigo_empresa, codigo_documento, numero_documento)
);
CREATE INDEX idx_mov ON movimientos_almacen(codigo_empresa, codigo_almacen_origen, fecha);

CREATE TABLE detalle_movimientos (
  id              UUID          PRIMARY KEY DEFAULT gen_random_uuid(),
  movimiento_id   UUID          NOT NULL REFERENCES movimientos_almacen(id) ON DELETE CASCADE,
  codigo_empresa  VARCHAR(10)   NOT NULL,
  codigo_articulo VARCHAR(10)   NOT NULL,
  cantidad        NUMERIC(14,4) NOT NULL,
  precio_unitario NUMERIC(12,4) DEFAULT 0,
  importe         NUMERIC(14,2) DEFAULT 0
);

CREATE TABLE kardex (
  id               BIGSERIAL     PRIMARY KEY,
  codigo_empresa   VARCHAR(10)   NOT NULL REFERENCES empresas(codigo),
  codigo_almacen   VARCHAR(5)    NOT NULL,
  codigo_articulo  VARCHAR(10)   NOT NULL,
  fecha            DATE          NOT NULL,
  codigo_documento VARCHAR(5)    NOT NULL,
  numero_documento VARCHAR(15)   NOT NULL,
  tipo             VARCHAR(20)   NOT NULL,
  cant_entrada     NUMERIC(14,4) DEFAULT 0,
  precio_entrada   NUMERIC(12,6) DEFAULT 0,
  importe_entrada  NUMERIC(16,4) DEFAULT 0,
  cant_salida      NUMERIC(14,4) DEFAULT 0,
  precio_salida    NUMERIC(12,6) DEFAULT 0,
  importe_salida   NUMERIC(16,4) DEFAULT 0,
  stock            NUMERIC(14,4) DEFAULT 0,
  precio_stock     NUMERIC(12,6) DEFAULT 0,
  importe_stock    NUMERIC(16,4) DEFAULT 0,
  orden            INT           DEFAULT 0,
  created_at       TIMESTAMPTZ   DEFAULT now()
);
CREATE INDEX idx_kx ON kardex(codigo_empresa, codigo_almacen, codigo_articulo, fecha);

-- ============================================================
-- GRUPO 5: Compras
-- ============================================================

CREATE TABLE compras (
  id               UUID          PRIMARY KEY DEFAULT gen_random_uuid(),
  codigo_empresa   VARCHAR(10)   NOT NULL REFERENCES empresas(codigo),
  codigo_documento VARCHAR(5)    NOT NULL,
  numero_documento VARCHAR(15)   NOT NULL,
  fecha            DATE          NOT NULL,
  forma_pago       VARCHAR(10)   NOT NULL DEFAULT 'CONTADO' CHECK(forma_pago IN('CONTADO','CREDITO')),
  plazo_dias       INT           DEFAULT 0,
  fecha_vencimiento DATE,
  observacion      VARCHAR(50),
  codigo_almacen   VARCHAR(5)    NOT NULL,
  codigo_proveedor VARCHAR(10)   NOT NULL,
  codigo_usuario   VARCHAR(10)   NOT NULL,
  subtotal         NUMERIC(14,2) DEFAULT 0,
  igv              NUMERIC(14,2) DEFAULT 0,
  total            NUMERIC(14,2) DEFAULT 0,
  subtotal_usd     NUMERIC(14,2) DEFAULT 0,
  igv_usd          NUMERIC(14,2) DEFAULT 0,
  total_usd        NUMERIC(14,2) DEFAULT 0,
  moneda           VARCHAR(5)    DEFAULT 'PEN',
  tipo_cambio      NUMERIC(8,4)  DEFAULT 1,
  anulado          BOOLEAN       DEFAULT false,
  created_at       TIMESTAMPTZ   DEFAULT now(),
  UNIQUE(codigo_empresa, codigo_documento, numero_documento)
);
CREATE INDEX idx_comp ON compras(codigo_empresa, codigo_proveedor, fecha);

CREATE TABLE detalle_compras (
  id                  UUID          PRIMARY KEY DEFAULT gen_random_uuid(),
  compra_id           UUID          NOT NULL REFERENCES compras(id) ON DELETE CASCADE,
  codigo_empresa      VARCHAR(10)   NOT NULL,
  codigo_articulo     VARCHAR(10)   NOT NULL,
  cantidad            NUMERIC(14,4) NOT NULL,
  precio_unitario     NUMERIC(12,4) DEFAULT 0,
  importe             NUMERIC(14,2) DEFAULT 0,
  fecha_vencimiento   DATE,
  precio_unitario_usd NUMERIC(12,4) DEFAULT 0,
  importe_usd         NUMERIC(14,2) DEFAULT 0
);

-- ============================================================
-- GRUPO 6: Ventas
-- ============================================================

CREATE TABLE ventas (
  id               UUID          PRIMARY KEY DEFAULT gen_random_uuid(),
  codigo_empresa   VARCHAR(10)   NOT NULL REFERENCES empresas(codigo),
  codigo_documento VARCHAR(5)    NOT NULL,
  numero_documento VARCHAR(15)   NOT NULL,
  fecha            DATE          NOT NULL,
  observacion      VARCHAR(50),
  codigo_almacen   VARCHAR(5)    NOT NULL,
  codigo_cliente   VARCHAR(10)   NOT NULL,
  codigo_usuario   VARCHAR(10)   NOT NULL,
  subtotal         NUMERIC(14,2) DEFAULT 0,
  igv              NUMERIC(14,2) DEFAULT 0,
  total            NUMERIC(14,2) DEFAULT 0,
  tipo_venta       VARCHAR(10)   NOT NULL DEFAULT 'CONTADO' CHECK(tipo_venta IN('CONTADO','CREDITO')),
  plazo_dias       INT           DEFAULT 0,
  fecha_vencimiento DATE,
  anulado          BOOLEAN       DEFAULT false,
  created_at       TIMESTAMPTZ   DEFAULT now(),
  UNIQUE(codigo_empresa, codigo_documento, numero_documento)
);
CREATE INDEX idx_vta_cli ON ventas(codigo_empresa, codigo_cliente, fecha);
CREATE INDEX idx_vta_usu ON ventas(codigo_empresa, codigo_usuario, fecha);
CREATE INDEX idx_vta_alm ON ventas(codigo_empresa, codigo_almacen, fecha);

CREATE TABLE detalle_ventas (
  id              UUID          PRIMARY KEY DEFAULT gen_random_uuid(),
  venta_id        UUID          NOT NULL REFERENCES ventas(id) ON DELETE CASCADE,
  codigo_empresa  VARCHAR(10)   NOT NULL,
  codigo_articulo VARCHAR(10)   NOT NULL,
  cantidad        NUMERIC(14,4) NOT NULL,
  precio_unitario NUMERIC(12,4) DEFAULT 0,
  descuento_pct   NUMERIC(6,2)  DEFAULT 0,
  importe         NUMERIC(14,2) DEFAULT 0
);

-- ============================================================
-- GRUPO 7: Cuentas por Cobrar
-- ============================================================

CREATE TABLE cuentas_cobrar (
  id                      UUID          PRIMARY KEY DEFAULT gen_random_uuid(),
  codigo_empresa          VARCHAR(10)   NOT NULL REFERENCES empresas(codigo),
  numero_provision        BIGINT        NOT NULL,
  numero_provision_origen BIGINT,
  tipo                    VARCHAR(15)   NOT NULL DEFAULT 'VENTA' CHECK(tipo IN('VENTA','RENOVACION')),
  codigo_documento        VARCHAR(5)    NOT NULL,
  numero_documento        VARCHAR(15)   NOT NULL,
  numero_cuota            SMALLINT      DEFAULT 1,
  total_cuotas            SMALLINT      DEFAULT 1,
  monto_total             NUMERIC(14,2) DEFAULT 0,
  monto_pagado            NUMERIC(14,2) DEFAULT 0,
  saldo                   NUMERIC(14,2) DEFAULT 0,
  interes                 NUMERIC(8,2)  DEFAULT 0,
  fecha_emision           DATE          NOT NULL,
  fecha_vencimiento       DATE,
  codigo_cliente          VARCHAR(10)   NOT NULL,
  pendiente               BOOLEAN       DEFAULT true,
  referencia              VARCHAR(50),
  created_at              TIMESTAMPTZ   DEFAULT now(),
  UNIQUE(codigo_empresa, numero_provision)
);
CREATE INDEX idx_cxc ON cuentas_cobrar(codigo_empresa, codigo_cliente, pendiente);

CREATE TABLE cobros (
  id               UUID          PRIMARY KEY DEFAULT gen_random_uuid(),
  codigo_empresa   VARCHAR(10)   NOT NULL REFERENCES empresas(codigo),
  cuenta_cobrar_id UUID          NOT NULL REFERENCES cuentas_cobrar(id),
  numero_recibo    VARCHAR(15)   NOT NULL,
  fecha            DATE          NOT NULL,
  tipo_pago        VARCHAR(15)   NOT NULL CHECK(tipo_pago IN('EFECTIVO','TRANSFERENCIA','CHEQUE')),
  numero_operacion VARCHAR(20),
  codigo_banco     VARCHAR(5),
  monto            NUMERIC(14,2) NOT NULL,
  estado           VARCHAR(10)   DEFAULT 'ACTIVO' CHECK(estado IN('ACTIVO','ANULADO')),
  codigo_usuario   VARCHAR(10)   NOT NULL,
  created_at       TIMESTAMPTZ   DEFAULT now(),
  UNIQUE(codigo_empresa, numero_recibo)
);

-- ============================================================
-- GRUPO 8: Cuentas por Pagar
-- ============================================================

CREATE TABLE cuentas_pagar (
  id                      UUID          PRIMARY KEY DEFAULT gen_random_uuid(),
  codigo_empresa          VARCHAR(10)   NOT NULL REFERENCES empresas(codigo),
  numero_provision        BIGINT        NOT NULL,
  numero_provision_origen BIGINT,
  tipo                    VARCHAR(15)   NOT NULL DEFAULT 'COMPRA' CHECK(tipo IN('COMPRA','PROVISION','RENOVACION')),
  codigo_documento        VARCHAR(5),
  numero_documento        VARCHAR(15),
  numero_cuota            SMALLINT      DEFAULT 1,
  total_cuotas            SMALLINT      DEFAULT 1,
  monto_total             NUMERIC(14,2) DEFAULT 0,
  monto_pagado            NUMERIC(14,2) DEFAULT 0,
  saldo                   NUMERIC(14,2) DEFAULT 0,
  interes                 NUMERIC(8,2)  DEFAULT 0,
  fecha_emision           DATE          NOT NULL,
  fecha_vencimiento       DATE,
  codigo_proveedor        VARCHAR(10)   NOT NULL,
  descripcion             VARCHAR(100),
  referencia              VARCHAR(50),
  pendiente               BOOLEAN       DEFAULT true,
  created_at              TIMESTAMPTZ   DEFAULT now(),
  UNIQUE(codigo_empresa, numero_provision)
);
CREATE INDEX idx_cxp ON cuentas_pagar(codigo_empresa, codigo_proveedor, pendiente);

CREATE TABLE pagos (
  id               UUID          PRIMARY KEY DEFAULT gen_random_uuid(),
  codigo_empresa   VARCHAR(10)   NOT NULL REFERENCES empresas(codigo),
  cuenta_pagar_id  UUID          NOT NULL REFERENCES cuentas_pagar(id),
  numero_recibo    VARCHAR(15)   NOT NULL,
  fecha            DATE          NOT NULL,
  tipo_pago        VARCHAR(15)   NOT NULL CHECK(tipo_pago IN('EFECTIVO','TRANSFERENCIA','CHEQUE')),
  numero_operacion VARCHAR(20),
  codigo_banco     VARCHAR(5),
  monto            NUMERIC(14,2) NOT NULL,
  codigo_usuario   VARCHAR(10)   NOT NULL,
  created_at       TIMESTAMPTZ   DEFAULT now(),
  UNIQUE(codigo_empresa, numero_recibo)
);

-- ============================================================
-- GRUPO 9: Caja
-- ============================================================

CREATE TABLE caja (
  id                UUID          PRIMARY KEY DEFAULT gen_random_uuid(),
  codigo_empresa    VARCHAR(10)   NOT NULL REFERENCES empresas(codigo),
  numero_movimiento BIGINT        NOT NULL,
  codigo_documento  VARCHAR(5),
  numero_documento  VARCHAR(20),
  fecha             DATE          NOT NULL,
  tipo              VARCHAR(10)   NOT NULL CHECK(tipo IN('INGRESO','EGRESO')),
  concepto          VARCHAR(100)  NOT NULL,
  codigo_usuario    VARCHAR(10)   NOT NULL,
  monto             NUMERIC(14,2) NOT NULL,
  tipo_transaccion  VARCHAR(15)   NOT NULL CHECK(tipo_transaccion IN('EFECTIVO','TRANSFERENCIA')),
  numero_referencia VARCHAR(20),
  codigo_banco      VARCHAR(5),
  created_at        TIMESTAMPTZ   DEFAULT now(),
  UNIQUE(codigo_empresa, numero_movimiento)
);
CREATE INDEX idx_caja ON caja(codigo_empresa, fecha, tipo);

-- ============================================================
-- ROW LEVEL SECURITY
-- El backend usa service_role (bypasses RLS), pero lo habilitamos
-- como capa de seguridad adicional para accesos directos.
-- ============================================================

DO $$ DECLARE t text; BEGIN
  FOR t IN SELECT unnest(ARRAY[
    'empresas','parametros','usuarios','refresh_tokens','auditoria_sesiones',
    'tipo_cambio','lineas','medidas','bancos','documentos','marcas',
    'articulos','clientes','proveedores','almacenes','stock',
    'movimientos_almacen','detalle_movimientos','kardex',
    'compras','detalle_compras','ventas','detalle_ventas',
    'cuentas_cobrar','cobros','cuentas_pagar','pagos','caja'
  ])
  LOOP
    EXECUTE format('ALTER TABLE %I ENABLE ROW LEVEL SECURITY', t);
  END LOOP;
END $$;

-- Políticas para tablas con codigo_empresa directo
DO $$ DECLARE tbl text; BEGIN
  FOR tbl IN SELECT unnest(ARRAY[
    'parametros','usuarios','tipo_cambio','lineas','medidas','bancos',
    'documentos','marcas','articulos','clientes','proveedores','almacenes',
    'stock','movimientos_almacen','detalle_movimientos','kardex',
    'compras','detalle_compras','ventas','detalle_ventas',
    'cuentas_cobrar','cobros','cuentas_pagar','pagos','caja','auditoria_sesiones'
  ])
  LOOP
    EXECUTE format(
      'CREATE POLICY ep_%s ON %I USING (codigo_empresa = current_setting(''app.current_empresa'', true))',
      tbl, tbl
    );
  END LOOP;
END $$;

-- Empresas: visible para todos (el backend filtra por el código del JWT)
CREATE POLICY ep_empresas ON empresas USING (true);

-- Refresh tokens: acceso por usuario
CREATE POLICY ep_refresh ON refresh_tokens
  USING (usuario_id = (SELECT id FROM usuarios
    WHERE codigo = current_setting('app.current_usuario', true)
    LIMIT 1));
