-- Agrega numero_operacion y codigo_banco a movimientos_caja, igual que
-- ya existe en cobros/pagos, para registrar el banco de origen/destino
-- de depósitos y transferencias en ingresos/egresos de caja.

ALTER TABLE movimientos_caja
  ADD COLUMN IF NOT EXISTS numero_operacion VARCHAR(20),
  ADD COLUMN IF NOT EXISTS codigo_banco     VARCHAR(5);

ALTER TABLE movimientos_caja
  ADD CONSTRAINT fk_movimientos_caja_banco
  FOREIGN KEY (codigo_empresa, codigo_banco)
  REFERENCES bancos(codigo_empresa, codigo);
