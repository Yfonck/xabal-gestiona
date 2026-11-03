import 'package:flutter/foundation.dart';

/// Respuesta paginada del backend Gestiona.
///
/// Estructura real de `data` en los listados:
/// `{count, page, page_size, total_pages, next, previous, results}`.
@immutable
class PaginatedResponse<T> {
  const PaginatedResponse({
    required this.results,
    required this.count,
    this.page = 1,
    this.pageSize = 20,
    this.totalPages = 1,
    this.next,
    this.previous,
  });

  final List<T> results;
  final int count;
  final int page;
  final int pageSize;
  final int totalPages;
  final String? next;
  final String? previous;

  bool get hayMas => next != null;

  bool get vacio => results.isEmpty;

  /// Construye la página a partir del objeto `data` del backend.
  ///
  /// Tolera respuestas sin metadatos de paginación (listas simples).
  factory PaginatedResponse.fromJson(
    dynamic json,
    T Function(Map<String, dynamic> json) itemBuilder,
  ) {
    if (json is List) {
      final items = json
          .whereType<Map>()
          .map((e) => itemBuilder(Map<String, dynamic>.from(e)))
          .toList(growable: false);
      return PaginatedResponse<T>(
        results: items,
        count: items.length,
        pageSize: items.length,
        totalPages: 1,
      );
    }

    if (json is Map) {
      final crudos = (json['results'] as List<dynamic>?) ?? const <dynamic>[];
      final items = crudos
          .whereType<Map>()
          .map((e) => itemBuilder(Map<String, dynamic>.from(e)))
          .toList(growable: false);
      final cantidad = _entero(json['count']) ?? items.length;
      final tamano = _entero(json['page_size']) ?? items.length;
      final pagina = _entero(json['page']) ?? 1;
      return PaginatedResponse<T>(
        results: items,
        count: cantidad,
        page: pagina,
        pageSize: tamano,
        totalPages: _entero(json['total_pages']) ??
            (tamano > 0 ? (cantidad / tamano).ceil() : 1),
        next: json['next']?.toString(),
        previous: json['previous']?.toString(),
      );
    }

    return PaginatedResponse<T>(
      results: const <Never>[],
      count: 0,
    );
  }

  static int? _entero(dynamic valor) {
    if (valor is int) return valor;
    if (valor is num) return valor.toInt();
    return int.tryParse(valor?.toString() ?? '');
  }
}
