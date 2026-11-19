import '../config/api_config.dart';
import '../models/notificacion.dart';
import 'api_client.dart';

/// Operaciones del centro de notificaciones.
class NotificacionService {
  NotificacionService({ApiClient? client})
      : _client = client ?? ApiClient.instance;

  final ApiClient _client;

  /// `GET /api/notificaciones/` — máximo 50, sin paginación.
  Future<List<Notificacion>> listar() async {
    final datos = await _client.get(ApiConfig.notificaciones);
    if (datos is! List) return const [];
    return datos
        .whereType<Map>()
        .map((e) => Notificacion.fromJson(Map<String, dynamic>.from(e)))
        .toList(growable: false);
  }

  /// `POST /api/notificaciones/{id}/leer/`.
  Future<void> marcarLeida(int id) async {
    await _client.post(ApiConfig.notificacionLeer('$id'));
  }

  /// `DELETE /api/notificaciones/{id}/`.
  Future<void> eliminar(int id) async {
    await _client.delete(ApiConfig.notificacion('$id'));
  }

  /// `DELETE /api/notificaciones/limpiar-todas/`.
  Future<void> limpiarTodas() async {
    await _client.delete(ApiConfig.notificacionesLimpiar);
  }

  /// `POST /api/notificaciones/` — crear notificación.
  ///
  /// [idUsuario] permite dirigir la notificación a otro usuario. El backend
  /// actual lo ignora (`id_usuario` es de solo lectura) y además no expone la
  /// creación de notificaciones; se envía para cuando el backend lo soporte.
  Future<Notificacion> crear({
    required String titulo,
    required String mensaje,
    String? link,
    String? idUsuario,
  }) async {
    final datos = await _client.post(
      ApiConfig.notificaciones,
      data: {
        'titulo': titulo,
        'mensaje': mensaje,
        'link': ?link,
        'id_usuario': ?idUsuario,
      },
    );
    return Notificacion.fromJson(Map<String, dynamic>.from(datos));
  }
}
