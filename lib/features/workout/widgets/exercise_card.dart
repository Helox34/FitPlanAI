import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/models/models.dart';

class ExerciseCard extends StatelessWidget {
  final int index;
  final PlanItem exercise;

  const ExerciseCard({
    super.key,
    required this.index,
    required this.exercise,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Index + Title
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: Text(
                  '$index',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  exercise.name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Details: Series & Reps
          Text(
            exercise.details,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          
          const SizedBox(height: 12),
          
          // Info Box (Tips)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.info_outline, size: 16, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Text(
                      'Wskazówka',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  _getExerciseTip(exercise.name), // Placeholder tip generator
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Simple helper to generate tips based on exercise keywords (Mock logic for visual)
  String _getExerciseTip(String name) {
    if (name.toLowerCase().contains('przysiad')) {
      return 'Pilnuj, by kolana nie przekraczały linii palców stóp. Trzymaj proste plecy.';
    } else if (name.toLowerCase().contains('wyciskanie')) {
      return 'Pamiętaj o stabilnej pozycji łopatek i pełnym zakresie ruchu.';
    } else if (name.toLowerCase().contains('martwy')) {
      return 'Utrzymuj naturalną krzywiznę kręgosłupa. Ruch wychodzi z biodra.';
    } else {
      return 'Skup się na technice i kontrolowanym oddechu.';
    }
  }
}
