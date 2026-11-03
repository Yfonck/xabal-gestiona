import 'dart:async';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../config/routes.dart';
import '../../config/theme.dart';
import '../../models/estadisticas_baja.dart';
import '../../models/estado_solicitud.dart';
import '../../models/opcion_filtro.dart';
import '../../models/solicitud_baja.dart';
import '../../providers/auth_provider.dart';
import '../../providers/bajas_pendientes_provider.dart';
import '../../providers/notificacion_provider.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/boton_accion.dart';
import '../../widgets/encabezado_pantalla.dart';
import '../../widgets/foto_cuadrada.dart';

/// HU05 — Bajas pendientes por área.
///
/// Muestra un resumen con donut por estado, el total de bajas pendientes y el
/// listado paginado de solicitantes con sus acciones rápidas.
class BajasPendientesScreen extends StatefulWidget {
  const BajasPendientesScreen({super.key});

  @override
  State<BajasPendientesScreen> createState() => _BajasPendientesScreenState();
}

class _BajasPendientesScreenState extends State<BajasPendientesScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _busqueda = TextEditingController();
  final ScrollController _scroll = ScrollController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _busqueda.addListener(_alEscribir);
    _scroll.addListener(_alDesplazar);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final provider = context.read<BajasPendientesProvider>();
      await provider.cargarFiltros();
      if (!mounted) return;
      await provider.cargar();
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _busqueda.removeListener(_alEscribir);
    _scroll.removeListener(_alDesplazar);
    _busqueda.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _alEscribir() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      context.read<BajasPendientesProvider>().buscar(_busqueda.text);
    });
  }

  void _alDesplazar() {
    if (!_scroll.hasClients) return;
    final posicion = _scroll.position;
    final provider = context.read<BajasPendientesProvider>();
    if (posicion.pixels >= posicion.maxScrollExtent - 220 && provider.hayMas) {
      provider.cargarMas();
    }
  }

  Future<void> _abrirFiltros() async {
    final provider = context.read<BajasPendientesProvider>();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppPalette.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => _FiltrosSheet(
        causas: provider.causas,
        seleccionada: provider.idCausaBaja,
        onAplicar: (id) {
          Navigator.of(context).pop();
          provider.seleccionarCausa(id);
        },
        onLimpiar: () {
          Navigator.of(context).pop();
          provider.limpiarFiltros();
        },
      ),
    );
  }

  void _verDetalle(SolicitudBaja solicitud) {
    context.push(AppRoutes.detalleSolicitud('${solicitud.idSolicitud}'));
  }

  void _editar(SolicitudBaja solicitud) {
    // TODO(HU09): el backend aún no expone PATCH para solicitudes de baja.
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text(
            'La edición de solicitudes estará disponible en la HU09.',
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BajasPendientesProvider>();
    final auth = context.watch<AuthProvider>();
    final noLeidas = context.watch<NotificacionProvider>().noLeidas;
    final usuario = auth.usuario;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppPalette.surface,
      drawer: const AppDrawer(rutaActual: AppRoutes.bajasPendientes),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            EncabezadoPantalla(
              titulo: 'Bajas pendientes',
              noLeidas: noLeidas,
              nombreUsuario: usuario?.nombreCompleto ?? '',
              fotoBase64: usuario?.fotoBase64,
              iconoAccion: Icons.folder_outlined,
              tooltipAccion: 'Solicitudes de baja',
              onAccion: () => context.go(AppRoutes.solicitudes),
              onAbrirMenu: () => _scaffoldKey.currentState?.openDrawer(),
              onNotificaciones: () => context.push(AppRoutes.notificaciones),
            ),
            _FiltrosSuperiores(
              areas: provider.areas,
              tipos: provider.tipos,
              idEstructura: provider.idEstructura,
              idTipoBaja: provider.idTipoBaja,
              onArea: provider.seleccionarArea,
              onTipo: provider.seleccionarTipo,
              onReset: provider.limpiarFiltros,
              onFiltros: _abrirFiltros,
            ),
            Expanded(
              child: _Contenido(
                provider: provider,
                scroll: _scroll,
                busqueda: _busqueda,
                onBuscar: () => provider.buscar(_busqueda.text),
                onVer: _verDetalle,
                onEditar: _editar,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Filtros superiores
// ---------------------------------------------------------------------------

class _FiltrosSuperiores extends StatelessWidget {
  const _FiltrosSuperiores({
    required this.areas,
    required this.tipos,
    required this.idEstructura,
    required this.idTipoBaja,
    required this.onArea,
    required this.onTipo,
    required this.onReset,
    required this.onFiltros,
  });

  final List<OpcionFiltro> areas;
  final List<OpcionFiltro> tipos;
  final int? idEstructura;
  final int? idTipoBaja;
  final Future<void> Function(int?) onArea;
  final Future<void> Function(int?) onTipo;
  final Future<void> Function() onReset;
  final VoidCallback onFiltros;

  @override
  Widget build(BuildContext context) {
    final areasValidas = OpcionFiltro.conIdNumericoUnico(areas);
    final tiposValidos = OpcionFiltro.conIdNumericoUnico(tipos);

    const estiloItem = TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w600,
      color: AppPalette.textSecondary,
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: _DropdownFiltro(
              valor: idEstructura,
              hint: 'Área',
              items: [
                ...areasValidas.map(
                  (area) => DropdownMenuItem<int?>(
                    value: area.id,
                    child: Text(
                      area.etiqueta,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: estiloItem,
                    ),
                  ),
                ),
              ],
              onChanged: onArea,
            ),
          ),
          const SizedBox(width: 8),
          _BotonIcono(
            icono: Icons.grid_view_rounded,
            tooltip: 'Ver todas las áreas',
            onTap: () => onReset(),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _DropdownFiltro(
              valor: idTipoBaja,
              hint: 'Tipo de baja',
              items: [
                ...tiposValidos.map(
                  (tipo) => DropdownMenuItem<int?>(
                    value: tipo.id,
                    child: Text(
                      tipo.etiqueta,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: estiloItem,
                    ),
                  ),
                ),
              ],
              onChanged: onTipo,
            ),
          ),
          const SizedBox(width: 8),
          _BotonIcono(
            icono: Icons.filter_alt_outlined,
            tooltip: 'Más filtros',
            onTap: onFiltros,
          ),
        ],
      ),
    );
  }
}

