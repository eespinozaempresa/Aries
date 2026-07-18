-- Agrega FK compuesta entre detalle_ventas y articulos
-- para que Supabase PostgREST reconozca la relación y permita
-- joins del tipo: detalle_ventas(*, articulos(descripcion))
ALTER TABLE detalle_ventas
  ADD CONSTRAINT fk_detvta_articulo
  FOREIGN KEY (codigo_empresa, codigo_articulo)
  REFERENCES articulos(codigo_empresa, codigo);
