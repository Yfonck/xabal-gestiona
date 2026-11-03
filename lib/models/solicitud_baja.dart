import 'package:flutter/foundation.dart';

import 'estado_solicitud.dart';

/// Solicitud de baja según `/api/bajas/` y `/api/bajas/{id}/`.
@immutable
class SolicitudBaja {
  const SolicitudBaja({
    required this.idSolicitud,
    required this.idEstadoSolicitud,
    this.idPersonaResponsable,
    this.idPersonaSolicitante,
    this.fechaRegistro,
    this.idTipoBaja,
    this.idCausaBaja,
    this.activo = true,
    this.nombreSolicitanteCompleto,
    this.ciSolicitante,
    this.nombreResponsable,
    this.carnetIdentidad,
    this.idEstructura,
    this.nombreEstructura,
    this.nombreTipoBaja,
    this.nombreCausaBaja,
    this.nombreEstadoSolicitud,
    this.fotoSolicitante,
    this.fotoResponsable,
    this.usuarioSolicitante,
    this.solapinSolicitante,
    this.caducidadSolicitante,
    this.rolSolicitante,
    this.responsabilidadSolicitante,
    this.fechaPlantillaSolicitante,
    this.nombreEstructuraSolicitante,
    this.usuarioResponsable,
    this.solapinResponsable,
    this.caducidadResponsable,
    this.rolResponsable,
    this.responsabilidadResponsable,
    this.fechaPlantillaResponsable,
    this.nombreEstructuraResponsable,
    this.fechaBaja,
  });

  final int idSolicitud;
  final int idEstadoSolicitud;
  final String? idPersonaResponsable;
  final String? idPersonaSolicitante;
  final DateTime? fechaRegistro;
  final int? idTipoBaja;
  final int? idCausaBaja;
  final bool activo;

  /// Solicitante: quien inicia el trámite.
  final String? nombreSolicitanteCompleto;
  final String? ciSolicitante;

  /// Responsable: la persona que se da de baja.
  final String? nombreResponsable;
  final String? carnetIdentidad;
  final int? idEstructura;
  final String? nombreEstructura;

  final String? nombreTipoBaja;
  final String? nombreCausaBaja;
  final String? nombreEstadoSolicitud;

  /// Fotos en `data:image/jpeg;base64,...` (solo en listados).
  final String? fotoSolicitante;
  final String? fotoResponsable;

  // Datos ampliados del detalle (HU06). Todos son opcionales para que el
  // listado siga funcionando aunque el backend no los envíe.

  final String? usuarioSolicitante;
  final String? solapinSolicitante;
  final String? caducidadSolicitante;
  final String? rolSolicitante;
  final String? responsabilidadSolicitante;
  final DateTime? fechaPlantillaSolicitante;
  final String? nombreEstructuraSolicitante;

  final String? usuarioResponsable;
  final String? solapinResponsable;
  final String? caducidadResponsable;
  final String? rolResponsable;
  final String? responsabilidadResponsable;
  final DateTime? fechaPlantillaResponsable;
  final String? nombreEstructuraResponsable;

  final DateTime? fechaBaja;

  EstadoSolicitud get estado => EstadoSolicitud.desdeId(idEstadoSolicitud);

