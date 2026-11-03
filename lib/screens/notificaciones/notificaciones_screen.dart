import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../config/theme.dart';
import '../../models/notificacion.dart';
import '../../providers/notificacion_provider.dart';
import '../../widgets/confirm_dialog.dart';

/// HU10 — Centro de notificaciones.
class NotificacionesScreen extends StatefulWidget {
  const NotificacionesScreen({super.key});

  @override
  State<NotificacionesScreen> createState() => _NotificacionesScreenState();
}

class _NotificacionesScreenState extends State<NotificacionesScreen> {
  static final DateFormat _formatoFecha = DateFormat('dd/MM/yyyy HH:mm');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotificacionProvider>().cargar();
    });
  }

  Future<void> _marcarLeida(Notificacion notificacion) async {
    try {
      await context.read<NotificacionProvider>().marcarLeida(notificacion);
    } catch (_) {
      _avisar('No se pudo marcar la notificación como leída.');
    }
  }

  Future<void> _eliminar(Notificacion notificacion) async {
    final confirmar = await mostrarConfirmacion(
      context,
      titulo: 'Eliminar notificación',
      mensaje: '¿Está seguro que desea eliminar este registro? '
          'Esta acción no se puede deshacer.',
    );
    if (!confirmar || !mounted) return;

    try {
      await context.read<NotificacionProvider>().eliminar(notificacion.id);
    } catch (_) {
      _avisar('No se pudo eliminar la notificación.');
    }
  }

  Future<void> _limpiarTodas() async {
    final confirmar = await mostrarConfirmacion(
      context,
      titulo: 'Eliminar todas',
      mensaje: '¿Desea eliminar todas las notificaciones? '
          'Esta acción no se puede deshacer.',
    );
    if (!confirmar || !mounted) return;

    try {
      await context.read<NotificacionProvider>().limpiarTodas();
    } catch (_) {
      _avisar('No se pudieron eliminar las notificaciones.');
    }
  }

  void _avisar(String mensaje) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(mensaje)));
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<NotificacionProvider>();

    return Scaffold(
      backgroundColor: AppPalette.surface,
      appBar: AppBar(
        title: const Text('Notificaciones'),
        actions: [
          if (provider.notificaciones.isNotEmpty)
            IconButton(
              tooltip: 'Eliminar todas',
              onPressed: _limpiarTodas,
              icon: const Icon(Icons.delete_sweep_outlined),
            ),
        ],
      ),
      body: _cuerpo(provider),
    );
  }

  Widget _cuerpo(NotificacionProvider provider) {
    if (provider.cargando && provider.notificaciones.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.errorMessage != null && provider.notificaciones.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off_outlined,
                  size: 48, color: AppPalette.error),
              const SizedBox(height: 12),
              Text(provider.errorMessage!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: () => provider.cargar(),
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }

    if (provider.notificaciones.isEmpty) {
      return const _EstadoVacio();
    }

    return RefreshIndicator(
      onRefresh: provider.cargar,
      color: AppPalette.primary,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: provider.notificaciones.length,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final notificacion = provider.notificaciones[index];
          return _TarjetaNotificacion(
            notificacion: notificacion,
            fecha: notificacion.fechaCreacion == null
                ? ''
                : _formatoFecha.format(notificacion.fechaCreacion!),
            onMarcarLeida: () => _marcarLeida(notificacion),
            onEliminar: () => _eliminar(notificacion),
          );
        },
      ),
    );
  }
}

class _TarjetaNotificacion extends StatelessWidget {
  const _TarjetaNotificacion({
    required this.notificacion,
    required this.fecha,
    required this.onMarcarLeida,
    required this.onEliminar,
  });

  final Notificacion notificacion;
  final String fecha;
  final VoidCallback onMarcarLeida;
  final VoidCallback onEliminar;

  @override
  Widget build(BuildContext context) {
    final sinLeer = !notificacion.leida;

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 6, 12),
      decoration: BoxDecoration(
        color: sinLeer ? AppPalette.primarySoft.withValues(alpha: 0.45) : AppPalette.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppPalette.outline),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: sinLeer ? AppPalette.primary : AppPalette.outline,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  notificacion.titulo,
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w600,
                    color: AppPalette.textPrimary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  notificacion.mensaje,
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.35,
                    color: AppPalette.textSecondary,
                  ),
                ),
                if (fecha.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    fecha,
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: AppPalette.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          PopupMenuButton<String>(
            tooltip: 'Acciones',
            icon: const Icon(Icons.more_vert, color: AppPalette.textSecondary),
            onSelected: (accion) {
              if (accion == 'leer') onMarcarLeida();
              if (accion == 'eliminar') onEliminar();
            },
            itemBuilder: (context) => [
              if (sinLeer)
                const PopupMenuItem(
                  value: 'leer',
                  child: Text('Marcar como leído'),
                ),
              const PopupMenuItem(
                value: 'eliminar',
                child: Text('Eliminar'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EstadoVacio extends StatelessWidget {
  const _EstadoVacio();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.notifications_off_outlined,
              size: 56, color: AppPalette.outline),
          SizedBox(height: 12),
          Text(
            'No tiene notificaciones',
            style: TextStyle(color: AppPalette.textSecondary),
          ),
        ],
      ),
    );
  }
}
