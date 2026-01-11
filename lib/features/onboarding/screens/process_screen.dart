import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/models/models.dart';
import '../../../core/widgets/custom_button.dart';
import '../../chat/screens/ai_chat_screen.dart';

/// Process screen showing plan creation overview
class ProcessScreen extends StatelessWidget {
  final CreatorMode mode;
  
  const ProcessScreen({
    super.key,
    required this.mode,
  });

  @override
  Widget build(BuildContext context) {
    final isWorkout = mode == CreatorMode.WORKOUT;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: colorScheme.onSurface),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              // Icon
              Icon(
                isWorkout ? Icons.fitness_center : Icons.restaurant,
                size: 64,
                color: isWorkout ? AppColors.primary : const Color(0xFF10B981),
              ),
              const SizedBox(height: 24),
              
              // Title
              Text(
                isWorkout ? 'Plan Treningowy' : 'Plan Dietetyczny',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              
              // Description
              Text(
                isWorkout
                    ? 'Przygotujemy dla Ciebie spersonalizowany plan treningowy dopasowany do Twoich celów i możliwości.'
                    : 'Przygotujemy dla Ciebie spersonalizowany plan żywieniowy dopasowany do Twoich potrzeb i preferencji.',
                style: TextStyle(
                  fontSize: 16,
                  color: colorScheme.onSurfaceVariant,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              
              // Process info
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      _buildInfoCard(
                        context,
                        'Czas trwania',
                        isWorkout ? '10-15 minut' : '15-20 minut',
                        Icons.access_time,
                      ),
                      const SizedBox(height: 16),
                      _buildInfoCard(
                        context,
                        'Liczba pytań',
                        isWorkout ? '27 pytań' : '30 pytań',
                        Icons.quiz,
                      ),
                      const SizedBox(height: 16),
                      _buildInfoCard(
                        context,
                        'Generowanie planu',
                        '30-60 sekund',
                        Icons.auto_awesome,
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Start button
              CustomButton(
                text: 'Rozpocznij wywiad',
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => AIChatScreen(mode: mode),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildInfoCard(BuildContext context, String title, String value, IconData icon) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outline.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.primary, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
