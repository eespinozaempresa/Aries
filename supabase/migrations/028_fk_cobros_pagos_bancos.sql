-- Agrega FKs compuestas desde cobros/pagos hacia bancos para bloquear
-- el borrado (error 23503) de un banco en uso. codigo_banco es nullable
-- (solo aplica a pagos con tipo_pago TRANSFERENCIA/CHEQUE).

ALTER TABLE cobros
  ADD CONSTRAINT fk_cobros_banco
  FOREIGN KEY (codigo_empresa, codigo_banco)
  REFERENCES bancos(codigo_empresa, codigo);

ALTER TABLE pagos
  ADD CONSTRAINT fk_pagos_banco
  FOREIGN KEY (codigo_empresa, codigo_banco)
  REFERENCES bancos(codigo_empresa, codigo);
