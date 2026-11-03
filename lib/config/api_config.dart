import 'dart:io' show Platform;

/// Configuración central de acceso al backend Gestiona.
///
/// La URL base se puede sobreescribir en tiempo de compilación:
///
/// ```bash
/// flutter run --dart-define=API_BASE_URL=http://192.168.1.20:8000/api/
/// ```
///
/// Sin `--dart-define` se usa el host del emulador Android (`10.0.2.2`), que
/// apunta a la máquina anfitriona. En escritorio se usa `127.0.0.1`.
abstract final class ApiConfig {
  static const String _override = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: '',
  );

  static const int _port = 8000;

  /// URL base terminada en `/`, tal como la espera Dio.
  static String get baseUrl {
    if (_override.isNotEmpty) {
      return _override.endsWith('/') ? _override : '$_override/';
    }
    final host = Platform.isAndroid ? '10.0.2.2' : '127.0.0.1';
    return 'http://$host:$_port/api/';
  }

  /// Tiempo máximo de espera para conectar y para cada respuesta.
  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 20);
  static const Duration sendTimeout = Duration(seconds: 20);

  // ---- Endpoints ----
  // Autenticación
  static const String login = 'auth/login/';
  static const String refresh = 'auth/refresh/';
  static const String logout = 'auth/logout/';
  static const String me = 'auth/me/';

  // Personas
  static const String personas = 'personas/';
  static const String personasFiltros = 'personas/filters/';
  static String persona(String id) => 'personas/$id/';

  // Bajas
  static const String bajas = 'bajas/';
  static const String bajasPendientes = 'bajas/pendientes/';
  static const String bajasEstadisticas = 'bajas/estadisticas/';
  static const String bajasFiltros = 'bajas/filters/';
  static const String bajasTienePendientes = 'bajas/tiene-pendientes/';
  static String baja(String id) => 'bajas/$id/';
  static String bajaConfirmar(String id) => 'bajas/$id/confirmar/';
  static String bajaCerrar(String id) => 'bajas/$id/cerrar/';
  static String bajaCancelar(String id) => 'bajas/$id/cancelar/';
  static String bajaAreasConfirmacion(String id) =>
      'bajas/$id/areas-confirmacion/';

  // Notificaciones
  static const String notificaciones = 'notificaciones/';
  static String notificacionLeer(String id) => 'notificaciones/$id/leer/';
  static String notificacion(String id) => 'notificaciones/$id/';
  static const String notificacionesLimpiar = 'notificaciones/limpiar-todas/';

  // Catálogos de bajas (gestión, solo administradores)
  static const String tiposBaja = 'admin/tipos-baja/';
  static const String causasBaja = 'admin/causas-baja/';
  static const String areasBaja = 'admin/areas-baja/';
}
