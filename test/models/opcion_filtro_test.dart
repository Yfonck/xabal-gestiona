import 'package:flutter_test/flutter_test.dart';
import 'package:xabal_gestiona/models/opcion_filtro.dart';

void main() {
  group('OpcionFiltro.conIdNumericoUnico', () {
    test('conserva las opciones con id numérico', () {
      const opciones = [
        OpcionFiltro(valor: '1', etiqueta: 'Vicerrectoría'),
        OpcionFiltro(valor: '7', etiqueta: 'Dirección de Informatización'),
      ];

      final resultado = OpcionFiltro.conIdNumericoUnico(opciones);

      expect(resultado.map((o) => o.id), [1, 7]);
      expect(resultado.map((o) => o.etiqueta), [
        'Vicerrectoría',
        'Dirección de Informatización',
      ]);
    });

    test('descarta valores no numéricos para no duplicar el ítem nulo', () {
      const opciones = [
        OpcionFiltro(valor: 'DI', etiqueta: 'Dirección de Informatización'),
        OpcionFiltro(valor: '', etiqueta: 'Sin valor'),
        OpcionFiltro(valor: '3', etiqueta: 'Facultad 3'),
      ];

      final resultado = OpcionFiltro.conIdNumericoUnico(opciones);

      expect(resultado, hasLength(1));
      expect(resultado.single.id, 3);
    });

    test('elimina ids repetidos dejando la primera aparición', () {
      const opciones = [
        OpcionFiltro(valor: '2', etiqueta: 'Primera'),
        OpcionFiltro(valor: '2', etiqueta: 'Duplicada'),
        OpcionFiltro(valor: '5', etiqueta: 'Otra'),
      ];

      final resultado = OpcionFiltro.conIdNumericoUnico(opciones);

      expect(resultado.map((o) => o.etiqueta), ['Primera', 'Otra']);
      expect(resultado.map((o) => o.id).toSet(), {2, 5});
    });

    test('devuelve lista vacía si no hay opciones válidas', () {
      expect(OpcionFiltro.conIdNumericoUnico(const []), isEmpty);
      expect(
        OpcionFiltro.conIdNumericoUnico(const [
          OpcionFiltro(valor: 'abc', etiqueta: 'Sin id'),
        ]),
        isEmpty,
      );
    });
  });
}
