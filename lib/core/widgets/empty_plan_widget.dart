import 'package:flutter/material.dart';
import '../models/models.dart';
import '../theme/app_colors.dart';

/// Empty state widget when no plan is available
class EmptyPlanWidget extends StatelessWidget {
  final CreatorMode mode;
  final VoidCallback onGeneratePlan;

  const EmptyPlanWidget({
    super.key,
    required this.mode,
    required this.onGeneratePlan,
  });

  @override
  Widget build(BuildContext context) {
    // Different text based on mode
    final String emptyTitle = mode == CreatorMode.WORKOUT 
        ? 'Brak wygenerowanego planu'
        : 'Brak wygenerowanej diety';
    
    final String emptySubtitle = mode == CreatorMode.WORKOUT
        ? 'Nie masz jeszcze planu treningowego'
        : 'Nie masz jeszcze planu dietetycznego';

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.calendar_today_outlined,
              size: 64,
              color: AppColors.textTertiary.withOpacity(0.5),
            ),
            const SizedBox(height: 24),
            Text(
              emptyTitle,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              emptySubtitle,
              style: TextStyle(
                fontSize: 16,
                color: AppColors.textTertiary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: onGeneratePlan,
              icon: const Icon(Icons.add),
              label: const Text('Wygeneruj plan'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
