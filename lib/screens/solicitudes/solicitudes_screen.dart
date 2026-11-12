import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../config/routes.dart';
import '../../config/theme.dart';
import '../../models/solicitud_baja.dart';
import '../../providers/auth_provider.dart';
import '../../providers/notificacion_provider.dart';
import '../../providers/solicitud_provider.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/decoracion_superior.dart';
import '../../widgets/estado_badge.dart';
import '../../widgets/foto_avatar.dart';
import '../../widgets/marca_xabal.dart';
import 'crear_solicitud_dialog.dart';

/// HU03 — Lista de solicitudes de baja con filtro por periodo, buscador y
/// creación de nuevas solicitudes.
class SolicitudesScreen extends StatefulWidget {
  const SolicitudesScreen({super.key});

  @override
  State<SolicitudesScreen> createState() => _SolicitudesScreenState();
}

class _SolicitudesScreenState extends State<SolicitudesScreen> {
  static final DateFormat _formatoFecha = DateFormat('dd/MM/yyyy');

  static const List<_OpcionPeriodo> _periodos = [
    _OpcionPeriodo('1 semana', 7),
    _OpcionPeriodo('1 mes', 30),
    _OpcionPeriodo('3 meses', 90),
    _OpcionPeriodo('6 meses', 180),
    _OpcionPeriodo('1 año', 365),
    _OpcionPeriodo('Todo el tiempo', null),
  ];

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _busqueda = TextEditingController();
  final ScrollController _scroll = ScrollController();

  Timer? _debounce;
  _OpcionPeriodo? _periodo = _periodos.first;
  DateTimeRange? _rangoPersonalizado;
  String? _filtroActivoTexto;

  @override
  void initState() {
    super.initState();
    _busqueda.addListener(_alEscribir);
    _scroll.addListener(_alDesplazar);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      await context.read<SolicitudProvider>().cargarFiltros();
      if (!mounted) return;
      await _recargar();
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
    _debounce = Timer(const Duration(milliseconds: 300), _recargar);
  }

  void _alDesplazar() {
    if (!_scroll.hasClients) return;
    final posicion = _scroll.position;
    final provider = context.read<SolicitudProvider>();
    if (posicion.pixels >= posicion.maxScrollExtent - 220 && provider.hayMas) {
      provider.cargarMas();
    }
  }

  Future<void> _recargar() async {
    final ahora = DateTime.utc(DateTime.now().year, DateTime.now().month, DateTime.now().day);
    final hoy = DateTime(ahora.year, ahora.month, ahora.day);

    DateTime? desde;
    DateTime? hasta;
    String? filtroActivo;

    if (_rangoPersonalizado != null) {
      final rango = _rangoPersonalizado!;
      desde = DateTime.utc(rango.start.year, rango.start.month, rango.start.day);
      hasta = DateTime.utc(rango.end.year, rango.end.month, rango.end.day);
      filtroActivo =
          '${_formatoFecha.format(rango.start)} - '
          '${_formatoFecha.format(rango.end)}';
    } else if (_periodo?.dias != null) {
      final periodo = _periodo!;
      final dias = periodo.dias;
      if (dias != null) {
        final desdeLocal = hoy.subtract(Duration(days: dias - 1));
        final hastaLocal = hoy;
        desde = desdeLocal;
        hasta = hastaLocal;
        filtroActivo = '${periodo.etiqueta} '
            '(${_formatoFecha.format(desdeLocal)} - '
            '${_formatoFecha.format(hastaLocal)})';
      }
    }

    if (!mounted) return;
    await context.read<SolicitudProvider>().cargar(
      busqueda: _busqueda.text,
      fechaDesde: desde,
      fechaHasta: hasta,
    );
    if (!mounted) return;
    setState(() => _filtroActivoTexto = filtroActivo);
  }

  Future<void> _elegirRango() async {
    final ahora = DateTime.now();
    final rango = await showDateRangePicker(
      context: context,
      firstDate: DateTime(ahora.year - 3),
      lastDate: ahora,
      initialDateRange:
          _rangoPersonalizado ??
          DateTimeRange(
            start: ahora.subtract(const Duration(days: 6)),
            end: ahora,
          ),
      helpText: 'Seleccionar periodo',
      saveText: 'Aplicar',
    );
    if (rango == null || !mounted) return;

    setState(() {
      _rangoPersonalizado = rango;
      _periodo = null;
    });
    await _recargar();
  }

  Future<void> _cambiarPeriodo(_OpcionPeriodo? opcion) async {
    setState(() {
      _periodo = opcion;
      _rangoPersonalizado = null;
    });
    await _recargar();
  }

