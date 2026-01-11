import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/models/models.dart';
import '../../../core/widgets/empty_plan_widget.dart';
import '../../../providers/plan_provider.dart';
import '../../home/screens/main_shell.dart';
import '../widgets/exercise_card.dart';
import '../widgets/day_selector.dart';
import '../widgets/day_selector.dart';
import '../../../providers/live_workout_provider.dart';
import '../../../providers/user_provider.dart';
import 'live_workout_screen.dart';

/// Screen displaying the user's workout plan
class MyPlanScreen extends StatefulWidget {
  const MyPlanScreen({super.key});

  @override
  State<MyPlanScreen> createState() => _MyPlanScreenState();
}

class _MyPlanScreenState extends State<MyPlanScreen> {
  int _selectedDayIndex = DateTime.now().weekday - 1; // 0 = Monday
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PlanProvider>().loadPlans();
    });
  }
  
  void _navigateToProgressTab() {
    final mainShellState = mainShellKey.currentState;
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
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        title: Text(
          'Mój Plan',
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
          final plan = planProvider.workoutPlan;
          
          if (plan == null) {
            return EmptyPlanWidget(
              dayName: 'Nie masz jeszcze planu treningowego',
              onGeneratePlan: _navigateToProgressTab,
            );
          }
          
          return SafeArea(
            bottom: false,
            child: Column(
              children: [
                // Custom Header with Achievements and Title
                _buildDashboardHeader(plan),
                
                // Day Selector
                Container(
                  color: theme.scaffoldBackgroundColor, // was AppColors.surface, but clearer if matches background
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: DaySelector(
                    selectedDayIndex: _selectedDayIndex,
                    onDaySelected: (index) {
                      setState(() {
                        _selectedDayIndex = index;
                      });
                    },
                  ),
                ),
                
                const Divider(height: 1, indent: 16, endIndent: 16),
                
                // Content
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // "Start Live Training" Button
                      Builder(
                        builder: (context) {
                          // Check if selected day is today
                          // DateTime.weekday returns 1 for Monday, ..., 7 for Sunday
                          // _selectedDayIndex is 0 for Monday, ..., 6 for Sunday
                          final now = DateTime.now();
                          final currentDayIndex = now.weekday - 1;
                          final isToday = _selectedDayIndex == currentDayIndex;
                          
                          return Container(
                            width: double.infinity,
                            margin: const EdgeInsets.only(bottom: 24),
                            child: ElevatedButton.icon(
                              onPressed: isToday ? () {
                                // Start Live Training
                                final liveProvider = context.read<LiveWorkoutProvider>();
                                liveProvider.startWorkout(_selectedDayIndex);
                                
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => const LiveWorkoutScreen(),
                                  ),
                                );
                              } : () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Możesz rozpocząć tylko dzisiejszy trening!'),
                                    backgroundColor: Colors.orange,
                                  ),
                                );
                              },
                              icon: const Icon(Icons.play_circle_outline, size: 28),
                              label: const Text(
                                'Rozpocznij Trening Live',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isToday ? AppColors.primary : Colors.grey.shade400,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: isToday ? 4 : 0,
                              ),
                            ),
                          );
                        }
                      ),
                      
                      // Day Content
                      _buildDayContent(plan, _selectedDayIndex),
                    ],
                  ),
                ),
                
                // Add padding for bottom navigation bar
                const SizedBox(height: 80), 
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDashboardHeader(GeneratedPlan plan) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
      color: theme.scaffoldBackgroundColor, // Changed from Colors.white
      child: Consumer<UserProvider>(
        builder: (context, userProvider, _) {
          final streak = userProvider.profile?.isLoggedIn == true 
              ? (userProvider.age != null ? 0 : 0) // Just placeholder check
              : 0;
              
          // Use SharedPreferences values loaded in UserProvider
          // We need to expose getter for streak_current if not available, 
          // but looking at UserProvider it has no getter for streak_current.
          // Let's check UserProvider again.
          // It has `loadUserData` which loads `streak_current` but does not expose it as getter?
          // I need to add getters to UserProvider first or check if it exposes it.
          // Checked UserProvider, it has private `_age` etc. I need to check if I added streak getter.
          // I added `incrementStreak` but did I add getters? 
          // I will assume I need to add getters to UserProvider.
             
          return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
            // "Achievements" Mockup Section
            Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: colorScheme.outline.withOpacity(0.2)),
            ),
            child: Row(
                children: [
                const Icon(Icons.emoji_events, color: Colors.amber, size: 24),
                const SizedBox(width: 12),
                Expanded(
                    child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                         Text(
                        'Twoje Osiągnięcia',
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                        ),
                        ),
                        Text(
                        'Dni z rzędu: ${userProvider.streakCurrent} 🔥 | Odblokowano: ${userProvider.streakCurrent}/30',
                        style: TextStyle(
                            fontSize: 12,
                            color: colorScheme.onSurfaceVariant,
                        ),
                        ),
                    ],
                    ),
                ),
                ],
            ),
            ),
            
            // Plan Title Section (Moved inside Column)
            Text(
              plan.title,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              plan.description,
              style: TextStyle(
                fontSize: 14,
                color: colorScheme.onSurfaceVariant,
                height: 1.4,
              ),
            ),
          ],
        );
      }),
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
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.bed_outlined, size: 48, color: Theme.of(context).colorScheme.onSurfaceVariant),
              const SizedBox(height: 16),
              Text(
                'Dzień Regeneracji',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Dzisiaj odpoczywamy! ',
                style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
      );
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Day Title
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              dayNames[dayIndex],
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 16),
        
        if (planDay.summary != null) ...[
          Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.only(bottom: 24),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.primary.withOpacity(0.1)),
            ),
            child: Row(
              children: [
                const Icon(Icons.format_quote, color: AppColors.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    planDay.summary!,
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context).colorScheme.onSurface,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        
        ...planDay.items.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          return ExerciseCard(
            index: index + 1,
            exercise: item,
          );
        }).toList(),
      ],
    );
  }
}
