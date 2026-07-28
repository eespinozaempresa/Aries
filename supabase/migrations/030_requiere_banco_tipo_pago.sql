-- Agrega requiere_banco a tipo_pago para mostrar el control de Banco en los
-- formularios de cobro, pago e ingreso/salida de caja de forma independiente
-- a requiere_operacion (que solo controla el N° de Operación).

ALTER TABLE tipo_pago
  ADD COLUMN IF NOT EXISTS requiere_banco BOOLEAN NOT NULL DEFAULT false;
