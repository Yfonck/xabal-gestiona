import 'package:flutter/material.dart';

import '../config/theme.dart';

/// Diálogo de confirmación reutilizable (HU09/HU10).
///
/// Muestra una advertencia y dos acciones: cancelar (amarillo) y confirmar
/// (rojo por defecto).
Future<bool> mostrarConfirmacion(
  BuildContext context, {
  required String titulo,
  required String mensaje,
  String textoCancelar = 'Cancelar',
  String textoConfirmar = 'Eliminar',
  Color colorConfirmar = AppPalette.error,
}) async {
  final resultado = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Row(
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            color: AppPalette.warning,
            size: 28,
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(titulo)),
        ],
      ),
      content: Text(mensaje),
      actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      actions: [
        Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(false),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppPalette.warning,
                  foregroundColor: const Color(0xFF3D2A00),
                ),
                child: Text(textoCancelar),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorConfirmar,
                  foregroundColor: Colors.white,
                ),
                child: Text(textoConfirmar),
              ),
            ),
          ],
        ),
      ],
    ),
  );

  return resultado ?? false;
}
