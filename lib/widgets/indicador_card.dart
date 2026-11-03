import 'package:flutter/material.dart';

import '../config/theme.dart';

/// Tarjeta indicadora del panel principal (HU02).
///
/// Fondo gris claro, borde superior de color, ícono en la esquina y el total
/// en grande, tal como en el diseño.
class IndicadorCard extends StatelessWidget {
  const IndicadorCard({
    super.key,
    required this.titulo,
    required this.valor,
    required this.icono,
    required this.color,
    this.onTap,
  });

  final String titulo;
  final String valor;
  final IconData icono;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final contenido = ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Material(
        color: AppPalette.inputFill,
        child: InkWell(
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(height: 4, color: color),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                  child: Stack(
                    children: [
                      Align(
                        alignment: Alignment.topRight,
                        child: Icon(icono, color: color, size: 26),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Spacer(),
                          Text(
                            valor,
                            style: const TextStyle(
                              fontSize: 34,
                              fontWeight: FontWeight.w600,
                              color: AppPalette.textSecondary,
                              height: 1,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            titulo,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                              color: AppPalette.textSecondary,
                              height: 1.25,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    return contenido;
  }
}
