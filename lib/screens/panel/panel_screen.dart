import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../config/routes.dart';
import '../../config/theme.dart';
import '../../models/estadisticas_baja.dart';
import '../../models/opcion_filtro.dart';
import '../../providers/auth_provider.dart';
import '../../providers/notificacion_provider.dart';
import '../../providers/panel_provider.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/decoracion_superior.dart';
import '../../widgets/foto_avatar.dart';
import '../../widgets/indicador_card.dart';
import '../../widgets/marca_xabal.dart';
import '../solicitudes/crear_solicitud_dialog.dart';

/// HU02 — Panel principal con indicadores, filtro por área y accesos.
class PanelScreen extends StatefulWidget {
  const PanelScreen({super.key});

  @override
  State<PanelScreen> createState() => _PanelScreenState();
}

class _PanelScreenState extends State<PanelScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PanelProvider>().cargar();
      context.read<NotificacionProvider>().actualizarContador();
    });
  }

  Future<void> _recargar() async {
    await context.read<PanelProvider>().cargar();
  }

  void _abrirNotificaciones() {
    context.push(AppRoutes.notificaciones);
  }

  Future<void> _crearSolicitud() async {
    final panel = context.read<PanelProvider>();
    if (panel.filtros.tipos.isEmpty || panel.filtros.causas.isEmpty) {
      await panel.cargar();
    }
    if (!mounted) return;

    if (panel.filtros.tipos.isEmpty || panel.filtros.causas.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudieron cargar los catálogos de baja.'),
        ),
      );
      return;
    }

    final creada = await mostrarCrearSolicitud(context, panel.filtros);
    if (creada != true || !mounted) return;

    await panel.cargar();
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          backgroundColor: AppPalette.success,
          duration: const Duration(seconds: 4),
          content: const Row(
            children: [
              Icon(Icons.check_circle_outline, color: Colors.white),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Solicitud guardada con éxito !!',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final panel = context.watch<PanelProvider>();
    final auth = context.watch<AuthProvider>();
    final noLeidas = context.watch<NotificacionProvider>().noLeidas;
    final usuario = auth.usuario;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppPalette.surface,
      drawer: const AppDrawer(rutaActual: AppRoutes.panel),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const DecoracionSuperior(altura: 64),
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 8, 20, 10),
              child: Align(
                alignment: Alignment.centerLeft,
                child: MarcaXabal(),
              ),
            ),
            const Divider(height: 1),
            _Cabecera(
              titulo: 'Panel principal',
              noLeidas: noLeidas,
              nombreUsuario: usuario?.nombreCompleto ?? '',
              fotoBase64: usuario?.fotoBase64,
              onAbrirMenu: () => _scaffoldKey.currentState?.openDrawer(),
              onNotificaciones: _abrirNotificaciones,
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
              child: _SelectorArea(
                areas: panel.areas,
                seleccionada: panel.idEstructuraSeleccionada,
                onCambiar: (id) => context.read<PanelProvider>().seleccionarArea(id),
              ),
            ),
            Expanded(child: _Contenido(panel: panel, onRefrescar: _recargar)),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _crearSolicitud,
        tooltip: 'Crear solicitud de baja',
        child: const Icon(Icons.add, size: 30),
      ),
    );
  }
}

class _Cabecera extends StatelessWidget {
  const _Cabecera({
    required this.titulo,
    required this.noLeidas,
    required this.nombreUsuario,
    required this.fotoBase64,
    required this.onAbrirMenu,
    required this.onNotificaciones,
  });

  final String titulo;
  final int noLeidas;
  final String nombreUsuario;
  final String? fotoBase64;
  final VoidCallback onAbrirMenu;
  final VoidCallback onNotificaciones;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 8),
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
              style: const TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.w600,
                color: AppPalette.textPrimary,
              ),
            ),
          ),
          _CampanaNotificaciones(
            noLeidas: noLeidas,
            onTap: onNotificaciones,
          ),
          const SizedBox(width: 10),
          FotoAvatar(
            fotoBase64: fotoBase64,
            nombre: nombreUsuario,
            radio: 20,
          ),
        ],
      ),
    );
  }
}

