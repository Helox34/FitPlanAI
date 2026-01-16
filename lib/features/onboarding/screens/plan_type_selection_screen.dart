import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/models/models.dart';
import '../../../core/widgets/worm_loader.dart';
import 'process_screen.dart';
import 'training_days_picker_screen.dart'; // Training Days Picker

/// Screen for selecting plan type (Workout or Diet)
class PlanTypeSelectionScreen extends StatefulWidget {
  final CreatorMode? preselectedMode;
  
  const PlanTypeSelectionScreen({
    super.key,
    this.preselectedMode,
  });

  @override
  State<PlanTypeSelectionScreen> createState() => _PlanTypeSelectionScreenState();
}

class _PlanTypeSelectionScreenState extends State<PlanTypeSelectionScreen> {
  @override
  void initState() {
    super.initState();
    // If preselected mode is provided, navigate directly
    if (widget.preselectedMode != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (widget.preselectedMode == CreatorMode.WORKOUT) {
          // Workout plans go through training days picker
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => const TrainingDaysPickerScreen(),
            ),
          );
        } else {
          // Diet plans go directly to interview
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => ProcessScreen(mode: widget.preselectedMode!),
            ),
          );
        }
      });
    }
  }

  void _selectPlanType(BuildContext context, CreatorMode mode) {
    if (mode == CreatorMode.WORKOUT) {
      // For workout plans, go through training days picker first
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => const TrainingDaysPickerScreen(),
        ),
      );
    } else {
      // For diet plans, go directly to interview
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => ProcessScreen(mode: mode),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // If preselected, show loading while navigating
    if (widget.preselectedMode != null) {
      return Scaffold(
        body: Center(
          child: WormLoader(size: 60),
        ),
      );
    }
    
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Header
              const Icon(
                Icons.checklist_rounded,
                size: 64,
                color: AppColors.primary,
              ),
              const SizedBox(height: 24),
              Text(
                'FitPlan AI: Proces Tworzenia',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'Przejdziemy przez szczegółowy proces analityczny, aby Twój plan był w 100% dopasowany do Twoich potrzeb medycznych i treningowych.',
                style: TextStyle(
                  fontSize: 16,
                  color: colorScheme.onSurfaceVariant,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              
              // Process steps
              _buildProcessStep(1, 'Wywiad Szczegółowy: Odpowiedz na 27+ pytań w kategoriach zdrowia, stylu życia i preferencji.'),
              const SizedBox(height: 16),
              _buildProcessStep(2, 'Kompletowanie Odpowiedzi: System zbierze Twoje dane o historii medycznej, diecie i treningu.'),
              const SizedBox(height: 16),
              _buildProcessStep(3, 'Analiza Twoich potrzeb: Uporządkujemy zebrane informacje, aby stworzyć spójny obraz Twojej sytuacji.'),
              const SizedBox(height: 16),
              _buildProcessStep(4, 'Weryfikacja Bezpieczeństwa: Sprawdzimy, czy Twoje cele są realne i bezpieczne dla Twojego zdrowia.'),
              const SizedBox(height: 16),
              _buildProcessStep(5, 'Gotowy Plan Działania: Otrzymasz przejrzystą strategię (treningową lub dietetyczną) szytą na miarę.'),
              
              const SizedBox(height: 48),
              
              // Plan type buttons
              Row(
                children: [
                  Expanded(
                    child: _buildPlanTypeButton(
                      context,
                      'Plan Treningowy',
                      Icons.fitness_center,
                      AppColors.primary,
                      () => _selectPlanType(context, CreatorMode.WORKOUT),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildPlanTypeButton(
                      context,
                      'Plan Dietetyczny',
                      Icons.restaurant,
                      const Color(0xFF10B981),
                      () => _selectPlanType(context, CreatorMode.DIET),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildProcessStep(int number, String description) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Center(
            child: Text(
              '$number',
              style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            description,
            style: TextStyle(
              fontSize: 14,
              color: colorScheme.onSurfaceVariant,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildPlanTypeButton(
    BuildContext context,
    String label,
    IconData icon,
    Color color,
    VoidCallback onPressed,
  ) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Column(
            children: [
              Icon(icon, color: Colors.white, size: 32),
              const SizedBox(height: 8),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
