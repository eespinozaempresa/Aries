-- ============================================================
-- Aries — Autonumeración por Serie
-- Agrega campo 'serie' a documentos y tablas de transacciones.
-- Crea función atómica siguiente_numero_doc().
-- ============================================================

-- 1. Agregar 'serie' a documentos y actualizar clave única
ALTER TABLE documentos ADD COLUMN IF NOT EXISTS serie VARCHAR(4) NOT NULL DEFAULT '0001';

DO $$ BEGIN
  ALTER TABLE documentos DROP CONSTRAINT documentos_codigo_empresa_codigo_key;
EXCEPTION WHEN undefined_object THEN NULL; END $$;

ALTER TABLE documentos
  ADD CONSTRAINT documentos_empresa_codigo_serie_key UNIQUE(codigo_empresa, codigo, serie);

-- 2. Agregar 'serie' a compras
ALTER TABLE compras ADD COLUMN IF NOT EXISTS serie VARCHAR(4) NOT NULL DEFAULT '0001';

DO $$ BEGIN
  ALTER TABLE compras DROP CONSTRAINT compras_codigo_empresa_codigo_documento_numero_documento_key;
EXCEPTION WHEN undefined_object THEN NULL; END $$;

ALTER TABLE compras
  ADD CONSTRAINT compras_empresa_doc_serie_num_key UNIQUE(codigo_empresa, codigo_documento, serie, numero_documento);

-- 3. Agregar 'serie' a ventas
ALTER TABLE ventas ADD COLUMN IF NOT EXISTS serie VARCHAR(4) NOT NULL DEFAULT '0001';

DO $$ BEGIN
  ALTER TABLE ventas DROP CONSTRAINT ventas_codigo_empresa_codigo_documento_numero_documento_key;
EXCEPTION WHEN undefined_object THEN NULL; END $$;

ALTER TABLE ventas
  ADD CONSTRAINT ventas_empresa_doc_serie_num_key UNIQUE(codigo_empresa, codigo_documento, serie, numero_documento);

-- 4. Agregar 'serie' a movimientos_almacen
ALTER TABLE movimientos_almacen ADD COLUMN IF NOT EXISTS serie VARCHAR(4) NOT NULL DEFAULT '0001';

DO $$ BEGIN
  ALTER TABLE movimientos_almacen
    DROP CONSTRAINT movimientos_almacen_codigo_empresa_codigo_documento_numero_documento_key;
EXCEPTION WHEN undefined_object THEN NULL; END $$;

ALTER TABLE movimientos_almacen
  ADD CONSTRAINT movimientos_empresa_doc_serie_num_key UNIQUE(codigo_empresa, codigo_documento, serie, numero_documento);

-- 5. Agregar 'serie' a cobros y pagos
ALTER TABLE cobros ADD COLUMN IF NOT EXISTS serie VARCHAR(4) NOT NULL DEFAULT '0001';
ALTER TABLE pagos  ADD COLUMN IF NOT EXISTS serie VARCHAR(4) NOT NULL DEFAULT '0001';

-- 6. Agregar 'serie' opcional a caja
ALTER TABLE caja ADD COLUMN IF NOT EXISTS serie VARCHAR(4);

-- 7. Función atómica: lee numero_siguiente, incrementa y devuelve formateado "0000025"
CREATE OR REPLACE FUNCTION siguiente_numero_doc(
  p_empresa  VARCHAR,
  p_cod_doc  VARCHAR,
  p_serie    VARCHAR
) RETURNS TEXT LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_num BIGINT;
BEGIN
  SELECT numero_siguiente INTO v_num
  FROM documentos
  WHERE codigo_empresa = p_empresa
    AND codigo         = p_cod_doc
    AND serie          = p_serie
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Documento % serie % no encontrado para empresa %', p_cod_doc, p_serie, p_empresa;
  END IF;

  UPDATE documentos
     SET numero_siguiente = v_num + 1
   WHERE codigo_empresa = p_empresa
     AND codigo         = p_cod_doc
     AND serie          = p_serie;

  RETURN LPAD(v_num::TEXT, 7, '0');
END;
$$;
