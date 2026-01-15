import 'package:flutter/foundation.dart';
import '../core/models/models.dart';
import '../providers/user_provider.dart';
import '../providers/plan_provider.dart';

/// Service to handle exercise modification requests with full user context
class ExerciseModificationService {
  /// Builds comprehensive user context for AI recommendations
  Future<Map<String, dynamic>> buildUserContext({
    required UserProvider userProvider,
    required PlanProvider planProvider,
  }) async {
    // Collect all relevant user data
    final context = <String, dynamic>{};
    
    // Basic info
    context['age'] = userProvider.age ?? 25;
    context['weight'] = userProvider.weight ?? 70.0;
    context['height'] = userProvider.height ?? 175.0;
    
    // Fitness level (from survey or default to beginner)
    context['fitness_level'] = 'intermediate'; // TODO: Get from survey
    
    // Goals
    context['goals'] = ['general_fitness']; // TODO: Get from survey
    
    // Health conditions
    context['health_conditions'] = []; // TODO: Get from survey
    
    // Injuries (current and past)
    context['injuries'] = []; // TODO: Get from survey
    context['limitations'] = []; // TODO: Get from survey
    
    // Equipment access
    context['equipment'] = 'full_gym'; // TODO: Get from survey
    
    // Workout preferences
    context['workouts_per_week'] = 3; // TODO: Get from survey
    context['minutes_per_session'] = 60; // TODO: Get from survey
    
    // Current plan type
    if (planProvider.currentPlan != null) {
      context['current_plan_mode'] = planProvider.currentPlan!.mode.toString();
    }
    
    debugPrint('📋 Built user context: $context');
    
    return context;
  }
  
  /// Validates if a proposed exercise is safe for the user
  bool validateExerciseSafety({
    required PlanItem exercise,
    required Map<String, dynamic> userContext,
  }) {
    final injuries = userContext['injuries'] as List? ?? [];
    final limitations = userContext['limitations'] as List? ?? [];
    final healthConditions = userContext['health_conditions'] as List? ?? [];
    
    final exerciseName = exercise.name.toLowerCase();
    final exerciseDetails = exercise.details.toLowerCase();
    
    // Check for knee injuries
    if (injuries.contains('knee') || limitations.contains('no_knee_flexion')) {
      if (exerciseName.contains('przysiad') ||
          exerciseName.contains('squat') ||
          exerciseName.contains('lunge') ||
          exerciseName.contains('wykrok')) {
        debugPrint('❌ Exercise rejected: knee injury conflict');
        return false;
      }
    }
    
    // Check for shoulder injuries
    if (injuries.contains('shoulder') || limitations.contains('no_overhead')) {
      if (exerciseName.contains('overhead') ||
          exerciseName.contains('nad głową') ||
          exerciseName.contains('press') ||
          exerciseName.contains('wyciskanie')) {
        debugPrint('❌ Exercise rejected: shoulder injury conflict');
        return false;
      }
    }
    
    // Check for back injuries
    if (injuries.contains('lower_back') || injuries.contains('back')) {
      if (exerciseName.contains('martwy ciąg') ||
          exerciseName.contains('deadlift') ||
          exerciseName.contains('good morning')) {
        debugPrint('❌ Exercise rejected: back injury conflict');
        return false;
      }
    }
    
    // Check for diabetes - avoid very intense cardio
    if (healthConditions.contains('diabetes')) {
      if (exerciseDetails.contains('hiit') ||
          exerciseDetails.contains('sprint')) {
        debugPrint('⚠️ Exercise flagged: may require blood sugar monitoring');
        // Don't reject, just flag for user awareness
      }
    }
    
    debugPrint('✅ Exercise passed safety validation');
    return true;
  }
  
  /// Calculates how well an exercise matches user context (0.0 - 1.0)
  double calculateMatchScore({
    required PlanItem exercise,
    required Map<String, dynamic> userContext,
  }) {
    double score = 0.0;
    
    final fitnessLevel = userContext['fitness_level'] as String? ?? 'beginner';
    final equipment = userContext['equipment'] as String? ?? 'bodyweight';
    final goals = userContext['goals'] as List? ?? [];
    
    // Equipment match
    if (equipment == 'full_gym') {
      score += 0.3; // All exercises available
    } else if (equipment == 'home_basic' && 
               !exercise.name.toLowerCase().contains('sztanga')) {
      score += 0.2;
    } else if (equipment == 'bodyweight' &&
               exercise.details.toLowerCase().contains('ciężar własny')) {
      score += 0.3;
    }
    
    // Fitness level match
    if (fitnessLevel == 'beginner' && exercise.details.contains('3')) {
      score += 0.2; // Fewer sets = better for beginners
    } else if (fitnessLevel == 'advanced' && exercise.details.contains('5')) {
      score += 0.2; // More sets = better for advanced
    } else {
      score += 0.1;
    }
    
    // Goal alignment
    if (goals.contains('muscle_gain') || goals.contains('strength')) {
      if (exercise.details.contains('8-12') || exercise.details.contains('5-8')) {
        score += 0.3; // Hypertrophy/strength rep ranges
      }
    } else if (goals.contains('fat_loss') || goals.contains('endurance')) {
      if (exercise.details.contains('15-20') || exercise.details.contains('min')) {
        score += 0.3; // Endurance rep ranges
      }
    }
    
    // Always add some base score
    score += 0.2;
    
    return score.clamp(0.0, 1.0);
  }
}
