import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/user_provider.dart';
import '../../../core/theme/app_colors.dart';

class GoalTimelineCard extends StatelessWidget {
  const GoalTimelineCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<UserProvider>(
      builder: (context, userProvider, _) {
        final daysRemaining = userProvider.daysRemainingToGoal;
        final progress = userProvider.goalProgressPercent;
        final deadline = userProvider.goalDeadline;

        // If no goal set, show TEST BUTTON (Temporary for verification)
        if (deadline == null) {
          return Center(
            child: TextButton.icon(
              onPressed: () {
                // Set a dummy goal 3 months from now
                userProvider.updateGoal(
                  goal: 'build_muscle',
                  deadline: DateTime.now().add(const Duration(days: 90)),
                  targetWeight: 80.0,
                );
              },
              icon: const Icon(Icons.add_task),
              label: const Text('[TEST] Ustaw Cel na 90 dni'),
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
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
