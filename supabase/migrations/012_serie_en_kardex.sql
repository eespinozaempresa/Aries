-- ============================================================
-- Agrega columna 'serie' a la tabla kardex y actualiza las
-- funciones registrar_movimiento y recalcular_kardex_empresa
-- para propagar el campo serie en cada fila de kardex.
-- ============================================================

-- 1. Agregar 'serie' a kardex
ALTER TABLE kardex ADD COLUMN IF NOT EXISTS serie VARCHAR(4) NOT NULL DEFAULT '0001';

-- 2. Actualizar registrar_movimiento (acepta p_serie, lo escribe en movimientos y kardex)
CREATE OR REPLACE FUNCTION registrar_movimiento(
  p_empresa     TEXT,
  p_cod_doc     TEXT,
  p_num_doc     TEXT,
  p_fecha       DATE,
  p_tipo        TEXT,
  p_alm_origen  TEXT,
  p_alm_dest    TEXT DEFAULT NULL,
  p_observacion TEXT DEFAULT NULL,
  p_concepto    TEXT DEFAULT NULL,
  p_cod_usuario TEXT DEFAULT NULL,
  p_lineas      JSONB DEFAULT '[]'::jsonb,
  p_serie       TEXT DEFAULT '0001'
) RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_mov_id        UUID;
  v_total         NUMERIC := 0;
  v_linea         JSONB;
  v_art           TEXT;
  v_qty           NUMERIC;
  v_precio        NUMERIC;
  v_importe       NUMERIC;

  v_stk_orig      NUMERIC;
  v_cost_orig     NUMERIC;
  v_new_cost_orig NUMERIC;

  v_stk_dest      NUMERIC;
  v_cost_dest     NUMERIC;
  v_new_cost_dest NUMERIC;
