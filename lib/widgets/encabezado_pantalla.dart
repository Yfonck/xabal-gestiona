import 'package:flutter/material.dart';

import '../config/theme.dart';
import 'decoracion_superior.dart';
import 'foto_avatar.dart';
import 'marca_xabal.dart';

/// Cabecera común de las pantallas internas (HU05, HU06 y siguientes).
///
/// Reproduce el diseño de Figma: cinta roja superior, logotipo XABAL,
/// título de la pantalla, campana de notificaciones y avatar del usuario.
class EncabezadoPantalla extends StatelessWidget {
  const EncabezadoPantalla({
    super.key,
    required this.titulo,
    required this.onAbrirMenu,
    required this.onNotificaciones,
    this.noLeidas = 0,
    this.nombreUsuario = '',
    this.fotoBase64,
    this.mostrarCampana = true,
    this.iconoAccion,
    this.onAccion,
    this.tooltipAccion,
  });

  final String titulo;
  final VoidCallback onAbrirMenu;
  final VoidCallback onNotificaciones;
  final int noLeidas;
  final String nombreUsuario;
  final String? fotoBase64;
  final bool mostrarCampana;
  final IconData? iconoAccion;
  final VoidCallback? onAccion;
  final String? tooltipAccion;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const DecoracionSuperior(altura: 64),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 10),
          child: Row(
            children: [
              const MarcaXabal(compacta: true),
              const Spacer(),
              if (mostrarCampana)
                InkWell(
                  onTap: onNotificaciones,
                  borderRadius: BorderRadius.circular(24),
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Badge(
                      isLabelVisible: noLeidas > 0,
                      label: Text(noLeidas > 9 ? '9+' : '$noLeidas'),
                      backgroundColor: AppPalette.primary,
                      child: const Icon(
                        Icons.notifications_none,
                        color: AppPalette.primary,
                        size: 28,
                      ),
                    ),
                  ),
                ),
              if (iconoAccion != null && onAccion != null) ...[
                const SizedBox(width: 4),
                IconButton(
                  tooltip: tooltipAccion,
                  onPressed: onAccion,
                  icon: Icon(iconoAccion, color: AppPalette.primary, size: 26),
                ),
              ],
              const SizedBox(width: 10),
              FotoAvatar(
                fotoBase64: fotoBase64,
                nombre: nombreUsuario,
                radio: 20,
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Container(
          color: AppPalette.outlineSoft,
          padding: const EdgeInsets.fromLTRB(8, 2, 16, 2),
          child: Row(
            children: [
              IconButton(
                tooltip: 'Abrir menú',
                onPressed: onAbrirMenu,
                icon: const Icon(Icons.menu, color: AppPalette.textPrimary),
              ),
              Expanded(
                child: Text(
                  titulo,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w600,
                    color: AppPalette.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
