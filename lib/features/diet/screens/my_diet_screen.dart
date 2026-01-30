import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/models/models.dart';
import '../../../providers/plan_provider.dart';
import '../../../providers/user_provider.dart';
import '../../../core/widgets/empty_plan_widget.dart';
import '../../../services/meal_replacement_service.dart';
import '../../../core/widgets/worm_loader.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../workout/widgets/day_selector.dart';
import '../../../core/widgets/worm_loader.dart';

/// Screen displaying the user's diet plan (analogous to MyPlanScreen)
class MyDietScreen extends StatefulWidget {
  const MyDietScreen({super.key});

  @override
  State<MyDietScreen> createState() => _MyDietScreenState();
}

class _MyDietScreenState extends State<MyDietScreen> {
  int _selectedDayIndex = 0; // Start from Day 1 (today)
  // Diet plan starts TODAY, not from week start
  DateTime _planStartDate = DateTime.now();
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PlanProvider>().loadPlans();
    });
  }
  
  void _navigateToProgressTab() {
    // Switch to Progress tab (index 2)
    // TODO: Implement tab navigation without MainShellState
    // final mainShellState = context.findAncestorStateOfType<MainShellState>();
    // if (mainShellState != null) {
    //   mainShellState.changeTab(2); // Progress tab is at index 2
    // }
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
          
          if (planProvider.dietPlan == null) {
            return EmptyPlanWidget(
              mode: CreatorMode.DIET,
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
                      plan!.title,
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
              
              // Day Selector - Modified for 30-day plans
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: theme.scaffoldBackgroundColor,
                child: Column(
                  children: [
                    // Week navigation for 30-day plan
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.chevron_left),
                          onPressed: _selectedDayIndex >= 7 ? () {
                            setState(() {
                              _selectedDayIndex = (_selectedDayIndex - 7).clamp(0, plan.schedule.length - 1);
                            });
                          } : null,
                        ),
                        Text(
                          'Tydzień ${(_selectedDayIndex ~/ 7) + 1}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        IconButton(
                          icon: const Icon(Icons.chevron_right),
                          onPressed: _selectedDayIndex + 7 < plan.schedule.length ? () {
                            setState(() {
                              _selectedDayIndex = (_selectedDayIndex + 7).clamp(0, plan.schedule.length - 1);
                            });
                          } : null,
                        ),
                      ],
                    ),
                    // Day buttons for current week
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: List.generate(
                          7.clamp(0, plan.schedule.length - (_selectedDayIndex ~/ 7) * 7),
                          (index) {
                            final dayIndex = (_selectedDayIndex ~/ 7) * 7 + index;
                            final date = _planStartDate.add(Duration(days: dayIndex));
                            final isSelected = dayIndex == _selectedDayIndex;
                            final isToday = dayIndex == 0;
                            
                            return Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4),
                              child: InkWell(
                                onTap: () {
                                  setState(() {
                                    _selectedDayIndex = dayIndex;
                                  });
                                },
                                child: Container(
                                  width: 60,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? const Color(0xFF10B981)
                                        : (isToday ? const Color(0xFF10B981).withOpacity(0.1) : null),
                                    borderRadius: BorderRadius.circular(12),
                                    border: isToday && !isSelected
                                        ? Border.all(color: const Color(0xFF10B981), width: 2)
                                        : null,
                                  ),
                                  child: Column(
                                    children: [
                                      Text(
                                        ['Pon', 'Wt', 'Śr', 'Czw', 'Pt', 'Sob', 'Niedz'][date.weekday - 1],
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: isSelected
                                              ? Colors.white
                                              : colorScheme.onSurface.withOpacity(0.6),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${date.day}',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: isSelected ? Colors.white : colorScheme.onSurface,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
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
    
    // Validate day index
    if (dayIndex < 0 || dayIndex >= plan.schedule.length) {
      return EmptyPlanWidget(
        mode: CreatorMode.DIET,
        onGeneratePlan: _navigateToProgressTab,
      );
    }
    
    final planDay = plan.schedule[dayIndex];
    final date = _planStartDate.add(Duration(days: dayIndex));
    
    if (planDay == null || planDay.items.isEmpty) {
      return EmptyPlanWidget(
        mode: CreatorMode.DIET,
        onGeneratePlan: _navigateToProgressTab,
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
          // Change Meal Button
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => _showMealAlternativesDialog(context, item, number),
            icon: const Icon(Icons.sync, size: 18),
            label: const Text('Zmień posiłek'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF10B981),
              side: const BorderSide(color: Color(0xFF10B981)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showMealAlternativesDialog(BuildContext context, PlanItem currentMeal, int mealIndex) async {
    final planProvider = context.read<PlanProvider>();
    BuildContext? loadingDialogContext;
    
    // Build user context
    final userContext = {
      'goal': 'Redukcja wagi', // TODO: Get from user data
      'calories_target': 2000, // TODO: Calculate from user data
    };

    try {
      // Capture the dialog context for later use
      BuildContext? loadingDialogContext;
      
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) {
          loadingDialogContext = ctx;
          return Dialog(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Alternatywne posiłki',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Szukamy zamienników dla: ${currentMeal.name}',
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                  const SizedBox(height: 24),
                  WormLoader(size: 40),
                  const SizedBox(height: 16),
                  const Text('Generowanie alternatyw...'),
                ],
              ),
            ),
          );
        },
      );

      final service = MealReplacementService();
      final alternatives = await service.generateMealAlternatives(
        currentMeal: currentMeal,
        userContext: userContext,
      );

      if (!context.mounted) return;
      if (loadingDialogContext != null) {
        Navigator.pop(loadingDialogContext!); // Close loading dialog
      }

      // Show alternatives selection dialog
      showDialog(
        context: context,
        builder: (selectContext) => Dialog(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    const Icon(Icons.restaurant_menu, color: Color(0xFF10B981)),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Wybierz zamiennik',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(selectContext),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: alternatives.length,
                    itemBuilder: (context, index) {
                      final alt = alternatives[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: InkWell(
                          onTap: () async {
                            Navigator.pop(selectContext);
                            // Replace meal
                            await planProvider.replaceMeal(
                              dayIndex: _selectedDayIndex,
                              mealIndex: mealIndex - 1, // Convert from 1-indexed to 0-indexed
                              newMeal: alt,
                            );
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Zamieniono na: ${alt.name}'),
                                  backgroundColor: const Color(0xFF10B981),
                                ),
                              );
                            }
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  alt.name,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  alt.details,
                                  style: TextStyle(color: Colors.grey[700]),
                                ),
                                if (alt.note != null) ...[
                                  const SizedBox(height: 8),
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.grey[100],
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      alt.note!,
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  ),
                                ],
                                if (alt.tips != null) ...[
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.lightbulb_outline,
                                        size: 16,
                                        color: Color(0xFF10B981),
                                      ),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          alt.tips!,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontStyle: FontStyle.italic,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    } catch (e) {
      if (!context.mounted || loadingDialogContext == null) return;
      Navigator.pop(loadingDialogContext); // Close loading dialog
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Błąd: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
