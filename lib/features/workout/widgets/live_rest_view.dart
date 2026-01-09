import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class LiveRestView extends StatelessWidget {
  final int remainingSeconds;
  final String? nextExerciseName;
  final VoidCallback onSkip;

  const LiveRestView({
    super.key,
    required this.remainingSeconds,
    this.nextExerciseName,
    required this.onSkip,
  });

  String get _formattedTime {
    final minutes = (remainingSeconds / 60).floor();
    final seconds = remainingSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'Czas na odpoczynek',
            style: TextStyle(
              color: AppColors.primary,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 40),
          
          // Timer Circle
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 200,
                height: 200,
                child: CircularProgressIndicator(
                  value: remainingSeconds / 180.0, // Assuming 3 mins max
                  strokeWidth: 12,
                  backgroundColor: Colors.white10,
                  color: AppColors.primary, // Dark mode background
                ),
              ),
              Text(
                _formattedTime,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 40),
          
          if (nextExerciseName != null) ...[
            Text(
              'Następnie: $nextExerciseName',
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 24),
          ],
          
          ElevatedButton(
            onPressed: onSkip,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Pomiń przerwę',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
