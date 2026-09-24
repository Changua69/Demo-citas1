-- ============================================================================
-- BASE DE DATOS de la demo Cliente-Servidor (se ejecuta UNA vez en Supabase)
-- ----------------------------------------------------------------------------
-- Dónde ejecutarlo: en el panel de Supabase, menú lateral "SQL Editor",
-- pegar TODO este archivo y presionar "Run".
--
-- Nota importante para la clase: la base de datos vive en un equipo distinto
-- al del servidor Express (Supabase vs Render). El ÚNICO que se conecta a
-- ella es el servidor. Los clientes web jamás la tocan.
--
-- CAMBIO: se agrega un UNIQUE constraint sobre (profesional_id, fecha_hora)
-- para que la regla "un profesional no puede tener dos citas a la misma hora"
-- se cumpla de forma ATÓMICA a nivel de base de datos, incluso bajo carga
-- concurrente (varias peticiones llegando al mismo tiempo).
-- ============================================================================

-- Borrar las tablas si ya existían (permite re-ejecutar el script sin errores)
DROP TABLE IF EXISTS citas;
DROP TABLE IF EXISTS profesionales;

-- Tabla de profesionales de la salud
CREATE TABLE profesionales (
  id           SERIAL PRIMARY KEY,      -- número automático: 1, 2, 3...
  nombre       TEXT NOT NULL,
  especialidad TEXT NOT NULL
);

-- Tabla de citas: cada cita apunta a un profesional (llave foránea)
CREATE TABLE citas (
  id              SERIAL PRIMARY KEY,
  paciente        TEXT NOT NULL,
  profesional_id  INTEGER NOT NULL REFERENCES profesionales(id),
  fecha_hora      TIMESTAMPTZ NOT NULL,
  creada_en       TIMESTAMPTZ NOT NULL DEFAULT now(),

  -- Restricción clave: no pueden existir dos filas con el mismo
  -- profesional_id + fecha_hora. Postgres la aplica de forma atómica,
  -- así que aunque lleguen 100 peticiones simultáneas para la misma
  -- cita, solo UNA logra insertarse y el resto falla con error 23505.
  CONSTRAINT unique_profesional_fecha UNIQUE (profesional_id, fecha_hora)
);

-- Datos semilla: para que la demo no empiece vacía
INSERT INTO profesionales (nombre, especialidad) VALUES
  ('Dra. Laura Pérez',  'Medicina general'),
  ('Dr. Andrés Rojas',  'Odontología'),
  ('Dra. Camila Torres','Fisioterapia');

INSERT INTO citas (paciente, profesional_id, fecha_hora) VALUES
  ('Carlos Muñoz', 1, now() + interval '1 day'),
  ('María Salazar', 2, now() + interval '2 days');

-- Verificación rápida: debería mostrar las 2 citas de ejemplo
SELECT c.id, c.paciente, p.nombre AS profesional, c.fecha_hora
  FROM citas c JOIN profesionales p ON p.id = c.profesional_id;