class _DropdownFiltro extends StatelessWidget {
  const _DropdownFiltro({
    required this.valor,
    required this.hint,
    required this.items,
    required this.onChanged,
  });

  final int? valor;
  final String hint;
  final List<DropdownMenuItem<int?>> items;
  final ValueChanged<int?> onChanged;

  @override
  Widget build(BuildContext context) {
    // Un `DropdownButton` exige un único ítem por `value`; se descartan
    // duplicados para no disparar el assert de Flutter.
    final valoresVistos = <int?>{};
    final itemsUnicos = [
      for (final item in items)
        if (valoresVistos.add(item.value)) item,
    ];
    final existe = itemsUnicos.any((item) => item.value == valor);

    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: AppPalette.inputFill,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppPalette.outline),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int?>(
          isExpanded: true,
          value: existe ? valor : null,
          hint: Text(
            hint,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 13,
              color: AppPalette.textSecondary,
            ),
          ),
          icon: const Icon(
            Icons.keyboard_arrow_down,
            color: AppPalette.textSecondary,
            size: 20,
          ),
          items: itemsUnicos,
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class _BotonIcono extends StatelessWidget {
  const _BotonIcono({
    required this.icono,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icono;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppPalette.primary,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icono, color: Colors.white, size: 22),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Contenido
// ---------------------------------------------------------------------------

class _Contenido extends StatelessWidget {
  const _Contenido({
    required this.provider,
    required this.scroll,
    required this.busqueda,
    required this.onBuscar,
    required this.onVer,
    required this.onEditar,
  });

  final BajasPendientesProvider provider;
  final ScrollController scroll;
  final TextEditingController busqueda;
  final Future<void> Function() onBuscar;
  final ValueChanged<SolicitudBaja> onVer;
  final ValueChanged<SolicitudBaja> onEditar;

  @override
  Widget build(BuildContext context) {
    if (provider.cargando &&
        provider.estadisticas == null &&
        provider.solicitudes.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.errorMessage != null &&
        provider.estadisticas == null &&
        provider.solicitudes.isEmpty) {
      return _MensajeError(
        mensaje: provider.errorMessage!,
        onReintentar: provider.recargar,
      );
    }

    return RefreshIndicator(
      onRefresh: provider.recargar,
      color: AppPalette.primary,
      child: SingleChildScrollView(
        controller: scroll,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _TarjetaResumen(
              estadisticas: provider.estadisticas,
              nombreArea: provider.nombreArea,
              total: provider.totalPendientes,
            ),
            const SizedBox(height: 16),
            _TarjetaListado(
              provider: provider,
              busqueda: busqueda,
              onBuscar: onBuscar,
              onVer: onVer,
              onEditar: onEditar,
            ),
          ],
        ),
      ),
    );
  }
}

class _TarjetaResumen extends StatelessWidget {
  const _TarjetaResumen({
    required this.estadisticas,
    required this.nombreArea,
    required this.total,
  });

