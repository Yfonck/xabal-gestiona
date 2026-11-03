import 'package:flutter/foundation.dart';

import 'opcion_filtro.dart';

/// Opciones de filtro devueltas por `/api/bajas/filters/`.
///
/// El backend devuelve las claves `tipos_baja` y `causas_baja`; se aceptan
/// también `tipos` y `causas` por compatibilidad con versiones anteriores.
@immutable
class FiltrosBaja {
  const FiltrosBaja({
    this.estados = const [],
    this.tipos = const [],
    this.causas = const [],
    this.estructuras = const [],
  });

  final List<OpcionFiltro> estados;
  final List<OpcionFiltro> tipos;
  final List<OpcionFiltro> causas;
  final List<OpcionFiltro> estructuras;

  factory FiltrosBaja.fromJson(Map<String, dynamic> json) {
    return FiltrosBaja(
      estados: _lista(json['estados']),
      tipos: _lista(json['tipos_baja'] ?? json['tipos']),
      causas: _lista(json['causas_baja'] ?? json['causas']),
      estructuras: _lista(json['estructuras']),
    );
  }

  static List<OpcionFiltro> _lista(dynamic valor) {
    if (valor is! List) return const [];
    return valor
        .whereType<Map>()
        .map((e) => OpcionFiltro.fromJson(Map<String, dynamic>.from(e)))
        .toList(growable: false);
  }
}
