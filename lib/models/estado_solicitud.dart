import 'package:flutter/material.dart';

import '../config/theme.dart';

/// Estado de una solicitud de baja.
///
/// Los IDs coinciden con `tb_nestado_solicitud_baja` del backend.
enum EstadoSolicitud {
  iniciada(1, 'Iniciada'),
  enTramite(2, 'En Trámite'),
  finalizada(3, 'Finalizada'),
  baja(4, 'Baja'),
  cancelada(5, 'Cancelada'),
  expirada(6, 'Expirada');

  const EstadoSolicitud(this.id, this.etiqueta);

  final int id;
  final String etiqueta;

  /// Color del texto y del ícono del badge.
  Color get color => switch (this) {
        EstadoSolicitud.iniciada => AppPalette.tertiary,
        EstadoSolicitud.enTramite => AppPalette.warning,
        EstadoSolicitud.finalizada => AppPalette.success,
        EstadoSolicitud.baja => AppPalette.primary,
        EstadoSolicitud.cancelada => AppPalette.textSecondary,
        EstadoSolicitud.expirada => AppPalette.textSecondary,
      };

  /// Fondo suave del badge.
  Color get colorFondo => switch (this) {
        EstadoSolicitud.iniciada => const Color(0xFFE8EAFF),
        EstadoSolicitud.enTramite => AppPalette.warningSoft,
        EstadoSolicitud.finalizada => AppPalette.successSoft,
        EstadoSolicitud.baja => AppPalette.primarySoft,
        EstadoSolicitud.cancelada => AppPalette.inputFill,
        EstadoSolicitud.expirada => AppPalette.inputFill,
      };

  /// Estados que aún requieren trabajo (aparecen en "pendientes").
  bool get esPendiente =>
      this == EstadoSolicitud.iniciada || this == EstadoSolicitud.enTramite;

  /// Estados finales: la solicitud ya no avanza.
  bool get esFinal =>
      this == EstadoSolicitud.baja ||
      this == EstadoSolicitud.cancelada ||
      this == EstadoSolicitud.expirada;

  static EstadoSolicitud desdeId(int? id) {
    return EstadoSolicitud.values.firstWhere(
      (estado) => estado.id == id,
      orElse: () => EstadoSolicitud.iniciada,
    );
  }
}
