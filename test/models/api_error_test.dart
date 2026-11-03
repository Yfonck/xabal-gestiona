import 'package:flutter_test/flutter_test.dart';
import 'package:xabal_gestiona/models/api_error.dart';

void main() {
  group('ApiException.fromBody', () {
    test('extrae el sobre de error del backend', () {
      final error = ApiException.fromBody(
        {
          'success': false,
          'error': {'code': 'UNAUTHORIZED', 'message': 'Credenciales inválidas'},
        },
        statusCode: 401,
      );

      expect(error.codigo, 'UNAUTHORIZED');
      expect(error.mensaje, 'Credenciales inválidas');
      expect(error.esNoAutorizado, isTrue);
    });

    test('extrae el primer error de validación DRF', () {
      final error = ApiException.fromBody(
        {
          'id_persona': ['Este campo es obligatorio.'],
        },
        statusCode: 400,
      );

      expect(error.mensaje, 'Este campo es obligatorio.');
      expect(error.codigo, 'ERROR');
    });

    test('usa un mensaje genérico cuando el cuerpo está vacío', () {
      final error = ApiException.fromBody(null, statusCode: 500);

      expect(error.mensaje, contains('error inesperado'));
    });

    test('detecta rate limit por código o estado', () {
      const porEstado = ApiException(
        mensaje: 'Demasiados intentos',
        statusCode: 429,
        retryAfterSeconds: 30,
      );
      const porCodigo = ApiException(
        mensaje: 'Demasiados intentos',
        codigo: 'RATE_LIMITED',
      );

      expect(porEstado.esRateLimited, isTrue);
      expect(porEstado.retryAfterSeconds, 30);
      expect(porCodigo.esRateLimited, isTrue);
    });
  });
}
