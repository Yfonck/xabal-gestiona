import 'package:flutter/foundation.dart';

import 'estado_solicitud.dart';

/// Conteo de solicitudes por estado.
@immutable
class ConteoPorEstado {
  const ConteoPorEstado({required this.estado, required this.cantidad});

  final EstadoSolicitud estado;
  final int cantidad;

  factory ConteoPorEstado.fromJson(Map<String, dynamic> json) {
    return ConteoPorEstado(
      estado: EstadoSolicitud.desdeId(_int(json['id_estado'])),
      cantidad: _int(json['cantidad']) ?? 0,
    );
  }

  static int? _int(dynamic valor) {
    if (valor is int) return valor;
    if (valor is num) return valor.toInt();
    return int.tryParse(valor?.toString() ?? '');
  }
}

/// Conteo de solicitudes agrupadas por tipo o causa.
@immutable
class ConteoAgrupado {
  const ConteoAgrupado({
    required this.etiqueta,
    required this.cantidad,
    this.id,
  });

  final String etiqueta;
  final int cantidad;
  final int? id;

  factory ConteoAgrupado.fromJson(Map<String, dynamic> json) {
    final id = ConteoPorEstado._int(json['id_tipo'] ?? json['id_causa']);
    return ConteoAgrupado(
      id: id,
      etiqueta: (json['tipo'] ?? json['causa'] ?? 'Desconocido').toString(),
      cantidad: ConteoPorEstado._int(json['cantidad']) ?? 0,
    );
  }
}

/// Estadísticas del panel principal (`/api/bajas/estadisticas/`).
@immutable
class EstadisticasBaja {
  const EstadisticasBaja({
    this.totalSolicitudes = 0,
    this.personasEnBaja = 0,
    this.porEstado = const [],
    this.porTipo = const [],
    this.porCausa = const [],
  });

  final int totalSolicitudes;
  final int personasEnBaja;
  final List<ConteoPorEstado> porEstado;
  final List<ConteoAgrupado> porTipo;
  final List<ConteoAgrupado> porCausa;

  /// Cantidad de solicitudes en un estado concreto.
  int cantidadDe(EstadoSolicitud estado) {
    for (final conteo in porEstado) {
      if (conteo.estado == estado) return conteo.cantidad;
    }
    return 0;
  }

  int get enTramite => cantidadDe(EstadoSolicitud.enTramite);
  int get finalizadas => cantidadDe(EstadoSolicitud.finalizada);
  int get bajas => cantidadDe(EstadoSolicitud.baja);

  factory EstadisticasBaja.fromJson(Map<String, dynamic> json) {
    final estados = (json['por_estado'] as List<dynamic>?) ?? const [];
    final tipos = (json['por_tipo'] as List<dynamic>?) ?? const [];
    final causas = (json['por_causa'] as List<dynamic>?) ?? const [];

    return EstadisticasBaja(
      totalSolicitudes: ConteoPorEstado._int(json['total_solicitudes']) ?? 0,
      personasEnBaja: ConteoPorEstado._int(json['personas_en_baja']) ?? 0,
      porEstado: estados
          .whereType<Map>()
          .map((e) => ConteoPorEstado.fromJson(Map<String, dynamic>.from(e)))
          .toList(growable: false),
      porTipo: tipos
          .whereType<Map>()
          .map((e) => ConteoAgrupado.fromJson(Map<String, dynamic>.from(e)))
          .toList(growable: false),
      porCausa: causas
          .whereType<Map>()
          .map((e) => ConteoAgrupado.fromJson(Map<String, dynamic>.from(e)))
          .toList(growable: false),
    );
  }
}