  final EstadisticasBaja? estadisticas;
  final String nombreArea;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppPalette.inputFill,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppPalette.warning, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text.rich(
                  TextSpan(
                    style: const TextStyle(
                      fontSize: 17,
                      color: AppPalette.textSecondary,
                    ),
                    children: [
                      const TextSpan(
                        text: 'Área : ',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      TextSpan(
                        text: nombreArea,
                        style: const TextStyle(
                          color: AppPalette.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Icon(
                Icons.format_list_bulleted,
                color: AppPalette.warning,
                size: 24,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Text(
                '$total',
                style: const TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.w700,
                  color: AppPalette.tertiary,
                  height: 1,
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Bajas pendientes',
                  style: TextStyle(
                    fontSize: 15,
                    color: AppPalette.textSecondary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _Donut(estadisticas: estadisticas),
            ],
          ),
        ],
      ),
    );
  }
}

class _Donut extends StatelessWidget {
  const _Donut({required this.estadisticas});

  final EstadisticasBaja? estadisticas;

  @override
  Widget build(BuildContext context) {
    final datos = estadisticas;
    final iniciada = datos?.cantidadDe(EstadoSolicitud.iniciada) ?? 0;
    final enTramite = datos?.cantidadDe(EstadoSolicitud.enTramite) ?? 0;
    final finalizada = datos?.cantidadDe(EstadoSolicitud.finalizada) ?? 0;
    final total = iniciada + enTramite + finalizada;

    final secciones = total == 0
        ? [
            PieChartSectionData(
              value: 1,
              color: AppPalette.outline,
              radius: 40,
              showTitle: false,
            ),
          ]
        : [
            if (iniciada > 0)
              PieChartSectionData(
                value: iniciada.toDouble(),
                color: AppPalette.tertiary,
                radius: 20,
                showTitle: false,
              ),
            if (enTramite > 0)
              PieChartSectionData(
                value: enTramite.toDouble(),
                color: AppPalette.warning,
                radius: 20,
                showTitle: false,
              ),
            if (finalizada > 0)
              PieChartSectionData(
                value: finalizada.toDouble(),
                color: AppPalette.success,
                radius: 20,
                showTitle: false,
              ),
          ];

    return Container(
      width: 92,
      height: 92,
      padding: const EdgeInsets.all(4),
      decoration: const BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
      ),
      child: PieChart(
        PieChartData(
          sectionsSpace: 0,
          centerSpaceRadius: 22,
          startDegreeOffset: -90,
          sections: secciones,
        ),
      ),
    );
  }
}

class _TarjetaListado extends StatelessWidget {
  const _TarjetaListado({
    required this.provider,
    required this.busqueda,
    required this.onBuscar,
    required this.onVer,
    required this.onEditar,
  });

  final BajasPendientesProvider provider;
  final TextEditingController busqueda;
  final Future<void> Function() onBuscar;
  final ValueChanged<SolicitudBaja> onVer;
  final ValueChanged<SolicitudBaja> onEditar;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      decoration: BoxDecoration(
        color: AppPalette.inputFill,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppPalette.textSecondary, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppPalette.surface,
              borderRadius: BorderRadius.circular(8),
            ),
            child: _BarraBusqueda(controller: busqueda, onBuscar: onBuscar),
          ),
          const SizedBox(height: 12),
          const _CabeceraTabla(),
          const Divider(height: 1, color: AppPalette.outline),
          _ListaPendientes(
            provider: provider,
            onVer: onVer,
            onEditar: onEditar,
          ),
        ],
      ),
    );
  }
}

