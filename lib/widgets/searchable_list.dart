import 'dart:async';

import 'package:flutter/material.dart';

import '../config/theme.dart';

/// Lista con buscador reutilizable (HU04 y paso 2 de HU03).
///
/// Aplica un debounce de 300 ms y notifica cuando el usuario llega al final
/// para cargar la siguiente página.
class SearchableList<T> extends StatefulWidget {
  const SearchableList({
    super.key,
    required this.onBuscar,
    required this.resultados,
    required this.itemBuilder,
    this.hint = 'Nombre, Apellidos, CI, Solapín',
    this.cargando = false,
    this.hayMas = false,
    this.onCargarMas,
    this.vacio = false,
    this.errorMessage,
    this.mensajeVacio = 'No se encontraron resultados',
    this.autofocus = false,
  });

  final Future<void> Function(String termino) onBuscar;
  final List<T> resultados;
  final Widget Function(BuildContext context, T item) itemBuilder;
  final String hint;
  final bool cargando;
  final bool hayMas;
  final Future<void> Function()? onCargarMas;
  final bool vacio;
  final String? errorMessage;
  final String mensajeVacio;
  final bool autofocus;

  @override
  State<SearchableList<T>> createState() => _SearchableListState<T>();
}

class _SearchableListState<T> extends State<SearchableList<T>> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_alEscribir);
    _scrollController.addListener(_alDesplazar);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.removeListener(_alEscribir);
    _scrollController.removeListener(_alDesplazar);
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _alEscribir() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      widget.onBuscar(_controller.text);
    });
  }

  void _buscarAhora() {
    _debounce?.cancel();
    widget.onBuscar(_controller.text);
  }

  void _alDesplazar() {
    if (!_scrollController.hasClients) return;
    final posicion = _scrollController.position;
    if (posicion.pixels >= posicion.maxScrollExtent - 200 &&
        widget.hayMas &&
        !widget.cargando) {
      widget.onCargarMas?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                autofocus: widget.autofocus,
                textInputAction: TextInputAction.search,
                onSubmitted: (_) => _buscarAhora(),
                decoration: InputDecoration(
                  hintText: widget.hint,
                  isDense: true,
                ),
              ),
            ),
            const SizedBox(width: 10),
            SizedBox(
              width: 52,
              height: 48,
              child: ElevatedButton(
                onPressed: _buscarAhora,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppPalette.primary,
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(52, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Icon(Icons.search, color: Colors.white, size: 24),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Expanded(
          child: _contenido(),
        ),
      ],
    );
  }

  Widget _contenido() {
    if (widget.cargando && widget.resultados.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (widget.errorMessage != null && widget.resultados.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off_outlined,
                  size: 44, color: AppPalette.error),
              const SizedBox(height: 10),
              Text(widget.errorMessage!, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: _buscarAhora,
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }

    if (widget.vacio) {
      return Center(
        child: Text(
          widget.mensajeVacio,
          style: const TextStyle(color: AppPalette.textSecondary),
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: EdgeInsets.zero,
      itemCount: widget.resultados.length + (widget.hayMas ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= widget.resultados.length) {
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
        return widget.itemBuilder(context, widget.resultados[index]);
      },
    );
  }
}
