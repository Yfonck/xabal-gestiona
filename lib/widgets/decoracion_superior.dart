import 'package:flutter/material.dart';

/// Cintas rojas decorativas de la cabecera del login.
///
/// Reproduce el recurso gráfico del diseño sin depender de imágenes: tres
/// bandas curvas con distintos tonos y opacidades.
class DecoracionSuperior extends StatelessWidget {
  const DecoracionSuperior({super.key, this.altura = 200});

  final double altura;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: altura,
      width: double.infinity,
      child: CustomPaint(painter: _CintasPainter()),
    );
  }
}

class _CintasPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final ancho = size.width;
    final alto = size.height;

    // Banda clara de fondo.
    final claro = Path()
      ..moveTo(0, 0)
      ..lineTo(ancho * 0.62, 0)
      ..cubicTo(
        ancho * 0.4,
        alto * 0.34,
        ancho * 0.24,
        alto * 0.22,
        0,
        alto * 0.48,
      )
      ..close();
    canvas.drawPath(
      claro,
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0x33F24E4E), Color(0x11F24E4E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ).createShader(Offset.zero & size),
    );

    // Banda media.
    final media = Path()
      ..moveTo(0, 0)
      ..lineTo(ancho * 0.92, 0)
      ..cubicTo(
        ancho * 0.72,
        alto * 0.5,
        ancho * 0.5,
        alto * 0.5,
        ancho * 0.12,
        alto * 0.34,
      )
      ..cubicTo(ancho * 0.06, alto * 0.3, 0, alto * 0.32, 0, alto * 0.32)
      ..close();
    canvas.drawPath(
      media,
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0x66F24E4E), Color(0x22F24E4E)],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ).createShader(Offset.zero & size),
    );

    // Banda intensa superior.
    final intensa = Path()
      ..moveTo(0, 0)
      ..lineTo(ancho, 0)
      ..cubicTo(
        ancho * 0.9,
        alto * 0.3,
        ancho * 0.62,
        alto * 0.42,
        ancho * 0.3,
        alto * 0.2,
      )
      ..cubicTo(ancho * 0.18, alto * 0.12, ancho * 0.1, alto * 0.06, 0, 0)
      ..close();
    canvas.drawPath(
      intensa,
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFFF2554F), Color(0xFFC81E2C)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(Offset.zero & size),
    );

    // Filo blanco que separa la cinta del fondo.
    final filo = Path()
      ..moveTo(0, alto * 0.02)
      ..cubicTo(
        ancho * 0.34,
        alto * 0.46,
        ancho * 0.66,
        alto * 0.52,
        ancho,
        alto * 0.14,
      );
    canvas.drawPath(
      filo,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.55)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
