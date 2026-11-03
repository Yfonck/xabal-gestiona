import 'package:flutter/foundation.dart';

/// Notificación del usuario (`/api/notificaciones/`).
@immutable
class Notificacion {
  const Notificacion({
    required this.id,
    required this.titulo,
    required this.mensaje,
    this.idUsuario,
    this.leida = false,
    this.fechaCreacion,
    this.link,
  });

  final int id;
  final String titulo;
  final String mensaje;
  final String? idUsuario;
  final bool leida;
  final DateTime? fechaCreacion;
  final String? link;

  factory Notificacion.fromJson(Map<String, dynamic> json) {
    return Notificacion(
      id: _int(json['id']) ?? 0,
      titulo: (json['titulo'] ?? '').toString(),
      mensaje: (json['mensaje'] ?? '').toString(),
      idUsuario: json['id_usuario']?.toString(),
      leida: json['leida'] == true,
      fechaCreacion: DateTime.tryParse(json['fecha_creacion']?.toString() ?? ''),
      link: json['link']?.toString(),
    );
  }

  static int? _int(dynamic valor) {
    if (valor is int) return valor;
    if (valor is num) return valor.toInt();
    return int.tryParse(valor?.toString() ?? '');
  }
}
