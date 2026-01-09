import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class DaySelector extends StatelessWidget {
  final int selectedDayIndex;
  final Function(int) onDaySelected;
  final List<String>? customDays;

  const DaySelector({
    super.key,
    required this.selectedDayIndex,
    required this.onDaySelected,
    this.customDays,
  });

  List<String> get _days => customDays ?? const ['Pon', 'Wt', 'Śr', 'Czw', 'Pt', 'Sob', 'Nie'];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _days.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final isSelected = selectedDayIndex == index;
          return GestureDetector(
            onTap: () => onDaySelected(index),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? AppColors.primary : AppColors.border,
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                _days[index],
                style: TextStyle(
                  color: isSelected ? Colors.white : AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
