import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';

/// Widget que detecta interacciones del usuario (toques) para reiniciar el
/// temporizador de inactividad de la sesión.
///
/// Debe envolver el árbol de navegación principal de la aplicación.
class InactividadListener extends StatelessWidget {
  const InactividadListener({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context, listen: false);

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () => auth.notificarInteraccion(),
      onPanDown: (_) => auth.notificarInteraccion(),
      onScaleStart: (_) => auth.notificarInteraccion(),
      child: child,
    );
  }
}
