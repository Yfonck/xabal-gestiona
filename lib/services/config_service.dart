import 'package:shared_preferences/shared_preferences.dart';

/// Servicio de configuración que lee y guarda la URL del backend en
/// `SharedPreferences`.
///
/// Si no hay una URL guardada, se usa la por defecto:
/// `http://192.168.181.218:8000/api/`.
class ConfigService {
  ConfigService({this._prefs});

  static final ConfigService instance = ConfigService();

  static const String _claveUrl = 'xabal_api_base_url';
  static const String _urlPorDefecto =
      'http://192.168.181.218:8000/api/';

  SharedPreferences? _prefs;

  /// Inicializa `SharedPreferences`. Debe llamarse antes de usar el servicio.
  Future<void> inicializar() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  /// Devuelve la URL guardada, o la por defecto si no hay ninguna.
  String obtenerUrl() {
    return _prefs?.getString(_claveUrl) ?? _urlPorDefecto;
  }

  /// Guarda la URL del backend.
  Future<void> guardarUrl(String url) async {
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    await prefs.setString(_claveUrl, url);
  }
}