class _CampanaNotificaciones extends StatelessWidget {
  const _CampanaNotificaciones({required this.noLeidas, required this.onTap});

  final int noLeidas;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
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
    );
  }
}

class _SelectorArea extends StatelessWidget {
  const _SelectorArea({
    required this.areas,
    required this.seleccionada,
    required this.onCambiar,
  });

  final List<OpcionFiltro> areas;
  final int? seleccionada;
  final ValueChanged<int?> onCambiar;

  @override
  Widget build(BuildContext context) {
    final opciones = OpcionFiltro.conIdNumericoUnico(areas);
    final valorValido =
        opciones.any((opcion) => opcion.id == seleccionada) ? seleccionada : null;

    return Container(
      height: 46,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: AppPalette.inputFill,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppPalette.outline),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int?>(
          isExpanded: true,
          value: valorValido,
          icon: const Icon(Icons.keyboard_arrow_down,
              color: AppPalette.textSecondary),
          style: const TextStyle(
            fontSize: 15,
            color: AppPalette.textSecondary,
            fontWeight: FontWeight.w600,
          ),
          items: [
            const DropdownMenuItem<int?>(
              value: null,
              child: Text('Todas las áreas'),
            ),
            ...opciones.map(
              (area) => DropdownMenuItem<int?>(
                value: area.id,
                child: Text(area.etiqueta, overflow: TextOverflow.ellipsis),
              ),
            ),
          ],
          onChanged: onCambiar,
        ),
      ),
    );
  }
}

class _Contenido extends StatelessWidget {
  const _Contenido({required this.panel, required this.onRefrescar});

  final PanelProvider panel;
  final Future<void> Function() onRefrescar;

  @override
  Widget build(BuildContext context) {
    if (panel.cargando && panel.estadisticas == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (panel.errorMessage != null && panel.estadisticas == null) {
      return _MensajeError(mensaje: panel.errorMessage!, onReintentar: onRefrescar);
    }

    final estadisticas = panel.estadisticas;
    if (estadisticas == null) {
      return const SizedBox.shrink();
    }

    final tarjetas = _tarjetas(estadisticas, panel.notificacionesGeneradas);

    return RefreshIndicator(
      onRefresh: onRefrescar,
      color: AppPalette.primary,
      child: GridView.builder(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 96),
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: tarjetas.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 14,
          crossAxisSpacing: 14,
          childAspectRatio: 1,
        ),
        itemBuilder: (context, index) => tarjetas[index],
      ),
    );
  }

  List<Widget> _tarjetas(EstadisticasBaja estadisticas, int notificaciones) {
    return [
      IndicadorCard(
        titulo: 'Total de bajas',
        valor: '${estadisticas.totalSolicitudes}',
        icono: Icons.layers_outlined,
        color: AppPalette.primary,
      ),
      IndicadorCard(
        titulo: 'Bajas en trámite',
        valor: '${estadisticas.enTramite}',
        icono: Icons.assignment_outlined,
        color: AppPalette.warning,
      ),
      IndicadorCard(
        titulo: 'Finalizadas',
        valor: '${estadisticas.finalizadas}',
        icono: Icons.done_all,
        color: AppPalette.success,
      ),
      IndicadorCard(
        titulo: 'Bajas efectivas',
        valor: '${estadisticas.bajas}',
        icono: Icons.person_off_outlined,
        color: AppPalette.tertiary,
      ),
      IndicadorCard(
        titulo: 'Personas en baja',
        valor: '${estadisticas.personasEnBaja}',
        icono: Icons.groups_outlined,
        color: AppPalette.secondary,
      ),
      IndicadorCard(
        titulo: 'Notificaciones',
        valor: '$notificaciones',
        icono: Icons.notifications_outlined,
        color: AppPalette.tertiary,
      ),
    ];
  }
}

class _MensajeError extends StatelessWidget {
  const _MensajeError({required this.mensaje, required this.onReintentar});

  final String mensaje;
  final Future<void> Function() onReintentar;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_outlined,
                size: 48, color: AppPalette.error),
            const SizedBox(height: 12),
            Text(mensaje, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: onReintentar,
              child: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}
