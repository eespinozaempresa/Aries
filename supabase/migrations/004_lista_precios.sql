-- ============================================================
-- Aries — Lista de Precios
-- ============================================================

-- tipos_lista: categorías de lista de precios con descuentos por defecto
CREATE TABLE tipos_lista (
  id             UUID          PRIMARY KEY DEFAULT gen_random_uuid(),
  codigo_empresa VARCHAR(10)   NOT NULL REFERENCES empresas(codigo) ON UPDATE CASCADE,
  codigo         VARCHAR(5)    NOT NULL,
  descripcion    VARCHAR(100)  NOT NULL,
  dscto_pct      NUMERIC(5,2)  NOT NULL DEFAULT 0,
  dcto_mto       NUMERIC(10,4) NOT NULL DEFAULT 0,
  activo         BOOLEAN       DEFAULT true,
  created_at     TIMESTAMPTZ   DEFAULT now(),
  updated_at     TIMESTAMPTZ   DEFAULT now(),
  UNIQUE(codigo_empresa, codigo)
);
CREATE TRIGGER trg_tipos_lista_upd BEFORE UPDATE ON tipos_lista
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();
ALTER TABLE tipos_lista ENABLE ROW LEVEL SECURITY;
CREATE POLICY tipos_lista_empresa ON tipos_lista
  USING (codigo_empresa = current_setting('app.empresa', true));

-- lista_precios: precios por artículo y tipo de lista
CREATE TABLE lista_precios (
  id                UUID          PRIMARY KEY DEFAULT gen_random_uuid(),
  codigo_empresa    VARCHAR(10)   NOT NULL REFERENCES empresas(codigo) ON UPDATE CASCADE,
  id_articulo       UUID          NOT NULL REFERENCES articulos(id) ON DELETE CASCADE,
  id_tipo_lista     UUID          NOT NULL REFERENCES tipos_lista(id) ON DELETE CASCADE,
  precio_venta_base NUMERIC(10,4) NOT NULL DEFAULT 0,
  descuento_pct     NUMERIC(5,2)  NOT NULL DEFAULT 0,
  descuento_monto   NUMERIC(10,4) NOT NULL DEFAULT 0,
  precio_venta      NUMERIC(10,4) NOT NULL DEFAULT 0,
  activo            BOOLEAN       DEFAULT true,
  created_at        TIMESTAMPTZ   DEFAULT now(),
  updated_at        TIMESTAMPTZ   DEFAULT now(),
  UNIQUE(codigo_empresa, id_articulo, id_tipo_lista)
);
CREATE TRIGGER trg_lista_precios_upd BEFORE UPDATE ON lista_precios
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();
ALTER TABLE lista_precios ENABLE ROW LEVEL SECURITY;
CREATE POLICY lista_precios_empresa ON lista_precios
  USING (codigo_empresa = current_setting('app.empresa', true));

-- Asignar lista de precios a clientes
ALTER TABLE clientes
  ADD COLUMN id_tipo_lista UUID REFERENCES tipos_lista(id) ON DELETE SET NULL;
