import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../config/routes.dart';
import '../../config/theme.dart';
import '../../models/opcion_filtro.dart';
import '../../models/persona.dart';
import '../../providers/auth_provider.dart';
import '../../providers/notificacion_provider.dart';
import '../../providers/persona_provider.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/decoracion_superior.dart';
import '../../widgets/foto_avatar.dart';
import '../../widgets/marca_xabal.dart';
import '../../widgets/searchable_list.dart';

/// HU04 — Búsqueda de personas con filtros avanzados.
class PersonasScreen extends StatefulWidget {
  const PersonasScreen({super.key});

  @override
  State<PersonasScreen> createState() => _PersonasScreenState();
}

class _PersonasScreenState extends State<PersonasScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final PersonaProvider _personas = PersonaProvider();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      await _personas.cargarFiltros();
      if (!mounted) return;
      // Cargar todas las personas por defecto al abrir la pantalla
      await _buscar('');
    });
  }

  @override
  void dispose() {
    _personas.dispose();
    super.dispose();
  }

  Future<void> _buscar(String termino) {
    return _personas.buscar(
      termino,
      idEstructura: null,
      soloActivas: _personas.soloActivas,
    );
  }

  void _avisar(String mensaje) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(mensaje)));
  }

  OpcionFiltro? _estructuraDe(PersonaProvider provider) {
    for (final opcion in provider.filtros.estructuras) {
      if (opcion.id == provider.idEstructura) return opcion;
    }
    return null;
  }

  Future<void> _abrirFiltros() async {
    await _personas.cargarFiltros();
    if (!mounted) return;

    var estructura = _personas.idEstructura;
    var soloActivas = _personas.soloActivas;

    final aplicar = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateSheet) {
            final estructuras =
                OpcionFiltro.conIdNumericoUnico(_personas.filtros.estructuras);
            final estructuraValida =
                estructuras.any((opcion) => opcion.id == estructura)
                    ? estructura
                    : null;

            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 16,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 44,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppPalette.outline,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Filtros avanzados',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppPalette.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'El servidor busca por nombre, apellidos, CI y solapín.',
                    style: TextStyle(
                      fontSize: 12.5,
                      color: AppPalette.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Estructura',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppPalette.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
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
                        value: estructuraValida,
                        hint: const Text('Todas las estructuras'),
                        icon: const Icon(Icons.keyboard_arrow_down,
                            color: AppPalette.textSecondary),
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppPalette.textPrimary,
                        ),
                        items: [
                          const DropdownMenuItem<int?>(
                            value: null,
                            child: Text('Todas las estructuras'),
                          ),
                          ...estructuras.map(
                            (OpcionFiltro opcion) =>
                                DropdownMenuItem<int?>(
                              value: opcion.id,
                              child: Text(
                                opcion.etiqueta,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ],
                        onChanged: (valor) =>
                            setStateSheet(() => estructura = valor),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    title: const Text(
                      'Solo personas activas',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: const Text(
                      'Excluye a las personas que ya están de baja',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppPalette.textSecondary,
                      ),
                    ),
                    value: soloActivas,
                    onChanged: (valor) =>
                        setStateSheet(() => soloActivas = valor),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            setStateSheet(() {
                              estructura = null;
                              soloActivas = true;
                            });
                          },
                          child: const Text('Limpiar'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => Navigator.of(context).pop(true),
                          child: const Text('Aplicar'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    if (aplicar != true || !mounted) return;

    await _personas.aplicarFiltros(
      idEstructura: estructura,
      soloActivas: soloActivas,
    );
  }

  Future<void> _verDetalle(Persona persona) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => _DetallePersona(persona: persona),
    );
  }

  void _modificar(Persona persona) {
    // TODO(HU09): el backend no expone PATCH para personas (BD externa).
    _avisar('La modificación de personas estará disponible en la HU09.');
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<PersonaProvider>.value(
      value: _personas,
      child: Builder(
        builder: (context) {
          final auth = context.watch<AuthProvider>();
          final noLeidas = context.watch<NotificacionProvider>().noLeidas;
          final provider = context.watch<PersonaProvider>();
          final usuario = auth.usuario;

          return Scaffold(
            key: _scaffoldKey,
            backgroundColor: AppPalette.surface,
            drawer: const AppDrawer(rutaActual: AppRoutes.personas),
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
                    onAbrirMenu: () =>
                        _scaffoldKey.currentState?.openDrawer(),
                    onNotificaciones: () =>
                        context.push(AppRoutes.notificaciones),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
                    child: Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Buscar persona',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppPalette.textPrimary,
                            ),
                          ),
                        ),
                        OutlinedButton.icon(
                          onPressed: _abrirFiltros,
                          icon: const Icon(Icons.tune, size: 18),
                          label: const Text('Filtros'),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(0, 40),
                            padding:
                                const EdgeInsets.symmetric(horizontal: 12),
                            textStyle: const TextStyle(fontSize: 13.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                  _FiltrosActivos(
                    estructura: _estructuraDe(provider),
                    soloActivas: provider.soloActivas,
                    onQuitarEstructura: () => provider.aplicarFiltros(
                      soloActivas: provider.soloActivas,
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                      child: SearchableList<Persona>(
                        onBuscar: _buscar,
                        resultados: provider.personas,
                        cargando: provider.cargando,
                        hayMas: provider.hayMas,
                        onCargarMas: provider.cargarMas,
                        vacio: !provider.busco || provider.vacio,
                        mensajeVacio: provider.busco
                            ? 'No se encontraron personas'
                            : 'Escriba un nombre, CI o solapín para buscar',
                        errorMessage: provider.errorMessage,
                        itemBuilder: (context, persona) => _FilaPersona(
                          persona: persona,
                          onVer: () => _verDetalle(persona),
                          onModificar: () => _modificar(persona),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
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
              'Personas',
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

class _FiltrosActivos extends StatelessWidget {
  const _FiltrosActivos({
    required this.estructura,
    required this.soloActivas,
    required this.onQuitarEstructura,
  });

  final OpcionFiltro? estructura;
  final bool soloActivas;
  final VoidCallback onQuitarEstructura;

  @override
  Widget build(BuildContext context) {
    if (estructura == null && soloActivas) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Wrap(
          spacing: 8,
          runSpacing: 6,
          children: [
            if (estructura != null)
              InputChip(
                label: Text(estructura!.etiqueta),
                onDeleted: onQuitarEstructura,
                visualDensity: VisualDensity.compact,
              ),
            if (!soloActivas)
              const Chip(
                label: Text('Incluye personas de baja'),
                visualDensity: VisualDensity.compact,
              ),
          ],
        ),
      ),
    );
  }
}

class _FilaPersona extends StatelessWidget {
  const _FilaPersona({
    required this.persona,
    required this.onVer,
    required this.onModificar,
  });

  final Persona persona;
  final VoidCallback onVer;
  final VoidCallback onModificar;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppPalette.outlineSoft)),
      ),
      child: Row(
        children: [
          FotoAvatar(
            fotoBase64: persona.fotoBase64,
            nombre: persona.nombre,
            radio: 22,
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
                    fontWeight: FontWeight.w600,
                    color: AppPalette.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  [
                    if (persona.carnetIdentidad != null)
                      'CI ${persona.carnetIdentidad}',
                    if (persona.nombreEstructura != null)
                      persona.nombreEstructura!,
                  ].join(' · '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: AppPalette.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Ver detalles',
            onPressed: onVer,
            icon: const Icon(Icons.visibility_outlined,
                color: AppPalette.success, size: 21),
            visualDensity: VisualDensity.compact,
          ),
          IconButton(
            tooltip: 'Modificar',
            onPressed: onModificar,
            icon: const Icon(Icons.edit_outlined,
                color: AppPalette.tertiary, size: 20),
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }
}

class _DetallePersona extends StatelessWidget {
  const _DetallePersona({required this.persona});

  final Persona persona;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: AppPalette.outline,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              FotoAvatar(
                fotoBase64: persona.fotoBase64,
                nombre: persona.nombre,
                radio: 28,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      persona.nombre,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppPalette.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        color: persona.activa
                            ? AppPalette.successSoft
                            : AppPalette.primarySoft,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        persona.activa ? 'Activo' : 'De baja',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: persona.activa
                              ? AppPalette.success
                              : AppPalette.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          _DatoFila(
            icono: Icons.badge_outlined,
            etiqueta: 'Carnet de identidad',
            valor: persona.carnetIdentidad ?? 'No registrado',
          ),
          _DatoFila(
            icono: Icons.confirmation_number_outlined,
            etiqueta: 'Solapín',
            valor: persona.numeroSolapin ?? 'No registrado',
          ),
          _DatoFila(
            icono: Icons.account_balance_outlined,
            etiqueta: 'Estructura',
            valor: persona.nombreEstructura ?? 'No registrada',
          ),
          _DatoFila(
            icono: Icons.work_outline,
            etiqueta: 'Responsabilidad',
            valor: persona.nombreResponsabilidad ?? 'No registrada',
          ),
          _DatoFila(
            icono: Icons.school_outlined,
            etiqueta: 'Rol universitario',
            valor: persona.nombreRolUniversitario ?? 'No registrado',
          ),
          const SizedBox(height: 18),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }
}

class _DatoFila extends StatelessWidget {
  const _DatoFila({
    required this.icono,
    required this.etiqueta,
    required this.valor,
  });

  final IconData icono;
  final String etiqueta;
  final String valor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icono, size: 19, color: AppPalette.textSecondary),
          const SizedBox(width: 10),
          SizedBox(
            width: 138,
            child: Text(
              etiqueta,
              style: const TextStyle(
                fontSize: 13,
                color: AppPalette.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              valor,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppPalette.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
