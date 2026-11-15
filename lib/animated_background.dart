import 'dart:math';

import 'package:flutter/material.dart';

class AnimatedPolygonBackground extends StatefulWidget {
  const AnimatedPolygonBackground({super.key});

  @override
  State<AnimatedPolygonBackground> createState() =>
      _AnimatedPolygonBackgroundState();
}

class _AnimatedPolygonBackgroundState
    extends State<AnimatedPolygonBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 30),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          painter: _PolygonBackgroundPainter(
            progress: _controller.value,
          ),
          child: const SizedBox.expand(),
        );
      },
    );
  }
}

class _PolygonBackgroundPainter extends CustomPainter {
  final double progress;

  _PolygonBackgroundPainter({
    required this.progress,
  });

  final List<_FloatingShape> shapes = const [
    _FloatingShape(0.08, 0.12, 0.035, 0.015, 0.8, 0),
    _FloatingShape(0.22, 0.25, 0.025, 0.020, -0.5, 1),
    _FloatingShape(0.42, 0.10, 0.030, 0.018, 0.6, 2),
    _FloatingShape(0.67, 0.20, 0.020, 0.025, -0.7, 3),
    _FloatingShape(0.88, 0.12, 0.035, 0.020, 0.5, 4),

    _FloatingShape(0.15, 0.42, 0.022, 0.018, -0.6, 5),
    _FloatingShape(0.34, 0.52, 0.030, 0.015, 0.7, 6),
    _FloatingShape(0.58, 0.40, 0.025, 0.020, -0.4, 7),
    _FloatingShape(0.78, 0.50, 0.035, 0.018, 0.8, 8),
    _FloatingShape(0.94, 0.40, 0.020, 0.025, -0.5, 9),

    _FloatingShape(0.08, 0.68, 0.030, 0.018, 0.5, 10),
    _FloatingShape(0.28, 0.78, 0.020, 0.022, -0.7, 11),
    _FloatingShape(0.52, 0.70, 0.035, 0.020, 0.6, 12),
    _FloatingShape(0.72, 0.82, 0.025, 0.018, -0.5, 13),
    _FloatingShape(0.90, 0.70, 0.030, 0.022, 0.7, 14),

    _FloatingShape(0.40, 0.92, 0.020, 0.018, -0.6, 15),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    // ==================================================
    // FONDO GRADIENTE
    // ==================================================

    final backgroundPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFFDCEEFF),
          Color(0xFFEAF4FF),
          Color(0xFFF7F9FC),
          Color(0xFFFFFFFF),
        ],
        stops: [
          0.0,
          0.30,
          0.65,
          1.0,
        ],
      ).createShader(
        Rect.fromLTWH(
          0,
          0,
          size.width,
          size.height,
        ),
      );

    canvas.drawRect(
      Offset.zero & size,
      backgroundPaint,
    );

    // ==================================================
    // FIGURAS FLOTANTES
    // ==================================================

    for (final shape in shapes) {
      _drawShape(
        canvas,
        size,
        shape,
      );
    }
  }

  void _drawShape(
    Canvas canvas,
    Size size,
    _FloatingShape shape,
  ) {
    // Tiempo de animación
    final time = progress * 2 * pi;

    // Movimiento horizontal
    final movementX =
        sin(time * shape.speed + shape.phase) *
        size.width *
        0.035;

    // Movimiento vertical
    final movementY =
        cos(time * shape.speed + shape.phase) *
        size.height *
        0.045;

    final x = shape.x * size.width + movementX;

    final y = shape.y * size.height + movementY;

    // Rotación
    final rotation =
        time * shape.rotationSpeed * 0.15;

    final width =
        shape.width * size.width;

    final height =
        shape.height * size.height;

    // ==================================================
    // OPACIDAD
    // ==================================================

    final opacity =
        0.090 +
        (sin(time + shape.phase) + 1) * 0.012;

    final paint = Paint()
      ..color = const Color(0xFF1769C5).withOpacity(opacity)
      ..style = PaintingStyle.fill;

    // ==================================================
    // ROTACIÓN
    // ==================================================

    canvas.save();

    canvas.translate(x, y);

    canvas.rotate(rotation);

    // ==================================================
    // FORMAS
    // ==================================================

    switch (shape.type % 5) {
      // --------------------------------------------------
      // ROMBO
      // --------------------------------------------------

      case 0:
        final path = Path()
          ..moveTo(0, -height)
          ..lineTo(width, 0)
          ..lineTo(0, height)
          ..lineTo(-width, 0)
          ..close();

        canvas.drawPath(
          path,
          paint,
        );

        break;

      // --------------------------------------------------
      // TRIÁNGULO
      // --------------------------------------------------

      case 1:
        final path = Path()
          ..moveTo(0, -height)
          ..lineTo(width, height)
          ..lineTo(-width, height)
          ..close();

        canvas.drawPath(
          path,
          paint,
        );

        break;

      // --------------------------------------------------
      // HEXÁGONO
      // --------------------------------------------------

      case 2:
        final path = Path();

        for (int i = 0; i < 6; i++) {
          final angle =
              (pi / 3) * i - pi / 2;

          final px =
              cos(angle) * width;

          final py =
              sin(angle) * height;

          if (i == 0) {
            path.moveTo(px, py);
          } else {
            path.lineTo(px, py);
          }
        }

        path.close();

        canvas.drawPath(
          path,
          paint,
        );

        break;

      // --------------------------------------------------
      // RECTÁNGULO
      // --------------------------------------------------

      case 3:
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
              center: Offset.zero,
              width: width * 1.8,
              height: height * 1.3,
            ),
            const Radius.circular(3),
          ),
          paint,
        );

        break;

      // --------------------------------------------------
      // CÍRCULO
      // --------------------------------------------------

      case 4:
        canvas.drawCircle(
          Offset.zero,
          min(width, height),
          paint,
        );

        break;
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(
    covariant _PolygonBackgroundPainter oldDelegate,
  ) {
    return oldDelegate.progress != progress;
  }
}

// ======================================================
// FIGURA FLOTANTE
// ======================================================

class _FloatingShape {
  final double x;
  final double y;

  final double width;
  final double height;

  final double speed;

  final int type;

  final double phase;

  const _FloatingShape(
    this.x,
    this.y,
    this.width,
    this.height,
    this.speed,
    this.type, [
    this.phase = 0,
  ]);

  double get rotationSpeed {
    return speed * 0.35;
  }
}