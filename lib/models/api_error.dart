import 'package:flutter/foundation.dart';

/// Error de negocio o de red devuelto por la API de Gestiona.
///
/// El backend responde `{success: false, error: {code, message}}`; cualquier
/// otro formato se normaliza aquí para que las capas superiores solo manejen
/// [ApiException].
@immutable
class ApiException implements Exception {
  const ApiException({
    required this.mensaje,
    this.codigo = 'ERROR',
    this.statusCode,
    this.retryAfterSeconds,
  });

  final String mensaje;
  final String codigo;
  final int? statusCode;

  /// Segundos de espera cuando el backend responde 429.
  final int? retryAfterSeconds;

  /// La sesión dejó de ser válida (refresh inválido o revocado).
  bool get esSesionExpirada =>
      codigo == 'SESSION_ENDED_ELSEWHERE' ||
      codigo == 'TOKEN_INVALID' ||
      codigo == 'UNAUTHORIZED' && statusCode == 401;

  bool get esNoAutorizado => statusCode == 401;

  bool get esRateLimited => statusCode == 429 || codigo == 'RATE_LIMITED';

  bool get esSinConexion => codigo == 'NETWORK_ERROR' || codigo == 'TIMEOUT';

  /// Extrae el mensaje de cualquier cuerpo de error del backend.
  factory ApiException.fromBody(dynamic body, {int? statusCode}) {
    String? codigo;
    String? mensaje;

    if (body is Map) {
      final error = body['error'];
      if (error is Map) {
        codigo = error['code']?.toString();
        mensaje = error['message']?.toString();
      } else if (error is String) {
        mensaje = error;
      }
      mensaje ??= body['detail']?.toString() ?? body['message']?.toString();
      // Errores de validación DRF: {"campo": ["mensaje"]}
      if (mensaje == null) {
        for (final entrada in body.entries) {
          final valor = entrada.value;
          if (valor is List && valor.isNotEmpty) {
            mensaje = valor.first.toString();
            break;
          }
          if (valor is String && valor.isNotEmpty) {
            mensaje = valor;
            break;
          }
        }
      }
    } else if (body is String && body.trim().isNotEmpty) {
      mensaje = body;
    }

    return ApiException(
      mensaje: mensaje ?? 'Ocurrió un error inesperado. Intente nuevamente.',
      codigo: codigo ?? 'ERROR',
      statusCode: statusCode,
    );
  }

  @override
  String toString() => 'ApiException($codigo, $statusCode): $mensaje';
}
