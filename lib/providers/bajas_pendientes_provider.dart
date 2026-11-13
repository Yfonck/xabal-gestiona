import 'package:flutter/foundation.dart';

import '../models/api_error.dart';
import '../models/estado_solicitud.dart';
import '../models/estadisticas_baja.dart';
import '../models/filtros_baja.dart';
import '../models/opcion_filtro.dart';
import '../models/paginated_response.dart';
import '../models/solicitud_baja.dart';
import '../services/baja_service.dart';

/// Provider de la pantalla de bajas pendientes (HU05).
///
/// Mantiene el resumen por área (donut), el listado paginado de pendientes y
/// los filtros de área, tipo y causa.
class BajasPendientesProvider extends ChangeNotifier {
  BajasPendientesProvider({BajaService? servicio})
    : _servicio = servicio ?? BajaService();

  final BajaService _servicio;

  static const int tamanoPagina = 20;

  FiltrosBaja _filtros = const FiltrosBaja();
  EstadisticasBaja? _estadisticas;
  final List<SolicitudBaja> _solicitudes = [];

  int? _idEstructura;
  int? _idTipoBaja;
  int? _idCausaBaja;
  String _busqueda = '';

  int _pagina = 0;
  bool _hayMas = false;
  bool _cargando = false;
  bool _cargandoMas = false;
  bool _filtrosCargados = false;
  String? _errorMessage;

  FiltrosBaja get filtros => _filtros;
  List<OpcionFiltro> get areas => _filtros.estructuras;
  List<OpcionFiltro> get tipos => _filtros.tipos;
  List<OpcionFiltro> get causas => _filtros.causas;
  EstadisticasBaja? get estadisticas => _estadisticas;
  List<SolicitudBaja> get solicitudes => List.unmodifiable(_solicitudes);
  int? get idEstructura => _idEstructura;
  int? get idTipoBaja => _idTipoBaja;
  int? get idCausaBaja => _idCausaBaja;
  String get busqueda => _busqueda;
  bool get cargando => _cargando;
  bool get cargandoMas => _cargandoMas;
  bool get hayMas => _hayMas;
  String? get errorMessage => _errorMessage;
  bool get vacio => !_cargando && _solicitudes.isEmpty && _errorMessage == null;

  /// Total de bajas pendientes (Iniciada + En Trámite) del área seleccionada.
  int get totalPendientes {
    final estadisticas = _estadisticas;
    if (estadisticas == null) return 0;
    return estadisticas.cantidadDe(EstadoSolicitud.iniciada) +
        estadisticas.cantidadDe(EstadoSolicitud.enTramite);
  }

  /// Nombre del área seleccionada o "Todas las áreas".
  String get nombreArea {
    if (_idEstructura == null) return 'Todas las áreas';
    for (final area in _filtros.estructuras) {
      if (area.id == _idEstructura) return area.etiqueta;
    }
    return 'Área seleccionada';
  }

  /// Carga los catálogos de filtros una sola vez.
  Future<void> cargarFiltros() async {
    if (_filtrosCargados) return;
    try {
      _filtros = await _servicio.filtros();
      _filtrosCargados = true;
      notifyListeners();
    } on ApiException {
      // Los filtros son opcionales; el listado sigue siendo usable.
    } catch (_) {
      // Ignorar cualquier otro fallo de los catálogos.
    }
  }

  /// Carga la primera página aplicando los filtros indicados.
  Future<void> cargar({
    int? idEstructura,
    int? idTipoBaja,
    int? idCausaBaja,
    String? busqueda,
  }) async {
    _idEstructura = idEstructura;
    _idTipoBaja = idTipoBaja;
    _idCausaBaja = idCausaBaja;
    _busqueda = busqueda ?? '';

    _pagina = 0;
    _hayMas = false;
    _solicitudes.clear();
    _errorMessage = null;
    _cargando = true;
    notifyListeners();

    await _cargarDatos();

    _cargando = false;
    notifyListeners();
  }

  /// Recarga manteniendo los filtros actuales.
  Future<void> recargar() => cargar(
    idEstructura: _idEstructura,
    idTipoBaja: _idTipoBaja,
    idCausaBaja: _idCausaBaja,
    busqueda: _busqueda,
  );

