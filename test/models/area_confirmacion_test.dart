import 'package:flutter_test/flutter_test.dart';
import 'package:xabal_gestiona/models/area_confirmacion.dart';

void main() {
  group('AreaConfirmacion', () {
    test('lee el estado y la fecha desde el backend', () {
      final area = AreaConfirmacion.fromJson({
        'id_area': 10,
        'nombre_area': 'Tecnologías',
        'nombre_estado': 'Finalizada',
        'fecha_confirmacion': '2025-11-15T10:00:00',
      });

      expect(area.idArea, 10);
      expect(area.nombreArea, 'Tecnologías');
      expect(area.estado, 'Finalizada');
      expect(area.fecha, DateTime(2025, 11, 15, 10));
    });

    test('usa confirmada para deducir el estado', () {
      final pendiente = AreaConfirmacion.fromJson({
        'nombre_estructura': 'Deportes',
        'confirmada': false,
      });
      final confirmada = AreaConfirmacion.fromJson({
        'nombre_estructura': 'Deportes',
        'confirmada': true,
      });

      expect(pendiente.estado, 'Pendiente');
      expect(confirmada.estado, 'Finalizada');
    });

    test('deduce el estado desde el id cuando no hay etiqueta', () {
      final area = AreaConfirmacion.fromJson({
        'id_estado': 4,
        'nombre_area': 'Contabilidad',
      });

      expect(area.estado, 'Baja');
    });

    test('interpreta un estado numérico como id', () {
      final area = AreaConfirmacion.fromJson({
        'nombre_area': 'Deportes',
        'estado': 3,
      });

      expect(area.estado, 'Finalizada');
      expect(area.idEstado, 3);
    });

    test('tolera campos ausentes', () {
      final area = AreaConfirmacion.fromJson({});

      expect(area.nombreArea, 'Área');
      expect(area.estado, 'Pendiente');
      expect(area.fecha, isNull);
    });
  });
}
