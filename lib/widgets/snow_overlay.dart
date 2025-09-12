import 'dart:math' as math;
import 'package:flutter/material.dart';

class SnowOverlay extends StatefulWidget {
  const SnowOverlay({
    super.key,
    this.enabled = true,
    this.flakes = 100,
    this.baseSpeed = 35,
    this.wind = 12,
    this.color = const Color(0xFFFFFFFF),
    this.opacity = 0.9,
  });

  final bool enabled;
  final int flakes;
  final double baseSpeed;
  final double wind;
  final Color color;
  final double opacity;

  @override
  State<SnowOverlay> createState() => _SnowOverlayState();
}

class _SnowOverlayState extends State<SnowOverlay> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final List<_Flake> _flakes;
  Size _lastSize = Size.zero;
  final math.Random _rng = math.Random();

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController.unbounded(vsync: this)
      ..addListener(() => setState(() {}))
      ..repeat(min: 0, max: 1e9, period: const Duration(hours: 1));

    _flakes = List.generate(widget.flakes, (_) => _Flake.random(_rng));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) return const SizedBox.shrink();

    return IgnorePointer(
      child: RepaintBoundary(
        child: CustomPaint(
          painter: _SnowPainter(
            flakes: _flakes,
            time: _ctrl.lastElapsedDuration?.inMilliseconds ?? 0,
            baseSpeed: widget.baseSpeed,
            wind: widget.wind,
            color: widget.color.withOpacity(widget.opacity),
            onNeedBounds: (size) {
              if (_lastSize != size) {
                _lastSize = size;
                for (final f in _flakes) {
                  f.ensureBounds(size, _rng);
                }
              }
            },
          ),
          size: Size.infinite,
        ),
      ),
    );
  }
}

class _Flake {
  double x = 0;
  double y = 0;
  double r = 0;
  double speedFactor = 1;
  double sway = 0;

  _Flake();

  factory _Flake.random(math.Random rng) {
    final f = _Flake();
    f.x = rng.nextDouble();
    f.y = rng.nextDouble();
    f.speedFactor = 0.6 + rng.nextDouble() * 0.8;
    f.sway = rng.nextDouble() * math.pi * 2;
    f.r = 2 + rng.nextDouble() * 3; // flake size
    return f;
  }

  void ensureBounds(Size size, math.Random rng) {
    if (size.isEmpty) return;
    x = x.clamp(0.0, 1.0);
    y = y.clamp(0.0, 1.0);
    final shortest = math.max(320.0, math.min(size.width, size.height));
    r = (shortest / 390.0) * (2 + rng.nextDouble() * 3);
  }
}

class _SnowPainter extends CustomPainter {
  _SnowPainter({
    required this.flakes,
    required this.time,
    required this.baseSpeed,
    required this.wind,
    required this.color,
    required this.onNeedBounds,
  });

  final List<_Flake> flakes;
  final int time;
  final double baseSpeed;
  final double wind;
  final Color color;
  final void Function(Size) onNeedBounds;

  @override
  void paint(Canvas canvas, Size size) {
    onNeedBounds(size);
    if (size.isEmpty) return;

    final Paint p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = color
      ..isAntiAlias = true;

    final t = time / 1000.0;

    for (final f in flakes) {
      final y = (f.y * size.height + (baseSpeed * f.speedFactor) * t) % (size.height + 10) - 10;
      final swayX = math.sin((t * (0.6 + f.speedFactor * 0.8)) + f.sway) * wind;
      double x = (f.x * size.width + swayX);

      if (x < -10) x += size.width + 20;
      if (x > size.width + 10) x -= size.width + 20;

      _drawFlake(canvas, Offset(x, y), f.r, p);
    }
  }

  void _drawFlake(Canvas canvas, Offset c, double r, Paint p) {
    // 6-arm snowflake (hex symmetry)
    for (int i = 0; i < 6; i++) {
      final angle = (math.pi / 3) * i;
      final dx = r * math.cos(angle);
      final dy = r * math.sin(angle);
      final end = Offset(c.dx + dx, c.dy + dy);
      canvas.drawLine(c, end, p);
      // small side branches
      final side = r * 0.4;
      final branchAngle = angle + math.pi / 6;
      final bx = side * math.cos(branchAngle);
      final by = side * math.sin(branchAngle);
      canvas.drawLine(end, end - Offset(bx, by), p);
      final branchAngle2 = angle - math.pi / 6;
      final bx2 = side * math.cos(branchAngle2);
      final by2 = side * math.sin(branchAngle2);
      canvas.drawLine(end, end - Offset(bx2, by2), p);
    }
  }

  @override
  bool shouldRepaint(covariant _SnowPainter old) =>
      time != old.time || baseSpeed != old.baseSpeed || wind != old.wind || color != old.color;
}
