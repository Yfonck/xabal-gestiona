import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/theme.dart';
import '../../models/api_error.dart';
import '../../models/area_confirmacion.dart';
import '../../models/filtros_baja.dart';
import '../../models/opcion_filtro.dart';
import '../../models/persona.dart';
import '../../providers/persona_provider.dart';
import '../../providers/solicitud_provider.dart';
import '../../services/baja_service.dart';
import '../../services/notificacion_service.dart';
import '../../widgets/foto_avatar.dart';
import '../../widgets/searchable_list.dart';

/// HU03 — Modal de creación de solicitud de baja en dos pasos.
Future<bool?> mostrarCrearSolicitud(
  BuildContext context,
  FiltrosBaja filtros,
) {
  return showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (context) => CrearSolicitudDialog(filtros: filtros),
  );
}

class CrearSolicitudDialog extends StatefulWidget {
  const CrearSolicitudDialog({super.key, required this.filtros});

  final FiltrosBaja filtros;

  @override
  State<CrearSolicitudDialog> createState() => _CrearSolicitudDialogState();
}

class _CrearSolicitudDialogState extends State<CrearSolicitudDialog> {
  int _paso = 1;

  OpcionFiltro? _tipo;
  OpcionFiltro? _causa;
  Persona? _persona;
  bool _guardando = false;
  String? _errorMensaje;

  bool get _paso1Completo => _tipo != null && _causa != null;

