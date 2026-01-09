import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/models/models.dart';
import '../../../core/widgets/empty_plan_widget.dart';
import '../../../providers/plan_provider.dart';
import '../../onboarding/screens/plan_type_selection_screen.dart';
import '../../home/screens/main_shell.dart';

/// Screen displaying the user's diet plan (analogous to MyPlanScreen)
class MyDietScreen extends StatefulWidget {
  const MyDietScreen({super.key});

  @override
  State<MyDietScreen> createState() => _MyDietScreenState();
}

class _MyDietScreenState extends State<MyDietScreen> {
  int _selectedDayIndex = DateTime.now().weekday - 1; // 0 = Monday
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PlanProvider>().loadPlans();
    });
  }
  
  void _navigateToProgressTab() {
    // Switch to Progress tab (index 2)
    final mainShellState = mainShellKey.currentState;
    if (mainShellState != null) {
      mainShellState.changeTab(2); // Progress tab is at index 2
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: const Text(
          'Moja Dieta',
          style: TextStyle(
            color: AppColors.textPrimary,
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
                color: AppColors.surface,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      plan.title,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      plan.description,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Day selector
              Container(
                height: 60,
                color: AppColors.surface,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  itemCount: 7,
                  itemBuilder: (context, index) {
                    final days = ['Pon', 'Wt', 'Śr', 'Czw', 'Pt', 'Sob', 'Nie'];
                    final isSelected = index == _selectedDayIndex;
                    
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedDayIndex = index;
                        });
                      },
                      child: Container(
                        width: 50,
                        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected ? const Color(0xFF10B981) : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text(
                            days[index],
                            style: TextStyle(
                              color: isSelected ? Colors.white : AppColors.textSecondary,
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              
              const Divider(height: 1, color: AppColors.border),
              
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
    final dayNames = ['Poniedziałek', 'Wtorek', 'Środa', 'Czwartek', 'Piątek', 'Sobota', 'Niedziela'];
    
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
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textPrimary,
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
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
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
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            item.details,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          if (item.note != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.background,
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
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
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
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textPrimary,
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
