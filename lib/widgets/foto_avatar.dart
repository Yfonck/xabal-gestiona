import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../config/theme.dart';

/// Avatar circular de una persona.
///
/// Acepta la foto del backend en formato `data:image/...;base64,...` o el
/// base64 puro; si no hay foto (o no se puede decodificar) muestra las
/// iniciales del nombre.
class FotoAvatar extends StatelessWidget {
  const FotoAvatar({
    super.key,
    this.fotoBase64,
    required this.nombre,
    this.radio = 24,
  });

  final String? fotoBase64;
  final String nombre;
  final double radio;

  @override
  Widget build(BuildContext context) {
    final bytes = _decodificar(fotoBase64);
    final dimension = radio * 2;

    if (bytes != null) {
      return CircleAvatar(
        radius: radio,
        backgroundColor: AppPalette.inputFill,
        backgroundImage: MemoryImage(bytes),
      );
    }

    return CircleAvatar(
      radius: radio,
      backgroundColor: AppPalette.secondarySoft,
      child: Text(
        _iniciales(nombre),
        style: TextStyle(
          color: AppPalette.secondary,
          fontWeight: FontWeight.w600,
          fontSize: dimension * 0.36,
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
    final partes =
        nombre.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (partes.isEmpty) return '?';
    if (partes.length == 1) return partes.first.substring(0, 1).toUpperCase();
    return (partes.first.substring(0, 1) + partes.last.substring(0, 1))
        .toUpperCase();
  }
}
