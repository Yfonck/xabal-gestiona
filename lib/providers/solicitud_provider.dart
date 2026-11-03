import 'package:flutter/foundation.dart';

import '../models/api_error.dart';
import '../models/filtros_baja.dart';
import '../models/solicitud_baja.dart';
import '../services/baja_service.dart';

/// Provider de la lista de solicitudes de baja con scroll infinito.
class SolicitudProvider extends ChangeNotifier {
  SolicitudProvider({BajaService? servicio})
      : _servicio = servicio ?? BajaService();

  final BajaService _servicio;

  static const int tamanoPagina = 20;

  final List<SolicitudBaja> _solicitudes = [];
  FiltrosBaja _filtros = const FiltrosBaja();

  int _pagina = 0;
  bool _hayMas = true;
  bool _cargando = false;
  bool _cargandoMas = false;
  String? _errorMessage;

  // Filtros activos
  String _busqueda = '';
  int? _idEstado;
  int? _idTipoBaja;
  int? _idCausaBaja;
  int? _idEstructura;
  DateTime? _fechaDesde;
  DateTime? _fechaHasta;

  List<SolicitudBaja> get solicitudes => List.unmodifiable(_solicitudes);
  FiltrosBaja get filtros => _filtros;
  bool get cargando => _cargando;
  bool get cargandoMas => _cargandoMas;
  bool get hayMas => _hayMas;
  String? get errorMessage => _errorMessage;
  bool get vacio => !_cargando && _solicitudes.isEmpty && _errorMessage == null;

  String get busqueda => _busqueda;
  int? get idEstado => _idEstado;
  int? get idTipoBaja => _idTipoBaja;
  int? get idCausaBaja => _idCausaBaja;
  int? get idEstructura => _idEstructura;
  DateTime? get fechaDesde => _fechaDesde;
  DateTime? get fechaHasta => _fechaHasta;

  /// Carga la primera página aplicando los filtros indicados.
  Future<void> cargar({
    String? busqueda,
    int? idEstado,
    int? idTipoBaja,
    int? idCausaBaja,
    int? idEstructura,
    DateTime? fechaDesde,
    DateTime? fechaHasta,
  }) async {
    _busqueda = busqueda ?? '';
    _idEstado = idEstado;
    _idTipoBaja = idTipoBaja;
    _idCausaBaja = idCausaBaja;
    _idEstructura = idEstructura;
    _fechaDesde = fechaDesde;
    _fechaHasta = fechaHasta;

    _pagina = 0;
    _hayMas = true;
    _solicitudes.clear();
    _errorMessage = null;
    _cargando = true;
    notifyListeners();

    await _cargarPagina(1);

    _cargando = false;
    notifyListeners();
  }

  /// Recarga manteniendo los filtros actuales.
  Future<void> recargar() => cargar(
        busqueda: _busqueda,
        idEstado: _idEstado,
        idTipoBaja: _idTipoBaja,
        idCausaBaja: _idCausaBaja,
        idEstructura: _idEstructura,
        fechaDesde: _fechaDesde,
        fechaHasta: _fechaHasta,
      );

  /// Carga la siguiente página (scroll infinito).
  Future<void> cargarMas() async {
    if (_cargando || _cargandoMas || !_hayMas) return;
    _cargandoMas = true;
    notifyListeners();

    await _cargarPagina(_pagina + 1);

    _cargandoMas = false;
    notifyListeners();
  }

  /// Carga los catálogos de filtros una sola vez.
  Future<void> cargarFiltros() async {
    if (_filtros.tipos.isNotEmpty || _filtros.causas.isNotEmpty) return;
    try {
      _filtros = await _servicio.filtros();
      notifyListeners();
    } on ApiException {
      // Los filtros son opcionales; la lista sigue siendo usable.
    }
  }

  /// Crea una solicitud de baja y la inserta al inicio de la lista.
  Future<SolicitudBaja> crear({
    required String idPersona,
    required int idTipoBaja,
    required int idCausaBaja,
  }) async {
    final nueva = await _servicio.crear(
      idPersona: idPersona,
      idTipoBaja: idTipoBaja,
      idCausaBaja: idCausaBaja,
    );
    _solicitudes.insert(0, nueva);
    notifyListeners();
    return nueva;
  }

  /// Reemplaza una solicitud tras un cambio de estado.
  void reemplazar(SolicitudBaja actualizada) {
    final indice = _solicitudes
        .indexWhere((s) => s.idSolicitud == actualizada.idSolicitud);
    if (indice == -1) return;
    _solicitudes[indice] = actualizada;
    notifyListeners();
  }

  /// Elimina una solicitud de la lista local (tras cancelar).
  void quitar(int idSolicitud) {
    _solicitudes.removeWhere((s) => s.idSolicitud == idSolicitud);
    notifyListeners();
  }

  Future<void> _cargarPagina(int pagina) async {
    try {
      final respuesta = await _servicio.listar(
        page: pagina,
        pageSize: tamanoPagina,
        search: _busqueda,
        idEstado: _idEstado,
        idTipoBaja: _idTipoBaja,
        idCausaBaja: _idCausaBaja,
        idEstructura: _idEstructura,
        fechaDesde: _fechaDesde,
        fechaHasta: _fechaHasta,
      );

      _pagina = pagina;
      _hayMas = respuesta.hayMas;
      _solicitudes.addAll(respuesta.results);
      _errorMessage = null;
    } on ApiException catch (error) {
      _errorMessage = error.mensaje;
      _hayMas = false;
    } catch (_) {
      _errorMessage = 'No se pudieron cargar las solicitudes.';
      _hayMas = false;
    }
  }
}
