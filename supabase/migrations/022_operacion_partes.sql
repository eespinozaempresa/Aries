-- ============================================================
-- Operación de Partes (parámetro): en qué módulo se explota la
-- fórmula/BOM de un artículo Principal -- 'VENTAS' | 'MOVIMIENTOS'
-- ============================================================

ALTER TABLE parametros ADD COLUMN IF NOT EXISTS operacion_partes VARCHAR(20);
