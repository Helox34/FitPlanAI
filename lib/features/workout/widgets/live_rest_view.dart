import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/worm_loader.dart';

class LiveRestView extends StatelessWidget {
  final int remainingSeconds;
  final String nextExerciseName;
  final VoidCallback onSkip;

  const LiveRestView({
    super.key,
    required this.remainingSeconds,
    required this.nextExerciseName,
    required this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // "Czas na odpoczynek" header (green)
          Text(
            'Czas na odpoczynek',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: AppColors.primary, // Green color like in the image
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 40),
          
          // Timer circle
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 200,
                height: 200,
                child: WormLoader(
                  size: 200,
                  color: AppColors.primary.withOpacity(0.3),
                ),
              ),
              // Large timer text
              Text(
                _formatTime(remainingSeconds),
                style: const TextStyle(
                  fontSize: 56,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 40),
          
          // "Następnie:" label
          Text(
            'Następnie:',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white60,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          
          // Next exercise name
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              nextExerciseName,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          
          const SizedBox(height: 60),
          
          // "Pomiń przerwę" button
          ElevatedButton(
            onPressed: onSkip,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF0F172A), // Dark blue text
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 0,
            ),
            child: const Text(
              'Pomiń przerwę',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }
}
