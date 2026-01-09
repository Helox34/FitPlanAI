import 'dart:async';
import 'package:flutter/material.dart';
import '../core/models/models.dart';
import 'plan_provider.dart';

class LiveWorkoutProvider with ChangeNotifier {
  final PlanProvider _planProvider;
  
  // State
  bool _isActive = false;
  bool _isResting = false;
  
  int _currentDayIndex = 0;
  int _currentExerciseIndex = 0;
  int _currentSetNumber = 1;
  
  // Timer
  Timer? _timer;
  int _remainingRestSeconds = 0;
  int _totalRestSeconds = 180; // Default 3 minutes
  
  // Getters
  bool get isActive => _isActive;
  bool get isResting => _isResting;
  int get currentExerciseIndex => _currentExerciseIndex;
  int get currentSetNumber => _currentSetNumber;
  int get remainingRestSeconds => _remainingRestSeconds;
  double get progress => _calculateProgress();
  
  // Current Data Helpers
  GeneratedPlan? get _plan => _planProvider.workoutPlan;
  
  PlanDay? get currentDay {
    if (_plan == null || _plan!.schedule.isEmpty) return null;
    if (_currentDayIndex >= _plan!.schedule.length) return null;
    return _plan!.schedule[_currentDayIndex];
  }
  
  PlanItem? get currentExercise {
    final day = currentDay;
    if (day == null || day.items.isEmpty) return null;
    if (_currentExerciseIndex >= day.items.length) return null;
    return day.items[_currentExerciseIndex];
  }
  
  PlanItem? get nextExercise {
    final day = currentDay;
    if (day == null) return null;
    if (_currentExerciseIndex + 1 < day.items.length) {
      return day.items[_currentExerciseIndex + 1];
    }
    return null; // No next exercise (end of workout)
  }
  
  int get totalSetsForCurrentExercise {
    final exercise = currentExercise;
    if (exercise == null) return 1;
    
    final lower = exercise.details.toLowerCase();
    
    // Check for explicit "serie"
    if (lower.contains('seri')) { // seria, serie, serii
       // Extract number before "seri"
       final regex = RegExp(r'(\d+)\s*seri');
       final match = regex.firstMatch(lower);
       if (match != null) {
         return int.parse(match.group(1)!);
       }
       // If "serie" is present but regex fails, maybe it's "Serie: 3"
       // Fallback to split
    }
    
    // Check for time units without "serie" (implies 1 set, e.g. "10 minut marszu")
    if (lower.contains('minut') || lower.contains('sekund') || lower.contains('godzin')) {
       return 1;
    }
    
    // Default fallback (naive split)
    try {
      final parts = exercise.details.split(' ');
      if (parts.isNotEmpty) {
        return int.tryParse(parts[0]) ?? 3;
      }
    } catch (_) {}
    return 3;
  }

  LiveWorkoutProvider(this._planProvider);

  // Actions
  
  void startWorkout(int dayIndex) {
    _isActive = true;
    _isResting = false;
    _currentDayIndex = dayIndex;
    _currentExerciseIndex = 0;
    _currentSetNumber = 1;
    notifyListeners();
  }
  
  void completeSet() {
    if (!_isActive) return;
    
    // Check if this was the last set of the exercise
    if (_currentSetNumber >= totalSetsForCurrentExercise) {
      // Move to next exercise or finish
      if (nextExercise != null) {
        _startRest();
      } else {
        finishWorkout();
      }
    } else {
      // Move to next set within same exercise
      _startRest();
    }
  }
  
  void _startRest() {
    _isResting = true;
    _remainingRestSeconds = _totalRestSeconds;
    notifyListeners();
    
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingRestSeconds > 0) {
        _remainingRestSeconds--;
        notifyListeners();
      } else {
        skipRest();
      }
    });
  }
  
  void skipRest() {
    _timer?.cancel();
    _isResting = false;
    
    // Advance logic
    if (_currentSetNumber >= totalSetsForCurrentExercise) {
      // Was last set, move to next exercise
      _currentExerciseIndex++;
      _currentSetNumber = 1;
    } else {
      // Just next set
      _currentSetNumber++;
    }
    
    notifyListeners();
  }
  
  void finishWorkout() {
    _isActive = false;
    _timer?.cancel();
    notifyListeners();
    
    // Update Streak
    // We need context or reference to UserProvider. 
    // Since we don't have it here, we will rely on the UI to call it
    // OR we could pass a callback.
    // However, the cleanest way without refactoring everything is 
    // to handle it in the UI before pop.
  }
  
  void cancelWorkout() {
    _isActive = false;
    _timer?.cancel();
    notifyListeners();
  }
  
  double _calculateProgress() {
    final day = currentDay;
    if (day == null) return 0.0;
    
    int totalSets = 0;
    int completedSets = 0;
    
    for (int i = 0; i < day.items.length; i++) {
      final item = day.items[i];
      // Estimate sets (default 3 if parse fail)
      int sets = 3; 
      try {
        sets = int.tryParse(item.details.split(' ')[0]) ?? 3;
      } catch (_) {}
      
      totalSets += sets;
      
      if (i < _currentExerciseIndex) {
        completedSets += sets;
      } else if (i == _currentExerciseIndex) {
        completedSets += (_currentSetNumber - 1);
      }
    }
    
    if (totalSets == 0) return 0.0;
    return completedSets / totalSets;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
