import 'dart:math';
import 'package:flutter/material.dart';
import 'package:apex_f1/features/simulation/domain/race_sim_engine.dart';
import 'package:apex_f1/features/simulation/data/circuits/circuit_paths.dart';

// ─────────────────────────────────────────────────────────────────
//  APEX F1 — Multi-Car Circuit Visualization
//  Location: lib/features/simulation/presentation/widgets/
//            multi_car_circuit_painter.dart
//
//  GPS-accurate circuit map with all 20 cars racing as dots.
//  Supports Monaco + 10 other circuits.
//  Circuit is centered and fills the full widget area.
// ─────────────────────────────────────────────────────────────────

// ── 2024 F1 team colors ──────────────────────────────────────────
const Map<String, Color> _kTeamColors = {
  'ver': Color(0xFF3671C6), 'per': Color(0xFF3671C6),
  'lec': Color(0xFFE8002D), 'sai': Color(0xFFE8002D),
  'ham': Color(0xFF27F4D2), 'rus': Color(0xFF27F4D2),
  'nor': Color(0xFFFF8000), 'pia': Color(0xFFFF8000),
  'alo': Color(0xFF358C75), 'str': Color(0xFF358C75),
  'gas': Color(0xFF0090FF), 'oco': Color(0xFF0090FF),
  'alb': Color(0xFF64C4FF), 'sar': Color(0xFF64C4FF),
  'tsu': Color(0xFF6692FF), 'ric': Color(0xFF6692FF),
  'hul': Color(0xFFB6BABD), 'mag': Color(0xFFB6BABD),
  'bot': Color(0xFF52E252), 'zho': Color(0xFF52E252),
};

const _kCyan   = Color(0xFF00E5FF);
const _kYellow = Color(0xFFFFE600);
const _kWhite  = Colors.white;
const _kBg     = Color(0xFF0A0A18);

// ─────────────────────────────────────────────────────────────────
//  WIDGET
// ─────────────────────────────────────────────────────────────────

class MultiCarCircuit extends StatefulWidget {
  final List<SimDriver> drivers;
  final int totalLaps;
  final int currentLap;
  final bool safetyCar;
  final bool running;
  final int round; // race round number to pick correct circuit

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
  late AnimationController _ctrl;
  late List<Offset> _path;

  @override
  void initState() {
    super.initState();
    _path = _getPath(widget.round);
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();
  }

