-- Agrega FK compuesta entre detalle_movimientos y articulos
-- para que Supabase PostgREST reconozca la relación y permita
-- joins del tipo: detalle_movimientos(*, articulos(descripcion))
ALTER TABLE detalle_movimientos
  ADD CONSTRAINT fk_detmov_articulo
  FOREIGN KEY (codigo_empresa, codigo_articulo)
  REFERENCES articulos(codigo_empresa, codigo);
