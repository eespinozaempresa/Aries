-- ============================================================
-- Módulo Caja: sesiones_caja + movimientos_caja
-- ============================================================

-- Tabla maestra de cajas (puntos de venta)
CREATE TABLE IF NOT EXISTS cajas (
  id              UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
  codigo_empresa  VARCHAR(10)  NOT NULL REFERENCES empresas(codigo),
  codigo          VARCHAR(10)  NOT NULL,
  nombre          VARCHAR(80)  NOT NULL,
  activo          BOOLEAN      NOT NULL DEFAULT true,
  created_at      TIMESTAMPTZ  DEFAULT now(),
  UNIQUE (codigo_empresa, codigo)
);

-- Sesiones de caja (apertura / cierre)
CREATE TABLE IF NOT EXISTS sesiones_caja (
  id              UUID          PRIMARY KEY DEFAULT gen_random_uuid(),
  codigo_empresa  VARCHAR(10)   NOT NULL REFERENCES empresas(codigo),
  codigo_caja     VARCHAR(10)   NOT NULL,
  codigo_usuario  VARCHAR(10)   NOT NULL,
  fecha_apertura  TIMESTAMPTZ   NOT NULL DEFAULT now(),
  monto_apertura  NUMERIC(14,2) NOT NULL DEFAULT 0,
  fecha_cierre    TIMESTAMPTZ,
  montos_cierre   NUMERIC(14,2),
  diferencia      NUMERIC(14,2),
  estado          VARCHAR(10)   NOT NULL DEFAULT 'ABIERTA'
                  CHECK (estado IN ('ABIERTA','CERRADA')),
  created_at      TIMESTAMPTZ   DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_sesiones_caja_empresa
  ON sesiones_caja (codigo_empresa, estado);

-- Movimientos dentro de una sesión de caja
CREATE TABLE IF NOT EXISTS movimientos_caja (
  id              UUID          PRIMARY KEY DEFAULT gen_random_uuid(),
  codigo_empresa  VARCHAR(10)   NOT NULL REFERENCES empresas(codigo),
  sesion_caja_id  UUID          NOT NULL REFERENCES sesiones_caja(id),
  tipo            VARCHAR(10)   NOT NULL CHECK (tipo IN ('INGRESO','EGRESO')),
  concepto        VARCHAR(200)  NOT NULL,
  referencia      VARCHAR(100),
  monto           NUMERIC(14,2) NOT NULL CHECK (monto > 0),
  fecha           TIMESTAMPTZ   NOT NULL DEFAULT now(),
  codigo_usuario  VARCHAR(10)   NOT NULL,
  created_at      TIMESTAMPTZ   DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_movimientos_caja_sesion
  ON movimientos_caja (sesion_caja_id);
