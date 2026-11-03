import 'package:intl/intl.dart';

import '../config/api_config.dart';
import '../models/area_confirmacion.dart';
import '../models/estadisticas_baja.dart';
import '../models/filtros_baja.dart';
import '../models/paginated_response.dart';
import '../models/solicitud_baja.dart';
import 'api_client.dart';

/// Operaciones sobre solicitudes de baja.
class BajaService {
  BajaService({ApiClient? client}) : _client = client ?? ApiClient.instance;

  final ApiClient _client;

  static final DateFormat _formatoFecha = DateFormat('yyyy-MM-dd');

  /// `GET /api/bajas/` con filtros y paginación.
  Future<PaginatedResponse<SolicitudBaja>> listar({
    int page = 1,
    int pageSize = 20,
    String? search,
    int? idEstado,
    int? idTipoBaja,
    int? idCausaBaja,
    int? idEstructura,
    DateTime? fechaDesde,
    DateTime? fechaHasta,
  }) async {
    final datos = await _client.get(
      ApiConfig.bajas,
      queryParameters: _parametros(
        page: page,
        pageSize: pageSize,
        search: search,
        idEstado: idEstado,
        idTipoBaja: idTipoBaja,
        idCausaBaja: idCausaBaja,
        idEstructura: idEstructura,
        fechaDesde: fechaDesde,
        fechaHasta: fechaHasta,
      ),
    );
    return PaginatedResponse<SolicitudBaja>.fromJson(
      datos,
      SolicitudBaja.fromJson,
    );
  }

  /// `GET /api/bajas/pendientes/` (solicitudes en trámite).
  Future<PaginatedResponse<SolicitudBaja>> pendientes({
    int page = 1,
    int pageSize = 20,
    String? search,
    int? idEstructura,
    int? idTipoBaja,
    int? idCausaBaja,
  }) async {
    final datos = await _client.get(
      ApiConfig.bajasPendientes,
      queryParameters: _parametros(
        page: page,
        pageSize: pageSize,
        search: search,
        idEstructura: idEstructura,
        idTipoBaja: idTipoBaja,
        idCausaBaja: idCausaBaja,
      ),
    );
    return PaginatedResponse<SolicitudBaja>.fromJson(
      datos,
      SolicitudBaja.fromJson,
    );
  }

  /// `GET /api/bajas/estadisticas/`.
  Future<EstadisticasBaja> estadisticas({
    DateTime? fechaDesde,
    DateTime? fechaHasta,
    int? idEstructura,
  }) async {
    final datos = await _client.get(
      ApiConfig.bajasEstadisticas,
      queryParameters: {
        if (fechaDesde != null) 'fecha_desde': _formatoFecha.format(fechaDesde),
        if (fechaHasta != null) 'fecha_hasta': _formatoFecha.format(fechaHasta),
        'id_estructura': ?idEstructura,
      },
    );
    final mapa = datos is Map
        ? Map<String, dynamic>.from(datos)
        : <String, dynamic>{};
    return EstadisticasBaja.fromJson(mapa);
  }

  /// `GET /api/bajas/filters/`.
  Future<FiltrosBaja> filtros() async {
    final datos = await _client.get(ApiConfig.bajasFiltros);
    if (datos is! Map) return const FiltrosBaja();
    return FiltrosBaja.fromJson(Map<String, dynamic>.from(datos));
  }

  /// `GET /api/bajas/{id}/`.
  Future<SolicitudBaja> detalle(int id) async {
    final datos = await _client.get(ApiConfig.baja('$id'));
    if (datos is! Map) {
      throw StateError('Respuesta inválida al obtener la solicitud $id');
    }
    return SolicitudBaja.fromJson(Map<String, dynamic>.from(datos));
  }

  /// `GET /api/bajas/{id}/areas-confirmacion/`.
  ///
  /// Tolera que el backend devuelva una lista directa o un objeto con las
  /// claves `areas`, `results` o `confirmaciones`.
  Future<List<AreaConfirmacion>> areasConfirmacion(int id) async {
    final datos = await _client.get(ApiConfig.bajaAreasConfirmacion('$id'));
    final crudos = datos is Map
        ? (datos['areas'] ??
              datos['results'] ??
              datos['confirmaciones'] ??
              const <dynamic>[])
        : datos;
    if (crudos is! List) return const [];
    return crudos
        .whereType<Map>()
        .map((e) => AreaConfirmacion.fromJson(Map<String, dynamic>.from(e)))
        .toList(growable: false);
  }

  /// `POST /api/bajas/`.
  ///
  /// El backend crea la solicitud directamente en estado "En Trámite" (2).
  Future<SolicitudBaja> crear({
    required String idPersona,
    required int idTipoBaja,
    required int idCausaBaja,
  }) async {
    final datos = await _client.post(
      ApiConfig.bajas,
      data: {
        'id_persona': idPersona,
        'id_tipo_baja': idTipoBaja,
        'id_causa_baja': idCausaBaja,
      },
    );
    if (datos is! Map) {
      throw StateError('Respuesta inválida al crear la solicitud');
    }
    return SolicitudBaja.fromJson(Map<String, dynamic>.from(datos));
  }

  /// `POST /api/bajas/{id}/confirmar/` — confirmación de un área.
  Future<SolicitudBaja> confirmar(int id, {String observaciones = ''}) async {
    final datos = await _client.post(
      ApiConfig.bajaConfirmar('$id'),
      data: {if (observaciones.isNotEmpty) 'observaciones': observaciones},
    );
    return _solicitudDeRespuesta(datos, id);
  }

  /// `POST /api/bajas/{id}/cerrar/` — cierre definitivo (3 → 4).
  Future<SolicitudBaja> cerrar(int id) async {
    final datos = await _client.post(ApiConfig.bajaCerrar('$id'));
    return _solicitudDeRespuesta(datos, id);
  }

  /// `POST /api/bajas/{id}/cancelar/`.
  Future<SolicitudBaja> cancelar(int id) async {
    final datos = await _client.post(ApiConfig.bajaCancelar('$id'));
    return _solicitudDeRespuesta(datos, id);
  }

  SolicitudBaja _solicitudDeRespuesta(dynamic datos, int id) {
    if (datos is Map) {
      return SolicitudBaja.fromJson(Map<String, dynamic>.from(datos));
    }
    throw StateError('Respuesta inválida al actualizar la solicitud $id');
  }

  Map<String, dynamic> _parametros({
    required int page,
    required int pageSize,
    String? search,
    int? idEstado,
    int? idTipoBaja,
    int? idCausaBaja,
    int? idEstructura,
    DateTime? fechaDesde,
    DateTime? fechaHasta,
  }) {
    return {
      'page': page,
      'page_size': pageSize,
      if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
      'id_estado': ?idEstado,
      'id_tipo_baja': ?idTipoBaja,
      'id_causa_baja': ?idCausaBaja,
      'id_estructura': ?idEstructura,
      if (fechaDesde != null) 'fecha_desde': _formatoFecha.format(fechaDesde),
      if (fechaHasta != null) 'fecha_hasta': _formatoFecha.format(fechaHasta),
    };
  }
}
