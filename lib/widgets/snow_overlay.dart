import 'dart:math';
import 'package:flutter/material.dart';

class SnowOverlay extends StatefulWidget {
  const SnowOverlay({super.key});
  @override
  State<SnowOverlay> createState() => _SnowOverlayState();
}

class _SnowOverlayState extends State<SnowOverlay> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  final _flakes = <_Flake>[];
  final _rnd = Random();

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 60))..repeat();
    for (int i = 0; i < 28; i++) {
      _flakes.add(_Flake(rand: _rnd));
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (context, _) {
          final size = MediaQuery.of(context).size;
          for (final f in _flakes) f.update(size);
          return CustomPaint(painter: _SnowPainter(_flakes));
        },
      ),
    );
  }
}

class _Flake {
  double x = 0, y = 0, r = 2, vy = 0, vx = 0;
  final Random rand;
  _Flake({required this.rand}) {
    x = rand.nextDouble();
    y = rand.nextDouble();
    r = 1.5 + rand.nextDouble() * 2.5;
    vy = 0.2 + rand.nextDouble() * 0.7;
    vx = (rand.nextDouble() - 0.5) * 0.08;
  }

  void update(Size s) {
    y += vy / 90; // very subtle
    x += vx / 200;
    if (y > 1.15) { y = -0.05; x = rand.nextDouble(); }
  }
}

class _SnowPainter extends CustomPainter {
  final List<_Flake> flakes;
  _SnowPainter(this.flakes);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withOpacity(0.10);
    for (final f in flakes) {
      canvas.drawCircle(Offset(f.x * size.width, f.y * size.height), f.r, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
