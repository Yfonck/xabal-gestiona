import 'package:flutter_test/flutter_test.dart';
import 'package:xabal_gestiona/models/paginated_response.dart';

void main() {
  group('PaginatedResponse.fromJson', () {
    test('lee la estructura real de /api/bajas/', () {
      final pagina = PaginatedResponse<int>.fromJson(
        {
          'count': 42,
          'page': 2,
          'page_size': 20,
          'total_pages': 3,
          'next': '?page=3&page_size=20',
          'previous': '?page=1&page_size=20',
          'results': [
            {'id': 1},
            {'id': 2},
          ],
        },
        (json) => json['id'] as int,
      );

      expect(pagina.count, 42);
      expect(pagina.page, 2);
      expect(pagina.pageSize, 20);
      expect(pagina.totalPages, 3);
      expect(pagina.hayMas, isTrue);
      expect(pagina.results, [1, 2]);
    });

    test('acepta una lista simple sin metadatos', () {
      final pagina = PaginatedResponse<String>.fromJson(
        [
          {'nombre': 'a'},
          {'nombre': 'b'},
        ],
        (json) => json['nombre'] as String,
      );

      expect(pagina.count, 2);
      expect(pagina.totalPages, 1);
      expect(pagina.hayMas, isFalse);
      expect(pagina.results, ['a', 'b']);
    });

    test('calcula total_pages cuando el backend no lo envía', () {
      final pagina = PaginatedResponse<int>.fromJson(
        {
          'count': 25,
          'page_size': 10,
          'results': [],
        },
        (json) => 0,
      );

      expect(pagina.totalPages, 3);
    });

    test('está vacía cuando no hay resultados', () {
      final pagina = PaginatedResponse<int>.fromJson(
        {'count': 0, 'results': <dynamic>[]},
        (json) => 0,
      );

      expect(pagina.vacio, isTrue);
      expect(pagina.hayMas, isFalse);
    });
  });
}