  Future<void> _abrirCrear() async {
    final provider = context.read<SolicitudProvider>();
    await provider.cargarFiltros();
    if (!mounted) return;

    if (provider.filtros.tipos.isEmpty || provider.filtros.causas.isEmpty) {
      _avisar('No se pudieron cargar los catálogos. Intente nuevamente.');
      return;
    }

    final creada = await mostrarCrearSolicitud(context, provider.filtros);
    if (creada != true || !mounted) return;

    await provider.recargar();
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

  void _avisar(String mensaje) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(mensaje)));
  }

  void _verDetalle(SolicitudBaja solicitud) {
    context.push(AppRoutes.detalleSolicitud('${solicitud.idSolicitud}'));
  }

  void _editar(SolicitudBaja solicitud) {
    // TODO(HU09): el backend aún no expone PATCH para solicitudes de baja.
    _avisar('La edición de solicitudes estará disponible en la HU09.');
  }

  void _eliminar(SolicitudBaja solicitud) {
    // TODO(HU09): el backend aún no expone DELETE para solicitudes de baja.
    _avisar('La eliminación de solicitudes estará disponible en la HU09.');
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final noLeidas = context.watch<NotificacionProvider>().noLeidas;
    final usuario = auth.usuario;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppPalette.surface,
      drawer: const AppDrawer(rutaActual: AppRoutes.solicitudes),
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
              noLeidas: noLeidas,
              nombreUsuario: usuario?.nombreCompleto ?? '',
              fotoBase64: usuario?.fotoBase64,
              onAbrirMenu: () => _scaffoldKey.currentState?.openDrawer(),
              onNotificaciones: () => context.push(AppRoutes.notificaciones),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 44,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: AppPalette.inputFill,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppPalette.outline),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<_OpcionPeriodo>(
                          isExpanded: true,
                          value: _periodo,
                          hint: Text(
                            _rangoPersonalizado == null
                                ? 'Periodo'
                                : '${_formatoFecha.format(_rangoPersonalizado!.start)}'
                                      ' - '
                                      '${_formatoFecha.format(_rangoPersonalizado!.end)}',
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppPalette.textSecondary,
                            ),
                          ),
                          icon: const Icon(
                            Icons.keyboard_arrow_down,
                            color: AppPalette.textSecondary,
                          ),
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppPalette.textSecondary,
                          ),
                          items: _periodos
                              .map(
                                (opcion) => DropdownMenuItem<_OpcionPeriodo>(
                                  value: opcion,
                                  child: Text(opcion.etiqueta),
                                ),
                              )
                              .toList(),
                          onChanged: _cambiarPeriodo,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    width: 48,
                    height: 44,
                    child: ElevatedButton(
                      onPressed: _elegirRango,
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(48, 44),
                      ),
                      child: const Icon(
                        Icons.calendar_month_outlined,
                        size: 22,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (_filtroActivoTexto != null) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Row(
                  children: [
                    Icon(
                      Icons.filter_list,
                      size: 16,
                      color: AppPalette.primary,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Filtrando por: $_filtroActivoTexto',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppPalette.primary,
                        ),
                      ),
                    ),
                    if (_periodo?.etiqueta == 'Todo el tiempo' ||
                        _rangoPersonalizado == null &&
                            _periodo?.etiqueta == 'Todo el tiempo')
                      const SizedBox.shrink()
                    else
                      IconButton(
                        icon: const Icon(
                          Icons.filter_alt_off,
                          size: 20,
                          color: AppPalette.textSecondary,
                        ),
                        onPressed: () {
                          setState(() {
                            _periodo = _periodos.last;
                            _rangoPersonalizado = null;
                          });
                          _recargar();
                        },
                        tooltip: 'Quitar filtro',
                      ),
                  ],
                ),
              ),
            ],
            Expanded(
              child: Container(
                margin: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                decoration: BoxDecoration(
                  color: AppPalette.inputFill,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppPalette.secondary.withValues(alpha: 0.45),
                  ),
                ),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
                      child: _BarraBusqueda(
                        controller: _busqueda,
                        onBuscar: _recargar,
                      ),
                    ),
                    const _CabeceraTabla(),
                    Expanded(
                      child: _Listado(
                        scroll: _scroll,
                        onVer: _verDetalle,
                        onEditar: _editar,
                        onEliminar: _eliminar,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _abrirCrear,
        tooltip: 'Crear solicitud de baja',
        icon: const Icon(Icons.add),
        label: const Text('Crear solicitud'),
      ),
    );
  }
}

