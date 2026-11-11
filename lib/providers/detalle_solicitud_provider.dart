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

  /// Confirma el área de la solicitud (2 → 3).
  Future<void> confirmar(int id) async {
    _cargando = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _servicio.confirmar(id);
      await cargar(id);
    } on ApiException catch (error) {
      _errorMessage = error.mensaje;
    } catch (_) {
      _errorMessage = 'No se pudo confirmar el área.';
    } finally {
      _cargando = false;
      notifyListeners();
    }
  }

  /// Cancela la solicitud (2 → 5).
  Future<void> cancelar(int id, {String motivo = ''}) async {
    _cargando = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _servicio.cancelar(id);
      await cargar(id);
    } on ApiException catch (error) {
      _errorMessage = error.mensaje;
    } catch (_) {
      _errorMessage = 'No se pudo cancelar la solicitud.';
    } finally {
      _cargando = false;
      notifyListeners();
    }
  }

  /// Cierra la baja (3 → 4, solo admin/RRHH).
  Future<void> cerrar(int id) async {
    _cargando = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _servicio.cerrar(id);
      await cargar(id);
    } on ApiException catch (error) {
      _errorMessage = error.mensaje;
    } catch (_) {
      _errorMessage = 'No se pudo cerrar la baja.';
    } finally {
      _cargando = false;
      notifyListeners();
    }
  }

  /// Cierra la baja legacy (1→4 o 3→4, solo admin/RRHH).
  Future<void> cerrarLegacy(int id) async {
    _cargando = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _servicio.cerrarLegacy(id);
      await cargar(id);
    } on ApiException catch (error) {
      _errorMessage = error.mensaje;
    } catch (_) {
      _errorMessage = 'No se pudo cerrar la solicitud (legacy).';
    } finally {
      _cargando = false;
      notifyListeners();
    }
  }

  /// Cierra la baja de forma asíncrona (3 → 4, solo admin/RRHH).
  Future<void> cerrarAsync(int id) async {
    _cargando = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _servicio.cerrarAsync(id);
      await cargar(id);
    } on ApiException catch (error) {
      _errorMessage = error.mensaje;
    } catch (_) {
      _errorMessage = 'No se pudo iniciar el cierre asíncrono.';
    } finally {
      _cargando = false;
      notifyListeners();
    }
  }

  /// Da de baja definitiva a una solicitud Finalizada (3 → 4).
  /// Acción irreversible que requiere confirmación previa desde la UI.
  Future<void> darBajaDefinitiva(int id) async {
    await cerrar(id);
  }
}