  Future<void> seleccionarArea(int? id) => cargar(
    idEstructura: id,
    idTipoBaja: _idTipoBaja,
    idCausaBaja: _idCausaBaja,
    busqueda: _busqueda,
  );

  Future<void> seleccionarTipo(int? id) => cargar(
    idEstructura: _idEstructura,
    idTipoBaja: id,
    idCausaBaja: _idCausaBaja,
    busqueda: _busqueda,
  );

  Future<void> seleccionarCausa(int? id) => cargar(
    idEstructura: _idEstructura,
    idTipoBaja: _idTipoBaja,
    idCausaBaja: id,
    busqueda: _busqueda,
  );

  Future<void> buscar(String termino) => cargar(
    idEstructura: _idEstructura,
    idTipoBaja: _idTipoBaja,
    idCausaBaja: _idCausaBaja,
    busqueda: termino,
  );

  /// Quita todos los filtros, conservando el texto de búsqueda.
  Future<void> limpiarFiltros() => cargar(busqueda: _busqueda);

  /// Carga la siguiente página (scroll infinito).
  Future<void> cargarMas() async {
    if (_cargando || _cargandoMas || !_hayMas) return;
    _cargandoMas = true;
    notifyListeners();

    await _cargarPagina(_pagina + 1);

    _cargandoMas = false;
    notifyListeners();
  }

  /// Confirma el área de la solicitud (2 → 3).
  Future<void> confirmarArea(int id) async {
    _cargando = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _servicio.confirmar(id);
      await cargar(
        idEstructura: _idEstructura,
        idTipoBaja: _idTipoBaja,
        idCausaBaja: _idCausaBaja,
        busqueda: _busqueda,
      );
    } on ApiException catch (error) {
      _errorMessage = error.mensaje;
    } catch (_) {
      _errorMessage = 'No se pudo confirmar el área.';
    } finally {
      _cargando = false;
      notifyListeners();
    }
  }

  /// Cancela la solicitud con motivo (2 → 5).
  Future<void> cancelarConMotivo(int id, {required String motivo}) async {
    _cargando = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _servicio.cancelarConMotivo(id, motivo: motivo);
      await cargar(
        idEstructura: _idEstructura,
        idTipoBaja: _idTipoBaja,
        idCausaBaja: _idCausaBaja,
        busqueda: _busqueda,
      );
    } on ApiException catch (error) {
      _errorMessage = error.mensaje;
    } catch (_) {
      _errorMessage = 'No se pudo cancelar la solicitud.';
    } finally {
      _cargando = false;
      notifyListeners();
    }
  }

  Future<void> _cargarDatos() async {
    try {
      final resultados = await Future.wait([
        _servicio.estadisticas(idEstructura: _idEstructura),
        _servicio.pendientes(
          page: 1,
          pageSize: tamanoPagina,
          search: _busqueda,
          idEstructura: _idEstructura,
          idTipoBaja: _idTipoBaja,
          idCausaBaja: _idCausaBaja,
        ),
      ]);

      _estadisticas = resultados[0] as EstadisticasBaja;
      final pagina = resultados[1] as PaginatedResponse<SolicitudBaja>;
      _pagina = 1;
      _hayMas = pagina.hayMas;
      _solicitudes.addAll(pagina.results);
      _errorMessage = null;
    } on ApiException catch (error) {
      _errorMessage = error.mensaje;
    } catch (_) {
      _errorMessage = 'No se pudieron cargar las bajas pendientes.';
    }
  }

  Future<void> _cargarPagina(int pagina) async {
    try {
      final respuesta = await _servicio.pendientes(
        page: pagina,
        pageSize: tamanoPagina,
        search: _busqueda,
        idEstructura: _idEstructura,
        idTipoBaja: _idTipoBaja,
        idCausaBaja: _idCausaBaja,
      );
      _pagina = pagina;
      _hayMas = respuesta.hayMas;
      _solicitudes.addAll(respuesta.results);
      _errorMessage = null;
    } on ApiException catch (error) {
      _errorMessage = error.mensaje;
      _hayMas = false;
    } catch (_) {
      _errorMessage = 'No se pudieron cargar más bajas pendientes.';
      _hayMas = false;
    }
  }
}
