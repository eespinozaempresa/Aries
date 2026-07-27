-- Agrega FKs compuestas hacia clientes y proveedores para bloquear
-- el borrado (error 23503) si tienen operaciones asociadas.

ALTER TABLE ventas
  ADD CONSTRAINT fk_ventas_cliente
  FOREIGN KEY (codigo_empresa, codigo_cliente)
  REFERENCES clientes(codigo_empresa, codigo);

ALTER TABLE cuentas_cobrar
  ADD CONSTRAINT fk_cxc_cliente
  FOREIGN KEY (codigo_empresa, codigo_cliente)
  REFERENCES clientes(codigo_empresa, codigo);

ALTER TABLE compras
  ADD CONSTRAINT fk_compras_proveedor
  FOREIGN KEY (codigo_empresa, codigo_proveedor)
  REFERENCES proveedores(codigo_empresa, codigo);

ALTER TABLE cuentas_pagar
  ADD CONSTRAINT fk_cxp_proveedor
  FOREIGN KEY (codigo_empresa, codigo_proveedor)
  REFERENCES proveedores(codigo_empresa, codigo);