  List<Offset> _getPath(int round) {
    return CircuitPaths.forRound(round);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => CustomPaint(
        painter: _MultiCarPainter(
          path:       _path,
          drivers:    widget.drivers,
          totalLaps:  widget.totalLaps,
          currentLap: widget.currentLap,
          safetyCar:  widget.safetyCar,
          animValue:  _ctrl.value,
          running:    widget.running,
          round:      widget.round,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
//  CUSTOM PAINTER
// ─────────────────────────────────────────────────────────────────

class _MultiCarPainter extends CustomPainter {
  final List<Offset> path;
  final List<SimDriver> drivers;
  final int totalLaps;
  final int currentLap;
  final bool safetyCar;
  final double animValue;
  final bool running;
  final int round;

  _MultiCarPainter({
    required this.path,
    required this.drivers,
    required this.totalLaps,
    required this.currentLap,
    required this.safetyCar,
    required this.animValue,
    required this.running,
    required this.round,
  });

  // ── Scale: normalised → canvas, with padding for labels ───────
  Offset _s(Offset p, Size sz) {
    // Add inner padding so track doesn't touch edges
    const pad = 0.06;
    final x = pad * sz.width + p.dx * sz.width * (1 - 2 * pad);
    final y = pad * sz.height + p.dy * sz.height * (1 - 2 * pad);
    return Offset(x, y);
  }

  // ── Interpolate along path at progress 0..1 ───────────────────
  Offset _pointAt(double progress, Size size) {
    final n = path.length - 1;
    final f = (progress % 1.0).abs() * n;
    final i = f.floor().clamp(0, n - 1);
    final t = f - i;
    final a = path[i];
    final b = path[(i + 1).clamp(0, path.length - 1)];
    return _s(
      Offset(a.dx + (b.dx - a.dx) * t, a.dy + (b.dy - a.dy) * t),
      size,
    );
  }

  // ── Calculate each car's track position ───────────────────────
  double _carProgress(SimDriver d) {
    if (totalLaps == 0 || drivers.isEmpty) return animValue * 0.12;

    final lapFrac = currentLap / totalLaps;

    if (safetyCar) {
      // Bunch cars close together under SC
      final base   = lapFrac + animValue * 0.055;
      final spread = d.position * 0.003;
      return (base + spread) % 1.0;
    }

    // Normal: spread by position, ~0.012 circuit per position
    final player     = drivers.firstWhere((x) => x.isPlayer,
        orElse: () => drivers.first);
    final relPos     = d.position - player.position;
    final posOffset  = relPos * 0.012;
    final base       = lapFrac + animValue * 0.14 - posOffset;
    return base % 1.0;
  }

  @override
  void paint(Canvas canvas, Size size) {
    // Background
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = _kBg,
    );

    _drawTrack(canvas, size);
    _drawStartFinish(canvas, size);
    _drawAllCars(canvas, size);
    _drawLegend(canvas, size);
    _drawCircuitName(canvas, size);
  }

  // ── Track ─────────────────────────────────────────────────────
  void _drawTrack(Canvas canvas, Size size) {
    final pts = path.map((p) => _s(p, size)).toList();

    final trackPath = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (int i = 1; i < pts.length; i++) {
      trackPath.lineTo(pts[i].dx, pts[i].dy);
    }

    // Outer shadow
    canvas.drawPath(trackPath, Paint()
      ..color = const Color(0xFF0D0D20)
      ..strokeWidth = size.shortestSide * 0.055
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round);

    // Dark tarmac
    canvas.drawPath(trackPath, Paint()
      ..color = const Color(0xFF1E1E35)
      ..strokeWidth = size.shortestSide * 0.042
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round);

    // Mid grey surface
    canvas.drawPath(trackPath, Paint()
      ..color = const Color(0xFF2C2C48)
      ..strokeWidth = size.shortestSide * 0.030
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round);

    // Neon cyan racing line edge
    canvas.drawPath(trackPath, Paint()
      ..color = _kCyan.withOpacity(0.22)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round);
  }

  // ── Start/Finish line ─────────────────────────────────────────
  void _drawStartFinish(Canvas canvas, Size size) {
    final sf = _s(path.first, size);

    // White line perpendicular to track direction
    canvas.drawLine(
      Offset(sf.dx - 6, sf.dy + 5),
      Offset(sf.dx + 6, sf.dy + 5),
      Paint()
        ..color = _kWhite.withOpacity(0.85)
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round,
    );

    _text(canvas, 'S/F', Offset(sf.dx + 8, sf.dy + 4),
        6.5, _kYellow.withOpacity(0.8));
  }

  // ── All 20 cars ───────────────────────────────────────────────
  void _drawAllCars(Canvas canvas, Size size) {
    // Draw back-markers first, player last (always on top)
    final sorted = [...drivers]
      ..sort((a, b) => b.position.compareTo(a.position));

    for (final d in sorted) {
      if (d.isPlayer) continue;
      _drawCar(canvas, size, d);
    }
    final player = drivers.firstWhere((d) => d.isPlayer,
        orElse: () => drivers.first);
    _drawCar(canvas, size, player);
  }

  void _drawCar(Canvas canvas, Size size, SimDriver d) {
    final progress = _carProgress(d);
    final pos      = _pointAt(progress, size);
    final isPlayer = d.isPlayer;

    Color color;
    if (safetyCar) {
      color = isPlayer ? _kCyan : _kYellow.withOpacity(0.7);
    } else {
      color = isPlayer
          ? _kCyan
          : (_kTeamColors[d.id] ?? _kWhite.withOpacity(0.5));
    }

    final radius = isPlayer
        ? size.shortestSide * 0.038
        : size.shortestSide * 0.022;

    // Glow for player + top 3
    if (isPlayer || d.position <= 3) {
      canvas.drawCircle(pos, radius * 2.2, Paint()
        ..color = color.withOpacity(0.18)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6));
    }

    // Car dot
    canvas.drawCircle(pos, radius, Paint()..color = color);

    // White core for player
    if (isPlayer) {
      canvas.drawCircle(pos, radius * 0.38, Paint()..color = _kWhite);
    }

    // Surname label above player
    if (isPlayer) {
      final surname = d.name.split(' ').last.toUpperCase();
      _text(canvas, surname,
          Offset(pos.dx, pos.dy - radius - 7),
          size.shortestSide * 0.045, _kCyan,
          centered: true, bold: true);
    }

    // P1 / P2 / P3 badge
    if (d.position <= 3 && !isPlayer) {
      _text(canvas, 'P${d.position}',
          Offset(pos.dx + radius + 2, pos.dy - 4),
          size.shortestSide * 0.036, color.withOpacity(0.9));
    }
  }

  // ── Legend ────────────────────────────────────────────────────
  void _drawLegend(Canvas canvas, Size size) {
    final x = size.width  * 0.05;
    final y = size.height * 0.05;
    final r = size.shortestSide * 0.028;

    // You
    canvas.drawCircle(Offset(x, y), r, Paint()..color = _kCyan);
    canvas.drawCircle(Offset(x, y), r * 0.38, Paint()..color = _kWhite);
    _text(canvas, 'YOU', Offset(x + r + 5, y),
        size.shortestSide * 0.04, _kCyan);

    // Rivals
    canvas.drawCircle(Offset(x, y + r * 3), r * 0.72,
        Paint()..color = _kWhite.withOpacity(0.4));
    _text(canvas, 'RIVALS', Offset(x + r + 5, y + r * 3),
        size.shortestSide * 0.038, _kWhite.withOpacity(0.35));

    // SC badge
    if (safetyCar) {
      final pulse = sin(animValue * pi * 2) * 0.25 + 0.75;
      _text(canvas, '🟡 SC',
          Offset(x, y + r * 6.5),
          size.shortestSide * 0.046,
          _kYellow.withOpacity(pulse));
    }
  }

  // ── Circuit name ──────────────────────────────────────────────
  void _drawCircuitName(Canvas canvas, Size size) {
    final name = CircuitPaths.nameForRound(round);
    _text(canvas, name,
        Offset(size.width * 0.5, size.height * 0.97),
        size.shortestSide * 0.038,
        _kWhite.withOpacity(0.18),
        centered: true);
  }

  // ── Text helper ───────────────────────────────────────────────
  void _text(Canvas canvas, String txt, Offset pos, double fontSize,
      Color color, {bool centered = false, bool bold = false}) {
    final tp = TextPainter(
      text: TextSpan(
        text: txt,
        style: TextStyle(
          fontSize:   fontSize,
          color:      color,
          fontWeight: bold ? FontWeight.w900 : FontWeight.w700,
          fontFamily: 'Courier',
          height:     1.2,
        ),
      ),
      textDirection: TextDirection.ltr,
      textAlign:     centered ? TextAlign.center : TextAlign.left,
    )..layout();

    final dx = centered ? pos.dx - tp.width / 2 : pos.dx;
    final dy = pos.dy - tp.height / 2;
    tp.paint(canvas, Offset(dx, dy));
  }

  @override
  bool shouldRepaint(_MultiCarPainter old) =>
      old.animValue  != animValue  ||
          old.currentLap != currentLap ||
          old.safetyCar  != safetyCar;
}