import 'package:flutter_test/flutter_test.dart';
import 'package:xabal_gestiona/models/api_error.dart';
import 'package:xabal_gestiona/models/estado_solicitud.dart';
import 'package:xabal_gestiona/models/estadisticas_baja.dart';
import 'package:xabal_gestiona/models/filtros_baja.dart';
import 'package:xabal_gestiona/models/opcion_filtro.dart';
import 'package:xabal_gestiona/models/paginated_response.dart';
import 'package:xabal_gestiona/models/solicitud_baja.dart';
import 'package:xabal_gestiona/providers/bajas_pendientes_provider.dart';

import '../helpers/fake_baja_service.dart';

void main() {
  group('BajasPendientesProvider', () {
    test('carga filtros, estadísticas y la primera página', () async {
      final servicio = FakeBajaService(
        estadisticasRespuesta: const EstadisticasBaja(
          porEstado: [
            ConteoPorEstado(estado: EstadoSolicitud.iniciada, cantidad: 3),
            ConteoPorEstado(estado: EstadoSolicitud.enTramite, cantidad: 7),
            ConteoPorEstado(estado: EstadoSolicitud.finalizada, cantidad: 2),
          ],
        ),
        filtrosRespuesta: const FiltrosBaja(
          estructuras: [OpcionFiltro(valor: '10', etiqueta: 'Tecnologías')],
          tipos: [OpcionFiltro(valor: '1', etiqueta: 'Renuncia')],
          causas: [OpcionFiltro(valor: '2', etiqueta: 'Motivos personales')],
        ),
        paginas: {
          1: const PaginatedResponse<SolicitudBaja>(
            results: [SolicitudBaja(idSolicitud: 1, idEstadoSolicitud: 2)],
            count: 1,
          ),
        },
      );

      final provider = BajasPendientesProvider(servicio: servicio);
      await provider.cargarFiltros();
      await provider.cargar(idEstructura: 10, idTipoBaja: 1);

      expect(provider.areas.single.etiqueta, 'Tecnologías');
      expect(provider.totalPendientes, 10);
      expect(provider.nombreArea, 'Tecnologías');
      expect(provider.solicitudes.single.idSolicitud, 1);
      expect(servicio.ultimoIdEstructura, 10);
      expect(servicio.ultimoIdTipoBaja, 1);
    });

    test('carga más páginas sin repetir la primera', () async {
      final servicio = FakeBajaService(
        paginas: {
          1: const PaginatedResponse<SolicitudBaja>(
            results: [SolicitudBaja(idSolicitud: 1, idEstadoSolicitud: 2)],
            count: 2,
            next: '?page=2',
          ),
          2: const PaginatedResponse<SolicitudBaja>(
            results: [SolicitudBaja(idSolicitud: 2, idEstadoSolicitud: 2)],
            count: 2,
          ),
        },
      );

      final provider = BajasPendientesProvider(servicio: servicio);
      await provider.cargar();

      expect(provider.solicitudes.length, 1);
      expect(provider.hayMas, isTrue);

      await provider.cargarMas();

      expect(provider.solicitudes.length, 2);
      expect(provider.hayMas, isFalse);
      expect(servicio.ultimaPagina, 2);
    });

    test('propaga el error del servicio', () async {
      final servicio = FakeBajaService(
        errorPendientes: const ApiException(mensaje: 'Fallo de red'),
      );

      final provider = BajasPendientesProvider(servicio: servicio);
      await provider.cargar();

      expect(provider.errorMessage, 'Fallo de red');
      expect(provider.solicitudes, isEmpty);
    });
  });
}
