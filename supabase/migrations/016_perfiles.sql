CREATE TABLE IF NOT EXISTS perfiles (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  codigo_empresa VARCHAR(10) NOT NULL REFERENCES empresas(codigo),
  codigo VARCHAR(10) NOT NULL,
  descripcion VARCHAR(80) NOT NULL,
  activo BOOLEAN NOT NULL DEFAULT true,
  menus JSONB NOT NULL DEFAULT '[]',
  UNIQUE(codigo_empresa, codigo)
);

ALTER TABLE usuarios ADD COLUMN IF NOT EXISTS perfil_id UUID REFERENCES perfiles(id);
