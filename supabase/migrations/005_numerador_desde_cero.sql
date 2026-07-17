-- Permite que numero_siguiente = 0 genere correctamente desde 1.
-- Se actualiza la función siguiente_numero_doc para usar GREATEST(v_num, 1)
-- como valor retornado cuando el campo vale 0 (serie sin uso previo).
-- Series existentes con numero_siguiente >= 1 no se ven afectadas.

CREATE OR REPLACE FUNCTION siguiente_numero_doc(
  p_empresa  VARCHAR,
  p_cod_doc  VARCHAR,
  p_serie    VARCHAR
) RETURNS TEXT LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_num BIGINT;
  v_ret BIGINT;
BEGIN
  SELECT numero_siguiente INTO v_num
  FROM documentos
  WHERE codigo_empresa = p_empresa
    AND codigo         = p_cod_doc
    AND serie          = p_serie
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Documento % serie % no encontrado para empresa %', p_cod_doc, p_serie, p_empresa;
  END IF;

  -- numero_siguiente = 0 equivale a "no iniciada", el primer número es 1
  v_ret := GREATEST(v_num, 1);

  UPDATE documentos
     SET numero_siguiente = v_ret + 1
   WHERE codigo_empresa = p_empresa
     AND codigo         = p_cod_doc
     AND serie          = p_serie;

  RETURN LPAD(v_ret::TEXT, 7, '0');
END;
$$;
