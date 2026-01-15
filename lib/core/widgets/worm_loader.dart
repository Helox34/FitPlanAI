import 'package:flutter/material.dart';

class WormLoader extends StatefulWidget {
  final double size;
  final Color? color;

  const WormLoader({
    Key? key,
    this.size = 50.0,
    this.color,
  }) : super(key: key);

  @override
  State<WormLoader> createState() => _WormLoaderState();
}

class _WormLoaderState extends State<WormLoader> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final effectiveColor = widget.color ?? const Color(0xFF10B981);
    
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return CustomPaint(
            painter: _WormLoaderPainter(
              animationValue: _controller.value,
              color: effectiveColor,
            ),
          );
        },
      ),
    );
  }
}

class _WormLoaderPainter extends CustomPainter {
  final double animationValue;
  final Color color;

  _WormLoaderPainter({
    required this.animationValue,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.1
      ..strokeCap = StrokeCap.round;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.35;

    // Create a rotating arc effect
    const arcCount = 3;
    for (int i = 0; i < arcCount; i++) {
      final offset = (i / arcCount);
      final adjustedValue = (animationValue + offset) % 1.0;
      
      // Calculate arc parameters
      final startAngle = adjustedValue * 2 * 3.14159;
      final sweepAngle = (0.5 + 0.3 * (1 - ((adjustedValue - 0.5).abs() * 2))) * 3.14159;
      
      // Vary opacity based on position
      final opacity = 0.3 + 0.7 * (1 - ((adjustedValue - 0.5).abs() * 2));
      paint.color = color.withOpacity(opacity);
      
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_WormLoaderPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue || 
           oldDelegate.color != color;
  }
}
