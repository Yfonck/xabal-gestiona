import 'package:flutter/foundation.dart';

import '../models/api_error.dart';
import '../models/usuario.dart';
import '../services/auth_service.dart';

/// Estado de autenticación de la aplicación.
enum EstadoAuth { inicializando, noAutenticado, autenticado }

/// Provider de sesión: login, restauración, logout y usuario actual.
class AuthProvider extends ChangeNotifier {
  AuthProvider({AuthService? servicio}) : _servicio = servicio ?? AuthService() {
    _servicio.apiClient.onSesionExpirada = _alExpirarSesion;
  }

  final AuthService _servicio;

  EstadoAuth _estado = EstadoAuth.inicializando;
  Usuario? _usuario;
  bool _cargando = false;
  String? _errorMessage;

  /// Se activa cuando el backend invalidó la sesión (sesión única).
  bool _sesionExpirada = false;

  EstadoAuth get estado => _estado;
  Usuario? get usuario => _usuario;
  bool get cargando => _cargando;
  bool get autenticado => _estado == EstadoAuth.autenticado;
  String? get errorMessage => _errorMessage;
  bool get sesionExpirada => _sesionExpirada;

  /// Intenta recuperar la sesión guardada al arrancar la app.
  Future<void> restaurarSesion() async {
    _estado = EstadoAuth.inicializando;
    _cargando = true;
    notifyListeners();

    final usuario = await _servicio.restaurarSesion();
    _usuario = usuario;
    _estado = usuario == null ? EstadoAuth.noAutenticado : EstadoAuth.autenticado;
    _cargando = false;
    notifyListeners();
  }

  /// Inicia sesión. Devuelve `true` si el backend aceptó las credenciales.
  Future<bool> iniciarSesion({
    required String usuario,
    required String contrasena,
  }) async {
    if (_cargando) return false;

    _cargando = true;
    _errorMessage = null;
    _sesionExpirada = false;
    notifyListeners();

    try {
      final sesion = await _servicio.iniciarSesion(
        usuario: usuario,
        contrasena: contrasena,
      );
      _usuario = sesion.usuario;
      _estado = EstadoAuth.autenticado;
      return true;
    } on ApiException catch (error) {
      _estado = EstadoAuth.noAutenticado;
      _errorMessage = _mensajeDeLogin(error);
      return false;
    } catch (_) {
      _estado = EstadoAuth.noAutenticado;
      _errorMessage = 'Ocurrió un error inesperado. Intente nuevamente.';
      return false;
    } finally {
      _cargando = false;
      notifyListeners();
    }
  }

  /// Cierra la sesión local y notifica al backend.
  Future<void> cerrarSesion() async {
    _cargando = true;
    notifyListeners();

    await _servicio.cerrarSesion();

    _usuario = null;
    _estado = EstadoAuth.noAutenticado;
    _errorMessage = null;
    _sesionExpirada = false;
    _cargando = false;
    notifyListeners();
  }

  /// Refresca los datos del usuario (por ejemplo tras cambiar la foto).
  Future<void> actualizarPerfil() async {
    if (!autenticado) return;
    try {
      _usuario = await _servicio.obtenerPerfil();
      notifyListeners();
    } on ApiException {
      // Si el error es de sesión, el ApiClient ya disparó onSesionExpirada.
    }
  }

  void limpiarError() {
    if (_errorMessage == null) return;
    _errorMessage = null;
    notifyListeners();
  }

  /// Marca como leída la notificación de sesión expirada.
  void reconocerSesionExpirada() {
    _sesionExpirada = false;
    notifyListeners();
  }

  void _alExpirarSesion() {
    if (_estado == EstadoAuth.noAutenticado) return;
    _usuario = null;
    _estado = EstadoAuth.noAutenticado;
    _sesionExpirada = true;
    _errorMessage = null;
    notifyListeners();
  }

  String _mensajeDeLogin(ApiException error) {
    if (error.esRateLimited) {
      final segundos = error.retryAfterSeconds;
      return segundos == null
          ? 'Demasiados intentos. Espere un momento antes de reintentar.'
          : 'Demasiados intentos. Espere $segundos segundos antes de reintentar.';
    }
    if (error.esNoAutorizado) {
      return 'Usuario o contraseña incorrectos. Intente nuevamente.';
    }
    if (error.esSinConexion) {
      return error.mensaje;
    }
    return error.mensaje;
  }

  @override
  void dispose() {
    _servicio.apiClient.onSesionExpirada = null;
    super.dispose();
  }
}
