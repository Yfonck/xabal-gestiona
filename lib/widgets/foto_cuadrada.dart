import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../config/theme.dart';

/// Foto con esquinas redondeadas y borde de color (HU05 y HU06).
///
/// Acepta la foto del backend en formato `data:image/...;base64,...` o el
/// base64 puro; si no hay foto muestra las iniciales del nombre.
class FotoCuadrada extends StatelessWidget {
  const FotoCuadrada({
    super.key,
    this.fotoBase64,
    required this.nombre,
    this.tamano = 48,
    this.colorBorde = AppPalette.tertiary,
    this.radio = 8,
  });

  final String? fotoBase64;
  final String nombre;
  final double tamano;
  final Color colorBorde;
  final double radio;

  @override
  Widget build(BuildContext context) {
    final bytes = _decodificar(fotoBase64);

    return Container(
      width: tamano,
      height: tamano,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radio),
        border: Border.all(color: colorBorde, width: 1.6),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radio - 2),
        child: bytes != null
            ? Image.memory(bytes, fit: BoxFit.cover)
            : Container(
                color: AppPalette.secondarySoft,
                alignment: Alignment.center,
                child: Text(
                  _iniciales(nombre),
                  style: TextStyle(
                    color: AppPalette.secondary,
                    fontWeight: FontWeight.w600,
                    fontSize: tamano * 0.32,
                  ),
                ),
              ),
      ),
    );
  }

  static Uint8List? _decodificar(String? foto) {
    if (foto == null || foto.trim().isEmpty) return null;
    try {
      final limpio = foto.contains(',') ? foto.split(',').last : foto;
      return base64Decode(limpio);
    } catch (_) {
      return null;
    }
  }

  static String _iniciales(String nombre) {
    final partes = nombre
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();
    if (partes.isEmpty) return '?';
    if (partes.length == 1) return partes.first.substring(0, 1).toUpperCase();
    return (partes.first.substring(0, 1) + partes.last.substring(0, 1))
        .toUpperCase();
  }
}
