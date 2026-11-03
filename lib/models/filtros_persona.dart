import 'package:flutter/foundation.dart';

import 'opcion_filtro.dart';

/// Opciones de filtro devueltas por `/api/personas/filters/`.
@immutable
class FiltrosPersona {
  const FiltrosPersona({this.estructuras = const []});

  final List<OpcionFiltro> estructuras;

  factory FiltrosPersona.fromJson(Map<String, dynamic> json) {
    final estructuras = json['estructuras'];
    if (estructuras is! List) return const FiltrosPersona();

    return FiltrosPersona(
      estructuras: estructuras
          .whereType<Map>()
          .map(
            (e) => OpcionFiltro(
              valor: (e['id_estructura'] ?? '').toString(),
              etiqueta: (e['nombre_estructura'] ?? '').toString(),
            ),
          )
          .where((o) => o.id != null)
          .toList(growable: false),
    );
  }
}
