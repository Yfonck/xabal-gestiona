import '../config/api_config.dart';
import '../models/api_error.dart';
import '../models/sesion_iniciada.dart';
import '../models/usuario.dart';
import 'api_client.dart';

/// Operaciones de autenticación contra el backend Gestiona.
class AuthService {
  AuthService({ApiClient? client}) : _client = client ?? ApiClient.instance;

  final ApiClient _client;

  ApiClient get apiClient => _client;

  /// `POST /api/auth/login/` con `{username, password}`.
  ///
  /// El dominio UCI es solo informativo en la interfaz: el backend valida las
  /// credenciales contra LDAP/BD y no recibe el dominio.
  Future<SesionIniciada> iniciarSesion({
    required String usuario,
    required String contrasena,
  }) async {
    final datos = await _client.post(
      ApiConfig.login,
      data: {
        'username': usuario.trim().toLowerCase(),
        'password': contrasena,
      },
      conAutenticacion: false,
    );

    if (datos is! Map) {
      throw const ApiException(
        mensaje: 'Respuesta inválida del servidor al iniciar sesión.',
        codigo: 'INVALID_RESPONSE',
      );
    }

    final access = datos['access']?.toString();
    final refresh = datos['refresh']?.toString();
    final usuarioJson = datos['user'];

    if (access == null ||
        access.isEmpty ||
        refresh == null ||
        refresh.isEmpty ||
        usuarioJson is! Map) {
      throw const ApiException(
        mensaje: 'Respuesta inválida del servidor al iniciar sesión.',
        codigo: 'INVALID_RESPONSE',
      );
    }

    await _client.tokenStorage.guardar(access: access, refresh: refresh);

    return SesionIniciada(
      usuario: Usuario.fromJson(Map<String, dynamic>.from(usuarioJson)),
      access: access,
      refresh: refresh,
    );
  }

  /// `GET /api/auth/me/` — datos actualizados del usuario autenticado.
  Future<Usuario> obtenerPerfil() async {
    final datos = await _client.get(ApiConfig.me);
    if (datos is! Map) {
      throw const ApiException(
        mensaje: 'No se pudieron obtener los datos del usuario.',
        codigo: 'INVALID_RESPONSE',
      );
    }
    return Usuario.fromJson(Map<String, dynamic>.from(datos));
  }

  /// `POST /api/auth/logout/` — invalida el refresh token (idempotente).
  ///
  /// Siempre limpia el almacenamiento local, incluso si el backend falla.
  Future<void> cerrarSesion() async {
    final refresh = await _client.tokenStorage.obtenerRefresh();
    try {
      await _client.post(
        ApiConfig.logout,
        data: {'refresh': refresh},
        conAutenticacion: false,
      );
    } catch (_) {
      // El logout del backend es idempotente; un fallo de red no debe impedir
      // que el usuario salga de la aplicación.
    } finally {
      await _client.tokenStorage.limpiar();
    }
  }

  /// Restaura la sesión si existe un refresh guardado.
  ///
  /// Devuelve `null` cuando no hay sesión o cuando el backend la rechaza.
  Future<Usuario?> restaurarSesion() async {
    if (!await _client.tokenStorage.tieneSesion()) {
      return null;
    }
    try {
      return await obtenerPerfil();
    } on ApiException {
      await _client.tokenStorage.limpiar();
      return null;
    }
  }
}
