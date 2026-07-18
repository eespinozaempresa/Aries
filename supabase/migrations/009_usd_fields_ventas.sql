-- Agrega campos USD a ventas y detalle_ventas
-- para soportar facturación en dólares con tipo de cambio

ALTER TABLE ventas
  ADD COLUMN moneda       VARCHAR(5)    DEFAULT 'PEN',
  ADD COLUMN tipo_cambio  NUMERIC(8,4)  DEFAULT 1,
  ADD COLUMN subtotal_usd NUMERIC(14,2) DEFAULT 0,
  ADD COLUMN igv_usd      NUMERIC(14,2) DEFAULT 0,
  ADD COLUMN total_usd    NUMERIC(14,2) DEFAULT 0;

ALTER TABLE detalle_ventas
  ADD COLUMN precio_unitario_usd NUMERIC(12,4) DEFAULT 0,
  ADD COLUMN importe_usd         NUMERIC(14,2) DEFAULT 0;
