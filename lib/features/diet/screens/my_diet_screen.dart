import 'package:flutter/material.dart';
import '../../home/screens/main_shell.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/models/models.dart';
import '../../../core/widgets/empty_plan_widget.dart';
import '../../../providers/plan_provider.dart';
import '../../onboarding/screens/plan_type_selection_screen.dart';
import '../../onboarding/screens/plan_type_selection_screen.dart';

import '../../workout/widgets/day_selector.dart';
import '../../../core/widgets/worm_loader.dart';

/// Screen displaying the user's diet plan (analogous to MyPlanScreen)
class MyDietScreen extends StatefulWidget {
  const MyDietScreen({super.key});

  @override
  State<MyDietScreen> createState() => _MyDietScreenState();
}

class _MyDietScreenState extends State<MyDietScreen> {
  int _selectedDayIndex = DateTime.now().weekday - 1; // 0 = Monday
  // Initialize to the Monday of the current week
  DateTime _currentWeekStart = DateTime.now().subtract(Duration(days: DateTime.now().weekday - 1));
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PlanProvider>().loadPlans();
    });
  }
  
  void _navigateToProgressTab() {
    // Switch to Progress tab (index 2)
    final mainShellState = context.findAncestorStateOfType<MainShellState>();
    if (mainShellState != null) {
      mainShellState.changeTab(2); // Progress tab is at index 2
    }
  }
  
  @override
  Widget build(BuildContext context) {
    // Ensure index is valid (0-6)
    if (_selectedDayIndex < 0 || _selectedDayIndex > 6) {
      _selectedDayIndex = 0;
    }

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        title: Text(
          'Moja Dieta',
          style: TextStyle(
            color: colorScheme.onSurface,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Color(0xFF10B981)),
            onPressed: _navigateToProgressTab,
          ),
        ],
      ),
      body: Consumer<PlanProvider>(
        builder: (context, planProvider, _) {
          if (planProvider.isGenerating) {
             return const Center(
               child: Column(
                 mainAxisAlignment: MainAxisAlignment.center,
                 children: [
                   WormLoader(color: Color(0xFF10B981)), // Explicit Green for Diet
                   SizedBox(height: 24),
                   Text('Generowanie diety...', style: TextStyle(color: Colors.white70)),
                 ],
               ),
             );
          }

          final plan = planProvider.dietPlan;
          
          if (plan == null) {
            return EmptyPlanWidget(
              dayName: 'Nie masz jeszcze planu dietetycznego',
              onGeneratePlan: _navigateToProgressTab,
            );
          }
          
          return Column(
            children: [
              // Plan header
              Container(
                padding: const EdgeInsets.all(20),
                color: theme.scaffoldBackgroundColor, // Seamless header
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      plan.title,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      plan.description,
                      style: TextStyle(
                        fontSize: 14,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Day Selector (Calendar Strip)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: theme.scaffoldBackgroundColor,
                child: DaySelector(
                  currentWeekStart: _currentWeekStart,
                  selectedDayIndex: _selectedDayIndex,
                  onDaySelected: (index) {
                    setState(() {
                      _selectedDayIndex = index;
                    });
                  },
                  onPreviousWeek: () {
                    setState(() {
                      _currentWeekStart = _currentWeekStart.subtract(const Duration(days: 7));
                    });
                  },
                  onNextWeek: () {
                    setState(() {
                      _currentWeekStart = _currentWeekStart.add(const Duration(days: 7));
                    });
                  },
                ),
              ),
              
              const Divider(height: 1, indent: 16, endIndent: 16),
              
              // Day content
              Expanded(
                child: _buildDayContent(plan, _selectedDayIndex),
              ),
            ],
          );
        },
      ),
    );
  }
  
  Widget _buildDayContent(GeneratedPlan plan, int dayIndex) {
    final colorScheme = Theme.of(context).colorScheme;
    // Generate day names dynamically if more than 7
    final List<String> dayNames;
    if (plan.schedule.length <= 7) {
      dayNames = ['Poniedziałek', 'Wtorek', 'Środa', 'Czwartek', 'Piątek', 'Sobota', 'Niedziela'];
    } else {
      dayNames = List.generate(plan.schedule.length, (i) => 'Dzień ${i + 1}');
    }
    
    // Find the day in the schedule
    PlanDay? planDay;
    if (dayIndex < plan.schedule.length) {
      planDay = plan.schedule[dayIndex];
    }
    
    if (planDay == null || planDay.items.isEmpty) {
      return EmptyPlanWidget(
        dayName: dayNames[dayIndex],
      );
    }
    
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (planDay.summary != null) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              planDay.summary!,
              style: TextStyle(
                fontSize: 14,
                color: colorScheme.onSurface,
                height: 1.4,
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
        
        ...planDay.items.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          return _buildMealCard(item, index + 1);
        }).toList(),
      ],
    );
  }
  
  Widget _buildMealCard(PlanItem item, int number) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outline.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    '$number',
                    style: const TextStyle(
                      color: Color(0xFF10B981),
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  item.name,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            item.details,
            style: TextStyle(
              fontSize: 14,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          if (item.note != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: theme.scaffoldBackgroundColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline,
                    size: 16,
                    color: Color(0xFF10B981),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      item.note!,
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (item.tips != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.restaurant_menu,
                    size: 16,
                    color: Color(0xFF10B981),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      item.tips!,
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.onSurface,
                        fontStyle: FontStyle.italic,
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
  }
}
