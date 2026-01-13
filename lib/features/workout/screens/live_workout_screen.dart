import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../providers/live_workout_provider.dart';
import '../../../providers/user_provider.dart';
import '../widgets/live_exercise_view.dart';
import '../widgets/live_rest_view.dart';
import '../../../core/widgets/worm_loader.dart';

class LiveWorkoutScreen extends StatefulWidget {
  const LiveWorkoutScreen({super.key});

  @override
  State<LiveWorkoutScreen> createState() => _LiveWorkoutScreenState();
}

class _LiveWorkoutScreenState extends State<LiveWorkoutScreen> {
  @override
  void initState() {
    super.initState();
    // Add listener to check for completion
    final provider = context.read<LiveWorkoutProvider>();
    provider.addListener(_checkCompletion);
  }

  @override
  void dispose() {
    // Remove listener to avoid leaks
    try {
      context.read<LiveWorkoutProvider>().removeListener(_checkCompletion);
    } catch (_) {}
    super.dispose();
  }

  void _checkCompletion() {
    final provider = context.read<LiveWorkoutProvider>();
    if (!provider.isActive && mounted) {
      // Workout finished (and not just cancelled, assuming finishWorkout sets isActive=false)
      // Check if we should increment streak
      // We can assume if it closed naturally it's done. 
      // Ideally we would have a specific flag "isCompleted" in provider, 
      // but "isActive" going false without user cancellation implies finish.
      
      // Since we don't have a distinct "completed" flag, we'll increment streak here
      // But wait! cancelWorkout ALSO sets isActive = false.
      // We need to differentiate.
      // Let's modify provider to have a "completed" flag or just handle it here?
      // Actually, finishWorkout triggers notifyListeners after setting isActive=false.
      // But so does cancelWorkout.
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        final shouldPop = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Zakończyć trening?'),
            content: const Text('Twój postęp zostanie utracony.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Anuluj'),
              ),
              TextButton(
                onPressed: () {
                  context.read<LiveWorkoutProvider>().cancelWorkout();
                  Navigator.of(context).pop(true);
                },
                child: const Text('Zakończ'),
              ),
            ],
          ),
        );
        return shouldPop ?? false;
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF0F172A), // Deep dark blue background
        body: SafeArea(
          child: Consumer<LiveWorkoutProvider>(
            builder: (context, provider, child) {
              if (!provider.isActive) {
                // Determine if finished or cancelled
                // This is a bit tricky with just isActive.
                // Let's rely on a direct callback passing for now, or just assume
                // if we are in this build and not active, we shoud pop.
                
                // Let's improve the provider to handle this cleaner.
                // But for now, let's just use the Consumer to detect completion
                 WidgetsBinding.instance.addPostFrameCallback((_) {
                   if (mounted) Navigator.of(context).pop();
                });
                return Center(child: WormLoader(size: 50));
              }
              
              final exercise = provider.currentExercise;
              
              return Column(
                children: [
                   // Progress Bar
                  LinearProgressIndicator(
                    value: provider.progress,
                    backgroundColor: Colors.white24, // Higher contrast
                    color: AppColors.primary,
                    minHeight: 6, // Thicker
                  ),
                  
                  // Header
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white),
                          onPressed: () => Navigator.of(context).maybePop(),
                        ),
                        Text(
                          'Ćwiczenie ${provider.currentExerciseIndex + 1} z ${provider.currentDay?.items.length ?? '?' }', 
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.5),
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(width: 40), // Balance close button
                      ],
                    ),
                  ),
                  
                  // Main Content
                  Expanded(
                    child: provider.isResting
                        ? LiveRestView(
                            remainingSeconds: provider.remainingRestSeconds,
                            nextExerciseName: provider.nextExercise?.name ?? provider.currentExercise?.name ?? 'Koniec',  
                            onSkip: provider.skipRest,
                          )
                        : LiveExerciseView(
                            exercise: exercise!,
                            setNumber: provider.currentSetNumber,
                            totalSets: provider.totalSetsForCurrentExercise,
                            onComplete: () {
                               // Check if this is the absolute last step
                               final isLast = provider.nextExercise == null && 
                                              provider.currentSetNumber >= provider.totalSetsForCurrentExercise;
                               
                               if (isLast) {
                                 // Update streak BEFORE finishing
                                 context.read<UserProvider>().incrementStreak();
                                 
                                 // Show congratulations dialog
                                 showDialog(
                                   context: context,
                                   barrierDismissible: false,
                                   builder: (context) => AlertDialog(
                                     title: Row(
                                       children: const [
                                         Icon(Icons.emoji_events, color: Colors.amber),
                                         SizedBox(width: 8),
                                         Text('Trening Ukończony!'),
                                       ],
                                     ),
                                     content: const Text(
                                       'Świetna robota! Twój postęp został zapisany, a passa wzrosła! 🔥',
                                     ),
                                     actions: [
                                       TextButton(
                                         onPressed: () {
                                            Navigator.of(context).pop(); // Close dialog
                                            provider.finishWorkout(); // This will trigger pop via consumer/listener
                                         },
                                         child: const Text('Super!'),
                                       ),
                                     ],
                                   ),
                                 );
                               } else {
                                 provider.completeSet();
                               }
                            },
                          ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
