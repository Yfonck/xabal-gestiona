-- Datos de demostración para la base local de desarrollo (sgu_nucleo).
--
-- ⚠️ Solo para el entorno local (127.0.0.1:5433). No ejecutar en la base
-- institucional: inserta catálogos de bajas, estructuras y personas ficticias
-- con el único objetivo de probar la app Flutter.
--
-- Uso:
--   psql -h 127.0.0.1 -p 5433 -U postgres -d sgu_nucleo -f docs/sql/demo_local.sql
--
-- El script es idempotente: usa ON CONFLICT / NOT EXISTS para no duplicar.

BEGIN;

-- ============================================================
-- Catálogo de estados (ids fijos 1..6, requeridos por la app y el backend)
-- ============================================================
DELETE FROM sq_gestion_personal.tb_nestado_solicitud_baja e
WHERE NOT EXISTS (
    SELECT 1 FROM sq_gestion_personal.tb_dsolicitud_baja s
    WHERE s.id_estado_solicitud = e.id_estado_solicitud
);

INSERT INTO sq_gestion_personal.tb_nestado_solicitud_baja
    (id_estado_solicitud, nombre_estado_solicitud, descripcion, activo, color,
     fecha_registro)
OVERRIDING SYSTEM VALUE
VALUES
    (1, 'Iniciada',    'Solicitud recién creada',             true, '#5263FF', now()),
    (2, 'En Trámite',  'Solicitud en proceso de confirmación', true, '#F1A80A', now()),
    (3, 'Finalizada',  'Proceso de baja finalizado',           true, '#2ECC71', now()),
    (4, 'Baja',        'Persona dada de baja',                 true, '#F24E4E', now()),
    (5, 'Cancelada',   'Solicitud cancelada',                  true, '#5B6472', now()),
    (6, 'Expirada',    'Solicitud expirada por tiempo',        true, '#5B6472', now())
ON CONFLICT (id_estado_solicitud) DO UPDATE
    SET nombre_estado_solicitud = EXCLUDED.nombre_estado_solicitud,
        descripcion = EXCLUDED.descripcion,
        activo = EXCLUDED.activo,
        color = EXCLUDED.color;

SELECT setval(
    'sq_gestion_personal.tb_nestado_solicitud_baja_id_estado_solicitud_seq',
    6,
    true
);

-- ============================================================
-- Catálogo de tipos de baja
-- ============================================================
INSERT INTO sq_gestion_personal.tb_ntipo_baja
    (nombre_tipo_baja, descripcion, activo, fecha_registro)
SELECT v.nombre, v.descripcion, true, now()
FROM (VALUES
    ('Renuncia',    'La persona presenta renuncia voluntaria'),
    ('Jubilación',  'Baja por edad de jubilación'),
    ('Traslado',    'Traslado a otra institución'),
    ('Sanción',     'Separación por medida disciplinaria')
) AS v(nombre, descripcion)
WHERE NOT EXISTS (
    SELECT 1 FROM sq_gestion_personal.tb_ntipo_baja t
    WHERE t.nombre_tipo_baja = v.nombre
);

-- ============================================================
-- Catálogo de causas de baja
-- ============================================================
INSERT INTO sq_gestion_personal.tb_ncausa_baja
    (nombre_causa_baja, descripcion, activo, siglas, fecha_registro)
SELECT v.nombre, v.descripcion, true, v.siglas, now()
FROM (VALUES
    ('Motivos personales',      'Decisión personal de la persona',        'MP'),
    ('Mejor oferta laboral',    'Nueva oportunidad de empleo',            'MOL'),
    ('Edad de jubilación',      'Cumple la edad establecida',             'EJ'),
    ('Reestructuración',        'Ajuste organizacional',                  'RE'),
    ('Bajo rendimiento',        'Evaluación del desempeño desfavorable',  'BR'),
    ('Cambio de residencia',    'Mudanza fuera de la provincia',          'CR')
) AS v(nombre, descripcion, siglas)
WHERE NOT EXISTS (
    SELECT 1 FROM sq_gestion_personal.tb_ncausa_baja c
    WHERE c.nombre_causa_baja = v.nombre
);

