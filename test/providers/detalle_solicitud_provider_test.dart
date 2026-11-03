import 'package:flutter_test/flutter_test.dart';
import 'package:xabal_gestiona/models/api_error.dart';
import 'package:xabal_gestiona/models/area_confirmacion.dart';
import 'package:xabal_gestiona/models/solicitud_baja.dart';
import 'package:xabal_gestiona/providers/detalle_solicitud_provider.dart';

import '../helpers/fake_baja_service.dart';

void main() {
  group('DetalleSolicitudProvider', () {
    test('carga la solicitud y sus áreas', () async {
      final servicio = FakeBajaService(
        detalleRespuesta: const SolicitudBaja(
          idSolicitud: 5,
          idEstadoSolicitud: 2,
        ),
        areasRespuesta: const [
          AreaConfirmacion(
            nombreArea: 'Tecnologías',
            estadoEtiqueta: 'Finalizada',
          ),
        ],
      );

      final provider = DetalleSolicitudProvider(servicio: servicio);
      await provider.cargar(5);

      expect(provider.solicitud?.idSolicitud, 5);
      expect(provider.areas.single.nombreArea, 'Tecnologías');
      expect(provider.errorMessage, isNull);
      expect(provider.cargando, isFalse);
    });

    test('muestra el detalle aunque fallen las áreas', () async {
      final servicio = FakeBajaService(
        detalleRespuesta: const SolicitudBaja(
          idSolicitud: 6,
          idEstadoSolicitud: 1,
        ),
        errorAreas: const ApiException(mensaje: 'Sin permiso'),
      );

      final provider = DetalleSolicitudProvider(servicio: servicio);
      await provider.cargar(6);

      expect(provider.solicitud?.idSolicitud, 6);
      expect(provider.areas, isEmpty);
      expect(provider.errorMessage, isNull);
    });

    test('expone el error cuando falla el detalle', () async {
      final servicio = FakeBajaService(
        errorDetalle: const ApiException(mensaje: 'No encontrada'),
      );

      final provider = DetalleSolicitudProvider(servicio: servicio);
      await provider.cargar(99);

      expect(provider.solicitud, isNull);
      expect(provider.errorMessage, 'No encontrada');
    });
  });
}
