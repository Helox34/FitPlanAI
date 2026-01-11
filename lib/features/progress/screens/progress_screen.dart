import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/models/models.dart';
import '../../../providers/plan_provider.dart';
import '../../onboarding/screens/plan_type_selection_screen.dart';

/// Progress/Plan Selection Screen - accessible before generating plans
class ProgressScreen extends StatelessWidget {
  const ProgressScreen({super.key});

  void _navigateToCreatePlan(BuildContext context, CreatorMode mode) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => PlanTypeSelectionScreen(preselectedMode: mode),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        title: Text(
          'Postępy',
          style: TextStyle(
            color: colorScheme.onSurface,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Consumer<PlanProvider>(
        builder: (context, planProvider, _) {
          final hasWorkoutPlan = planProvider.hasWorkoutPlan;
          final hasDietPlan = planProvider.hasDietPlan;
          
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Text(
                  'Twoje plany',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Wybierz plan, który chcesz wygenerować lub zarządzaj istniejącymi',
                  style: TextStyle(
                    fontSize: 14,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 32),
                
                // Workout Plan Card
                _buildPlanCard(
                  context,
                  title: 'Plan Treningowy',
                  description: hasWorkoutPlan
                      ? 'Plan aktywny - zobacz szczegóły w zakładce "Mój Plan"'
                      : 'Stwórz spersonalizowany plan treningowy',
                  icon: Icons.fitness_center,
                  color: AppColors.primary,
                  isActive: hasWorkoutPlan,
                  onTap: () => _navigateToCreatePlan(context, CreatorMode.WORKOUT),
                ),
                const SizedBox(height: 16),
                
                // Diet Plan Card
                _buildPlanCard(
                  context,
                  title: 'Plan Dietetyczny',
                  description: hasDietPlan
                      ? 'Plan aktywny - zobacz szczegóły w zakładce "Moja Dieta"'
                      : 'Stwórz spersonalizowany plan żywieniowy',
                  icon: Icons.restaurant,
                  color: const Color(0xFF10B981),
                  isActive: hasDietPlan,
                  onTap: () => _navigateToCreatePlan(context, CreatorMode.DIET),
                ),
                
                const SizedBox(height: 32),
                
                // Info section
                if (!hasWorkoutPlan || !hasDietPlan) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.primary.withOpacity(0.2),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: AppColors.primary,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Możesz mieć aktywne oba plany jednocześnie. Każdy plan jest dostosowany do Twoich indywidualnych potrzeb.',
                            style: TextStyle(
                              fontSize: 13,
                              color: colorScheme.onSurface,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
  
  Widget _buildPlanCard(
    BuildContext context, {
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Material(
      color: colorScheme.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: isActive ? null : onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            border: Border.all(
              color: isActive ? color : colorScheme.outline.withOpacity(0.2),
              width: isActive ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        if (isActive) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'Aktywny',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: color,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 14,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              if (!isActive)
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: AppColors.textTertiary,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
