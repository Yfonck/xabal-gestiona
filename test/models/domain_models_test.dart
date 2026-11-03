import 'package:flutter_test/flutter_test.dart';
import 'package:xabal_gestiona/models/estado_solicitud.dart';
import 'package:xabal_gestiona/models/filtros_baja.dart';
import 'package:xabal_gestiona/models/notificacion.dart';
import 'package:xabal_gestiona/models/persona.dart';
import 'package:xabal_gestiona/models/solicitud_baja.dart';

void main() {
  group('EstadoSolicitud', () {
    test('mapea los seis estados del backend', () {
      expect(EstadoSolicitud.desdeId(1), EstadoSolicitud.iniciada);
      expect(EstadoSolicitud.desdeId(2), EstadoSolicitud.enTramite);
      expect(EstadoSolicitud.desdeId(3), EstadoSolicitud.finalizada);
      expect(EstadoSolicitud.desdeId(4), EstadoSolicitud.baja);
      expect(EstadoSolicitud.desdeId(5), EstadoSolicitud.cancelada);
      expect(EstadoSolicitud.desdeId(6), EstadoSolicitud.expirada);
    });

    test('usa iniciada como respaldo ante un id desconocido', () {
      expect(EstadoSolicitud.desdeId(99), EstadoSolicitud.iniciada);
      expect(EstadoSolicitud.desdeId(null), EstadoSolicitud.iniciada);
    });

    test('clasifica pendientes y finales', () {
      expect(EstadoSolicitud.enTramite.esPendiente, isTrue);
      expect(EstadoSolicitud.baja.esFinal, isTrue);
      expect(EstadoSolicitud.finalizada.esFinal, isFalse);
    });
  });

  group('FiltrosBaja', () {
    test('lee las claves reales tipos_baja y causas_baja', () {
      final filtros = FiltrosBaja.fromJson({
        'estados': [
          {'value': '2', 'label': 'En Trámite'},
        ],
        'tipos_baja': [
          {'value': '1', 'label': 'Renuncia'},
        ],
        'causas_baja': [
          {'value': '3', 'label': 'Motivos personales'},
        ],
        'estructuras': [
          {'value': '10', 'label': 'Facultad de Ciencias'},
        ],
      });

      expect(filtros.estados.single.etiqueta, 'En Trámite');
      expect(filtros.tipos.single.id, 1);
      expect(filtros.causas.single.etiqueta, 'Motivos personales');
      expect(filtros.estructuras.single.id, 10);
    });

    test('acepta las claves anteriores tipos y causas', () {
      final filtros = FiltrosBaja.fromJson({
        'tipos': [
          {'value': '5', 'label': 'Jubilación'},
        ],
        'causas': [
          {'value': '6', 'label': 'Edad'},
        ],
      });

      expect(filtros.tipos.single.id, 5);
      expect(filtros.causas.single.id, 6);
    });
  });

  group('SolicitudBaja', () {
    test('compone el nombre del solicitante y del responsable', () {
      final solicitud = SolicitudBaja.fromJson({
        'id_solicitud': 12,
        'id_estado_solicitud': 2,
        'fecha_registro': '2026-10-20T10:15:00',
        'apellido_solicitante': 'Pérez',
        'segundo_apellido_solicitante': 'Gómez',
        'nombre_solicitante': 'Ana',
        'segundo_nombre_solicitante': 'María',
        'primer_apellido': 'Rodríguez',
        'segundo_apellido': 'Díaz',
        'primer_nombre': 'Luis',
        'segundo_nombre': 'Alberto',
      });

      expect(solicitud.idSolicitud, 12);
      expect(solicitud.estado, EstadoSolicitud.enTramite);
      expect(solicitud.nombreSolicitanteCompleto, 'Pérez Gómez, Ana María');
      expect(solicitud.nombreResponsable, 'Rodríguez Díaz, Luis Alberto');
      expect(solicitud.fechaRegistro, DateTime(2026, 10, 20, 10, 15));
    });

    test('tolera campos ausentes sin lanzar excepciones', () {
      final solicitud = SolicitudBaja.fromJson({'id_solicitud': '7'});

      expect(solicitud.idSolicitud, 7);
      expect(solicitud.estado, EstadoSolicitud.iniciada);
      expect(solicitud.nombreSolicitanteCompleto, isNull);
      expect(solicitud.fechaRegistro, isNull);
    });
  });

  group('Persona', () {
    test('usa nombre_completo y determina el estado activo', () {
      final persona = Persona.fromJson({
        'id_persona': '123',
        'nombre_completo': 'Camila García González',
        'carnet_identidad': '01010101010',
        'baja': false,
      });

      expect(persona.idPersona, '123');
      expect(persona.nombre, 'Camila García González');
      expect(persona.activa, isTrue);
    });

    test('compone el nombre desde las partes cuando falta nombre_completo', () {
      final persona = Persona.fromJson({
        'id_persona': 9,
        'primer_nombre': 'Leo',
        'primer_apellido': 'Mesa',
        'baja': true,
      });

      expect(persona.idPersona, '9');
      expect(persona.nombre, 'Leo Mesa');
      expect(persona.activa, isFalse);
    });
  });

  group('Notificacion', () {
    test('lee la notificación con fecha y estado', () {
      final notificacion = Notificacion.fromJson({
        'id': 4,
        'titulo': 'Solicitud confirmada',
        'mensaje': 'Su solicitud fue confirmada por RRHH.',
        'leida': true,
        'fecha_creacion': '2026-10-21T08:30:00Z',
      });

      expect(notificacion.id, 4);
      expect(notificacion.leida, isTrue);
      expect(notificacion.fechaCreacion, isNotNull);
    });
  });
}