class _BarraBusqueda extends StatelessWidget {
  const _BarraBusqueda({required this.controller, required this.onBuscar});

  final TextEditingController controller;
  final Future<void> Function() onBuscar;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 44,
            child: TextField(
              controller: controller,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => onBuscar(),
              style: const TextStyle(fontSize: 13.5),
              decoration: InputDecoration(
                hintText: 'Nombre, Apellidos, CI, Solapín',
                hintStyle: const TextStyle(
                  fontSize: 13,
                  color: AppPalette.textSecondary,
                ),
                isDense: true,
                filled: true,
                fillColor: AppPalette.surface,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: const BorderSide(color: AppPalette.outline),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: const BorderSide(color: AppPalette.outline),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: const BorderSide(
                    color: AppPalette.tertiary,
                    width: 1.4,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 46,
          height: 44,
          child: ElevatedButton(
            onPressed: onBuscar,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppPalette.primary,
              padding: EdgeInsets.zero,
              minimumSize: const Size(46, 44),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            child: const Icon(Icons.search, color: Colors.white, size: 22),
          ),
        ),
      ],
    );
  }
}

class _CabeceraTabla extends StatelessWidget {
  const _CabeceraTabla();

  @override
  Widget build(BuildContext context) {
    const estilo = TextStyle(
      fontSize: 13.5,
      fontWeight: FontWeight.w700,
      color: AppPalette.textPrimary,
    );

    return const Padding(
      padding: EdgeInsets.fromLTRB(4, 4, 4, 8),
      child: Row(
        children: [
          SizedBox(width: 50, child: Text('Foto', style: estilo)),
          Expanded(child: Text('Solicitante', style: estilo)),
          SizedBox(
            width: 90,
            child: Text('Acciones', textAlign: TextAlign.center, style: estilo),
          ),
        ],
      ),
    );
  }
}

class _ListaPendientes extends StatelessWidget {
  const _ListaPendientes({
    required this.provider,
    required this.onVer,
    required this.onEditar,
  });

  final BajasPendientesProvider provider;
  final ValueChanged<SolicitudBaja> onVer;
  final ValueChanged<SolicitudBaja> onEditar;

