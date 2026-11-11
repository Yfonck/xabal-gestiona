import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../config/routes.dart';
import '../config/theme.dart';
import '../providers/auth_provider.dart';
import 'confirm_dialog.dart';
import 'foto_avatar.dart';
import 'marca_xabal.dart';

/// Menú lateral compartido por las pantallas internas.
class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key, required this.rutaActual});

  /// Ruta activa, para resaltar el elemento correspondiente.
  final String rutaActual;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final usuario = auth.usuario;

    return Drawer(
      backgroundColor: AppPalette.surface,
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 14),
              child: Row(
                children: [
                  const MarcaXabal(compacta: true),
                  const Spacer(),
                  FotoAvatar(
                    fotoBase64: usuario?.fotoBase64,
                    nombre: usuario?.nombreCompleto ?? '',
                    radio: 20,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      usuario?.nombreCompleto ?? 'Usuario',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppPalette.textPrimary,
                      ),
                    ),
                    if (usuario?.rol.isNotEmpty ?? false)
                      Text(
                        usuario!.rol,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppPalette.textSecondary,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const Divider(height: 1),
            const SizedBox(height: 8),
            _ElementoMenu(
              icono: Icons.dashboard_outlined,
              etiqueta: 'Panel principal',
              ruta: AppRoutes.panel,
              rutaActual: rutaActual,
            ),
            _ElementoMenu(
              icono: Icons.assignment_outlined,
              etiqueta: 'Solicitudes de baja',
              ruta: AppRoutes.solicitudes,
              rutaActual: rutaActual,
            ),
            _ElementoMenu(
              icono: Icons.pending_actions_outlined,
              etiqueta: 'Bajas pendientes',
              ruta: AppRoutes.bajasPendientes,
              rutaActual: rutaActual,
            ),
            _ElementoMenu(
              icono: Icons.people_outline,
              etiqueta: 'Personas',
              ruta: AppRoutes.personas,
              rutaActual: rutaActual,
            ),
            const Spacer(),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.logout, color: AppPalette.error),
              title: const Text(
                'Cerrar sesión',
                style: TextStyle(color: AppPalette.error),
              ),
              onTap: () async {
                Navigator.of(context).pop();
                final confirmar = await mostrarConfirmacion(
                  context,
                  titulo: 'Cerrar sesión',
                  mensaje: '¿Desea cerrar la sesión actual?',
                  textoCancelar: 'Cancelar',
                  textoConfirmar: 'Cerrar sesión',
                  colorConfirmar: AppPalette.error,
                );
                if (confirmar && context.mounted) {
                  await context.read<AuthProvider>().cerrarSesion();
                }
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _ElementoMenu extends StatelessWidget {
  const _ElementoMenu({
    required this.icono,
    required this.etiqueta,
    required this.ruta,
    required this.rutaActual,
  });

  final IconData icono;
  final String etiqueta;
  final String ruta;
  final String rutaActual;

  @override
  Widget build(BuildContext context) {
    final activo = rutaActual == ruta;
    return ListTile(
      leading: Icon(icono, color: activo ? AppPalette.primary : null),
      title: Text(
        etiqueta,
        style: TextStyle(
          fontWeight: activo ? FontWeight.w600 : FontWeight.w500,
          color: activo ? AppPalette.primary : AppPalette.textPrimary,
        ),
      ),
      selected: activo,
      selectedTileColor: AppPalette.primarySoft,
      onTap: () {
        Navigator.of(context).pop();
        if (!activo) {
          // Navegar tras cerrar el drawer para evitar que go_router procese
          // la ruta mientras el árbol del Scaffold/Drawer está desmontándose.
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) context.go(ruta);
          });
        }
      },
    );
  }
}
