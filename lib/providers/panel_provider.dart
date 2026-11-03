import 'package:flutter/foundation.dart';

import '../models/api_error.dart';
import '../models/estadisticas_baja.dart';
import '../models/filtros_baja.dart';
import '../models/opcion_filtro.dart';
import '../services/baja_service.dart';
import '../services/notificacion_service.dart';

/// Provider del panel principal (HU02): estadísticas, filtros por área y
/// contador de notificaciones.
class PanelProvider extends ChangeNotifier {
  PanelProvider({
    BajaService? bajas,
    NotificacionService? notificaciones,
  })  : _bajas = bajas ?? BajaService(),
        _notificaciones = notificaciones ?? NotificacionService();

  final BajaService _bajas;
  final NotificacionService _notificaciones;

  EstadisticasBaja? _estadisticas;
  FiltrosBaja _filtros = const FiltrosBaja();
  int _notificacionesGeneradas = 0;
  int? _idEstructuraSeleccionada;
  bool _cargando = false;
  String? _errorMessage;

  EstadisticasBaja? get estadisticas => _estadisticas;
  FiltrosBaja get filtros => _filtros;
  List<OpcionFiltro> get areas => _filtros.estructuras;
  int get notificacionesGeneradas => _notificacionesGeneradas;
  int? get idEstructuraSeleccionada => _idEstructuraSeleccionada;
  bool get cargando => _cargando;
  String? get errorMessage => _errorMessage;

  /// Carga inicial del panel.
  Future<void> cargar() async {
    if (_cargando) return;
    _cargando = true;
    _errorMessage = null;
    notifyListeners();

    await _cargarDatos();

    _cargando = false;
    notifyListeners();
  }

  /// Cambia el filtro de área y recarga las estadísticas.
  Future<void> seleccionarArea(int? idEstructura) async {
    if (_idEstructuraSeleccionada == idEstructura) return;
    _idEstructuraSeleccionada = idEstructura;
    _cargando = true;
    _errorMessage = null;
    notifyListeners();

    await _cargarDatos();

    _cargando = false;
    notifyListeners();
  }

  /// Actualiza solo el contador de notificaciones (badge del AppBar).
  Future<void> actualizarNotificaciones() async {
    try {
      final lista = await _notificaciones.listar();
      _notificacionesGeneradas = lista.length;
      notifyListeners();
    } on ApiException {
      // No se interrumpe el panel por un fallo del contador.
    }
  }

  Future<void> _cargarDatos() async {
    try {
      final resultados = await Future.wait([
        _bajas.estadisticas(idEstructura: _idEstructuraSeleccionada),
        _bajas.filtros(),
        _notificaciones.listar(),
      ]);

      _estadisticas = resultados[0] as EstadisticasBaja;
      _filtros = resultados[1] as FiltrosBaja;
      _notificacionesGeneradas = (resultados[2] as List).length;
    } on ApiException catch (error) {
      _errorMessage = error.mensaje;
    } catch (_) {
      _errorMessage = 'No se pudo cargar el panel. Intente nuevamente.';
    }
  }
}