  @override
  Widget build(BuildContext context) {
    if (provider.cargando && provider.solicitudes.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (provider.errorMessage != null && provider.solicitudes.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 12),
        child: Column(
          children: [
            const Icon(
              Icons.cloud_off_outlined,
              size: 40,
              color: AppPalette.error,
            ),
            const SizedBox(height: 8),
            Text(
              provider.errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 10),
            OutlinedButton(
              onPressed: provider.recargar,
              child: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    if (provider.solicitudes.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24, horizontal: 12),
        child: Column(
          children: [
            Icon(Icons.inbox_outlined, size: 44, color: AppPalette.outline),
            SizedBox(height: 8),
            Text(
              'No hay bajas pendientes para los filtros seleccionados',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: AppPalette.textSecondary),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        for (final solicitud in provider.solicitudes)
          _FilaPendiente(
            solicitud: solicitud,
            onVer: () => onVer(solicitud),
            onEditar: () => onEditar(solicitud),
          ),
        if (provider.cargandoMas)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
      ],
    );
  }
}

class _FilaPendiente extends StatelessWidget {
  const _FilaPendiente({
    required this.solicitud,
    required this.onVer,
    required this.onEditar,
  });

  final SolicitudBaja solicitud;
  final VoidCallback onVer;
  final VoidCallback onEditar;

  @override
  Widget build(BuildContext context) {
    final nombre = solicitud.nombreSolicitanteCompleto ?? 'Sin nombre';

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppPalette.outline)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 50,
            child: FotoCuadrada(
              fotoBase64: solicitud.fotoSolicitante,
              nombre: nombre,
              tamano: 34,
              colorBorde: AppPalette.tertiary,
              radio: 7,
            ),
          ),
          Expanded(
            child: Text(
              nombre,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: AppPalette.textPrimary,
              ),
            ),
          ),
          SizedBox(
            width: 90,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                BotonAccion(
                  icono: Icons.visibility_outlined,
                  color: AppPalette.success,
                  tooltip: 'Ver detalle',
                  onTap: onVer,
                ),
                const SizedBox(width: 6),
                BotonAccion(
                  icono: Icons.edit_outlined,
                  color: AppPalette.tertiary,
                  tooltip: 'Editar',
                  onTap: onEditar,
                ),
              ],
            ),
          ),
        ],
      ),
    );
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
            const Icon(
              Icons.cloud_off_outlined,
              size: 48,
              color: AppPalette.error,
            ),
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

// ---------------------------------------------------------------------------
// Filtros avanzados
// ---------------------------------------------------------------------------

class _FiltrosSheet extends StatefulWidget {
  const _FiltrosSheet({
    required this.causas,
    required this.seleccionada,
    required this.onAplicar,
    required this.onLimpiar,
  });

  final List<OpcionFiltro> causas;
  final int? seleccionada;
  final ValueChanged<int?> onAplicar;
  final VoidCallback onLimpiar;

  @override
  State<_FiltrosSheet> createState() => _FiltrosSheetState();
}

class _FiltrosSheetState extends State<_FiltrosSheet> {
  int? _causa;

  @override
  void initState() {
    super.initState();
    _causa = widget.seleccionada;
  }

  @override
  Widget build(BuildContext context) {
    final causasValidas = OpcionFiltro.conIdNumericoUnico(widget.causas);

    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        16,
        20,
        20 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Filtros',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppPalette.textPrimary,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Cerrar',
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Causa de baja',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppPalette.textSecondary,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            height: 46,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: AppPalette.inputFill,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppPalette.outline),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<int?>(
                isExpanded: true,
                value: _causa,
                hint: const Text(
                  'Todas las causas',
                  style: TextStyle(color: AppPalette.textSecondary),
                ),
                icon: const Icon(
                  Icons.keyboard_arrow_down,
                  color: AppPalette.textSecondary,
                ),
                items: [
                  const DropdownMenuItem<int?>(
                    value: null,
                    child: Text('Todas las causas'),
                  ),
                  ...causasValidas.map(
                    (causa) => DropdownMenuItem<int?>(
                      value: causa.id,
                      child: Text(
                        causa.etiqueta,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
                onChanged: (valor) => setState(() => _causa = valor),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: widget.onLimpiar,
                  child: const Text('Limpiar'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => widget.onAplicar(_causa),
                  child: const Text('Aplicar'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
