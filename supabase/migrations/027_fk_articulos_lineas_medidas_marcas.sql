-- Agrega FKs compuestas desde articulos hacia lineas/medidas/marcas
-- para bloquear el borrado (error 23503) de una tabla base en uso.
-- Las columnas son nullable, por lo que artículos sin línea/medida/marca
-- asignada no se ven afectados.

ALTER TABLE articulos
  ADD CONSTRAINT fk_articulos_linea
  FOREIGN KEY (codigo_empresa, codigo_linea)
  REFERENCES lineas(codigo_empresa, codigo);

ALTER TABLE articulos
  ADD CONSTRAINT fk_articulos_medida
  FOREIGN KEY (codigo_empresa, codigo_medida)
  REFERENCES medidas(codigo_empresa, codigo);

ALTER TABLE articulos
  ADD CONSTRAINT fk_articulos_marca
  FOREIGN KEY (codigo_empresa, codigo_marca)
  REFERENCES marcas(codigo_empresa, codigo);
