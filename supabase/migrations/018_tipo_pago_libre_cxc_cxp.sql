-- ============================================================
-- Permitir tipos de pago del catálogo configurable (tipo_pago)
-- en Cobros (CxC) y Pagos (CxP), en vez del CHECK fijo a
-- EFECTIVO/TRANSFERENCIA/CHEQUE heredado del esquema inicial.
-- ============================================================

ALTER TABLE cobros DROP CONSTRAINT IF EXISTS cobros_tipo_pago_check;
ALTER TABLE cobros ALTER COLUMN tipo_pago TYPE VARCHAR(80);

ALTER TABLE pagos DROP CONSTRAINT IF EXISTS pagos_tipo_pago_check;
ALTER TABLE pagos ALTER COLUMN tipo_pago TYPE VARCHAR(80);
