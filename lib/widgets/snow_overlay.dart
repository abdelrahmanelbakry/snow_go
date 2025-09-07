
import 'dart:math';
import 'package:flutter/material.dart';

class SnowOverlay extends StatefulWidget {
  const SnowOverlay({super.key});
  @override State<SnowOverlay> createState() => _SnowOverlayState();
}

class _SnowOverlayState extends State<SnowOverlay> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  final List<_Flake> flakes = [];
  final rnd = Random();
  @override void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 60))..repeat();
    for (int i=0;i<25;i++) flakes.add(_Flake(rand: rnd));
  }
  @override void dispose() { _ctrl.dispose(); super.dispose(); }
  @override Widget build(BuildContext context) {
    return IgnorePointer(child: AnimatedBuilder(animation: _ctrl, builder: (context, _) { for (final f in flakes) f.update(MediaQuery.of(context).size); return CustomPaint(painter: _SnowPainter(flakes: flakes)); }));
  }
}

class _Flake {
  double x=0,y=0,r=2,vy=0,vx=0; final Random rand;
  _Flake({required this.rand}) { x=rand.nextDouble(); y=rand.nextDouble(); r=1.5+rand.nextDouble()*3.0; vy=0.2+rand.nextDouble()*0.8; vx=(rand.nextDouble()-0.5)*0.2; }
  void update(Size s) { y += vy/100; x += vx; if (y>1.2) { y=-0.1; x=rand.nextDouble(); } }
}

class _SnowPainter extends CustomPainter {
  final List<_Flake> flakes; _SnowPainter({required this.flakes});
  @override void paint(Canvas canvas, Size size) { final paint = Paint()..color = Colors.white.withOpacity(0.12); for (final f in flakes) canvas.drawCircle(Offset(f.x*size.width, f.y*size.height), f.r, paint); }
  @override bool shouldRepaint(covariant CustomPainter old) => true;
}
