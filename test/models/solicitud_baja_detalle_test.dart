import 'package:flutter_test/flutter_test.dart';
import 'package:xabal_gestiona/models/solicitud_baja.dart';

void main() {
  group('SolicitudBaja (detalle HU06)', () {
    test('lee los datos ampliados desde objetos anidados', () {
      final solicitud = SolicitudBaja.fromJson({
        'id_solicitud': 15,
        'id_estado_solicitud': 2,
        'fecha_registro': '2025-10-10T08:00:00',
        'fecha_baja': '2025-12-01T00:00:00',
        'nombre_tipo_baja': 'Trabajadores externos',
        'nombre_causa_baja': 'Liberación de adiestramiento',
        'solicitante': {
          'nombre_completo': 'Camila García González',
          'carnet_identidad': '99250570247',
          'username': 'camignzales',
          'numero_solapin': 'EI25874',
          'numero_caducidad': 'T25483',
          'nombre_rol_universitario': 'Trabajador',
          'nombre_responsabilidad': 'Especialista "B"',
          'nombre_estructura': 'Dirección de Información',
          'fecha_plantilla': '2024-05-01T00:00:00',
        },
        'responsable': {
          'nombre_completo': 'Raúl García González',
          'carnet_identidad': '99250580247',
          'username': 'raulgzales',
          'numero_solapin': 'EI26774',
          'numero_caducidad': 'T28483',
          'nombre_rol_universitario': 'Directivo',
          'nombre_responsabilidad': 'Director',
          'nombre_estructura': 'Dirección de Información',
          'fecha_plantilla': '2023-10-05T00:00:00',
        },
      });

      expect(solicitud.nombreSolicitanteCompleto, 'Camila García González');
      expect(solicitud.ciSolicitante, '99250570247');
      expect(solicitud.usuarioSolicitante, 'camignzales');
      expect(solicitud.solapinSolicitante, 'EI25874');
      expect(solicitud.caducidadSolicitante, 'T25483');
      expect(solicitud.rolSolicitante, 'Trabajador');
      expect(solicitud.responsabilidadSolicitante, 'Especialista "B"');
      expect(solicitud.fechaPlantillaSolicitante, DateTime(2024, 5, 1));
      expect(solicitud.nombreEstructuraSolicitante, 'Dirección de Información');
      expect(solicitud.usuarioResponsable, 'raulgzales');
      expect(solicitud.carnetIdentidad, '99250580247');
      expect(solicitud.rolResponsable, 'Directivo');
      expect(solicitud.responsabilidadResponsable, 'Director');
      expect(solicitud.fechaPlantillaResponsable, DateTime(2023, 10, 5));
      expect(solicitud.nombreEstructuraResponsable, 'Dirección de Información');
      expect(solicitud.fechaBaja, DateTime(2025, 12, 1));
      expect(solicitud.nombreTipoBaja, 'Trabajadores externos');
      expect(solicitud.nombreCausaBaja, 'Liberación de adiestramiento');
    });

    test('compone el nombre desde los objetos anidados', () {
      final solicitud = SolicitudBaja.fromJson({
        'id_solicitud': 17,
        'solicitante': {
          'primer_nombre': 'Camila',
          'segundo_nombre': 'María',
          'primer_apellido': 'García',
          'segundo_apellido': 'Gonzáles',
        },
        'responsable': {'nombre': 'Raúl', 'apellidos': 'García Gonzáles'},
      });

      expect(
        solicitud.nombreSolicitanteCompleto,
        'García Gonzáles, Camila María',
      );
      expect(solicitud.nombreResponsable, 'García Gonzáles, Raúl');
    });

    test('lee los datos ampliados desde campos planos', () {
      final solicitud = SolicitudBaja.fromJson({
        'id_solicitud': 16,
        'usuario_solicitante': 'usuario1',
        'solapin_solicitante': 'EI1',
        'caducidad_solicitante': 'T1',
        'rol_solicitante': 'Trabajador',
        'responsabilidad_solicitante': 'Analista',
        'fecha_plantilla_solicitante': '2024-01-02T00:00:00',
        'usuario_responsable': 'usuario2',
        'solapin_responsable': 'EI2',
        'caducidad_responsable': 'T2',
        'rol_responsable': 'Directivo',
        'responsabilidad_responsable': 'Jefe',
        'fecha_plantilla_responsable': '2023-03-04T00:00:00',
        'fecha_baja_efectiva': '2026-01-01T00:00:00',
      });

      expect(solicitud.usuarioSolicitante, 'usuario1');
      expect(solicitud.solapinSolicitante, 'EI1');
      expect(solicitud.caducidadSolicitante, 'T1');
      expect(solicitud.rolSolicitante, 'Trabajador');
      expect(solicitud.responsabilidadSolicitante, 'Analista');
      expect(solicitud.fechaPlantillaSolicitante, DateTime(2024, 1, 2));
      expect(solicitud.usuarioResponsable, 'usuario2');
      expect(solicitud.solapinResponsable, 'EI2');
      expect(solicitud.caducidadResponsable, 'T2');
      expect(solicitud.rolResponsable, 'Directivo');
      expect(solicitud.responsabilidadResponsable, 'Jefe');
      expect(solicitud.fechaPlantillaResponsable, DateTime(2023, 3, 4));
      expect(solicitud.fechaBaja, DateTime(2026, 1, 1));
    });
  });
}
