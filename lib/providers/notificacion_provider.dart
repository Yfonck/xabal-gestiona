import 'package:flutter/foundation.dart';

import '../models/api_error.dart';
import '../models/notificacion.dart';
import '../services/notificacion_service.dart';

/// Provider del centro de notificaciones (HU10).
///
/// También alimenta el badge de la campana en el AppBar.
class NotificacionProvider extends ChangeNotifier {
  NotificacionProvider({NotificacionService? servicio})
      : _servicio = servicio ?? NotificacionService();

  final NotificacionService _servicio;

  List<Notificacion> _notificaciones = const [];
  bool _cargando = false;
  String? _errorMessage;

  List<Notificacion> get notificaciones => List.unmodifiable(_notificaciones);
  bool get cargando => _cargando;
  String? get errorMessage => _errorMessage;

  int get total => _notificaciones.length;
  int get noLeidas => _notificaciones.where((n) => !n.leida).length;
  bool get vacio => !_cargando && _notificaciones.isEmpty;

  /// Carga el listado del usuario autenticado.
  Future<void> cargar() async {
    if (_cargando) return;
    _cargando = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _notificaciones = await _servicio.listar();
    } on ApiException catch (error) {
      _errorMessage = error.mensaje;
    } catch (_) {
      _errorMessage = 'No se pudieron cargar las notificaciones.';
    }

    _cargando = false;
    notifyListeners();
  }

  /// Actualiza el badge sin mostrar el spinner del listado.
  Future<void> actualizarContador() async {
    try {
      _notificaciones = await _servicio.listar();
      notifyListeners();
    } on ApiException {
      // Silencioso: el badge es información secundaria.
    }
  }

  Future<void> marcarLeida(Notificacion notificacion) async {
    if (notificacion.leida) return;
    try {
      await _servicio.marcarLeida(notificacion.id);
      _notificaciones = [
        for (final actual in _notificaciones)
          if (actual.id == notificacion.id)
            Notificacion(
              id: actual.id,
              titulo: actual.titulo,
              mensaje: actual.mensaje,
              idUsuario: actual.idUsuario,
              leida: true,
              fechaCreacion: actual.fechaCreacion,
              link: actual.link,
            )
          else
            actual,
      ];
      notifyListeners();
    } on ApiException catch (error) {
      _errorMessage = error.mensaje;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> eliminar(int id) async {
    try {
      await _servicio.eliminar(id);
      _notificaciones =
          _notificaciones.where((n) => n.id != id).toList(growable: false);
      notifyListeners();
    } on ApiException catch (error) {
      _errorMessage = error.mensaje;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> limpiarTodas() async {
    try {
      await _servicio.limpiarTodas();
      _notificaciones = const [];
      notifyListeners();
    } on ApiException catch (error) {
      _errorMessage = error.mensaje;
      notifyListeners();
      rethrow;
    }
  }

  /// Limpia la sesión de notificaciones al cerrar sesión.
  void reiniciar() {
    _notificaciones = const [];
    _errorMessage = null;
    notifyListeners();
  }
}
