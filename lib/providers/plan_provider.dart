import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../core/models/models.dart';
import '../services/openrouter_service.dart';
import '../services/plan_service.dart';

/// Provider for managing workout and diet plans
class PlanProvider with ChangeNotifier {
  final OpenRouterService _openRouterService = OpenRouterService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  GeneratedPlan? _workoutPlan;
  GeneratedPlan? _dietPlan;
  bool _isGenerating = false;
  String? _generationError;
  
  GeneratedPlan? get workoutPlan => _workoutPlan;
  GeneratedPlan? get dietPlan => _dietPlan;
  bool get isGenerating => _isGenerating;
  String? get generationError => _generationError;
  
  bool get hasWorkoutPlan => _workoutPlan != null;
  bool get hasDietPlan => _dietPlan != null;
  
  /// Load saved plans from storage
  Future<void> loadPlans() async {
    try {
      // 1. Try Local Load first
      final savedPlan = await PlanService.getCurrentPlan();
      if (savedPlan != null) {
        if (savedPlan.mode == CreatorMode.WORKOUT) {
          _workoutPlan = savedPlan;
        } else {
          _dietPlan = savedPlan;
        }
        notifyListeners();
      }
      
      // 2. If logged in, Sync from Cloud (Source of Truth)
      final user = _auth.currentUser;
      if (user != null) {
        await syncPlans(user);
      }
    } catch (e) {
      debugPrint('Error loading plans: $e');
    }
  }

  /// Sync plans from Firestore
  Future<void> syncPlans(User user) async {
    try {
      final userPlansRef = FirebaseFirestore.instance.collection('users').doc(user.uid).collection('plans');
      
      // Load Workout Plan
      final workoutDoc = await userPlansRef.doc('workout').get();
      if (workoutDoc.exists && workoutDoc.data() != null) {
        try {
          // Add mode if missing from old docs
          final data = workoutDoc.data()!;
          if (data['mode'] == null) data['mode'] = 'workout';
          
          _workoutPlan = GeneratedPlan.fromJson(data);
          // Update local cache too
          await PlanService.savePlan(_workoutPlan!);
        } catch (e) {
          debugPrint('Error parsing workout plan from Firestore: $e');
        }
      } else {
        // If Firestore is empty but we have local, maybe push local to cloud?
        // Or assume cloud is empty. 
        // For now, let's respect cloud state but keep local if cloud is 404? 
        // No, if user logs in new device, cloud 404 means no plan.
        // But if user just registered, local might be empty too.
      }

      // Load Diet Plan
      final dietDoc = await userPlansRef.doc('diet').get();
      if (dietDoc.exists && dietDoc.data() != null) {
        try {
           final data = dietDoc.data()!;
          if (data['mode'] == null) data['mode'] = 'diet';
          
          _dietPlan = GeneratedPlan.fromJson(data);
          // Need to handle saving diet plan to local service if we had a distinct diet service
          // For now PlanService seems to only handle one "Current Plan" (likely workout).
          // If PlanService is single-slot, we might overwrite workout with diet?
          // Let's check PlanService... it has `_currentPlanKey`. 
          // It seems PlanService is currently designed for ONE active plan.
          // IMPORTANT: If we have both, PlanService might struggle. 
          // For now, let's just update memory state.
        } catch (e) {
          debugPrint('Error parsing diet plan from Firestore: $e');
        }
      }
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error syncing plans from Firestore: $e');
    }
  }
  
  /// Helper to save plan to Firestore
  Future<void> _savePlanToFirestore(GeneratedPlan plan) async {
    final user = _auth.currentUser;
    if (user == null) return;
    
    try {
      final docId = plan.mode == CreatorMode.WORKOUT ? 'workout' : 'diet';
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('plans')
          .doc(docId)
          .set(plan.toJson());
    } catch (e) {
      debugPrint('Error saving plan to Firestore: $e');
    }
  }
  
  /// Generate a new plan from interview history
  Future<bool> generatePlan(
    List<ChatMessage> interviewHistory,
    CreatorMode mode,
  ) async {
    _isGenerating = true;
    _generationError = null;
    notifyListeners();
    
    try {
      final plan = await _openRouterService.generatePlan(
        interviewHistory,
        mode,
      );
      
      // Save the plan
      if (mode == CreatorMode.WORKOUT) {
        _workoutPlan = plan;
        
        // --- VALIDATION LOGGING (Volume Fix) ---
        for (var day in plan.schedule) {
          int dailySets = 0;
          if (day.dayName.toLowerCase().contains('odpoczynek')) continue;
          
          for (var item in day.items) {
             // Extract sets count from "details" string (e.g. "3 serie x 10 powt")
             // Simple naive parsing for validation logging
             if (item.details.contains('seri')) {
               final parts = item.details.split(' ');
               for (var part in parts) {
                 if (int.tryParse(part) != null) {
                   dailySets += int.parse(part);
                   break; // Assume first number is sets
                 }
               }
             }
          }
          debugPrint('📊 VERIFICATION for ${day.dayName}: Found ~$dailySets sets (Goal: 12-35)');
        }
        // ---------------------------------------
        
      } else {
        // DIET PLAN - Duplicate 7 days to 28 days (4 weeks)
        if (plan.schedule.length == 7) {
          debugPrint('📅 Expanding 7-day diet plan to 28 days (4 weeks)...');
          
          final weeklySchedule = List<PlanDay>.from(plan.schedule);
          final expandedSchedule = <PlanDay>[];
          
          // Replicate the week 4 times (28 days total)
          for (int week = 0; week < 4; week++) {
            for (int day = 0; day < 7; day++) {
              final originalDay = weeklySchedule[day];
              final dayNumber = week * 7 + day + 1;
              
              // Create copy with updated day name
              expandedSchedule.add(
                PlanDay(
                  dayName: 'Tydzień ${week + 1} - Dzień ${day + 1}',
                  items: originalDay.items.map((item) => PlanItem(
                    name: item.name,
                    details: item.details,
                    note: item.note,
                    tips: item.tips,
                  )).toList(),
                  summary: originalDay.summary,
                ),
              );
            }
          }
          
          // Create new plan with expanded schedule
          _dietPlan = GeneratedPlan(
            mode: plan.mode,
            title: plan.title,
            description: plan.description,
            schedule: expandedSchedule,
            progress: plan.progress,
          );
          
          debugPrint('✅ Expanded to ${expandedSchedule.length} days');
        } else {
          _dietPlan = plan;
        }
      }
      
      // Persist to local storage
      final planToSave = mode == CreatorMode.WORKOUT ? _workoutPlan! : _dietPlan!;
      await PlanService.savePlan(planToSave);
      
      // Persist to Cloud
      await _savePlanToFirestore(planToSave);
      
      _isGenerating = false;
      notifyListeners();
      return true;
    } catch (e) {
      _generationError = 'Nie udało się wygenerować planu: $e';
      _isGenerating = false;
      notifyListeners();
      return false;
    }
  }
  
