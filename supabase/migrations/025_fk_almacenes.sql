-- Agrega FKs compuestas hacia almacenes para bloquear el borrado
-- de un almacén (error 23503) si tiene operaciones asociadas.
-- Mismo patrón que 006/007/008_fk_..._articulos.sql (sin ON DELETE,
-- por lo que el default NO ACTION rechaza el DELETE si hay filas relacionadas).

ALTER TABLE stock
  ADD CONSTRAINT fk_stock_almacen
  FOREIGN KEY (codigo_empresa, codigo_almacen)
  REFERENCES almacenes(codigo_empresa, codigo);

ALTER TABLE movimientos_almacen
  ADD CONSTRAINT fk_mov_almacen_origen
  FOREIGN KEY (codigo_empresa, codigo_almacen_origen)
  REFERENCES almacenes(codigo_empresa, codigo);

ALTER TABLE movimientos_almacen
  ADD CONSTRAINT fk_mov_almacen_dest
  FOREIGN KEY (codigo_empresa, codigo_almacen_dest)
  REFERENCES almacenes(codigo_empresa, codigo);

ALTER TABLE compras
  ADD CONSTRAINT fk_compras_almacen
  FOREIGN KEY (codigo_empresa, codigo_almacen)
  REFERENCES almacenes(codigo_empresa, codigo);

ALTER TABLE ventas
  ADD CONSTRAINT fk_ventas_almacen
  FOREIGN KEY (codigo_empresa, codigo_almacen)
  REFERENCES almacenes(codigo_empresa, codigo);
