-- ============================================================
-- Fix: la tabla pagos nunca se migró para igualar el contrato que
-- el código (entity/DTO/puerto/Flutter "N° Voucher") ya esperaba.
-- Se renombra numero_recibo -> numero_voucher y se agrega estado,
-- igual que ya tiene la tabla cobros.
-- ============================================================

ALTER TABLE pagos RENAME COLUMN numero_recibo TO numero_voucher;
ALTER TABLE pagos ADD COLUMN IF NOT EXISTS estado VARCHAR(10) NOT NULL DEFAULT 'ACTIVO'
  CHECK (estado IN ('ACTIVO','ANULADO'));
