import 'package:flutter/material.dart';

import '../config/theme.dart';

/// Logotipo de XABAL Gestiona usado en el login y en las cabeceras.
///
/// El escudo se toma de la imagen oficial (`assets/images/xabal_logo1.png`)
/// y se acompaña del texto de la marca.
class MarcaXabal extends StatelessWidget {
  const MarcaXabal({super.key, this.compacta = false});

  /// Versión reducida para el AppBar de las pantallas internas.
  final bool compacta;

  static const String _rutaLogo = 'assets/images/xabal_logo1.png';

  @override
  Widget build(BuildContext context) {
    final tamanoCirculo = compacta ? 36.0 : 64.0;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: tamanoCirculo,
          height: tamanoCirculo,
          child: Image.asset(
            _rutaLogo,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.high,
            semanticLabel: 'Logotipo de XABAL Gestiona',
          ),
        ),
        SizedBox(width: compacta ? 8 : 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'XABAL',
              style: TextStyle(
                color: AppPalette.primary,
                fontSize: compacta ? 12 : 18,
                fontWeight: FontWeight.w700,
                letterSpacing: compacta ? 0.8 : 1.4,
                height: 1.1,
              ),
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'Gestiona',
                  style: TextStyle(
                    color: AppPalette.secondary,
                    fontSize: compacta ? 16 : 30,
                    fontWeight: FontWeight.w700,
                    height: 1.05,
                    letterSpacing: -0.4,
                  ),
                ),
                if (!compacta) ...[
                  const SizedBox(width: 6),
                  const Padding(
                    padding: EdgeInsets.only(bottom: 4),
                    child: Text(
                      'Sistema de Gestión\nAdministrativa',
                      style: TextStyle(
                        color: AppPalette.secondary,
                        fontSize: 8,
                        height: 1.2,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ],
    );
  }
}
