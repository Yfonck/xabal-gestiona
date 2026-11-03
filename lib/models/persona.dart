import 'package:flutter/foundation.dart';

/// Persona del sistema (`/api/personas/`).
@immutable
class Persona {
  const Persona({
    required this.idPersona,
    this.nombreCompleto,
    this.primerNombre,
    this.segundoNombre,
    this.primerApellido,
    this.segundoApellido,
    this.carnetIdentidad,
    this.numeroSolapin,
    this.idEstructura,
    this.nombreEstructura,
    this.nombreResponsabilidad,
    this.nombreRolUniversitario,
    this.baja = false,
    this.fotoBase64,
  });

  final String idPersona;
  final String? nombreCompleto;
  final String? primerNombre;
  final String? segundoNombre;
  final String? primerApellido;
  final String? segundoApellido;
  final String? carnetIdentidad;
  final String? numeroSolapin;
  final int? idEstructura;
  final String? nombreEstructura;
  final String? nombreResponsabilidad;
  final String? nombreRolUniversitario;
  final bool baja;
  final String? fotoBase64;

  /// La persona está activa si el backend no la marca de baja.
  bool get activa => !baja;

  String get nombre {
    final completo = nombreCompleto?.trim();
    if (completo != null && completo.isNotEmpty) return completo;
    final partes = [
      primerNombre,
      segundoNombre,
      primerApellido,
      segundoApellido,
    ].whereType<String>().where((p) => p.trim().isNotEmpty);
    return partes.isEmpty ? 'Sin nombre' : partes.join(' ');
  }

  factory Persona.fromJson(Map<String, dynamic> json) {
    return Persona(
      idPersona: (json['id_persona'] ?? '').toString(),
      nombreCompleto: _texto(json['nombre_completo']),
      primerNombre: _texto(json['primer_nombre']),
      segundoNombre: _texto(json['segundo_nombre']),
      primerApellido: _texto(json['primer_apellido']),
      segundoApellido: _texto(json['segundo_apellido']),
      carnetIdentidad: _texto(json['carnet_identidad']),
      numeroSolapin: _texto(json['numero_solapin']),
      idEstructura: _entero(json['id_estructura']),
      nombreEstructura: _texto(json['nombre_estructura']),
      nombreResponsabilidad: _texto(json['nombre_responsabilidad']),
      nombreRolUniversitario: _texto(json['nombre_rol_universitario']),
      baja: json['baja'] == true,
      fotoBase64: _texto(json['foto_base64']),
    );
  }

  static String? _texto(dynamic valor) {
    if (valor == null) return null;
    final texto = valor.toString().trim();
    return texto.isEmpty ? null : texto;
  }

  static int? _entero(dynamic valor) {
    if (valor is int) return valor;
    if (valor is num) return valor.toInt();
    return int.tryParse(valor?.toString() ?? '');
  }
}
