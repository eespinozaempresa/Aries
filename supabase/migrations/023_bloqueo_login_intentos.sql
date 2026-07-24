-- Configuración de sistema para el bloqueo de usuarios por intentos fallidos de login.
-- Fila única (a nivel de sistema, no por empresa).
--   max_intentos_fallidos    (X): intentos fallidos permitidos antes de bloquear
--   ventana_intentos_minutos (Y): ventana de minutos en la que se cuentan esos intentos
--   bloqueo_temporal_minutos (Z): duración del bloqueo automático
--   max_bloqueos_temporales  (Q): bloqueos temporales que, repetidos, escalan a indefinido
--   ventana_bloqueos_minutos (P): ventana de minutos en la que se cuentan esos bloqueos
CREATE TABLE IF NOT EXISTS tiempos (
  id                        UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  max_intentos_fallidos     INT NOT NULL DEFAULT 5,
  ventana_intentos_minutos  INT NOT NULL DEFAULT 15,
  bloqueo_temporal_minutos  INT NOT NULL DEFAULT 30,
  max_bloqueos_temporales   INT NOT NULL DEFAULT 3,
  ventana_bloqueos_minutos  INT NOT NULL DEFAULT 1440,
  updated_at                TIMESTAMPTZ DEFAULT now()
);

INSERT INTO tiempos (id)
SELECT gen_random_uuid()
WHERE NOT EXISTS (SELECT 1 FROM tiempos);

CREATE TRIGGER trg_tiempos_upd BEFORE UPDATE ON tiempos
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- Historial de bloqueos de usuario: TEMPORAL (automático, con fecha_fin) o
-- INDEFINIDO (tras reincidencia, fecha_fin NULL hasta que un admin lo desbloquee).
CREATE TABLE IF NOT EXISTS usuario_bloqueos (
  id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  usuario_id       UUID NOT NULL REFERENCES usuarios(id),
  tipo             VARCHAR(20) NOT NULL CHECK (tipo IN ('TEMPORAL', 'INDEFINIDO')),
  motivo           VARCHAR(200),
  fecha_inicio     TIMESTAMPTZ NOT NULL DEFAULT now(),
  fecha_fin        TIMESTAMPTZ,
  desbloqueado_por UUID REFERENCES usuarios(id),
  desbloqueado_en  TIMESTAMPTZ,
  created_at       TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_usuario_bloqueos_usuario ON usuario_bloqueos(usuario_id);