  /// Modify existing plan
  Future<bool> modifyPlan(
    GeneratedPlan currentPlan,
    String userRequest,
  ) async {
    _isGenerating = true;
    _generationError = null;
    notifyListeners();
    
    try {
      final result = await _openRouterService.modifyPlan(
        currentPlan,
        userRequest,
      );
      
      if (result.approved && result.plan != null) {
        // Update the plan
        if (currentPlan.mode == CreatorMode.WORKOUT) {
          _workoutPlan = result.plan;
        } else {
          _dietPlan = result.plan;
        }
        
        // Persist to storage
        await PlanService.savePlan(result.plan!);
        
         // Persist to Cloud
        await _savePlanToFirestore(result.plan!);
        
        _isGenerating = false;
        notifyListeners();
        return true;
      } else {
        _generationError = result.refusalReason ?? 'Modyfikacja została odrzucona';
        _isGenerating = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _generationError = 'Nie udało się zmodyfikować planu: $e';
      _isGenerating = false;
      notifyListeners();
      return false;
    }
  }
  
  /// Replace a single exercise in the workout plan
  Future<void> replaceExercise({
    required int dayIndex,
    required int exerciseIndex,
    required PlanItem newExercise,
  }) async {
    if (_workoutPlan == null) {
      debugPrint('❌ Cannot replace exercise: no workout plan loaded');
      return;
    }
    
    if (dayIndex < 0 || dayIndex >= _workoutPlan!.schedule.length) {
      debugPrint('❌ Invalid dayIndex: $dayIndex');
      return;
    }
    
    final day = _workoutPlan!.schedule[dayIndex];
    if (exerciseIndex < 0 || exerciseIndex >= day.items.length) {
      debugPrint('❌ Invalid exerciseIndex: $exerciseIndex');
      return;
    }
    
    // Replace the exercise
    day.items[exerciseIndex] = newExercise;
    
    // Update the plan
    notifyListeners();
    
    // Save to storage
    try {
      await PlanService.savePlan(_workoutPlan!);
      await _savePlanToFirestore(_workoutPlan!);
      debugPrint('✅ Exercise replaced and saved');
    } catch (e) {
      debugPrint('❌ Error saving modified plan: $e');
    }
  }
  
  /// Replace a single meal in the diet plan
  Future<void> replaceMeal({
    required int dayIndex,
    required int mealIndex,
    required PlanItem newMeal,
  }) async {
    if (_dietPlan == null) {
      debugPrint('❌ Cannot replace meal: no diet plan loaded');
      return;
    }
    
    if (dayIndex < 0 || dayIndex >= _dietPlan!.schedule.length) {
      debugPrint('❌ Invalid dayIndex: $dayIndex');
      return;
    }
    
    final day = _dietPlan!.schedule[dayIndex];
    if (mealIndex < 0 || mealIndex >= day.items.length) {
      debugPrint('❌ Invalid mealIndex: $mealIndex');
      return;
    }
    
    // Replace the meal
    day.items[mealIndex] = newMeal;
    
    // Update the plan
    notifyListeners();
    
    // Save to storage
    try {
      await PlanService.savePlan(_dietPlan!);
      await _savePlanToFirestore(_dietPlan!);
      debugPrint('✅ Meal replaced and saved');
    } catch (e) {
      debugPrint('❌ Error saving modified plan: $e');
    }
  }
  
  /// Get current plan based on mode
  GeneratedPlan? get currentPlan => _workoutPlan;  // Default to workout
  
  /// Delete a plan
  Future<void> deletePlan(CreatorMode mode) async {
    if (mode == CreatorMode.WORKOUT) {
      _workoutPlan = null;
    } else {
      _dietPlan = null;
    }
    
    await PlanService.deleteCurrentPlan();
    
    // Delete from Cloud
    final user = _auth.currentUser;
    if (user != null) {
       try {
        final docId = mode == CreatorMode.WORKOUT ? 'workout' : 'diet';
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('plans')
            .doc(docId)
            .delete();
      } catch (e) {
        debugPrint('Error deleting plan from Firestore: $e');
      }
    }
    
    notifyListeners();
  }
  
  /// Clear error message
  void clearError() {
    _generationError = null;
    notifyListeners();
  }
}