  Future<void> _guardar() async {
    if (_persona == null || _tipo == null || _causa == null) return;

    setState(() {
      _guardando = true;
      _errorMensaje = null;
    });

    try {
      final nuevaSolicitud = await context.read<SolicitudProvider>().crear(
            idPersona: _persona!.idPersona,
            idTipoBaja: _tipo!.id!,
            idCausaBaja: _causa!.id!,
          );

      if (mounted) Navigator.of(context).pop(true);

      // Notificar a los directivos de las áreas que deben confirmar la baja
      _notificarDirectivosDeAreas(nuevaSolicitud.idSolicitud);
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _guardando = false;
        _errorMensaje = error.mensaje;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _guardando = false;
        _errorMensaje = 'No se pudo guardar la solicitud.';
      });
    }
  }

  /// Notifica a los directivos de las áreas que deben confirmar la baja.
  Future<void> _notificarDirectivosDeAreas(int idSolicitud) async {
    try {
      final servicioBajas = BajaService();
      final areas = await servicioBajas.areasConfirmacion(idSolicitud);

      final personaProvider = PersonaProvider();
      final notificacionService = NotificacionService();

      for (final area in areas) {
        final directivos = await personaProvider.buscarDirectivosPorArea(area.idArea!);

        for (final directivo in directivos) {
          await notificacionService.crear(
            titulo: 'Nueva solicitud de baja pendiente',
            mensaje:
                'Se ha creado una nueva solicitud de baja que requiere confirmación de su área. Solicitante: ${_persona!.nombre}.',
            link: '/bajas/${idSolicitud}',
          );
        }
      }
    } catch (_) {
      // No bloquear el flujo principal si falla el envío de notificaciones
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520, maxHeight: 640),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  const Align(
                    alignment: Alignment.center,
                    child: Text(
                      'Crear solicitud de baja',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppPalette.textPrimary,
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: IconButton(
                      tooltip: 'Cerrar',
                      onPressed: () => Navigator.of(context).pop(false),
                      icon: const Icon(Icons.close, size: 26),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _IndicadorPasos(paso: _paso),
              const SizedBox(height: 20),
              if (_paso == 1)
                Flexible(child: SingleChildScrollView(child: _formularioPaso1()))
              else
                Expanded(child: _paso2()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _formularioPaso1() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _CampoCatalogo(
          etiqueta: 'Tipo de baja',
          icono: Icons.layers_outlined,
          valor: _tipo,
          opciones: widget.filtros.tipos,
          onCambiar: (opcion) => setState(() => _tipo = opcion),
        ),
        const SizedBox(height: 22),
        _CampoCatalogo(
          etiqueta: 'Causa de baja',
          icono: Icons.help_outline,
          valor: _causa,
          opciones: widget.filtros.causas,
          onCambiar: (opcion) => setState(() => _causa = opcion),
        ),
        const SizedBox(height: 26),
        Row(
          children: [
            Switch(
              // TODO: Validar con PO. El backend no expone un "estado activo"
              // al crear la solicitud; se crea directamente en En Trámite.
              value: true,
              onChanged: null,
            ),
            const SizedBox(width: 8),
            const Text(
              'Estado activo',
              style: TextStyle(
                fontSize: 16,
                color: AppPalette.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        _AccionCircular(
          icono: Icons.arrow_forward,
          onTap: _paso1Completo ? () => setState(() => _paso = 2) : null,
          alineacion: Alignment.centerRight,
        ),
      ],
    );
  }

  Widget _paso2() {
    return ChangeNotifierProvider<PersonaProvider>(
      create: (_) => PersonaProvider(),
      child: Consumer<PersonaProvider>(
        builder: (context, provider, _) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Center(
                child: Text(
                  'Buscar persona',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppPalette.textPrimary,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Expanded(
                child: SearchableList<Persona>(
                  autofocus: false,
                  onBuscar: (termino) =>
                      provider.buscar(termino, soloActivas: true),
                  resultados: provider.personas,
                  cargando: provider.cargando,
                  hayMas: provider.hayMas,
                  onCargarMas: provider.cargarMas,
                  vacio: !provider.busco || provider.vacio,
                  errorMessage: provider.errorMessage,
                  mensajeVacio: provider.busco
                      ? 'No se encontraron personas activas'
                      : 'Escriba un nombre, CI o solapín',
                  itemBuilder: (context, persona) => _FilaPersona(
                    persona: persona,
                    seleccionada: _persona?.idPersona == persona.idPersona,
                    onSeleccionar: () => setState(() => _persona = persona),
                  ),
                ),
              ),
              if (_errorMensaje != null) ...[
                const SizedBox(height: 8),
                Text(
                  _errorMensaje!,
                  style: const TextStyle(color: AppPalette.error, fontSize: 13),
                ),
              ],
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _AccionCircular(
                    icono: Icons.arrow_back,
                    onTap: () => setState(() => _paso = 1),
                  ),
                  _guardando
                      ? const SizedBox(
                          width: 44,
                          height: 44,
                          child: Padding(
                            padding: EdgeInsets.all(10),
                            child: CircularProgressIndicator(strokeWidth: 2.4),
                          ),
                        )
                      : _AccionCircular(
                          icono: Icons.check,
                          onTap: _persona == null ? null : _guardar,
                        ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _IndicadorPasos extends StatelessWidget {
  const _IndicadorPasos({required this.paso});

  final int paso;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 22,
          height: 22,
          decoration: const BoxDecoration(
            color: AppPalette.tertiary,
            shape: BoxShape.circle,
          ),
        ),
        Expanded(
          child: Container(
            height: 4,
            margin: const EdgeInsets.symmetric(horizontal: 6),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: paso == 1
                    ? const [AppPalette.outline, AppPalette.outline]
                    : const [AppPalette.tertiary, AppPalette.secondary],
              ),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            color: paso == 2 ? AppPalette.secondary : AppPalette.outline,
            shape: BoxShape.circle,
          ),
        ),
      ],
    );
  }
}

class _CampoCatalogo extends StatelessWidget {
  const _CampoCatalogo({
    required this.etiqueta,
    required this.icono,
    required this.valor,
    required this.opciones,
    required this.onCambiar,
  });

  final String etiqueta;
  final IconData icono;
  final OpcionFiltro? valor;
  final List<OpcionFiltro> opciones;
  final ValueChanged<OpcionFiltro?> onCambiar;

  @override
  Widget build(BuildContext context) {
    // `DropdownButton` exige un único ítem por `value`: se eliminan opciones
    // repetidas (mismo `valor`) y se ignora un valor seleccionado que ya no
    // exista en la lista.
    final unicas = <OpcionFiltro>[];
    final valoresVistos = <String>{};
    for (final opcion in opciones) {
      if (valoresVistos.add(opcion.valor)) unicas.add(opcion);
    }
    final seleccionValida = unicas.contains(valor) ? valor : null;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: AppPalette.inputFill,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppPalette.outline),
          ),
          child: Icon(icono, color: AppPalette.tertiary, size: 24),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                etiqueta,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppPalette.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                height: 44,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: AppPalette.inputFill,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppPalette.outline),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<OpcionFiltro>(
                    isExpanded: true,
                    value: seleccionValida,
                    hint: const Text(
                      '-Seleccione-',
                      style: TextStyle(color: AppPalette.textSecondary),
                    ),
                    icon: const Icon(Icons.keyboard_arrow_down,
                        color: AppPalette.textSecondary),
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppPalette.textPrimary,
                    ),
                    items: unicas
                        .map(
                          (opcion) => DropdownMenuItem<OpcionFiltro>(
                            value: opcion,
                            child: Text(
                              opcion.etiqueta,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: onCambiar,
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

class _FilaPersona extends StatelessWidget {
  const _FilaPersona({
    required this.persona,
    required this.seleccionada,
    required this.onSeleccionar,
  });

  final Persona persona;
  final bool seleccionada;
  final VoidCallback onSeleccionar;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onSeleccionar,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: AppPalette.outlineSoft)),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 28,
              child: seleccionada
                  ? const Icon(Icons.check_box,
                      color: AppPalette.tertiary, size: 22)
                  : const Icon(Icons.check_box_outline_blank,
                      color: AppPalette.outline, size: 22),
            ),
            FotoAvatar(
              fotoBase64: persona.fotoBase64,
              nombre: persona.nombre,
              radio: 18,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    persona.nombre,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppPalette.textPrimary,
                    ),
                  ),
                  if (persona.carnetIdentidad != null)
                    Text(
                      'CI ${persona.carnetIdentidad}',
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: AppPalette.textSecondary,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AccionCircular extends StatelessWidget {
  const _AccionCircular({
    required this.icono,
    required this.onTap,
    this.alineacion = Alignment.centerLeft,
  });

  final IconData icono;
  final VoidCallback? onTap;
  final Alignment alineacion;

  @override
  Widget build(BuildContext context) {
    final habilitado = onTap != null;
    return Align(
      alignment: alineacion,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: habilitado ? AppPalette.tertiary : AppPalette.outline,
              width: 2.5,
            ),
          ),
          child: Icon(
            icono,
            color: habilitado ? AppPalette.tertiary : AppPalette.outline,
            size: 24,
          ),
        ),
      ),
    );
  }
}
