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

  @override
  bool operator ==(Object other) =>
      other is OpcionFiltro && other.valor == valor;

  @override
  int get hashCode => valor.hashCode;
}