class _Cabecera extends StatelessWidget {
  const _Cabecera({
    required this.noLeidas,
    required this.nombreUsuario,
    required this.fotoBase64,
    required this.onAbrirMenu,
    required this.onNotificaciones,
  });

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
          const Expanded(
            child: Text(
              'Solicitudes de baja',
              style: TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.w600,
                color: AppPalette.textPrimary,
              ),
            ),
          ),
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
          const SizedBox(width: 10),
          FotoAvatar(fotoBase64: fotoBase64, nombre: nombreUsuario, radio: 20),
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

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
      child: Row(
        children: [
          const SizedBox(width: 50, child: Text('Foto', style: estilo)),
          const Expanded(child: Text('Solicitante', style: estilo)),
          SizedBox(
            width: 108,
            child: Text('Acciones', textAlign: TextAlign.center, style: estilo),
          ),
        ],
      ),
    );
  }
}

class _Listado extends StatelessWidget {
  const _Listado({
    required this.scroll,
    required this.onVer,
    required this.onEditar,
    required this.onEliminar,
  });

  final ScrollController scroll;
  final ValueChanged<SolicitudBaja> onVer;
  final ValueChanged<SolicitudBaja> onEditar;
  final ValueChanged<SolicitudBaja> onEliminar;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SolicitudProvider>();

    if (provider.cargando && provider.solicitudes.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.errorMessage != null && provider.solicitudes.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.cloud_off_outlined,
                size: 44,
                color: AppPalette.error,
              ),
              const SizedBox(height: 10),
              Text(
                provider.errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: provider.recargar,
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }

    if (provider.solicitudes.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.inbox_outlined, size: 48, color: AppPalette.outline),
              SizedBox(height: 10),
              Text(
                'No hay solicitudes en el periodo seleccionado',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: AppPalette.textSecondary),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: provider.recargar,
      color: AppPalette.primary,
      child: ListView.builder(
        controller: scroll,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 96),
        itemCount: provider.solicitudes.length + (provider.hayMas ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= provider.solicitudes.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            );
          }

          final solicitud = provider.solicitudes[index];
          return _FilaSolicitud(
            solicitud: solicitud,
            onVer: () => onVer(solicitud),
            onEditar: () => onEditar(solicitud),
            onEliminar: () => onEliminar(solicitud),
          );
        },
      ),
    );
  }
}

class _FilaSolicitud extends StatelessWidget {
  const _FilaSolicitud({
    required this.solicitud,
    required this.onVer,
    required this.onEditar,
    required this.onEliminar,
  });

  static final DateFormat _formatoFecha = DateFormat('dd/MM/yyyy');

  final SolicitudBaja solicitud;
  final VoidCallback onVer;
  final VoidCallback onEditar;
  final VoidCallback onEliminar;

  @override
  Widget build(BuildContext context) {
    final nombre = solicitud.nombreSolicitanteCompleto ?? 'Sin nombre';
    final fecha = solicitud.fechaRegistro == null
        ? null
        : _formatoFecha.format(solicitud.fechaRegistro!);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppPalette.outline)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 50,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppPalette.tertiary, width: 2),
              ),
              child: FotoAvatar(
                fotoBase64: solicitud.fotoSolicitante,
                nombre: nombre,
                radio: 17,
              ),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nombre,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: AppPalette.textPrimary,
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    EstadoBadge(estado: solicitud.estado, compacto: true),
                    if (fecha != null) ...[
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          fecha,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppPalette.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          SizedBox(
            width: 108,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _BotonAccion(
                  icono: Icons.visibility_outlined,
                  color: AppPalette.success,
                  tooltip: 'Ver detalle',
                  onTap: onVer,
                ),
                const SizedBox(width: 6),
                _BotonAccion(
                  icono: Icons.edit_outlined,
                  color: AppPalette.tertiary,
                  tooltip: 'Editar',
                  onTap: onEditar,
                ),
                const SizedBox(width: 6),
                _BotonAccion(
                  icono: Icons.delete_outline,
                  color: AppPalette.primary,
                  tooltip: 'Eliminar',
                  onTap: onEliminar,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BotonAccion extends StatelessWidget {
  const _BotonAccion({
    required this.icono,
    required this.color,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icono;
  final Color color;
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
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icono, color: Colors.white, size: 19),
        ),
      ),
    );
  }
}

/// Opción del selector de periodo.
class _OpcionPeriodo {
  const _OpcionPeriodo(this.etiqueta, this.dias);

  final String etiqueta;
  final int? dias;
}
