-- ============================================================
-- Aries — Fórmulas (BOM: Principal + Partes)
-- Define qué artículos "Principal" están compuestos por otros
-- artículos "Parte" y en qué cantidad. Se usa en el flujo de
-- venta para explotar el consumo de Partes en Movimientos,
-- Kardex y Stock (además del propio Principal).
-- ============================================================

-- formulas: cabecera, una fórmula activa por artículo Principal
CREATE TABLE formulas (
  id              UUID          PRIMARY KEY DEFAULT gen_random_uuid(),
  codigo_empresa  VARCHAR(10)   NOT NULL REFERENCES empresas(codigo) ON UPDATE CASCADE,
  codigo_articulo VARCHAR(10)   NOT NULL,
  observacion     VARCHAR(150),
  activo          BOOLEAN       DEFAULT true,
  created_at      TIMESTAMPTZ   DEFAULT now(),
  updated_at      TIMESTAMPTZ   DEFAULT now(),
  UNIQUE(codigo_empresa, codigo_articulo),
  FOREIGN KEY (codigo_empresa, codigo_articulo) REFERENCES articulos(codigo_empresa, codigo)
);
CREATE TRIGGER trg_formulas_upd BEFORE UPDATE ON formulas
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();
ALTER TABLE formulas ENABLE ROW LEVEL SECURITY;
CREATE POLICY formulas_empresa ON formulas
  USING (codigo_empresa = current_setting('app.empresa', true));

-- detalle_formulas: líneas (Partes) que componen el Principal
CREATE TABLE detalle_formulas (
  id              UUID          PRIMARY KEY DEFAULT gen_random_uuid(),
  formula_id      UUID          NOT NULL REFERENCES formulas(id) ON DELETE CASCADE,
  codigo_empresa  VARCHAR(10)   NOT NULL REFERENCES empresas(codigo) ON UPDATE CASCADE,
  codigo_articulo VARCHAR(10)   NOT NULL,
  cantidad        NUMERIC(14,4) NOT NULL CHECK (cantidad > 0),
  orden           INT           DEFAULT 0,
  created_at      TIMESTAMPTZ   DEFAULT now(),
  UNIQUE(formula_id, codigo_articulo),
  FOREIGN KEY (codigo_empresa, codigo_articulo) REFERENCES articulos(codigo_empresa, codigo)
);
ALTER TABLE detalle_formulas ENABLE ROW LEVEL SECURITY;
CREATE POLICY detalle_formulas_empresa ON detalle_formulas
  USING (codigo_empresa = current_setting('app.empresa', true));
