import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../config/api_config.dart';
import '../models/api_error.dart';
import 'config_service.dart';
import 'token_storage.dart';

/// Cliente HTTP único de la aplicación.
///
/// Responsabilidades:
/// - Adjuntar el `Authorization: Bearer <access>` a cada petición.
/// - Desenvolver el sobre `{success, data}` del backend.
/// - Renovar el access token ante un 401 (una sola vez aunque haya varias
///   peticiones concurrentes) y reintentar la petición original.
/// - Traducir cualquier fallo a [ApiException].
class ApiClient {
  ApiClient({Dio? dio, TokenStorage? tokenStorage})
      : _tokenStorage = tokenStorage ?? TokenStorage.instance {
    _dio = dio ??
        Dio(
          BaseOptions(
            baseUrl: ConfigService.instance.obtenerUrl(),
            connectTimeout: ApiConfig.connectTimeout,
            receiveTimeout: ApiConfig.receiveTimeout,
            sendTimeout: ApiConfig.sendTimeout,
            headers: ApiConfig.headersPorDefecto,
          ),
        );
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: _adjuntarToken,
        onError: _manejarError,
      ),
    );
  }

  static final ApiClient instance = ApiClient();

  late final Dio _dio;
  final TokenStorage _tokenStorage;

  /// Inicializa la URL base del cliente desde `ConfigService` (SharedPreferences).
  /// Debe llamarse antes de realizar peticiones, típicamente al arrancar la app
  /// o tras cambiar la URL en la pantalla de login.
  Future<void> inicializar() async {
    await ConfigService.instance.inicializar();
    _dio.options.baseUrl = ConfigService.instance.obtenerUrl();
  }

  /// Se invoca cuando el refresh token deja de ser válido.
  VoidCallback? onSesionExpirada;

  Future<bool>? _refreshEnCurso;

  Dio get dio => _dio;

  TokenStorage get tokenStorage => _tokenStorage;

  Future<dynamic> get(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) {
    return _ejecutar(
      () => _dio.get<dynamic>(
        path,
        queryParameters: queryParameters,
      ),
    );
  }

  Future<dynamic> post(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    bool conAutenticacion = true,
    Duration? timeout,
  }) {
    return _ejecutar(
      () => _dio.post<dynamic>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: Options(
          extra: {if (!conAutenticacion) _claveSinAuth: true},
          sendTimeout: timeout,
        ),
      ),
    );
  }

  Future<dynamic> put(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
  }) {
    return _ejecutar(
      () => _dio.put<dynamic>(path, data: data, queryParameters: queryParameters),
    );
  }

  Future<dynamic> patch(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
  }) {
    return _ejecutar(
      () => _dio.patch<dynamic>(
        path,
        data: data,
        queryParameters: queryParameters,
      ),
    );
  }

  Future<dynamic> delete(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
  }) {
    return _ejecutar(
      () => _dio.delete<dynamic>(
        path,
        data: data,
        queryParameters: queryParameters,
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Internos
  // ---------------------------------------------------------------------------

  static const String _claveSinAuth = 'xabal_skip_auth';
  static const String _claveReintentado = 'xabal_retried';

  Future<dynamic> _ejecutar(Future<Response<dynamic>> Function() peticion) async {
    try {
      final respuesta = await peticion();
      return _desenvolver(respuesta);
    } on DioException catch (error) {
      throw _mapearDio(error);
    }
  }

  Future<void> _adjuntarToken(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Refuerzo por petición: garantiza la cabecera incluso si el `Dio`
    // inyectado no trae `ApiConfig.headersPorDefecto` (tests, usos futuros).
    options.headers['ngrok-skip-browser-warning'] ??= 'true';

    if (options.extra[_claveSinAuth] != true) {
      final token = await _tokenStorage.obtenerAccess();
      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    }
    handler.next(options);
  }

  Future<void> _manejarError(
    DioException error,
    ErrorInterceptorHandler handler,
  ) async {
    final options = error.requestOptions;
    final status = error.response?.statusCode;

    final noReintentar = options.extra[_claveSinAuth] == true ||
        options.extra[_claveReintentado] == true ||
        options.path.contains(ApiConfig.login) ||
        options.path.contains(ApiConfig.refresh);

    if (status != 401 || noReintentar) {
      handler.next(error);
      return;
    }

    final renovado = await _renovarToken();
    if (!renovado) {
      handler.next(error);
      return;
    }

    try {
      final access = await _tokenStorage.obtenerAccess();
      options.headers['Authorization'] = 'Bearer $access';
      options.extra[_claveReintentado] = true;
      final respuesta = await _dio.fetch<dynamic>(options);
      handler.resolve(respuesta);
    } on DioException catch (nuevoError) {
      handler.next(nuevoError);
    }
  }

  /// Renueva el access token. Varias peticiones concurrentes comparten la
  /// misma renovación para no rotar el refresh token más de una vez.
  Future<bool> _renovarToken() {
    return _refreshEnCurso ??= _ejecutarRenovacion().whenComplete(() {
      _refreshEnCurso = null;
    });
  }

  Future<bool> _ejecutarRenovacion() async {
    final refresh = await _tokenStorage.obtenerRefresh();
    if (refresh == null || refresh.isEmpty) {
      await _cerrarSesionLocal();
      return false;
    }

    final dioRefresh = Dio(
      BaseOptions(
        baseUrl: ConfigService.instance.obtenerUrl(),
        connectTimeout: ApiConfig.connectTimeout,
        receiveTimeout: ApiConfig.receiveTimeout,
        headers: ApiConfig.headersPorDefecto,
      ),
    );

    try {
      final respuesta = await dioRefresh.post<dynamic>(
        ApiConfig.refresh,
        data: {'refresh': refresh},
      );

      final cuerpo = respuesta.data;
      // simplejwt responde sin sobre; se tolera también el formato envuelto.
      final datos = cuerpo is Map && cuerpo['success'] == true
          ? cuerpo['data']
          : cuerpo;

      if (datos is! Map) {
        await _cerrarSesionLocal();
        return false;
      }

      final access = datos['access']?.toString();
      if (access == null || access.isEmpty) {
        await _cerrarSesionLocal();
        return false;
      }

      await _tokenStorage.actualizarAccess(access);
      final nuevoRefresh = datos['refresh']?.toString();
      if (nuevoRefresh != null && nuevoRefresh.isNotEmpty) {
        await _tokenStorage.actualizarRefresh(nuevoRefresh);
      }
      return true;
    } on DioException {
      await _cerrarSesionLocal();
      return false;
    }
  }

  Future<void> _cerrarSesionLocal() async {
    await _tokenStorage.limpiar();
    onSesionExpirada?.call();
  }

  /// Desenvuelve `{success: true, data: ...}` y lanza [ApiException] si el
  /// backend respondió con error dentro del sobre.
  dynamic _desenvolver(Response<dynamic> respuesta) {
    final cuerpo = respuesta.data;
    final status = respuesta.statusCode ?? 200;

    if (cuerpo is Map && cuerpo.containsKey('success')) {
      if (cuerpo['success'] == true) {
        return cuerpo['data'];
      }
      throw ApiException.fromBody(cuerpo, statusCode: status);
    }

    if (status >= 400) {
      throw ApiException.fromBody(cuerpo, statusCode: status);
    }

    return cuerpo;
  }

  ApiException _mapearDio(DioException error) {
    final respuesta = error.response;
    if (respuesta != null) {
      final excepcion =
          ApiException.fromBody(respuesta.data, statusCode: respuesta.statusCode);
      final retryAfter = respuesta.headers.value('retry-after');
      final segundos = int.tryParse(retryAfter ?? '');
      if (segundos != null) {
        return ApiException(
          mensaje: excepcion.mensaje,
          codigo: excepcion.codigo,
          statusCode: excepcion.statusCode,
          retryAfterSeconds: segundos,
        );
      }
      return excepcion;
    }

    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const ApiException(
          mensaje: 'El servidor tardó demasiado en responder. '
              'Verifique su conexión e intente nuevamente.',
          codigo: 'TIMEOUT',
        );
      case DioExceptionType.cancel:
        return const ApiException(
          mensaje: 'La solicitud fue cancelada.',
          codigo: 'CANCELLED',
        );
      default:
        return const ApiException(
          mensaje: 'No se pudo conectar con el servidor. '
              'Verifique su conexión e intente nuevamente.',
          codigo: 'NETWORK_ERROR',
        );
    }
  }
}
