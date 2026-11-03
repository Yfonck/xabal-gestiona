import 'package:flutter/foundation.dart';

/// Usuario autenticado según `GET /api/auth/me/` y `POST /api/auth/login/`.
@immutable
class Usuario {
  const Usuario({
    required this.nombreUsuario,
    this.esAdmin = false,
    this.esDirectivo = false,
    this.permisoRrhh = false,
    this.enBaja = false,
    this.fotoBase64,
    this.idPersona,
    this.primerNombre,
    this.segundoNombre,
    this.primerApellido,
    this.segundoApellido,
    this.carnetIdentidad,
    this.idEstructura,
    this.nombreEstructura,
    this.nombreResponsabilidad,
    this.nombreRolUniversitario,
    this.estructuras = const <int>[],
  });

  final String nombreUsuario;
  final bool esAdmin;
  final bool esDirectivo;
  final bool permisoRrhh;
  final bool enBaja;

  /// Foto en formato `data:image/...;base64,<datos>` (puede ser nula).
  final String? fotoBase64;

  final String? idPersona;
  final String? primerNombre;
  final String? segundoNombre;
  final String? primerApellido;
  final String? segundoApellido;
  final String? carnetIdentidad;
  final int? idEstructura;
  final String? nombreEstructura;
  final String? nombreResponsabilidad;
  final String? nombreRolUniversitario;
  final List<int> estructuras;

  factory Usuario.fromJson(Map<String, dynamic> json) {
    return Usuario(
      nombreUsuario: (json['username'] ?? '').toString(),
      esAdmin: json['is_admin'] == true,
      esDirectivo: json['is_directivo'] == true,
      permisoRrhh: json['permiso_rrhh'] == true,
      enBaja: json['en_baja'] == true,
      fotoBase64: _textoONulo(json['foto_base64']),
      idPersona: _textoONulo(json['id_persona']),
      primerNombre: _textoONulo(json['primer_nombre']),
      segundoNombre: _textoONulo(json['segundo_nombre']),
      primerApellido: _textoONulo(json['primer_apellido']),
      segundoApellido: _textoONulo(json['segundo_apellido']),
      carnetIdentidad: _textoONulo(json['carnet_identidad']),
      idEstructura: _enteroONulo(json['id_estructura']),
      nombreEstructura: _textoONulo(json['nombre_estructura']),
      nombreResponsabilidad: _textoONulo(json['nombre_responsabilidad']),
      nombreRolUniversitario: _textoONulo(json['nombre_rol_universitario']),
      estructuras: (json['estructuras'] as List<dynamic>?)
              ?.map(_enteroONulo)
              .whereType<int>()
              .toList(growable: false) ??
          const <int>[],
    );
  }

  /// Nombre y apellidos; si no hay datos de persona usa el usuario.
  String get nombreCompleto {
    final partes = [
      primerNombre,
      segundoNombre,
      primerApellido,
      segundoApellido,
    ].whereType<String>().where((p) => p.trim().isNotEmpty).toList();
    return partes.isEmpty ? nombreUsuario : partes.join(' ');
  }

  /// Iniciales para el avatar (máximo dos letras).
  String get iniciales {
    final fuente = nombreCompleto.trim();
    if (fuente.isEmpty) return '?';
    final palabras = fuente.split(RegExp(r'\s+'));
    if (palabras.length == 1) {
      return palabras.first.substring(0, 1).toUpperCase();
    }
    return (palabras.first.substring(0, 1) +
            palabras.last.substring(0, 1))
        .toUpperCase();
  }

  /// Etiqueta legible del rol principal del usuario.
  String get rol {
    if (esAdmin) return 'Administrador';
    if (permisoRrhh) return 'Recursos Humanos';
    if (esDirectivo) return 'Directivo';
    return 'Usuario';
  }

  static String? _textoONulo(dynamic valor) {
    if (valor == null) return null;
    final texto = valor.toString().trim();
    return texto.isEmpty ? null : texto;
  }

  static int? _enteroONulo(dynamic valor) {
    if (valor is int) return valor;
    if (valor is num) return valor.toInt();
    return int.tryParse(valor?.toString() ?? '');
  }
}
