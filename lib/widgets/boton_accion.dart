import 'package:flutter/material.dart';

/// Botón cuadrado de acciones rápidas (ver, editar, eliminar).
///
/// Se usa en los listados de solicitudes y bajas pendientes para reproducir
/// los botones de colores del diseño de Figma.
class BotonAccion extends StatelessWidget {
  const BotonAccion({
    super.key,
    required this.icono,
    required this.color,
    required this.tooltip,
    required this.onTap,
    this.tamano = 32,
  });

  final IconData icono;
  final Color color;
  final String tooltip;
  final VoidCallback onTap;
  final double tamano;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: tamano,
          height: tamano,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icono, color: Colors.white, size: tamano * 0.6),
        ),
      ),
    );
  }
}
