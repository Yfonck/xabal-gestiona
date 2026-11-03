import 'package:flutter/foundation.dart';

import 'usuario.dart';

/// Resultado de un inicio de sesión exitoso.
@immutable
class SesionIniciada {
  const SesionIniciada({
    required this.usuario,
    required this.access,
    required this.refresh,
  });

  final Usuario usuario;
  final String access;
  final String refresh;
}
