import 'package:flutter/foundation.dart';

import '../models/api_error.dart';
import '../models/filtros_persona.dart';
import '../models/persona.dart';
import '../services/persona_service.dart';

/// Provider de búsqueda de personas (HU04) y selector de la HU03.
class PersonaProvider extends ChangeNotifier {
  PersonaProvider({PersonaService? servicio})
      : _servicio = servicio ?? PersonaService();

  final PersonaService _servicio;

  static const int tamanoPagina = 20;

  final List<Persona> _personas = [];
  String _termino = '';
  bool _soloActivas = true;
  int? _idEstructura;
  FiltrosPersona _filtros = const FiltrosPersona();
  int _pagina = 0;
  bool _hayMas = false;
  bool _cargando = false;
  bool _cargandoMas = false;
  bool _busco = false;
  String? _errorMessage;

  List<Persona> get personas => List.unmodifiable(_personas);
  String get termino => _termino;
  bool get soloActivas => _soloActivas;
  int? get idEstructura => _idEstructura;
  FiltrosPersona get filtros => _filtros;
  bool get cargando => _cargando;
  bool get cargandoMas => _cargandoMas;
  bool get hayMas => _hayMas;
  bool get busco => _busco;
  String? get errorMessage => _errorMessage;
  bool get vacio =>
      _busco && !_cargando && _personas.isEmpty && _errorMessage == null;

  /// Busca personas por nombre, apellidos, CI o solapín.
  Future<void> buscar(
    String termino, {
    bool? soloActivas,
    int? idEstructura,
  }) async {
    _termino = termino.trim();
    _soloActivas = soloActivas ?? _soloActivas;
    _idEstructura = idEstructura;
    _pagina = 0;
    _hayMas = false;
    _personas.clear();
    _errorMessage = null;
    _busco = true;
    _cargando = true;
    notifyListeners();

    await _cargarPagina(1);

    _cargando = false;
    notifyListeners();
  }

  /// Aplica filtros avanzados y repite la búsqueda actual.
  Future<void> aplicarFiltros({
    int? idEstructura,
    bool? soloActivas,
  }) async {
    _idEstructura = idEstructura;
    _soloActivas = soloActivas ?? _soloActivas;
    if (!_busco) {
      notifyListeners();
      return;
    }
    await buscar(
      _termino,
      soloActivas: _soloActivas,
      idEstructura: _idEstructura,
    );
  }

  /// Carga los catálogos de filtros una sola vez.
  Future<void> cargarFiltros() async {
    if (_filtros.estructuras.isNotEmpty) return;
    try {
      _filtros = await _servicio.filtros();
      notifyListeners();
    } on ApiException {
      // Los filtros son opcionales.
    }
  }

  Future<void> cargarMas() async {
    if (_cargando || _cargandoMas || !_hayMas) return;
    _cargandoMas = true;
    notifyListeners();

    await _cargarPagina(_pagina + 1);

    _cargandoMas = false;
    notifyListeners();
  }

  /// Limpia los resultados (al cerrar el modal de búsqueda).
  void limpiar() {
    _personas.clear();
    _termino = '';
    _pagina = 0;
    _hayMas = false;
    _busco = false;
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> _cargarPagina(int pagina) async {
    try {
      final respuesta = await _servicio.buscar(
        search: _termino,
        page: pagina,
        pageSize: tamanoPagina,
        idEstructura: _idEstructura,
        soloActivas: _soloActivas,
      );
      _pagina = pagina;
      _hayMas = respuesta.hayMas;
      _personas.addAll(respuesta.results);
      _errorMessage = null;
    } on ApiException catch (error) {
      _errorMessage = error.mensaje;
      _hayMas = false;
    } catch (_) {
      _errorMessage = 'No se pudo buscar personas. Intente nuevamente.';
      _hayMas = false;
    }
  }
}
