import 'package:flutter/foundation.dart';

/// Opción de un catálogo o filtro: `{value, label}`.
@immutable
class OpcionFiltro {
  const OpcionFiltro({required this.valor, required this.etiqueta});

  final String valor;
  final String etiqueta;

  int? get id => int.tryParse(valor);

  factory OpcionFiltro.fromJson(Map<String, dynamic> json) {
    return OpcionFiltro(
      valor: (json['value'] ?? json['id'] ?? '').toString(),
      etiqueta: (json['label'] ?? json['nombre'] ?? '').toString(),
    );
  }

  /// Opciones con `id` numérico y sin ids repetidos.
  ///
  /// Los `DropdownButton<int?>` de la app usan `id` como `value`. Si el
  /// backend envía un `value` no numérico, `id` sería `null` y el desplegable
  /// tendría varios ítems con `value: null`; si repite ids, tendría dos ítems
  /// con el mismo `value`. En ambos casos Flutter lanza el assert
  /// `widget.items!.where(...).length == 1`.
  static List<OpcionFiltro> conIdNumericoUnico(
    Iterable<OpcionFiltro> opciones,
  ) {
    final vistos = <int>{};
    final resultado = <OpcionFiltro>[];
    for (final opcion in opciones) {
      final id = opcion.id;
      if (id == null || !vistos.add(id)) continue;
      resultado.add(opcion);
    }
    return resultado;
  }

  @override
  bool operator ==(Object other) =>
      other is OpcionFiltro && other.valor == valor;

  @override
  int get hashCode => valor.hashCode;
}
