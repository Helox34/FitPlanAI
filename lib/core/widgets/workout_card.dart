import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class WorkoutCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? duration;
  final int? sets;
  final int? reps;
  final VoidCallback? onTap;
  final bool isCompleted;

  const WorkoutCard({
    super.key,
    required this.title,
    this.subtitle,
    this.duration,
    this.sets,
    this.reps,
    this.onTap,
    this.isCompleted = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Checkbox or icon
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isCompleted ? AppColors.primary : AppColors.border,
                    width: 2,
                  ),
                  color: isCompleted ? AppColors.primary : Colors.transparent,
                ),
                child: isCompleted
                    ? const Icon(
                        Icons.check,
                        size: 16,
                        color: AppColors.textOnPrimary,
                      )
                    : null,
              ),
              const SizedBox(width: 16),
              
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            decoration: isCompleted
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle!,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                    if (sets != null || reps != null || duration != null) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          if (sets != null)
                            _buildInfoChip(
                              context,
                              '$sets serie',
                              Icons.repeat,
                            ),
                          if (reps != null) ...[
                            const SizedBox(width: 8),
                            _buildInfoChip(
                              context,
                              '$reps powtórzeń',
                              Icons.fitness_center,
                            ),
                          ],
                          if (duration != null) ...[
                            const SizedBox(width: 8),
                            _buildInfoChip(
                              context,
                              duration!,
                              Icons.timer_outlined,
                            ),
                          ],
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              
              // Arrow icon
              if (onTap != null)
                const Icon(
                  Icons.chevron_right,
                  color: AppColors.textTertiary,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(BuildContext context, String text, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.textSecondary),
          const SizedBox(width: 4),
          Text(
            text,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
