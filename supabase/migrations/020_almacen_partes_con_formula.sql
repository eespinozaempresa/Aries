-- ============================================================
-- Almacén de Partes (parámetro) + flag con_formula en articulos
-- ============================================================

ALTER TABLE parametros ADD COLUMN IF NOT EXISTS almacen_partes VARCHAR(5);
ALTER TABLE articulos   ADD COLUMN IF NOT EXISTS con_formula BOOLEAN NOT NULL DEFAULT false;

-- Backfill: artículos que ya tienen una fórmula activa quedan marcados
UPDATE articulos a SET con_formula = true
WHERE EXISTS (
  SELECT 1 FROM formulas f
  WHERE f.codigo_empresa = a.codigo_empresa
    AND f.codigo_articulo = a.codigo
    AND f.activo = true
);
