import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';

class DaySelector extends StatefulWidget {
  final DateTime currentWeekStart;
  final int selectedDayIndex; // 0-6 (Mon-Sun) relative to the week
  final Function(int) onDaySelected;
  final VoidCallback onPreviousWeek;
  final VoidCallback onNextWeek;

  const DaySelector({
    super.key,
    required this.currentWeekStart,
    required this.selectedDayIndex,
    required this.onDaySelected,
    required this.onPreviousWeek,
    required this.onNextWeek,
  });

  @override
  State<DaySelector> createState() => _DaySelectorState();
}

class _DaySelectorState extends State<DaySelector> {
  @override
  Widget build(BuildContext context) {
    // Format Month (e.g., "STY", "LUT")
    // We use strict Polish abbreviations as requested/inferred
    final months = [
      '', 'STY', 'LUT', 'MAR', 'KWI', 'MAJ', 'CZE', 
      'LIP', 'SIE', 'WRZ', 'PAŹ', 'LIS', 'GRU'
    ];
    // Use the month of the Thursday of the week to determine the "week's month" (ISO standard-ish)
    // Or just use the start date's month.
    final monthName = months[widget.currentWeekStart.month];
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      color: Colors.transparent, 
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start, // Align to top to manage offsets manually
        children: [
          // Month Label
          Container(
            width: 50,
            // Align month text with Day Names (top) or center? 
            // Screenshot shows Month barely visible or just simple. 
            // Let's keep it somewhat centered or adjust.
            // User put arrow "lower", implies Month might be fine?
            // Let's align Month with the vertical center of the whole strip effectively.
            height: 56, // Approx height of day column
            alignment: Alignment.center,
            child: Text(
              monthName,
              style: const TextStyle(
                color: AppColors.primary, 
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
          
          // Prev Arrow - Pushed down to align with Numbers
          Padding(
            padding: const EdgeInsets.only(top: 20), // Push down to align with numbers
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, size: 18),
              color: colorScheme.onSurfaceVariant, // Darker grey for visibility
              onPressed: widget.onPreviousWeek,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32),
            ),
          ),
          
          // Days Strip
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(7, (index) {
                final date = widget.currentWeekStart.add(Duration(days: index));
                final isSelected = widget.selectedDayIndex == index;
                final isToday = _isSameDay(date, DateTime.now());
                
                return GestureDetector(
                  onTap: () => widget.onDaySelected(index),
                  behavior: HitTestBehavior.opaque,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Day Name (pon, wt...)
                      Text(
                        _getDayName(index),
                        style: TextStyle(
                          color: isSelected ? AppColors.primary : colorScheme.onSurfaceVariant,
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      const SizedBox(height: 6),
                      
                      // Day Number Circle
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.primary : Colors.transparent,
                          shape: BoxShape.circle,
                          border: isToday && !isSelected 
                              ? Border.all(color: AppColors.primary, width: 1)
                              : null,
                          boxShadow: isSelected ? [
                            BoxShadow(
                              color: AppColors.primary.withOpacity(0.4),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ) 
                          ] : null,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '${date.day}',
                          style: TextStyle(
                            // Fixed: distinct color for unselected state (e.g., Black/Grey) instead of White70
                            color: isSelected ? Colors.white : colorScheme.onSurface, 
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
          ),
          
          // Next Arrow - Pushed down
          Padding(
            padding: const EdgeInsets.only(top: 20), // Push down
            child: IconButton(
              icon: const Icon(Icons.arrow_forward_ios, size: 18),
              color: colorScheme.onSurfaceVariant,
              onPressed: widget.onNextWeek,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32),
            ),
          ),
        ],
      ),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  String _getDayName(int index) {
    const days = ['pon', 'wt', 'śr', 'czw', 'pt', 'sob', 'nie'];
    return days[index % 7];
  }
}
