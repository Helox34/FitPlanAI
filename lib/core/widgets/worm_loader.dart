import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../theme/app_colors.dart';

class WormLoader extends StatefulWidget {
  final double size;
  final Color? color;

  const WormLoader({
    super.key,
    this.size = 50.0,
    this.color,
  });

  @override
  State<WormLoader> createState() => _WormLoaderState();
}

class _WormLoaderState extends State<WormLoader> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500), // Slightly faster than CSS usually is for snappy feel
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return CustomPaint(
            painter: _WormPainter(
              progress: _controller.value,
              color: widget.color ?? AppColors.primary,
            ),
          );
        },
      ),
    );
  }
}

class _WormPainter extends CustomPainter {
  final double progress;
  final Color color;

  _WormPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..strokeWidth = size.width * 0.12 // Thickness relative to size
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - paint.strokeWidth) / 2;

    // Simulate the "worm" effect:
    // The start and end of the arc move at different speeds/times.
    
    // Rotation logic (keeps it spinning)
    final double rotation = progress * 2 * math.pi;

    // Length logic (expands and contracts)
    // We want a sinusoidal length variation or similar to the CSS ease-in-out
    // CSS keys: 0% -> off 0, 20% -> off 0, 60% -> off -big
    
    // Simplified Flutter equivalent:
    // Head moves faster than tail at times.
    
    // Tail (Start Angle)
    final double tail = math.sin(progress * math.pi) * math.pi; 
    // Head (End Angle) - offset phase
    final double head = math.sin((progress + 0.5) * math.pi) * math.pi; 
    
    // Actually, standard material curve is:
    // Head travels 0 -> 2pi in one cycle.
    // Tail travels 0 -> 2pi in one cycle but lagged.
    
    // Let's implement a distinct "Worm" curve manually
    // 0.0 -> 0.5: Head moves away from Tail (Length grows)
    // 0.5 -> 1.0: Tail catches up to Head (Length shrinks)
    
    double startAngle = -math.pi / 2; // Start at top
    double sweepAngle = 0;
    
    // Rotate the whole thing constantly
    startAngle += (progress * 2 * math.pi * 1.5); // 1.5x rotation speed

    // Pulse the length
    // When progress 0.0 -> 0.5, sweep grows 0.1 -> 4.5
    // When progress 0.5 -> 1.0, sweep shrinks 4.5 -> 0.1
    
    if (progress < 0.5) {
      // Growing
      final t = progress * 2; // 0..1
      // Ease out interp
      final val = CurveTween(curve: Curves.fastOutSlowIn).transform(t);
      sweepAngle = 0.2 + (val * (2 * math.pi - 1.0)); // Grow to almost full circle
    } else {
      // Shrinking
      final t = (progress - 0.5) * 2; // 0..1
      final val = CurveTween(curve: Curves.fastOutSlowIn).transform(t);
      sweepAngle = (2 * math.pi - 0.8) - (val * (2 * math.pi - 1.0));
      
      // To keep the head moving forward while tail pulls in, we essentially add to startAngle
      // But standard rotation handles most of it.
      // Actually, to mimic "worm" strictly:
      // Head position = curve(t)
      // Tail position = curve(t - lag)
    }
    
    // Let's use the Material-style path logic which is robust
    // But customized for that "Green Worm" look
    
    // Correction for visual distinctiveness
    if (sweepAngle < 0.1) sweepAngle = 0.1;
    
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _WormPainter oldDelegate) => 
      oldDelegate.progress != progress || oldDelegate.color != color;
}