BEGIN
  -- Cabecera
  INSERT INTO movimientos_almacen (
    codigo_empresa, codigo_documento, serie, numero_documento,
    fecha, tipo, codigo_almacen_origen, codigo_almacen_dest,
    observacion, concepto, codigo_usuario
  ) VALUES (
    p_empresa, p_cod_doc, p_serie, p_num_doc,
    p_fecha, p_tipo, p_alm_origen, p_alm_dest,
    p_observacion, p_concepto, p_cod_usuario
  ) RETURNING id INTO v_mov_id;

  -- Procesar cada línea
  FOR v_linea IN SELECT value FROM jsonb_array_elements(p_lineas)
  LOOP
    v_art     := v_linea->>'codigoArticulo';
    v_qty     := (v_linea->>'cantidad')::NUMERIC;
    v_precio  := (v_linea->>'precioUnitario')::NUMERIC;
    v_importe := ROUND(v_qty * v_precio, 2);
    v_total   := v_total + v_importe;

    -- Detalle
    INSERT INTO detalle_movimientos (
      movimiento_id, codigo_empresa, codigo_articulo,
      cantidad, precio_unitario, importe
    ) VALUES (
      v_mov_id, p_empresa, v_art,
      v_qty, v_precio, v_importe
    );

    -- Asegurar fila de stock origen
    INSERT INTO stock (codigo_empresa, codigo_almacen, codigo_articulo)
    VALUES (p_empresa, p_alm_origen, v_art)
    ON CONFLICT (codigo_empresa, codigo_almacen, codigo_articulo) DO NOTHING;

    -- Leer stock+costo origen
    SELECT
      stock_actual(p_empresa, p_alm_origen, v_art),
      costo_promedio
    INTO v_stk_orig, v_cost_orig
    FROM stock
    WHERE codigo_empresa = p_empresa
      AND codigo_almacen  = p_alm_origen
      AND codigo_articulo = v_art
    FOR UPDATE;

    -- ── INGRESO ──────────────────────────────────────────────
    IF p_tipo = 'INGRESO' THEN
      IF v_stk_orig + v_qty > 0 THEN
        v_new_cost_orig := ROUND(
          (v_stk_orig * v_cost_orig + v_qty * v_precio) / (v_stk_orig + v_qty), 6);
      ELSE
        v_new_cost_orig := v_precio;
      END IF;

      UPDATE stock SET
        stock_entradas    = stock_entradas + v_qty,
        costo_promedio    = v_new_cost_orig,
        importe_total     = ROUND((v_stk_orig + v_qty) * v_new_cost_orig, 2),
        fecha_actualizacion = p_fecha
      WHERE codigo_empresa = p_empresa
        AND codigo_almacen  = p_alm_origen
        AND codigo_articulo = v_art;

      INSERT INTO kardex (
        codigo_empresa, codigo_almacen, codigo_articulo,
        fecha, codigo_documento, serie, numero_documento, tipo,
        cant_entrada, precio_entrada, importe_entrada,
        stock, precio_stock, importe_stock
      ) VALUES (
        p_empresa, p_alm_origen, v_art,
        p_fecha, p_cod_doc, p_serie, p_num_doc, 'INGRESO',
        v_qty, v_precio, v_importe,
        v_stk_orig + v_qty, v_new_cost_orig,
        ROUND((v_stk_orig + v_qty) * v_new_cost_orig, 2)
      );

    -- ── SALIDA ───────────────────────────────────────────────
    ELSIF p_tipo = 'SALIDA' THEN
      v_new_cost_orig := v_cost_orig;

      UPDATE stock SET
        stock_salidas     = stock_salidas + v_qty,
        importe_total     = ROUND((v_stk_orig - v_qty) * v_cost_orig, 2),
        fecha_actualizacion = p_fecha
      WHERE codigo_empresa = p_empresa
        AND codigo_almacen  = p_alm_origen
        AND codigo_articulo = v_art;

      INSERT INTO kardex (
        codigo_empresa, codigo_almacen, codigo_articulo,
        fecha, codigo_documento, serie, numero_documento, tipo,
        cant_salida, precio_salida, importe_salida,
        stock, precio_stock, importe_stock
      ) VALUES (
        p_empresa, p_alm_origen, v_art,
        p_fecha, p_cod_doc, p_serie, p_num_doc, 'SALIDA',
        v_qty, v_precio, ROUND(v_qty * v_precio, 2),
        v_stk_orig - v_qty, v_cost_orig,
        ROUND((v_stk_orig - v_qty) * v_cost_orig, 2)
      );

    -- ── TRASLADO ─────────────────────────────────────────────
    ELSIF p_tipo = 'TRASLADO' THEN
      v_new_cost_orig := v_cost_orig;

      -- Origen: salida
      UPDATE stock SET
        stock_traslados_out = stock_traslados_out + v_qty,
        importe_total       = ROUND((v_stk_orig - v_qty) * v_cost_orig, 2),
        fecha_actualizacion = p_fecha
      WHERE codigo_empresa = p_empresa
        AND codigo_almacen  = p_alm_origen
        AND codigo_articulo = v_art;

      INSERT INTO kardex (
        codigo_empresa, codigo_almacen, codigo_articulo,
        fecha, codigo_documento, serie, numero_documento, tipo,
        cant_salida, precio_salida, importe_salida,
        stock, precio_stock, importe_stock
      ) VALUES (
        p_empresa, p_alm_origen, v_art,
        p_fecha, p_cod_doc, p_serie, p_num_doc, 'TRASLADO-SAL',
        v_qty, v_cost_orig, ROUND(v_qty * v_cost_orig, 2),
        v_stk_orig - v_qty, v_cost_orig,
        ROUND((v_stk_orig - v_qty) * v_cost_orig, 2)
      );

      -- Destino: entrada
      INSERT INTO stock (codigo_empresa, codigo_almacen, codigo_articulo)
      VALUES (p_empresa, p_alm_dest, v_art)
      ON CONFLICT (codigo_empresa, codigo_almacen, codigo_articulo) DO NOTHING;

      SELECT
        stock_actual(p_empresa, p_alm_dest, v_art),
        costo_promedio
      INTO v_stk_dest, v_cost_dest
      FROM stock
      WHERE codigo_empresa = p_empresa
        AND codigo_almacen  = p_alm_dest
        AND codigo_articulo = v_art
      FOR UPDATE;

      IF v_stk_dest + v_qty > 0 THEN
        v_new_cost_dest := ROUND(
          (v_stk_dest * v_cost_dest + v_qty * v_cost_orig) / (v_stk_dest + v_qty), 6);
      ELSE
        v_new_cost_dest := v_cost_orig;
      END IF;

      UPDATE stock SET
        stock_traslados_in  = stock_traslados_in + v_qty,
        costo_promedio      = v_new_cost_dest,
        importe_total       = ROUND((v_stk_dest + v_qty) * v_new_cost_dest, 2),
        fecha_actualizacion = p_fecha
      WHERE codigo_empresa = p_empresa
        AND codigo_almacen  = p_alm_dest
        AND codigo_articulo = v_art;

      INSERT INTO kardex (
        codigo_empresa, codigo_almacen, codigo_articulo,
        fecha, codigo_documento, serie, numero_documento, tipo,
        cant_entrada, precio_entrada, importe_entrada,
        stock, precio_stock, importe_stock
      ) VALUES (
        p_empresa, p_alm_dest, v_art,
        p_fecha, p_cod_doc, p_serie, p_num_doc, 'TRASLADO-ENT',
        v_qty, v_cost_orig, ROUND(v_qty * v_cost_orig, 2),
        v_stk_dest + v_qty, v_new_cost_dest,
        ROUND((v_stk_dest + v_qty) * v_new_cost_dest, 2)
      );
    END IF;

  END LOOP;

  -- Actualizar total del movimiento
  UPDATE movimientos_almacen SET total = ROUND(v_total, 2) WHERE id = v_mov_id;

  RETURN v_mov_id;
