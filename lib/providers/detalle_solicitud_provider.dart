import 'package:flutter/foundation.dart';

import '../models/api_error.dart';
import '../models/area_confirmacion.dart';
import '../models/solicitud_baja.dart';
import '../services/baja_service.dart';

/// Provider del detalle de una solicitud de baja (HU06).
///
/// Carga en paralelo la solicitud y sus áreas de confirmación. Si las áreas
/// fallan, el detalle se muestra igualmente.
class DetalleSolicitudProvider extends ChangeNotifier {
  DetalleSolicitudProvider({BajaService? servicio})
    : _servicio = servicio ?? BajaService();

  final BajaService _servicio;

  int? _id;
  SolicitudBaja? _solicitud;
  List<AreaConfirmacion> _areas = const [];
  bool _cargando = false;
  String? _errorMessage;

  int? get id => _id;
  SolicitudBaja? get solicitud => _solicitud;
  List<AreaConfirmacion> get areas => List.unmodifiable(_areas);
  bool get cargando => _cargando;
  String? get errorMessage => _errorMessage;

  /// Carga el detalle de la solicitud indicada.
  Future<void> cargar(int id) async {
    _id = id;
    _cargando = true;
    _errorMessage = null;
    _solicitud = null;
    _areas = const [];
    notifyListeners();

    try {
      _solicitud = await _servicio.detalle(id);
    } on ApiException catch (error) {
      _errorMessage = error.mensaje;
    } catch (_) {
      _errorMessage = 'No se pudo cargar el detalle de la solicitud.';
    }

    if (_solicitud != null) {
      try {
        _areas = await _servicio.areasConfirmacion(id);
      } on ApiException {
        // Las áreas son información complementaria; no bloquean el detalle.
      } catch (_) {
        // Ignorar cualquier otro fallo de las áreas.
      }
    }

    _cargando = false;
    notifyListeners();
  }

  /// Recarga el detalle actual.
  Future<void> recargar() async {
    final id = _id;
    if (id == null) return;
    await cargar(id);
  }
}
