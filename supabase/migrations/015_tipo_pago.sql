-- ============================================================
-- Tabla: tipo_pago
-- ============================================================

CREATE TABLE IF NOT EXISTS tipo_pago (
  id                 UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
  codigo_empresa     VARCHAR(10)  NOT NULL REFERENCES empresas(codigo),
  codigo             VARCHAR(10)  NOT NULL,
  descripcion        VARCHAR(80)  NOT NULL,
  activo             BOOLEAN      NOT NULL DEFAULT true,
  requiere_operacion BOOLEAN      NOT NULL DEFAULT false,
  UNIQUE(codigo_empresa, codigo)
);

CREATE INDEX IF NOT EXISTS idx_tipo_pago_empresa
  ON tipo_pago (codigo_empresa, activo);

-- Agregar tipo_pago a movimientos_caja
ALTER TABLE movimientos_caja
  ADD COLUMN IF NOT EXISTS tipo_pago VARCHAR(20);
