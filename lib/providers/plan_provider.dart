import 'package:flutter/foundation.dart';
import '../core/models/models.dart';
import '../services/openrouter_service.dart';
import '../services/plan_service.dart';

/// Provider for managing workout and diet plans
class PlanProvider with ChangeNotifier {
  final OpenRouterService _openRouterService = OpenRouterService();
  
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
      final savedPlan = await PlanService.getCurrentPlan();
      if (savedPlan != null) {
        if (savedPlan.mode == CreatorMode.WORKOUT) {
          _workoutPlan = savedPlan;
        } else {
          _dietPlan = savedPlan;
        }
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading plans: $e');
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
      } else {
        _dietPlan = plan;
      }
      
      // Persist to storage
      await PlanService.savePlan(plan);
      
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
  
  /// Delete a plan
  Future<void> deletePlan(CreatorMode mode) async {
    if (mode == CreatorMode.WORKOUT) {
      _workoutPlan = null;
    } else {
      _dietPlan = null;
    }
    
    await PlanService.deleteCurrentPlan();
    notifyListeners();
  }
  
  /// Clear error message
  void clearError() {
    _generationError = null;
    notifyListeners();
  }
}
