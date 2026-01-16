import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/user_provider.dart';
import '../../../core/theme/app_colors.dart';

class GoalSettingDialog extends StatefulWidget {
  const GoalSettingDialog({super.key});

  @override
  State<GoalSettingDialog> createState() => _GoalSettingDialogState();
}

class _GoalSettingDialogState extends State<GoalSettingDialog> {
  String _selectedGoal = 'build_muscle';
  DateTime _selectedDeadline = DateTime.now().add(const Duration(days: 90));
  double? _targetWeight;
  final _weightController = TextEditingController();

  final Map<String, Map<String, dynamic>> _goals = {
    'lose_weight': {
      'icon': Icons.local_fire_department,
      'color': const Color(0xFFEF4444), // Red
      'label': 'Schudnąć',
      'description': 'Redukcja tk anki tłuszczowej',
    },
    'build_muscle': {
      'icon': Icons.fitness_center,
      'color': const Color(0xFF8B5CF6), // Purple
      'label': 'Nabić Masę',
      'description': 'Hipertrofia mięśniowa',
    },
    'get_fit': {
      'icon': Icons.bolt,
      'color': const Color(0xFFF59E0B), // Orange
      'label': 'Poprawić Formę',
      'description': 'Ogólna sprawność',
    },
    'strength': {
      'icon': Icons.sports_gymnastics,
      'color': const Color(0xFF3B82F6), // Blue
      'label': 'Zwiększyć Siłę',
      'description': 'Progresja siłowa',
    },
  };

  @override
  void dispose() {
    _weightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.flag,
                    color: AppColors.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ustaw Swój Cel',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      Text(
                        'Pomożemy Ci go osiągnąć!',
                        style: TextStyle(
                          fontSize: 14,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Goal Selection
            Text(
              'Jaki jest Twój główny cel?',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _goals.entries.map((entry) {
                final isSelected = _selectedGoal == entry.key;
                return ChoiceChip(
                  label: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      entry.value['icon'] as IconData,
                      size: 20,
                      color: isSelected ? entry.value['color'] as Color : colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 8),
                    Text(entry.value['label']),
                  ],
                ),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      _selectedGoal = entry.key;
                    });
                  },
                  selectedColor: AppColors.primary.withOpacity(0.2),
                  backgroundColor: colorScheme.surfaceVariant,
                  labelStyle: TextStyle(
                    color: isSelected ? AppColors.primary : colorScheme.onSurface,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                  side: BorderSide(
                    color: isSelected ? AppColors.primary : Colors.transparent,
                    width: 2,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // Deadline Selection
            Text(
              'Kiedy chcesz osiągnąć cel?',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _selectedDeadline,
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 730)), // 2 years
                  builder: (context, child) {
                    return Theme(
                      data: Theme.of(context).copyWith(
                        colorScheme: ColorScheme.light(
                          primary: AppColors.primary,
                          onPrimary: Colors.white,
                          surface: Colors.white,
                          onSurface: Colors.black,
                        ),
                      ),
                      child: child!,
                    );
                  },
                );
                if (picked != null) {
                  setState(() {
                    _selectedDeadline = picked;
                  });
                }
              },
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: colorScheme.outline.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today, color: AppColors.primary),
                    const SizedBox(width: 12),
                    Text(
                      _formatDate(_selectedDeadline),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Spacer(),
                    Icon(Icons.chevron_right, color: colorScheme.onSurfaceVariant),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Quick presets
            Wrap(
              spacing: 8,
              children: [
                _buildPresetChip('1 miesiąc', 30),
                _buildPresetChip('3 miesiące', 90),
                _buildPresetChip('6 miesięcy', 180),
              ],
            ),
            const SizedBox(height: 24),

            // Optional: Target Weight (only for lose_weight/build_muscle)
            if (_selectedGoal == 'lose_weight' || _selectedGoal == 'build_muscle') ...[
              Text(
                'Docelowa waga (opcjonalnie)',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _weightController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: 'np. 75',
                  suffixText: 'kg',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: colorScheme.outline.withOpacity(0.2)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.primary, width: 2),
                  ),
                ),
                onChanged: (value) {
                  _targetWeight = double.tryParse(value);
                },
              ),
              const SizedBox(height: 24),
            ],

            // Save Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  final userProvider = context.read<UserProvider>();
                  userProvider.updateGoal(
                    goal: _selectedGoal,
                    deadline: _selectedDeadline,
                    targetWeight: _targetWeight,
                  );
                  Navigator.pop(context);
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          const Icon(Icons.check_circle, color: Colors.white),
                          const SizedBox(width: 12),
                          Text('Cel ustawiony: ${_goals[_selectedGoal]!['label']}!'),
                        ],
                      ),
                      backgroundColor: AppColors.primary,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
                child: const Text(
                  'Zapisz Cel',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPresetChip(String label, int days) {
    return ActionChip(
      label: Text(label),
      onPressed: () {
        setState(() {
          _selectedDeadline = DateTime.now().add(Duration(days: days));
        });
      },
      backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
      side: BorderSide.none,
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
