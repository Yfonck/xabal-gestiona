import 'package:flutter/material.dart';

import '../models/estado_solicitud.dart';

/// Badge del estado de una solicitud (HU03, HU05 y HU06).
class EstadoBadge extends StatelessWidget {
  const EstadoBadge({
    super.key,
    required this.estado,
    this.compacto = false,
  });

  final EstadoSolicitud estado;
  final bool compacto;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compacto ? 8 : 10,
        vertical: compacto ? 3 : 4,
      ),
      decoration: BoxDecoration(
        color: estado.colorFondo,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        estado.etiqueta,
        style: TextStyle(
          fontSize: compacto ? 11 : 11.5,
          fontWeight: FontWeight.w600,
          color: estado.color,
        ),
      ),
    );
  }
}
