import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../config/routes.dart';
import '../../config/theme.dart';
import '../../models/area_confirmacion.dart';
import '../../models/estado_solicitud.dart';
import '../../models/solicitud_baja.dart';
import '../../providers/auth_provider.dart';
import '../../providers/detalle_solicitud_provider.dart';
import '../../providers/notificacion_provider.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/confirm_dialog.dart';
import '../../widgets/encabezado_pantalla.dart';
import '../../widgets/foto_cuadrada.dart';
import '../../services/notificacion_service.dart';

/// HU06 — Detalle de una solicitud de baja.
///
/// Muestra las secciones Solicitante, Responsable, Detalles de la solicitud y
/// Áreas de Bajas, con las acciones rápidas de editar y eliminar.
class DetalleSolicitudScreen extends StatefulWidget {
  const DetalleSolicitudScreen({super.key, required this.idSolicitud});

  final int idSolicitud;

  @override
  State<DetalleSolicitudScreen> createState() => _DetalleSolicitudScreenState();
}

class _DetalleSolicitudScreenState extends State<DetalleSolicitudScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<DetalleSolicitudProvider>().cargar(widget.idSolicitud);
    });
  }

  Future<void> _cancelarConMotivo() async {
    final motivoCtrl = TextEditingController();
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancelar solicitud'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('¿Está seguro de que desea cancelar esta solicitud?'),
            const SizedBox(height: 16),
            TextField(
              controller: motivoCtrl,
              decoration: const InputDecoration(
                labelText: 'Motivo de la cancelación',
                hintText: 'Ingrese el motivo',
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('No, cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: AppPalette.error),
            child: const Text('Sí, cancelar'),
          ),
        ],
      ),
    );
    if (confirmar != true || !mounted) return;
    final motivo = motivoCtrl.text.trim();
    if (motivo.isEmpty) {
      _avisar('El motivo de cancelación es obligatorio.');
      return;
    }
    await context.read<DetalleSolicitudProvider>().cancelarConMotivo(
      widget.idSolicitud,
      motivo: motivo,
    );
    if (!mounted) return;

    final error = context.read<DetalleSolicitudProvider>().errorMessage;
    if (error != null) {
      _avisar(error);
      return;
    }

    try {
      await NotificacionService().crear(
        titulo: 'Solicitud de baja pendiente de cancelación',
        mensaje:
            'El área ha solicitado cancelar la solicitud ID: ${widget.idSolicitud}. Motivo: $motivo',
        link: '/bajas/${widget.idSolicitud}',
      );
      _avisar('Solicitud enviada a RRHH para revisión.');
    } catch (_) {
      _avisar('La solicitud se canceló pero no se pudo notificar a RRHH.');
    }
  }

  Future<void> _confirmar() async {
    await context.read<DetalleSolicitudProvider>().confirmar(widget.idSolicitud);
  }

  Future<void> _cerrar() async {
    await context.read<DetalleSolicitudProvider>().cerrar(widget.idSolicitud);
  }

  Future<void> _cerrarLegacy() async {
    await context.read<DetalleSolicitudProvider>().cerrarLegacy(widget.idSolicitud);
  }

  Future<void> _cerrarAsync() async {
    await context.read<DetalleSolicitudProvider>().cerrarAsync(widget.idSolicitud);
  }

  Future<void> _darBajaDefinitiva() async {
    await context.read<DetalleSolicitudProvider>().darBajaDefinitiva(widget.idSolicitud);
  }

  void _avisar(String mensaje) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(mensaje)));
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DetalleSolicitudProvider>();
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
            EncabezadoPantalla(
              titulo: 'Solicitudes de baja / Ver detalles',
              noLeidas: noLeidas,
              nombreUsuario: usuario?.nombreCompleto ?? '',
              fotoBase64: usuario?.fotoBase64,
              iconoAccion: Icons.folder_outlined,
              tooltipAccion: 'Solicitudes de baja',
              onAccion: () => context.go(AppRoutes.solicitudes),
              onAbrirMenu: () => _scaffoldKey.currentState?.openDrawer(),
              onNotificaciones: () => context.push(AppRoutes.notificaciones),
            ),
            Expanded(
              child: _Contenido(
                provider: provider,
                auth: auth,
                onEliminar: _cancelarConMotivo,
                onConfirmar: _confirmar,
                onCancelar: _cancelarConMotivo,
                onCerrar: _cerrar,
                onCerrarLegacy: _cerrarLegacy,
                onCerrarAsync: _cerrarAsync,
                onDarBajaDefinitiva: _darBajaDefinitiva,
              ),
            ),
          ],
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
    required this.auth,
    required this.onEliminar,
    required this.onConfirmar,
    required this.onCancelar,
    required this.onCerrar,
    required this.onCerrarLegacy,
    required this.onCerrarAsync,
    required this.onDarBajaDefinitiva,
  });

  final DetalleSolicitudProvider provider;
  final AuthProvider auth;
  final VoidCallback onEliminar;
  final Future<void> Function() onConfirmar;
  final Future<void> Function() onCancelar;
  final Future<void> Function() onCerrar;
  final Future<void> Function() onCerrarLegacy;
  final Future<void> Function() onCerrarAsync;
  final Future<void> Function() onDarBajaDefinitiva;

  @override
  Widget build(BuildContext context) {
    if (provider.cargando && provider.solicitud == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.errorMessage != null && provider.solicitud == null) {
      return _MensajeError(
        mensaje: provider.errorMessage!,
        onReintentar: provider.recargar,
      );
    }

    final solicitud = provider.solicitud;
    if (solicitud == null) return const SizedBox.shrink();

    return RefreshIndicator(
      onRefresh: provider.recargar,
      color: AppPalette.primary,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _TarjetaPersona(
              titulo: 'Solicitante',
              colorBorde: AppPalette.tertiary,
              fotoBase64: solicitud.fotoSolicitante,
              nombre: solicitud.nombreSolicitanteCompleto ?? 'Sin nombre',
              rol: solicitud.rolSolicitante ?? 'Trabajador',
              filas: [
                _Dato('Nombre(s)', solicitud.nombreSolicitanteCompleto),
                _Dato('CI', solicitud.ciSolicitante),
                _Dato('Usuario', solicitud.usuarioSolicitante),
                _Dato('Solapín', solicitud.solapinSolicitante),
                _Dato('No. Caducidad', solicitud.caducidadSolicitante),
                _Dato(
                  'Área',
                  solicitud.nombreEstructuraSolicitante ??
                      solicitud.nombreEstructura,
                ),
              ],
              plantilla: [
                _Dato(
                  'Área',
                  solicitud.nombreEstructuraSolicitante ??
                      solicitud.nombreEstructura,
                ),
                _Dato('Responsabilidad', solicitud.responsabilidadSolicitante),
                _Dato(
                  'Fecha',
                  _formatearFecha(solicitud.fechaPlantillaSolicitante),
                ),
              ],
              tituloPlantilla: 'Plantilla del solicitante',
            ),
            const SizedBox(height: 16),
            _TarjetaPersona(
              titulo: 'Responsable',
              colorBorde: AppPalette.primary,
              fotoBase64: solicitud.fotoResponsable,
              nombre: solicitud.nombreResponsable ?? 'Sin nombre',
              rol: solicitud.rolResponsable ?? 'Directivo',
              filas: [
                _Dato('Nombre(s)', solicitud.nombreResponsable),
                _Dato('CI', solicitud.carnetIdentidad),
                _Dato('Usuario', solicitud.usuarioResponsable),
                _Dato('Solapín', solicitud.solapinResponsable),
                _Dato('No. Caducidad', solicitud.caducidadResponsable),
                _Dato(
                  'Área',
                  solicitud.nombreEstructuraResponsable ??
                      solicitud.nombreEstructura,
                ),
              ],
              plantilla: [
                _Dato(
                  'Área',
                  solicitud.nombreEstructuraResponsable ??
                      solicitud.nombreEstructura,
                ),
                _Dato('Responsabilidad', solicitud.responsabilidadResponsable),
                _Dato(
                  'Fecha',
                  _formatearFecha(solicitud.fechaPlantillaResponsable),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _TarjetaDetalle(solicitud: solicitud),
            const SizedBox(height: 16),
            _TarjetaAreas(areas: provider.areas),
            const SizedBox(height: 24),
            _Acciones(
              provider: provider,
              auth: auth,
              onEliminar: onEliminar,
              onConfirmar: onConfirmar,
              onCancelar: onCancelar,
              onCerrar: onCerrar,
              onCerrarLegacy: onCerrarLegacy,
              onCerrarAsync: onCerrarAsync,
              onDarBajaDefinitiva: onDarBajaDefinitiva,
            ),
          ],
        ),
      ),
    );
  }

  static String? _formatearFecha(DateTime? fecha) {
    if (fecha == null) return null;
    return DateFormat('dd/MM/yyyy').format(fecha);
  }
}