  factory SolicitudBaja.fromJson(Map<String, dynamic> json) {
    final solicitante = json['solicitante'] is Map
        ? Map<String, dynamic>.from(json['solicitante'] as Map)
        : const <String, dynamic>{};
    final responsable = json['responsable'] is Map
        ? Map<String, dynamic>.from(json['responsable'] as Map)
        : const <String, dynamic>{};

    return SolicitudBaja(
      idSolicitud: _entero(json['id_solicitud']) ?? 0,
      idEstadoSolicitud: _entero(json['id_estado_solicitud']) ?? 1,
      idPersonaResponsable: _texto(json['id_persona_responsable']),
      idPersonaSolicitante: _texto(json['id_persona_solicitante']),
      fechaRegistro: _fecha(json['fecha_registro']),
      idTipoBaja: _entero(json['id_tipo_baja']),
      idCausaBaja: _entero(json['id_causa_baja']),
      activo: json['activo'] != false,
      nombreSolicitanteCompleto:
          _texto(solicitante['nombre_completo']) ??
          _componerDesdeMapa(solicitante) ??
          _texto(json['nombre_solicitante_completo']) ??
          _componerSolicitante(json),
      ciSolicitante: _texto(
        solicitante['carnet_identidad'] ?? json['ci_solicitante'],
      ),
      nombreResponsable:
          _texto(responsable['nombre_completo']) ??
          _componerDesdeMapa(responsable) ??
          _texto(json['nombre_responsable']) ??
          _componerResponsable(json),
      carnetIdentidad: _texto(
        responsable['carnet_identidad'] ?? json['carnet_identidad'],
      ),
      idEstructura: _entero(json['id_estructura']),
      nombreEstructura: _texto(json['nombre_estructura']),
      nombreTipoBaja: _texto(json['nombre_tipo_baja']),
      nombreCausaBaja: _texto(json['nombre_causa_baja']),
      nombreEstadoSolicitud:
          _texto(json['nombre_estado_solicitud']) ??
          _texto(json['estado_display']),
      fotoSolicitante: _texto(
        solicitante['foto_base64'] ?? json['foto_solicitante'],
      ),
      fotoResponsable: _texto(
        responsable['foto_base64'] ?? json['foto_responsable'],
      ),
      usuarioSolicitante: _texto(
        solicitante['username'] ??
            solicitante['usuario'] ??
            json['usuario_solicitante'] ??
            json['username_solicitante'],
      ),
      solapinSolicitante: _texto(
        solicitante['numero_solapin'] ??
            solicitante['solapin'] ??
            json['solapin_solicitante'] ??
            json['numero_solapin_solicitante'],
      ),
      caducidadSolicitante: _texto(
        solicitante['numero_caducidad'] ??
            solicitante['caducidad'] ??
            json['caducidad_solicitante'] ??
            json['numero_caducidad_solicitante'],
      ),
      rolSolicitante: _texto(
        solicitante['nombre_rol_universitario'] ??
            solicitante['rol_universitario'] ??
            solicitante['categoria'] ??
            json['rol_solicitante'] ??
            json['nombre_rol_solicitante'],
      ),
      responsabilidadSolicitante: _texto(
        solicitante['nombre_responsabilidad'] ??
            solicitante['responsabilidad'] ??
            json['responsabilidad_solicitante'] ??
            json['nombre_responsabilidad_solicitante'],
      ),
      fechaPlantillaSolicitante: _fecha(
        solicitante['fecha_plantilla'] ??
            solicitante['fecha_alta'] ??
            solicitante['fecha_registro'] ??
            json['fecha_plantilla_solicitante'],
      ),
      nombreEstructuraSolicitante: _texto(
        solicitante['nombre_estructura'] ??
            json['nombre_estructura_solicitante'],
      ),
      usuarioResponsable: _texto(
        responsable['username'] ??
            responsable['usuario'] ??
            json['usuario_responsable'] ??
            json['username_responsable'],
      ),
      solapinResponsable: _texto(
        responsable['numero_solapin'] ??
            responsable['solapin'] ??
            json['solapin_responsable'] ??
            json['numero_solapin_responsable'],
      ),
      caducidadResponsable: _texto(
        responsable['numero_caducidad'] ??
            responsable['caducidad'] ??
            json['caducidad_responsable'] ??
            json['numero_caducidad_responsable'],
      ),
      rolResponsable: _texto(
        responsable['nombre_rol_universitario'] ??
            responsable['rol_universitario'] ??
            responsable['categoria'] ??
            json['rol_responsable'] ??
            json['nombre_rol_responsable'],
      ),
      responsabilidadResponsable: _texto(
        responsable['nombre_responsabilidad'] ??
            responsable['responsabilidad'] ??
            json['responsabilidad_responsable'] ??
            json['nombre_responsabilidad_responsable'],
      ),
      fechaPlantillaResponsable: _fecha(
        responsable['fecha_plantilla'] ??
            responsable['fecha_alta'] ??
            responsable['fecha_registro'] ??
            json['fecha_plantilla_responsable'],
      ),
      nombreEstructuraResponsable: _texto(
        responsable['nombre_estructura'] ??
            json['nombre_estructura_responsable'] ??
            json['nombre_estructura'],
      ),
      fechaBaja: _fecha(json['fecha_baja'] ?? json['fecha_baja_efectiva']),
    );
  }

  /// Compone el nombre desde un objeto anidado con nombres/apellidos.
  static String? _componerDesdeMapa(Map<String, dynamic> json) {
    final apellidos = [
      json['primer_apellido'],
      json['segundo_apellido'],
      json['apellido'],
      json['apellidos'],
    ].whereType<String>().where((p) => p.trim().isNotEmpty).join(' ');
    final nombres = [
      json['primer_nombre'],
      json['segundo_nombre'],
      json['nombre'],
      json['nombres'],
    ].whereType<String>().where((p) => p.trim().isNotEmpty).join(' ');
    if (apellidos.isEmpty && nombres.isEmpty) return null;
    return apellidos.isEmpty
        ? nombres
        : (nombres.isEmpty ? apellidos : '$apellidos, $nombres');
  }

  static String? _componerSolicitante(Map<String, dynamic> json) {
    final apellidos = [
      json['apellido_solicitante'],
      json['segundo_apellido_solicitante'],
    ].whereType<String>().where((p) => p.trim().isNotEmpty).join(' ');
    final nombres = [
      json['nombre_solicitante'],
      json['segundo_nombre_solicitante'],
    ].whereType<String>().where((p) => p.trim().isNotEmpty).join(' ');
    if (apellidos.isEmpty && nombres.isEmpty) return null;
    return apellidos.isEmpty
        ? nombres
        : (nombres.isEmpty ? apellidos : '$apellidos, $nombres');
  }

  static String? _componerResponsable(Map<String, dynamic> json) {
    final apellidos = [
      json['primer_apellido'],
      json['segundo_apellido'],
    ].whereType<String>().where((p) => p.trim().isNotEmpty).join(' ');
    final nombres = [
      json['primer_nombre'],
      json['segundo_nombre'],
    ].whereType<String>().where((p) => p.trim().isNotEmpty).join(' ');
    if (apellidos.isEmpty && nombres.isEmpty) return null;
    return apellidos.isEmpty
        ? nombres
        : (nombres.isEmpty ? apellidos : '$apellidos, $nombres');
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

  static DateTime? _fecha(dynamic valor) {
    if (valor == null) return null;
    return DateTime.tryParse(valor.toString());
  }
}
