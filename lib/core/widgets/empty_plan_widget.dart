import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Empty state widget for when no plan exists
class EmptyPlanWidget extends StatelessWidget {
  final String dayName;
  final VoidCallback? onGeneratePlan;
  
  const EmptyPlanWidget({
    super.key,
    required this.dayName,
    this.onGeneratePlan,
  });

  @override
  Widget build(BuildContext context) {
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
              'Brak planu na ten dzień',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              dayName,
              style: TextStyle(
                fontSize: 16,
                color: AppColors.textTertiary,
              ),
              textAlign: TextAlign.center,
            ),
            if (onGeneratePlan != null) ...[
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
          ],
        ),
      ),
    );
  }
}