// ---------------------------------------------------------------------------
// Tarjeta de persona (solicitante / responsable)
// ---------------------------------------------------------------------------

class _Dato {
  const _Dato(this.etiqueta, this.valor);

  final String etiqueta;
  final String? valor;
}

class _TarjetaPersona extends StatelessWidget {
  const _TarjetaPersona({
    required this.titulo,
    required this.colorBorde,
    required this.fotoBase64,
    required this.nombre,
    required this.rol,
    required this.filas,
    required this.plantilla,
    this.tituloPlantilla,
  });

  final String titulo;
  final Color colorBorde;
  final String? fotoBase64;
  final String nombre;
  final String rol;
  final List<_Dato> filas;
  final List<_Dato> plantilla;
  final String? tituloPlantilla;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppPalette.inputFill,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorBorde, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            titulo,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: AppPalette.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  FotoCuadrada(
                    fotoBase64: fotoBase64,
                    nombre: nombre,
                    tamano: 64,
                    colorBorde: colorBorde,
                    radio: 10,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    rol,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: colorBorde,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  children: [for (final dato in filas) _FilaDato(dato: dato)],
                ),
              ),
            ],
          ),
          if (plantilla.isNotEmpty) ...[
            if (tituloPlantilla != null) ...[
              const SizedBox(height: 16),
              Text(
                tituloPlantilla!,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppPalette.textPrimary,
                ),
              ),
            ],
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppPalette.surface,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [for (final dato in plantilla) _FilaDato(dato: dato)],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _FilaDato extends StatelessWidget {
  const _FilaDato({required this.dato});

  final _Dato dato;

  @override
  Widget build(BuildContext context) {
    final valor = dato.valor?.trim();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 105,
            child: Text(
              '${dato.etiqueta}:',
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: AppPalette.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              valor != null && valor.isNotEmpty ? valor : '—',
              style: const TextStyle(
                fontSize: 12.5,
                color: AppPalette.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Tarjeta de detalles de la solicitud
// ---------------------------------------------------------------------------

class _TarjetaDetalle extends StatelessWidget {
  const _TarjetaDetalle({required this.solicitud});

  final SolicitudBaja solicitud;

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
        children: [
          _FilaDetalle(
            etiqueta: 'Estado de la solicitud',
            valor: solicitud.estado.etiqueta,
          ),
          _FilaDetalle(
            etiqueta: 'Causa de baja',
            valor: solicitud.nombreCausaBaja,
          ),
          _FilaDetalle(
            etiqueta: 'Tipo de baja',
            valor: solicitud.nombreTipoBaja,
          ),
          _FilaDetalle(
            etiqueta: 'Fecha creada',
            valor: _formatearFecha(solicitud.fechaRegistro),
          ),
          _FilaDetalle(
            etiqueta: 'Fecha de baja',
            valor: _formatearFecha(solicitud.fechaBaja) ?? '--/--/----',
          ),
        ],
      ),
    );
  }

  static String? _formatearFecha(DateTime? fecha) {
    if (fecha == null) return null;
    return DateFormat('dd/MM/yyyy').format(fecha);
  }
}

class _FilaDetalle extends StatelessWidget {
  const _FilaDetalle({required this.etiqueta, this.valor});

  final String etiqueta;
  final String? valor;

  @override
  Widget build(BuildContext context) {
    final texto = valor?.trim();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 150,
            child: Text(
              '$etiqueta:',
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: AppPalette.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              texto != null && texto.isNotEmpty ? texto : '—',
              style: const TextStyle(
                fontSize: 13,
                color: AppPalette.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Tarjeta de áreas de bajas
// ---------------------------------------------------------------------------

class _TarjetaAreas extends StatefulWidget {
  const _TarjetaAreas({required this.areas});

  final List<AreaConfirmacion> areas;

  @override
  State<_TarjetaAreas> createState() => _TarjetaAreasState();
}

class _TarjetaAreasState extends State<_TarjetaAreas> {
  final TextEditingController _filtroController = TextEditingController();
  String _filtro = '';
  AreaConfirmacion? _areaSeleccionada;

  List<AreaConfirmacion> get _areasFiltradas {
    if (_filtro.isEmpty) return widget.areas;
    return widget.areas
        .where((a) =>
            a.nombreArea.toLowerCase().contains(_filtro.toLowerCase()))
        .toList();
  }

  void _seleccionarArea(AreaConfirmacion area) {
    setState(() {
      _areaSeleccionada =
          _areaSeleccionada?.idArea == area.idArea ? null : area;
    });
  }

  @override
  void dispose() {
    _filtroController.dispose();
    super.dispose();
  }

  static const TextStyle _estiloCabecera = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w700,
    color: AppPalette.textPrimary,
  );

  @override
  Widget build(BuildContext context) {
    final areas = _areasFiltradas;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppPalette.inputFill,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppPalette.textSecondary, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _filtroController,
            decoration: InputDecoration(
              hintText: 'Buscar área...',
              prefixIcon: const Icon(Icons.search, size: 20),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 8),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: AppPalette.outline),
              ),
            ),
            onChanged: (valor) => setState(() => _filtro = valor),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(flex: 4, child: Text('Área', style: _estiloCabecera)),
              Expanded(flex: 3, child: Text('Estado', style: _estiloCabecera)),
              Expanded(
                flex: 2,
                child: Text(
                  'Fecha',
                  textAlign: TextAlign.end,
                  style: _estiloCabecera,
                ),
              ),
              Expanded(flex: 2, child: SizedBox.shrink()),
            ],
          ),
          const SizedBox(height: 8),
          if (areas.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text(
                'Sin áreas registradas',
                style: TextStyle(fontSize: 13, color: AppPalette.textSecondary),
              ),
            )
          else
            for (final area in areas)
              _FilaArea(
                area: area,
                seleccionada: _areaSeleccionada?.idArea == area.idArea,
                onSeleccionar: () => _seleccionarArea(area),
              ),
          if (_areaSeleccionada != null) ...[
            const SizedBox(height: 16),
            _PanelAreaSeleccionada(area: _areaSeleccionada!),
          ],
        ],
      ),
    );
  }
}

