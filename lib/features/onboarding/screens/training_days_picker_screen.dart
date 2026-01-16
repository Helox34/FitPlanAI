import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/user_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/models/models.dart'; // CreatorMode enum
import '../../chat/screens/ai_chat_screen.dart';

class TrainingDaysPickerScreen extends StatefulWidget {
  const TrainingDaysPickerScreen({super.key});

  @override
  State<TrainingDaysPickerScreen> createState() => _TrainingDaysPickerScreenState();
}

class _TrainingDaysPickerScreenState extends State<TrainingDaysPickerScreen> {
  final List<String> _dayNames = ['pon.', 'wt.', 'śr.', 'czw.', 'pt.', 'sob.', 'niedz.'];
  final Set<int> _selectedDays = {};
  bool _alertsEnabled = true;
  
  int _recommendedFrequency = 4; // Default, can be calculated based on user data

  @override
  void initState() {
    super.initState();
    // Pre-select recommended days (e.g., Mon, Wed, Fri, Sat for 4x/week)
    _selectedDays.addAll([0, 2, 4, 5]); // Mon, Wed, Fri, Sat
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Plan Treningowy'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
              Text(
                'Wybierz dni treningu!',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 16),

              // Subtitle with recommendation
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.lightbulb, color: AppColors.primary, size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Świetnie! Na podstawie Twoich danych zalecamy $_recommendedFrequency treningi tygodniowo.',
                        style: TextStyle(
                          fontSize: 14,
                          color: colorScheme.onSurface,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Days Grid
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: List.generate(7, (index) {
                  final isSelected = _selectedDays.contains(index);
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        if (isSelected) {
                          _selectedDays.remove(index);
                        } else {
                          _selectedDays.add(index);
                        }
                      });
                    },
                    child: Container(
                      width: (MediaQuery.of(context).size.width - 72) / 4, // 4 per row with spacing
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.primary : colorScheme.surfaceVariant,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? AppColors.primary : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: Column(
                        children: [
                          if (isSelected)
                            const Icon(Icons.check_circle, color: Colors.white, size: 20)
                          else
                            Icon(Icons.circle_outlined, color: colorScheme.onSurfaceVariant, size: 20),
                          const SizedBox(height: 8),
                          Text(
                            _dayNames[index],
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                              color: isSelected ? Colors.white : colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 32),

              // Alerts Toggle
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceVariant.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Alerty',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Wybierz sobie nawyk i już nigdy nie przegapiesz ani dnia treningu!',
                            style: TextStyle(
                              fontSize: 13,
                              color: colorScheme.onSurfaceVariant,
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Switch(
                      value: _alertsEnabled,
                      onChanged: (value) {
                        setState(() {
                          _alertsEnabled = value;
                        });
                      },
                      activeColor: AppColors.primary,
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // Next Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                      onPressed: _selectedDays.isEmpty
                      ? null
                      : () {
                          // Save selected days to user provider
                          final userProvider = context.read<UserProvider>();
                          // TODO: Add method to save training days preference
                          
                          // Navigate to AI Chat for workout interview
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute(
                              builder: (_) => AIChatScreen(mode: CreatorMode.WORKOUT),
                            ),
                          );
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                    disabledBackgroundColor: Colors.grey.shade300,
                  ),
                  child: Text(
                    'Dalej (${_selectedDays.length} ${_selectedDays.length == 1 ? 'dzień' : 'dni'})',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
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
}
