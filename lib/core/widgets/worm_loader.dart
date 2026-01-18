import 'package:flutter/material.dart';
import 'dart:math' as math;

/// Fitness Activity Rings Loader
/// Three concentric rings filling and pulsing - inspired by fitness trackers
class WormLoader extends StatefulWidget {
  final double size;
  final Color? color;
  final Color? ringColor;

  const WormLoader({
    super.key,
    this.size = 80,
    this.color,
    this.ringColor,
  });

  @override
  State<WormLoader> createState() => _WormLoaderState();
}

class _WormLoaderState extends State<WormLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
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
            size: Size(widget.size, widget.size),
            painter: _ActivityRingsPainter(
              progress: _controller.value,
              primaryColor: widget.color ?? const Color(0xFF10B981),
              secondaryColor: const Color(0xFF3B82F6), // Blue
              tertiaryColor: const Color(0xFF059669), // Dark Green (User requested removing pink)
            ),
          );
        },
      ),
    );
  }
}

class _ActivityRingsPainter extends CustomPainter {
  final double progress;
  final Color primaryColor;
  final Color secondaryColor;
  final Color tertiaryColor;

  _ActivityRingsPainter({
    required this.progress,
    required this.primaryColor,
    required this.secondaryColor,
    required this.tertiaryColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final strokeWidth = size.width * 0.08;

    // Three rings at different radii
    final outerRadius = size.width * 0.42;
    final middleRadius = size.width * 0.32;
    final innerRadius = size.width * 0.22;

    // Each ring fills and pulses with offset timing
    _drawActivityRing(
      canvas,
      center,
      outerRadius,
      strokeWidth,
      primaryColor,
      progress,
      0.0, // No offset for outer ring
    );

    _drawActivityRing(
      canvas,
      center,
      middleRadius,
      strokeWidth,
      secondaryColor,
      progress,
      0.15, // Slight delay
    );

    _drawActivityRing(
      canvas,
      center,
      innerRadius,
      strokeWidth,
      tertiaryColor,
      progress,
      0.3, // More delay
    );
  }

  void _drawActivityRing(
    Canvas canvas,
    Offset center,
    double radius,
    double strokeWidth,
    Color color,
    double progress,
    double timeOffset,
  ) {
    // Offset the progress for this ring
    final ringProgress = (progress + timeOffset) % 1.0;

    // Ring fills from 0 to full, then empties
    // 0.0 - 0.6: filling (0% → 100%)
    // 0.6 - 0.7: pause at full
    // 0.7 - 1.0: emptying (100% → 0%)
    double fillAmount;
    double pulseScale;

    if (ringProgress < 0.6) {
      // Filling phase
      fillAmount = (ringProgress / 0.6).clamp(0.0, 1.0);
      // Subtle pulse as it fills
      pulseScale = 1.0 + math.sin(ringProgress * math.pi * 10) * 0.03;
    } else if (ringProgress < 0.7) {
      // Pause at full - strong pulse
      fillAmount = 1.0;
      final pulseProgress = (ringProgress - 0.6) / 0.1;
      pulseScale = 1.0 + math.sin(pulseProgress * math.pi * 2) * 0.08;
    } else {
      // Emptying phase
      final emptyProgress = (ringProgress - 0.7) / 0.3;
      fillAmount = (1.0 - emptyProgress).clamp(0.0, 1.0);
      pulseScale = 1.0;
    }

    final currentRadius = radius * pulseScale;

    // Background ring (empty/unfilled portion)
    final bgPaint = Paint()
      ..color = color.withOpacity(0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, currentRadius, bgPaint);

    // Filled portion (active arc)
    if (fillAmount > 0) {
      final fillPaint = Paint()
        ..shader = RadialGradient(
          colors: [
            color.withOpacity(0.9),
            color.withOpacity(0.7),
          ],
        ).createShader(Rect.fromCircle(center: center, radius: currentRadius))
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      final sweepAngle = fillAmount * 2 * math.pi;
      final startAngle = -math.pi / 2; // Start from top

      final rect = Rect.fromCircle(center: center, radius: currentRadius);
      canvas.drawArc(rect, startAngle, sweepAngle, false, fillPaint);

      // Glow effect at the end of the arc when filling
      if (fillAmount > 0.1 && fillAmount < 1.0) {
        final endAngle = startAngle + sweepAngle;
        final endX = center.dx + currentRadius * math.cos(endAngle);
        final endY = center.dy + currentRadius * math.sin(endAngle);
        final endPoint = Offset(endX, endY);

        final glowPaint = Paint()
          ..color = color.withOpacity(0.6)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

        canvas.drawCircle(endPoint, strokeWidth * 0.6, glowPaint);
      }
    }
  }

  @override
  bool shouldRepaint(_ActivityRingsPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
