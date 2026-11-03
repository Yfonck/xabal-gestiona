import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../config/routes.dart';
import '../../config/theme.dart';
import '../../models/area_confirmacion.dart';
import '../../models/solicitud_baja.dart';
import '../../providers/auth_provider.dart';
import '../../providers/detalle_solicitud_provider.dart';
import '../../providers/notificacion_provider.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/confirm_dialog.dart';
import '../../widgets/encabezado_pantalla.dart';
import '../../widgets/foto_cuadrada.dart';

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

  void _editar() {
    // TODO(HU09): el backend aún no expone PATCH para solicitudes de baja.
    _avisar('La edición de la solicitud estará disponible en la HU09.');
  }

  Future<void> _eliminar() async {
    final confirmar = await mostrarConfirmacion(
      context,
      titulo: 'Eliminar solicitud',
      mensaje: '¿Está seguro de que desea eliminar esta solicitud de baja?',
      textoCancelar: 'Cancelar',
      textoConfirmar: 'Eliminar',
    );
    if (!confirmar || !mounted) return;
    // TODO(HU09): el backend aún no expone DELETE para solicitudes de baja.
    _avisar(
      'La eliminación estará disponible cuando el backend la habilite (HU09).',
    );
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
                onEditar: _editar,
                onEliminar: _eliminar,
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
    required this.onEditar,
    required this.onEliminar,
  });

  final DetalleSolicitudProvider provider;
  final VoidCallback onEditar;
  final VoidCallback onEliminar;

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
            _Acciones(onEditar: onEditar, onEliminar: onEliminar),
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

class _TarjetaAreas extends StatelessWidget {
  const _TarjetaAreas({required this.areas});

  final List<AreaConfirmacion> areas;

  static const TextStyle _estiloCabecera = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w700,
    color: AppPalette.textPrimary,
  );

  @override
  Widget build(BuildContext context) {
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
          const Row(
            children: [
              Expanded(
                flex: 6,
                child: Text('Áreas de Bajas', style: _estiloCabecera),
              ),
              Expanded(flex: 3, child: Text('Estado', style: _estiloCabecera)),
              Expanded(
                flex: 3,
                child: Text(
                  'Fecha',
                  textAlign: TextAlign.end,
                  style: _estiloCabecera,
                ),
              ),
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
            for (final area in areas) _FilaArea(area: area),
        ],
      ),
    );
  }
}

class _FilaArea extends StatelessWidget {
  const _FilaArea({required this.area});

  final AreaConfirmacion area;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 6,
            child: Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Text(
                area.nombreArea,
                style: const TextStyle(
                  fontSize: 12.5,
                  color: AppPalette.textPrimary,
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
            flex: 3,
            child: Text(
              _formatearFecha(area.fecha),
              textAlign: TextAlign.end,
              style: const TextStyle(
                fontSize: 12.5,
                color: AppPalette.textSecondary,
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

// ---------------------------------------------------------------------------
// Acciones y estados de error
// ---------------------------------------------------------------------------

class _Acciones extends StatelessWidget {
  const _Acciones({required this.onEditar, required this.onEliminar});

  final VoidCallback onEditar;
  final VoidCallback onEliminar;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: onEditar,
            icon: const Icon(Icons.edit_outlined),
            label: const Text('Editar'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppPalette.tertiary,
            ),
          ),
        ),
        const SizedBox(width: 12),
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
