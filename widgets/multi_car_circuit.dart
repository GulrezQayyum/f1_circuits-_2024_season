import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:apex_f1/features/simulation/domain/race_sim_engine.dart';

// ─────────────────────────────────────────────────────────────────
//  MULTI-CAR CIRCUIT WIDGET
//  Location: lib/features/simulation/presentation/widgets/multi_car_circuit.dart
// ─────────────────────────────────────────────────────────────────

class MultiCarCircuit extends StatefulWidget {
  final List<SimDriver> drivers;
  final int totalLaps;
  final int currentLap;
  final bool safetyCar;
  final bool running;
  final int round;

  const MultiCarCircuit({
    super.key,
    required this.drivers,
    required this.totalLaps,
    required this.currentLap,
    required this.safetyCar,
    required this.running,
    required this.round,
  });

  @override
  State<MultiCarCircuit> createState() => _MultiCarCircuitState();
}

class _MultiCarCircuitState extends State<MultiCarCircuit>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  
  // Normalized path points (0..1)
  late List<Offset> _path;

  @override
  void initState() {
    super.initState();
    _path = _getCircuitPath(widget.round);
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    if (widget.running) _controller.repeat();
  }

  @override
  void didUpdateWidget(MultiCarCircuit oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.running && !oldWidget.running) {
      _controller.repeat();
    } else if (!widget.running && oldWidget.running) {
      _controller.stop();
    }
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
          painter: _MultiCarPainter(
            path: _path,
            drivers: widget.drivers,
            animationValue: _controller.value,
            safetyCar: widget.safetyCar,
            currentLap: widget.currentLap,
            totalLaps: widget.totalLaps,
          ),
          child: Container(),
        );
      },
    );
  }

  List<Offset> _getCircuitPath(int round) {
    // Tracing circuit outline (same as your existing points)
    return switch (round) {
      3 => const [
          Offset(0.50, 0.08), Offset(0.72, 0.10), Offset(0.88, 0.18),
          Offset(0.92, 0.35), Offset(0.88, 0.52), Offset(0.80, 0.65),
          Offset(0.82, 0.78), Offset(0.70, 0.90), Offset(0.50, 0.92),
          Offset(0.30, 0.90), Offset(0.18, 0.78), Offset(0.20, 0.65),
          Offset(0.12, 0.52), Offset(0.08, 0.35), Offset(0.12, 0.18),
          Offset(0.28, 0.10), Offset(0.50, 0.08),
        ],
      _ => const [
          Offset(0.50, 0.08), Offset(0.72, 0.10), Offset(0.88, 0.22),
          Offset(0.92, 0.42), Offset(0.82, 0.60), Offset(0.68, 0.72),
          Offset(0.65, 0.85), Offset(0.50, 0.92), Offset(0.35, 0.85),
          Offset(0.32, 0.72), Offset(0.18, 0.60), Offset(0.08, 0.42),
          Offset(0.12, 0.22), Offset(0.28, 0.10), Offset(0.50, 0.08),
        ],
    };
  }
}

class _MultiCarPainter extends CustomPainter {
  final List<Offset> path;
  final List<SimDriver> drivers;
  final double animationValue;
  final bool safetyCar;
  final int currentLap;
  final int totalLaps;

  _MultiCarPainter({
    required this.path,
    required this.drivers,
    required this.animationValue,
    required this.safetyCar,
    required this.currentLap,
    required this.totalLaps,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (path.isEmpty) return;
    const pad = 20.0;
    final pts = path.map((p) => Offset(
      pad + p.dx * (size.width - pad * 2),
      pad + p.dy * (size.height - pad * 2),
    )).toList();

    final trackPath = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (var i = 1; i < pts.length; i++) {
      trackPath.lineTo(pts[i].dx, pts[i].dy);
    }

    // 1. Draw Track
    canvas.drawPath(trackPath, Paint()
      ..color = Colors.white.withOpacity(0.1)
      ..strokeWidth = 6
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round);

    canvas.drawPath(trackPath, Paint()
      ..color = const Color(0xFF00E5FF).withOpacity(0.2)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke);

    // 2. Draw Drivers
    for (final driver in drivers) {
      if (driver.retired) continue;

      // Calculate progress: each driver has a slightly different offset on the track based on gap
      // This is a simplified visual representation
      double progress = (animationValue + (driver.position * 0.04)) % 1.0;
      
      final carPt = _getPointOnPath(pts, progress);
      final color = driver.isPlayer ? const Color(0xFF00E5FF) : Colors.white.withOpacity(0.4);
      final size = driver.isPlayer ? 5.0 : 3.0;

      // Car glow
      if (driver.isPlayer) {
        canvas.drawCircle(carPt, 10, Paint()
          ..color = color.withOpacity(0.2)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6));
      }

      canvas.drawCircle(carPt, size, Paint()..color = color);
    }

    // 3. Safety Car Overlay
    if (safetyCar) {
      final scPt = _getPointOnPath(pts, animationValue);
      canvas.drawCircle(scPt, 6, Paint()..color = const Color(0xFFFFE600));
      canvas.drawCircle(scPt, 12, Paint()
        ..color = const Color(0xFFFFE600).withOpacity(0.2)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8));
    }
  }

  Offset _getPointOnPath(List<Offset> pts, double t) {
    final total = pts.length - 1;
    final segF = t * total;
    final segI = segF.floor().clamp(0, total - 1);
    final segT = segF - segI;
    return Offset.lerp(pts[segI], pts[segI + 1], segT)!;
  }

  @override
  bool shouldRepaint(covariant _MultiCarPainter old) => true;
}