-- ============================================================
-- Estructuras organizacionales
-- ============================================================
INSERT INTO sq_estructura_composicion.tb_destructura
    (id_estructura, nombre_estructura, id_estructura_padre, activo,
     miembro_consejo_universitario)
VALUES
    (1000, 'Facultad de Ingeniería', NULL, true, false),
    (1001, 'Departamento de Informática', 1000, true, false),
    (1002, 'Dirección de Recursos Humanos', NULL, true, false),
    (1003, 'Departamento de Contabilidad', 1002, true, false)
ON CONFLICT (id_estructura) DO NOTHING;

-- ============================================================
-- Personas (tb_dpersona y tb_dpersona_data_plus)
-- ============================================================
INSERT INTO sq_gestion_personal.tb_dpersona
    (id_persona, primer_nombre, segundo_nombre, primer_apellido,
     segundo_apellido, carnet_identidad, fundador_uci, eliminado,
     fecha_registro, fecha_modificado)
VALUES
    ('1001', 'Camila', 'Lucía', 'García', 'González', '01010101010', false, false, now(), now()),
    ('1002', 'Luis', 'Alberto', 'Rodríguez', 'Díaz', '02020202020', false, false, now(), now()),
    ('1003', 'Ana', 'María', 'Pérez', 'Gómez', '03030303030', false, false, now(), now()),
    ('1004', 'Carlos', 'Manuel', 'Suárez', 'Martínez', '04040404040', false, false, now(), now()),
    ('1005', 'Marta', 'Elena', 'Fernández', 'Ruiz', '05050505050', false, false, now(), now()),
    ('1006', 'Pedro', 'José', 'Hernández', 'León', '06060606060', false, false, now(), now())
ON CONFLICT (id_persona) DO NOTHING;

INSERT INTO sq_gestion_personal.tb_dpersona_data_plus
    (id_persona, primer_nombre, segundo_nombre, primer_apellido,
     segundo_apellido, carnet_identidad, id_estructura, nombre_estructura,
     id_responsabilidad, nombre_responsabilidad, es_cargo,
     id_rol_universitario, nombre_rol_universitario, baja,
     correo_electronico, numero_solapin, a_busqueda, tiene_foto, id_expediente)
VALUES
    ('1001', 'Camila', 'Lucía', 'García', 'González', '01010101010',
     1001, 'Departamento de Informática', 1, 'Jefa de Departamento', true,
     21, 'Docente', false, 'camila.garcia@uci.cu', '1001',
     'camila lucía garcía gonzález 01010101010 1001', false, 'EXP-1001'),
    ('1002', 'Luis', 'Alberto', 'Rodríguez', 'Díaz', '02020202020',
     1001, 'Departamento de Informática', 2, 'Profesor', false,
     21, 'Docente', false, 'luis.rodriguez@uci.cu', '1002',
     'luis alberto rodríguez díaz 02020202020 1002', false, 'EXP-1002'),
    ('1003', 'Ana', 'María', 'Pérez', 'Gómez', '03030303030',
     1002, 'Dirección de Recursos Humanos', 1, 'Directora', true,
     22, 'Directivo', false, 'ana.perez@uci.cu', '1003',
     'ana maría pérez gómez 03030303030 1003', false, 'EXP-1003'),
    ('1004', 'Carlos', 'Manuel', 'Suárez', 'Martínez', '04040404040',
     1000, 'Facultad de Ingeniería', 2, 'Decano', false,
     22, 'Directivo', false, 'carlos.suarez@uci.cu', '1004',
     'carlos manuel suárez martínez 04040404040 1004', false, 'EXP-1004'),
    ('1005', 'Marta', 'Elena', 'Fernández', 'Ruiz', '05050505050',
     1003, 'Departamento de Contabilidad', 2, 'Especialista', false,
     23, 'Técnico', false, 'marta.fernandez@uci.cu', '1005',
     'marta elena fernández ruiz 05050505050 1005', false, 'EXP-1005'),
    ('1006', 'Pedro', 'José', 'Hernández', 'León', '06060606060',
     1000, 'Facultad de Ingeniería', 2, 'Profesor', false,
     21, 'Docente', true, 'pedro.hernandez@uci.cu', '1006',
     'pedro josé hernández león 06060606060 1006', false, 'EXP-1006')
ON CONFLICT (id_persona) DO NOTHING;

COMMIT;
