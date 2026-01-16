import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/user_provider.dart';
import '../../../core/theme/app_colors.dart';
import 'initial_survey_screen.dart';

class GenderSelectionScreen extends StatefulWidget {
  const GenderSelectionScreen({super.key});

  @override
  State<GenderSelectionScreen> createState() => _GenderSelectionScreenState();
}

class _GenderSelectionScreenState extends State<GenderSelectionScreen> {
  String? _selectedGender;

  void _selectGender(String gender) {
    setState(() {
      _selectedGender = gender;
    });
    
    // Save to provider and navigate after short delay for visual feedback
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        context.read<UserProvider>().updateGender(gender);
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => const InitialSurveyScreen(),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),
              
              // Header
              Text(
                'Witamy w FitPlan AI.',
                style: TextStyle(
                  fontSize: 18,
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Jaka jest Twoja płeć?',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 48),

              // Gender Cards
              Expanded(
                child: ListView(
                  children: [
                    _buildGenderCard(
                      gender: 'female',
                      label: 'Kobieta',
                      icon: Icons.female,
                      color: const Color(0xFFEC4899), // Pink
                    ),
                    const SizedBox(height: 16),
                    _buildGenderCard(
                      gender: 'male',
                      label: 'Mężczyzna',
                      icon: Icons.male,
                      color: const Color(0xFF3B82F6), // Blue
                    ),
                    const SizedBox(height: 16),
                    _buildGenderCard(
                      gender: 'other',
                      label: 'Inne',
                      icon: Icons.transgender,
                      color: const Color(0xFF8B5CF6), // Purple
                    ),
                  ],
                ),
              ),

              // Footer
              const SizedBox(height: 24),
              Center(
                child: Text(
                  'Masz już konto?',
                  style: TextStyle(
                    fontSize: 14,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text(
                    'Zaloguj',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGenderCard({
    required String gender,
    required String label,
    required IconData icon,
    required Color color,
  }) {
    final isSelected = _selectedGender == gender;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _selectGender(gender),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isSelected 
                ? color.withOpacity(0.1) 
                : colorScheme.surfaceVariant.withOpacity(0.3),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? color : Colors.transparent,
              width: 3,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: color.withOpacity(0.2),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              // Icon/Avatar
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 36,
                  color: color,
                ),
              ),
              const SizedBox(width: 20),
              
              // Label
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? color : colorScheme.onSurface,
                  ),
                ),
              ),
              
              // Checkmark
              if (isSelected)
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
