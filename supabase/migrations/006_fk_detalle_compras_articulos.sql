-- Agrega FK compuesta entre detalle_compras y articulos
-- para que Supabase PostgREST reconozca la relación y permita
-- joins del tipo: detalle_compras(*, articulos(descripcion))
ALTER TABLE detalle_compras
  ADD CONSTRAINT fk_detcomp_articulo
  FOREIGN KEY (codigo_empresa, codigo_articulo)
  REFERENCES articulos(codigo_empresa, codigo);
