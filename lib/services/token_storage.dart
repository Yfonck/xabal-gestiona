import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Almacenamiento seguro de los tokens JWT.
///
/// Los tokens viven exclusivamente en `flutter_secure_storage`; además se
/// mantiene una copia en memoria para no leer el keystore en cada petición.
class TokenStorage {
  TokenStorage({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  static final TokenStorage instance = TokenStorage();

  static const String _claveAccess = 'xabal_access_token';
  static const String _claveRefresh = 'xabal_refresh_token';

  final FlutterSecureStorage _storage;

  String? _accessEnMemoria;
  String? _refreshEnMemoria;
  bool _cargado = false;

  Future<void> guardar({
    required String access,
    required String refresh,
  }) async {
    _accessEnMemoria = access;
    _refreshEnMemoria = refresh;
    _cargado = true;

    await _storage.write(key: _claveAccess, value: access);
    await _storage.write(key: _claveRefresh, value: refresh);
  }

  Future<void> actualizarAccess(String access) async {
    _accessEnMemoria = access;
    await _storage.write(key: _claveAccess, value: access);
  }

  /// Solo actualiza el refresh cuando el backend rota el token.
  Future<void> actualizarRefresh(String refresh) async {
    _refreshEnMemoria = refresh;
    await _storage.write(key: _claveRefresh, value: refresh);
  }

  Future<String?> obtenerAccess() async => _accessEnMemoria ??= await _leer(_claveAccess);

  Future<String?> obtenerRefresh() async =>
      _refreshEnMemoria ??= await _leer(_claveRefresh);

  Future<bool> tieneSesion() async {
    final refresh = await obtenerRefresh();
    return refresh != null && refresh.isNotEmpty;
  }

  Future<void> limpiar() async {
    _accessEnMemoria = null;
    _refreshEnMemoria = null;
    _cargado = true;
    await _storage.delete(key: _claveAccess);
    await _storage.delete(key: _claveRefresh);
  }

  Future<String?> _leer(String clave) async {
    if (!_cargado) {
      // Primera lectura: se cargan ambos tokens de una sola vez.
      _cargado = true;
      final todos = await _storage.readAll();
      _accessEnMemoria = todos[_claveAccess];
      _refreshEnMemoria = todos[_claveRefresh];
    }
    return clave == _claveAccess ? _accessEnMemoria : _refreshEnMemoria;
  }
}
