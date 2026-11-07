import 'package:flutter_test/flutter_test.dart';
import 'package:xabal_gestiona/config/api_config.dart';
import 'package:xabal_gestiona/services/api_client.dart';

void main() {
  group('Cabeceras HTTP por defecto', () {
    test('ApiConfig declara la cabecera que evita el aviso de ngrok', () {
      expect(ApiConfig.headersPorDefecto['ngrok-skip-browser-warning'], 'true');
      expect(ApiConfig.headersPorDefecto['Accept'], 'application/json');
    });

    test('ApiClient envía las cabeceras por defecto en todas las peticiones',
        () {
      final cliente = ApiClient();

      expect(cliente.dio.options.headers['ngrok-skip-browser-warning'], 'true');
      expect(cliente.dio.options.headers['Accept'], 'application/json');
    });
  });
}