class _FilaArea extends StatelessWidget {
  const _FilaArea({
    required this.area,
    required this.seleccionada,
    required this.onSeleccionar,
  });

  final AreaConfirmacion area;
  final bool seleccionada;
  final VoidCallback onSeleccionar;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 4,
            child: Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Text(
                area.nombreArea,
                style: TextStyle(
                  fontSize: 12.5,
                  color: AppPalette.textPrimary,
                  fontWeight:
                      seleccionada ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              area.estado,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: area.colorEstado,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              _formatearFecha(area.fecha),
              textAlign: TextAlign.end,
              style: const TextStyle(
                fontSize: 12.5,
                color: AppPalette.textSecondary,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: onSeleccionar,
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    seleccionada ? AppPalette.primary : AppPalette.tertiary,
                foregroundColor: Colors.white,
                minimumSize: Size.zero,
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                seleccionada ? 'Seleccionada' : 'Seleccionar',
                style: const TextStyle(fontSize: 11),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String _formatearFecha(DateTime? fecha) {
    if (fecha == null) return '--/--/----';
    return DateFormat('dd/MM/yyyy').format(fecha);
  }
}

class _PanelAreaSeleccionada extends StatelessWidget {
  const _PanelAreaSeleccionada({required this.area});

  final AreaConfirmacion area;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppPalette.primarySoft.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppPalette.primary.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Área seleccionada',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppPalette.primary,
            ),
          ),
          const SizedBox(height: 8),
          _filaInfo('Área', area.nombreArea),
          _filaInfo('Estado', area.estado),
          _filaInfo('Fecha', _formatearFecha(area.fecha)),
          if (area.idArea != null) _filaInfo('ID', area.idArea!.toString()),
        ],
      ),
    );
  }

  static String _formatearFecha(DateTime? fecha) {
    if (fecha == null) return '--/--/----';
    return DateFormat('dd/MM/yyyy').format(fecha);
  }

  Widget _filaInfo(String etiqueta, String valor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 70,
            child: Text(
              '$etiqueta:',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppPalette.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              valor,
              style: const TextStyle(fontSize: 12, color: AppPalette.textPrimary),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Acciones y estados de error
// ---------------------------------------------------------------------------

class _Acciones extends StatelessWidget {
  const _Acciones({
    required this.provider,
    required this.auth,
    required this.onEliminar,
    required this.onConfirmar,
    required this.onCancelar,
    required this.onCerrar,
    required this.onCerrarLegacy,
    required this.onCerrarAsync,
    required this.onDarBajaDefinitiva,
  });

  final DetalleSolicitudProvider provider;
  final AuthProvider auth;
  final VoidCallback onEliminar;
  final Future<void> Function() onConfirmar;
  final Future<void> Function() onCancelar;
  final Future<void> Function() onCerrar;
  final Future<void> Function() onCerrarLegacy;
  final Future<void> Function() onCerrarAsync;
  final Future<void> Function() onDarBajaDefinitiva;

  bool get _esAdminOrRrhh => auth.usuario?.esAdmin == true ||
      auth.usuario?.permisoRrhh == true;

  List<Widget> _botonesTransicion(BuildContext context) {
    final estado = provider.solicitud?.estado;
    if (estado == null) return const [];

    final botones = <Widget>[];

    switch (estado) {
      case EstadoSolicitud.iniciada:
        // Cerrar legacy desde Iniciada (1→4), solo admin/RRHH
        if (_esAdminOrRrhh) {
          botones.add(
            _BotonTransicion(
              texto: 'Cerrar (legacy)',
              icono: Icons.close_fullscreen,
              color: AppPalette.error,
              onPressed: () => _ejecutarAccion(context, onCerrarLegacy),
            ),
          );
        }
        break;

      case EstadoSolicitud.enTramite:
        // Confirmar área (2→3)
        botones.add(
          _BotonTransicion(
            texto: 'Confirmar área',
            icono: Icons.check_circle_outline,
            color: AppPalette.success,
            onPressed: () => _ejecutarAccion(context, onConfirmar),
          ),
        );
        // Cancelar (2→5)
        botones.add(
          _BotonTransicion(
            texto: 'Cancelar',
            icono: Icons.cancel_outlined,
            color: AppPalette.error,
            onPressed: () => onCancelar(),
          ),
        );
        break;

      case EstadoSolicitud.finalizada:
        // Cerrar baja definitiva (3→4), solo admin/RRHH
        if (_esAdminOrRrhh) {
          botones.add(
            _BotonTransicion(
              texto: 'Dar baja definitiva',
              icono: Icons.person_off_outlined,
              color: AppPalette.primary,
              onPressed: () => _confirmarBajaDefinitiva(context),
            ),
          );
          // Cerrar (3→4)
          botones.add(
            _BotonTransicion(
              texto: 'Cerrar',
              icono: Icons.close_fullscreen,
              color: AppPalette.error,
              onPressed: () => _ejecutarAccion(context, onCerrar),
            ),
          );
          // Cerrar legacy (3→4)
          botones.add(
            _BotonTransicion(
              texto: 'Cerrar (legacy)',
              icono: Icons.close_fullscreen,
              color: AppPalette.error,
              onPressed: () => _ejecutarAccion(context, onCerrarLegacy),
            ),
          );
          // Cerrar async (3→4)
          botones.add(
            _BotonTransicion(
              texto: 'Cerrar (async)',
              icono: Icons.schedule_outlined,
              color: AppPalette.tertiary,
              onPressed: () => _ejecutarAccion(context, onCerrarAsync),
            ),
          );
        }
        break;

      case EstadoSolicitud.baja:
      case EstadoSolicitud.cancelada:
      case EstadoSolicitud.expirada:
        // Estados finales: sin acciones de transición
        break;
    }

    return botones;
  }

  Future<void> _ejecutarAccion(
    BuildContext context,
    Future<void> Function() accion,
  ) async {
    await accion();
    if (!context.mounted) return;
    final error = provider.errorMessage;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(error ?? 'Operación realizada con éxito.'),
          backgroundColor: error != null ? AppPalette.error : AppPalette.success,
        ),
      );
  }

  Future<void> _confirmarBajaDefinitiva(BuildContext context) async {
    final confirmar = await mostrarConfirmacion(
      context,
      titulo: 'Dar baja definitiva',
      mensaje:
          '¿Está seguro de que desea dar de baja definitiva esta solicitud? '
          'Esta acción es irreversible y cambiará el estado a "Baja" (ID=4).',
      textoCancelar: 'Cancelar',
      textoConfirmar: 'Dar de baja',
    );
    if (confirmar != true || !context.mounted) return;
    await onDarBajaDefinitiva();
  }

  @override
  Widget build(BuildContext context) {
    final estado = provider.solicitud?.estado;
    final hayTransiciones = estado != null &&
        (estado == EstadoSolicitud.iniciada ||
            estado == EstadoSolicitud.enTramite ||
            estado == EstadoSolicitud.finalizada);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Botones de transición de estado (HU07 / HU08)
        if (hayTransiciones) ...[
          const Text(
            'Acciones de estado',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppPalette.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _botonesTransicion(context),
          ),
          const SizedBox(height: 20),
        ],
        // Botón de cancelar
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: onEliminar,
                icon: const Icon(Icons.delete_outline),
                label: const Text('Eliminar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppPalette.primary,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Botón individual de transición de estado.
class _BotonTransicion extends StatelessWidget {
  const _BotonTransicion({
    required this.texto,
    required this.icono,
    required this.color,
    required this.onPressed,
  });

  final String texto;
  final IconData icono;
  final Color color;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icono, size: 18),
      label: Text(texto, style: const TextStyle(fontSize: 12)),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        minimumSize: Size.zero,
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
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


