import 'package:xabal_gestiona/models/api_error.dart';
import 'package:xabal_gestiona/models/area_confirmacion.dart';
import 'package:xabal_gestiona/models/estadisticas_baja.dart';
import 'package:xabal_gestiona/models/filtros_baja.dart';
import 'package:xabal_gestiona/models/paginated_response.dart';
import 'package:xabal_gestiona/models/solicitud_baja.dart';
import 'package:xabal_gestiona/services/baja_service.dart';

/// Doble de prueba de [BajaService] que no realiza peticiones HTTP.
class FakeBajaService extends BajaService {
  FakeBajaService({
    this.estadisticasRespuesta,
    this.filtrosRespuesta = const FiltrosBaja(),
    this.paginas = const {},
    this.detalleRespuesta,
    this.areasRespuesta = const [],
    this.errorPendientes,
    this.errorDetalle,
    this.errorAreas,
  });

  final EstadisticasBaja? estadisticasRespuesta;
  final FiltrosBaja filtrosRespuesta;
  final Map<int, PaginatedResponse<SolicitudBaja>> paginas;
  final SolicitudBaja? detalleRespuesta;
  final List<AreaConfirmacion> areasRespuesta;
  final ApiException? errorPendientes;
  final ApiException? errorDetalle;
  final ApiException? errorAreas;

  int llamadasPendientes = 0;
  int? ultimaPagina;
  int? ultimoIdEstructura;
  int? ultimoIdTipoBaja;
  int? ultimoIdCausaBaja;
  String? ultimaBusqueda;

  @override
  Future<EstadisticasBaja> estadisticas({
    DateTime? fechaDesde,
    DateTime? fechaHasta,
    int? idEstructura,
  }) async {
    return estadisticasRespuesta ?? const EstadisticasBaja();
  }

  @override
  Future<PaginatedResponse<SolicitudBaja>> pendientes({
    int page = 1,
    int pageSize = 20,
    String? search,
    int? idEstructura,
    int? idTipoBaja,
    int? idCausaBaja,
  }) async {
    if (errorPendientes != null) throw errorPendientes!;
    llamadasPendientes++;
    ultimaPagina = page;
    ultimoIdEstructura = idEstructura;
    ultimoIdTipoBaja = idTipoBaja;
    ultimoIdCausaBaja = idCausaBaja;
    ultimaBusqueda = search;
    return paginas[page] ??
        const PaginatedResponse<SolicitudBaja>(results: [], count: 0);
  }

  @override
  Future<FiltrosBaja> filtros() async => filtrosRespuesta;

  @override
  Future<SolicitudBaja> detalle(int id) async {
    if (errorDetalle != null) throw errorDetalle!;
    return detalleRespuesta ??
        const SolicitudBaja(idSolicitud: 1, idEstadoSolicitud: 1);
  }

  @override
  Future<List<AreaConfirmacion>> areasConfirmacion(int id) async {
    if (errorAreas != null) throw errorAreas!;
    return areasRespuesta;
  }
}
