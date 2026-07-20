-- Permitir usuario_id nullable (intentos fallidos con usuario inexistente)
ALTER TABLE auditoria_sesiones ALTER COLUMN usuario_id DROP NOT NULL;

-- Columna para el código de usuario intentado
ALTER TABLE auditoria_sesiones ADD COLUMN IF NOT EXISTS usuario_codigo VARCHAR(20);

-- Ampliar constraint de tipo para incluir LOGIN_FAIL
ALTER TABLE auditoria_sesiones DROP CONSTRAINT IF EXISTS auditoria_sesiones_tipo_check;
ALTER TABLE auditoria_sesiones
  ADD CONSTRAINT auditoria_sesiones_tipo_check
  CHECK (tipo IN ('LOGIN', 'LOGIN_FAIL', 'LOGOUT'));
