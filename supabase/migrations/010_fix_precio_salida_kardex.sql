-- ============================================================
-- Fix: precio_salida en kardex usa el precio real de la
-- factura/documento en lugar del costo promedio ponderado.
-- ============================================================

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
  p_lineas      JSONB DEFAULT '[]'::jsonb
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
    codigo_empresa, codigo_documento, numero_documento,
    fecha, tipo, codigo_almacen_origen, codigo_almacen_dest,
    observacion, concepto, codigo_usuario
  ) VALUES (
    p_empresa, p_cod_doc, p_num_doc,
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

    -- Leer stock + costo origen (con bloqueo)
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
        stock_entradas      = stock_entradas + v_qty,
        costo_promedio      = v_new_cost_orig,
        importe_total       = ROUND((v_stk_orig + v_qty) * v_new_cost_orig, 2),
        fecha_actualizacion = p_fecha
      WHERE codigo_empresa = p_empresa
        AND codigo_almacen  = p_alm_origen
        AND codigo_articulo = v_art;

      INSERT INTO kardex (
        codigo_empresa, codigo_almacen, codigo_articulo,
        fecha, codigo_documento, numero_documento, tipo,
        cant_entrada, precio_entrada, importe_entrada,
        stock, precio_stock, importe_stock
      ) VALUES (
        p_empresa, p_alm_origen, v_art,
        p_fecha, p_cod_doc, p_num_doc, 'INGRESO',
        v_qty, v_precio, v_importe,
        v_stk_orig + v_qty, v_new_cost_orig,
        ROUND((v_stk_orig + v_qty) * v_new_cost_orig, 2)
      );

    -- ── SALIDA ───────────────────────────────────────────────
    -- precio_salida = precio real del documento (factura de venta)
    -- precio_stock  = costo promedio ponderado (sin cambio)
    ELSIF p_tipo = 'SALIDA' THEN
      v_new_cost_orig := v_cost_orig;

      UPDATE stock SET
        stock_salidas       = stock_salidas + v_qty,
        importe_total       = ROUND((v_stk_orig - v_qty) * v_cost_orig, 2),
        fecha_actualizacion = p_fecha
      WHERE codigo_empresa = p_empresa
        AND codigo_almacen  = p_alm_origen
        AND codigo_articulo = v_art;

      INSERT INTO kardex (
        codigo_empresa, codigo_almacen, codigo_articulo,
        fecha, codigo_documento, numero_documento, tipo,
        cant_salida, precio_salida, importe_salida,
        stock, precio_stock, importe_stock
      ) VALUES (
        p_empresa, p_alm_origen, v_art,
        p_fecha, p_cod_doc, p_num_doc, 'SALIDA',
        v_qty, v_precio, ROUND(v_qty * v_precio, 2),
        v_stk_orig - v_qty, v_cost_orig,
        ROUND((v_stk_orig - v_qty) * v_cost_orig, 2)
      );

    -- ── TRASLADO ─────────────────────────────────────────────
    ELSIF p_tipo = 'TRASLADO' THEN
      v_new_cost_orig := v_cost_orig;

      -- Origen: salida al costo promedio
      UPDATE stock SET
        stock_traslados_out = stock_traslados_out + v_qty,
        importe_total       = ROUND((v_stk_orig - v_qty) * v_cost_orig, 2),
        fecha_actualizacion = p_fecha
      WHERE codigo_empresa = p_empresa
        AND codigo_almacen  = p_alm_origen
        AND codigo_articulo = v_art;

      INSERT INTO kardex (
        codigo_empresa, codigo_almacen, codigo_articulo,
        fecha, codigo_documento, numero_documento, tipo,
        cant_salida, precio_salida, importe_salida,
        stock, precio_stock, importe_stock
      ) VALUES (
        p_empresa, p_alm_origen, v_art,
        p_fecha, p_cod_doc, p_num_doc, 'TRASLADO-SAL',
        v_qty, v_cost_orig, ROUND(v_qty * v_cost_orig, 2),
        v_stk_orig - v_qty, v_cost_orig,
        ROUND((v_stk_orig - v_qty) * v_cost_orig, 2)
      );

      -- Destino: entrada al costo promedio del origen
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
        fecha, codigo_documento, numero_documento, tipo,
        cant_entrada, precio_entrada, importe_entrada,
        stock, precio_stock, importe_stock
      ) VALUES (
        p_empresa, p_alm_dest, v_art,
        p_fecha, p_cod_doc, p_num_doc, 'TRASLADO-ENT',
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
