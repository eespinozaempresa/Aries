-- ============================================================
-- Función recalcular_kardex_empresa
-- Reconstruye kardex y stock desde movimientos_almacen
-- existentes SIN crear nuevos registros en movimientos_almacen.
-- Corrige el bug de RecalcularKardexUseCase que llamaba a
-- registrar_movimiento y duplicaba / fallaba por UNIQUE constraint.
-- ============================================================

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
          fecha, codigo_documento, numero_documento, tipo,
          cant_entrada, precio_entrada, importe_entrada,
          stock, precio_stock, importe_stock
        ) VALUES (
          p_empresa, v_mov.codigo_almacen_origen, v_linea.codigo_articulo,
          v_mov.fecha, v_mov.codigo_documento, v_mov.numero_documento, 'INGRESO',
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
          fecha, codigo_documento, numero_documento, tipo,
          cant_salida, precio_salida, importe_salida,
          stock, precio_stock, importe_stock
        ) VALUES (
          p_empresa, v_mov.codigo_almacen_origen, v_linea.codigo_articulo,
          v_mov.fecha, v_mov.codigo_documento, v_mov.numero_documento, 'SALIDA',
          v_qty, v_precio, ROUND(v_qty * v_precio, 2),
          v_stk_orig - v_qty, v_cost_orig,
          ROUND((v_stk_orig - v_qty) * v_cost_orig, 2)
        );

      -- ── TRASLADO ─────────────────────────────────────────
      ELSIF v_mov.tipo = 'TRASLADO' THEN
        -- Origen: salida al costo promedio
        UPDATE stock SET
          stock_traslados_out = stock_traslados_out + v_qty,
          importe_total       = ROUND((v_stk_orig - v_qty) * v_cost_orig, 2),
          fecha_actualizacion = v_mov.fecha
        WHERE codigo_empresa = p_empresa
          AND codigo_almacen  = v_mov.codigo_almacen_origen
          AND codigo_articulo = v_linea.codigo_articulo;

        INSERT INTO kardex (
          codigo_empresa, codigo_almacen, codigo_articulo,
          fecha, codigo_documento, numero_documento, tipo,
          cant_salida, precio_salida, importe_salida,
          stock, precio_stock, importe_stock
        ) VALUES (
          p_empresa, v_mov.codigo_almacen_origen, v_linea.codigo_articulo,
          v_mov.fecha, v_mov.codigo_documento, v_mov.numero_documento, 'TRASLADO-SAL',
          v_qty, v_cost_orig, ROUND(v_qty * v_cost_orig, 2),
          v_stk_orig - v_qty, v_cost_orig,
          ROUND((v_stk_orig - v_qty) * v_cost_orig, 2)
        );

        -- Destino: entrada al costo promedio del origen
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
          fecha, codigo_documento, numero_documento, tipo,
          cant_entrada, precio_entrada, importe_entrada,
          stock, precio_stock, importe_stock
        ) VALUES (
          p_empresa, v_mov.codigo_almacen_dest, v_linea.codigo_articulo,
          v_mov.fecha, v_mov.codigo_documento, v_mov.numero_documento, 'TRASLADO-ENT',
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
