import 'package:flutter/material.dart';

import '../config/theme.dart';

/// Área involucrada en una solicitud de baja.
///
/// Se obtiene de `GET /api/bajas/{id}/areas-confirmacion/`. El backend puede
/// devolver el estado como texto (`nombre_estado`, `estado`) o como id; aquí
/// se normalizan ambos casos.
@immutable
class AreaConfirmacion {
  const AreaConfirmacion({
    this.idArea,
    required this.nombreArea,
    this.idEstado,
    this.estadoEtiqueta,
    this.fecha,
  });

  final int? idArea;
  final String nombreArea;
  final int? idEstado;
  final String? estadoEtiqueta;
  final DateTime? fecha;

  /// Etiqueta del estado del área. Si el backend no la envía se deduce del id
  /// y, en último caso, se asume "Pendiente".
  String get estado {
    final etiqueta = estadoEtiqueta?.trim();
    if (etiqueta != null && etiqueta.isNotEmpty) return etiqueta;
    if (idEstado != null) return _nombrePorId(idEstado!);
    return 'Pendiente';
  }

  /// Color del estado según la paleta de la aplicación y el diseño de Figma:
  /// Iniciada (verde), En Trámite (naranja), Finalizada (azul) y Baja/Pendiente
  /// (rojo).
  Color get colorEstado {
    switch (estado.toLowerCase()) {
      case 'iniciada':
        return AppPalette.success;
      case 'en trámite':
      case 'en tramite':
        return AppPalette.warning;
      case 'pendiente':
      case 'baja':
        return AppPalette.primary;
      case 'finalizada':
      case 'confirmada':
        return AppPalette.tertiary;
      case 'cancelada':
      case 'expirada':
        return AppPalette.textSecondary;
      default:
        return AppPalette.textSecondary;
    }
  }

  factory AreaConfirmacion.fromJson(Map<String, dynamic> json) {
    final confirmada = json['confirmada'];
    final estadoCrudo =
        json['nombre_estado'] ??
        json['estado'] ??
        json['estado_display'] ??
        json['nombre_estado_confirmacion'] ??
        (confirmada is bool ? (confirmada ? 'Finalizada' : 'Pendiente') : null);
    final estadoEsId =
        estadoCrudo is num ||
        int.tryParse(estadoCrudo?.toString() ?? '') != null;

    return AreaConfirmacion(
      idArea: _entero(
        json['id_area'] ?? json['id_estructura'] ?? json['id_area_baja'],
      ),
      nombreArea:
          (json['nombre_area'] ??
                  json['nombre_estructura'] ??
                  json['area'] ??
                  'Área')
              .toString(),
      idEstado: _entero(
        json['id_estado'] ??
            json['id_estado_confirmacion'] ??
            (estadoEsId ? estadoCrudo : null),
      ),
      estadoEtiqueta: estadoEsId ? null : estadoCrudo?.toString(),
      fecha: _fecha(
        json['fecha'] ?? json['fecha_confirmacion'] ?? json['fecha_registro'],
      ),
    );
  }

  static String _nombrePorId(int id) {
    switch (id) {
      case 1:
        return 'Iniciada';
      case 2:
        return 'En Trámite';
      case 3:
        return 'Finalizada';
      case 4:
        return 'Baja';
      case 5:
        return 'Cancelada';
      case 6:
        return 'Expirada';
      default:
        return 'Pendiente';
    }
  }

  static int? _entero(dynamic valor) {
    if (valor is int) return valor;
    if (valor is num) return valor.toInt();
    return int.tryParse(valor?.toString() ?? '');
  }

  static DateTime? _fecha(dynamic valor) {
    if (valor == null) return null;
    return DateTime.tryParse(valor.toString());
  }
}
