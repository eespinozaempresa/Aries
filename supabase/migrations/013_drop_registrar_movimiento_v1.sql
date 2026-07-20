-- Elimina la versión original de registrar_movimiento (11 parámetros).
-- La versión con p_serie (migración 012) es la única que debe existir.
DROP FUNCTION IF EXISTS public.registrar_movimiento(
  text, text, text, date, text, text, text, text, text, text, jsonb
);