END;
$$;

-- 3. Actualizar recalcular_kardex_empresa para propagar serie desde movimientos_almacen
CREATE OR REPLACE FUNCTION recalcular_kardex_empresa(
  p_empresa TEXT
) RETURNS INTEGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_mov           RECORD;
  v_linea         RECORD;
  v_qty           NUMERIC;
  v_precio        NUMERIC;
  v_importe       NUMERIC;
  v_stk_orig      NUMERIC;
  v_cost_orig     NUMERIC;
  v_new_cost_orig NUMERIC;
  v_stk_dest      NUMERIC;
  v_cost_dest     NUMERIC;
  v_new_cost_dest NUMERIC;
  v_count         INTEGER := 0;
BEGIN
  -- 1. Eliminar todo el kardex de la empresa
  DELETE FROM kardex WHERE codigo_empresa = p_empresa;

  -- 2. Resetear contadores de stock (mantener stock_inicial)
  UPDATE stock SET
    stock_compras       = 0,
    stock_ventas        = 0,
    stock_entradas      = 0,
    stock_salidas       = 0,
    stock_traslados_in  = 0,
    stock_traslados_out = 0,
    costo_promedio      = 0,
    importe_total       = 0
  WHERE codigo_empresa = p_empresa;

  -- 3. Procesar cada movimiento no-anulado en orden cronológico
  FOR v_mov IN
    SELECT * FROM movimientos_almacen
    WHERE codigo_empresa = p_empresa
      AND NOT anulado
    ORDER BY fecha ASC, created_at ASC
  LOOP
    FOR v_linea IN
      SELECT * FROM detalle_movimientos
      WHERE movimiento_id = v_mov.id
        AND codigo_empresa = p_empresa
    LOOP
      v_qty     := v_linea.cantidad;
      v_precio  := v_linea.precio_unitario;
      v_importe := ROUND(v_qty * v_precio, 2);

      -- Asegurar fila de stock origen
      INSERT INTO stock (codigo_empresa, codigo_almacen, codigo_articulo)
      VALUES (p_empresa, v_mov.codigo_almacen_origen, v_linea.codigo_articulo)
      ON CONFLICT (codigo_empresa, codigo_almacen, codigo_articulo) DO NOTHING;

      SELECT
        stock_actual(p_empresa, v_mov.codigo_almacen_origen, v_linea.codigo_articulo),
        costo_promedio
      INTO v_stk_orig, v_cost_orig
      FROM stock
      WHERE codigo_empresa = p_empresa
        AND codigo_almacen  = v_mov.codigo_almacen_origen
        AND codigo_articulo = v_linea.codigo_articulo
      FOR UPDATE;

      -- ── INGRESO ──────────────────────────────────────────
      IF v_mov.tipo = 'INGRESO' THEN
        IF v_stk_orig + v_qty > 0 THEN
          v_new_cost_orig := ROUND(
            (v_stk_orig * v_cost_orig + v_qty * v_precio) / (v_stk_orig + v_qty), 6);
        ELSE
          v_new_cost_orig := v_precio;
        END IF;

        UPDATE stock SET
          stock_entradas      = stock_entradas + v_qty,
          costo_promedio      = v_new_cost_orig,
          importe_total       = ROUND((v_stk_orig + v_qty) * v_new_cost_orig, 2),
          fecha_actualizacion = v_mov.fecha
        WHERE codigo_empresa = p_empresa
          AND codigo_almacen  = v_mov.codigo_almacen_origen
          AND codigo_articulo = v_linea.codigo_articulo;

        INSERT INTO kardex (
          codigo_empresa, codigo_almacen, codigo_articulo,
          fecha, codigo_documento, serie, numero_documento, tipo,
          cant_entrada, precio_entrada, importe_entrada,
          stock, precio_stock, importe_stock
        ) VALUES (
          p_empresa, v_mov.codigo_almacen_origen, v_linea.codigo_articulo,
          v_mov.fecha, v_mov.codigo_documento, COALESCE(v_mov.serie, '0001'), v_mov.numero_documento, 'INGRESO',
          v_qty, v_precio, v_importe,
          v_stk_orig + v_qty, v_new_cost_orig,
          ROUND((v_stk_orig + v_qty) * v_new_cost_orig, 2)
        );

      -- ── SALIDA ───────────────────────────────────────────
      ELSIF v_mov.tipo = 'SALIDA' THEN
        UPDATE stock SET
          stock_salidas       = stock_salidas + v_qty,
          importe_total       = ROUND((v_stk_orig - v_qty) * v_cost_orig, 2),
          fecha_actualizacion = v_mov.fecha
        WHERE codigo_empresa = p_empresa
          AND codigo_almacen  = v_mov.codigo_almacen_origen
          AND codigo_articulo = v_linea.codigo_articulo;

        INSERT INTO kardex (
          codigo_empresa, codigo_almacen, codigo_articulo,
          fecha, codigo_documento, serie, numero_documento, tipo,
          cant_salida, precio_salida, importe_salida,
          stock, precio_stock, importe_stock
        ) VALUES (
          p_empresa, v_mov.codigo_almacen_origen, v_linea.codigo_articulo,
          v_mov.fecha, v_mov.codigo_documento, COALESCE(v_mov.serie, '0001'), v_mov.numero_documento, 'SALIDA',
          v_qty, v_precio, ROUND(v_qty * v_precio, 2),
          v_stk_orig - v_qty, v_cost_orig,
          ROUND((v_stk_orig - v_qty) * v_cost_orig, 2)
        );

      -- ── TRASLADO ─────────────────────────────────────────
      ELSIF v_mov.tipo = 'TRASLADO' THEN
        UPDATE stock SET
          stock_traslados_out = stock_traslados_out + v_qty,
          importe_total       = ROUND((v_stk_orig - v_qty) * v_cost_orig, 2),
          fecha_actualizacion = v_mov.fecha
        WHERE codigo_empresa = p_empresa
          AND codigo_almacen  = v_mov.codigo_almacen_origen
          AND codigo_articulo = v_linea.codigo_articulo;

        INSERT INTO kardex (
          codigo_empresa, codigo_almacen, codigo_articulo,
          fecha, codigo_documento, serie, numero_documento, tipo,
          cant_salida, precio_salida, importe_salida,
          stock, precio_stock, importe_stock
        ) VALUES (
          p_empresa, v_mov.codigo_almacen_origen, v_linea.codigo_articulo,
          v_mov.fecha, v_mov.codigo_documento, COALESCE(v_mov.serie, '0001'), v_mov.numero_documento, 'TRASLADO-SAL',
          v_qty, v_cost_orig, ROUND(v_qty * v_cost_orig, 2),
          v_stk_orig - v_qty, v_cost_orig,
          ROUND((v_stk_orig - v_qty) * v_cost_orig, 2)
        );

        INSERT INTO stock (codigo_empresa, codigo_almacen, codigo_articulo)
        VALUES (p_empresa, v_mov.codigo_almacen_dest, v_linea.codigo_articulo)
        ON CONFLICT (codigo_empresa, codigo_almacen, codigo_articulo) DO NOTHING;

        SELECT
          stock_actual(p_empresa, v_mov.codigo_almacen_dest, v_linea.codigo_articulo),
          costo_promedio
        INTO v_stk_dest, v_cost_dest
        FROM stock
        WHERE codigo_empresa = p_empresa
          AND codigo_almacen  = v_mov.codigo_almacen_dest
          AND codigo_articulo = v_linea.codigo_articulo
        FOR UPDATE;

        IF v_stk_dest + v_qty > 0 THEN
          v_new_cost_dest := ROUND(
            (v_stk_dest * v_cost_dest + v_qty * v_cost_orig) / (v_stk_dest + v_qty), 6);
        ELSE
          v_new_cost_dest := v_cost_orig;
        END IF;

        UPDATE stock SET
          stock_traslados_in  = stock_traslados_in + v_qty,
          costo_promedio      = v_new_cost_dest,
          importe_total       = ROUND((v_stk_dest + v_qty) * v_new_cost_dest, 2),
          fecha_actualizacion = v_mov.fecha
        WHERE codigo_empresa = p_empresa
          AND codigo_almacen  = v_mov.codigo_almacen_dest
          AND codigo_articulo = v_linea.codigo_articulo;

        INSERT INTO kardex (
          codigo_empresa, codigo_almacen, codigo_articulo,
          fecha, codigo_documento, serie, numero_documento, tipo,
          cant_entrada, precio_entrada, importe_entrada,
          stock, precio_stock, importe_stock
        ) VALUES (
          p_empresa, v_mov.codigo_almacen_dest, v_linea.codigo_articulo,
          v_mov.fecha, v_mov.codigo_documento, COALESCE(v_mov.serie, '0001'), v_mov.numero_documento, 'TRASLADO-ENT',
          v_qty, v_cost_orig, ROUND(v_qty * v_cost_orig, 2),
          v_stk_dest + v_qty, v_new_cost_dest,
          ROUND((v_stk_dest + v_qty) * v_new_cost_dest, 2)
        );
      END IF;

    END LOOP;
    v_count := v_count + 1;
  END LOOP;

  RETURN v_count;
END;
$$;
