import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/user_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../profile/widgets/goal_setting_dialog.dart';

class GoalTimelineCard extends StatelessWidget {
  const GoalTimelineCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<UserProvider>(
      builder: (context, userProvider, _) {
        final daysRemaining = userProvider.daysRemainingToGoal;
        final progress = userProvider.goalProgressPercent;
        final deadline = userProvider.goalDeadline;

        // If no goal set, show SET GOAL button
        if (deadline == null) {
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary.withOpacity(0.1),
                  AppColors.secondary.withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.primary.withOpacity(0.3)),
            ),
            child: Column(
              children: [
                const Text(
                  '🎯',
                  style: TextStyle(fontSize: 48),
                ),
                const SizedBox(height: 16),
                Text(
                  'Ustaw Swój Cel Fitness',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Zdefiniuj cel i datę osiągnięcia, a my pomożemy Ci go zrealizować!',
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => const GoalSettingDialog(),
                    );
                  },
                  icon: const Icon(Icons.add_task),
                  label: const Text('Ustaw Cel'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        return _buildTimelineCard(
          context,
          daysRemaining: daysRemaining ?? 0,
          progress: progress ?? 0.0,
          deadline: deadline,
        );
      },
    );
  }

  Widget _buildTimelineCard(
    BuildContext context, {
    required int daysRemaining,
    required double progress,
    required DateTime deadline,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withOpacity(0.3)),
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
          Row(
            children: [
              const Text(
                '🎯',
                style: TextStyle(fontSize: 24),
              ),
              const SizedBox(width: 8),
              Text(
                'Twój Cel',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: Icon(Icons.edit, size: 20, color: colorScheme.onSurfaceVariant),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => const GoalSettingDialog(),
                  );
                },
                tooltip: 'Edytuj cel',
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Dobra wiadomość! Na podstawie osiągów użytkowników podobnych do Ciebie, przewidujemy, że osiągniesz swój cel do ${_formatDate(deadline)}.',
            style: TextStyle(
              fontSize: 14,
              height: 1.5,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(Icons.calendar_today, size: 16, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                'Pozostało: $daysRemaining dni',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              backgroundColor: colorScheme.surfaceVariant,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${(progress * 100).toInt()}% ukończone',
            style: TextStyle(
              fontSize: 12,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    const months = [
      'stycznia', 'lutego', 'marca', 'kwietnia', 'maja', 'czerwca',
      'lipca', 'sierpnia', 'września', 'października', 'listopada', 'grudnia'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}
