import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/models/models.dart';

/// Service for managing workout plan persistence using SharedPreferences
class PlanService {
  static const String _currentPlanKey = 'current_workout_plan';
  static const String _planHistoryKey = 'plan_history';

  /// Save a generated plan as the current active plan
  static Future<void> savePlan(GeneratedPlan plan) async {
    final prefs = await SharedPreferences.getInstance();
    
    // Convert plan to JSON
    final planJson = jsonEncode(plan.toJson());
    
    // Save as current plan
    await prefs.setString(_currentPlanKey, planJson);
    
    // Also add to history (for future use)
    final history = await _getPlanHistory();
    history.add(plan);
    
    // Keep only last 5 plans in history
    if (history.length > 5) {
      history.removeAt(0);
    }
    
    final historyJson = jsonEncode(history.map((p) => p.toJson()).toList());
    await prefs.setString(_planHistoryKey, historyJson);
  }

  /// Get the current active workout plan
  static Future<GeneratedPlan?> getCurrentPlan() async {
    final prefs = await SharedPreferences.getInstance();
    final planJson = prefs.getString(_currentPlanKey);
    
    if (planJson == null) {
      return null;
    }
    
    try {
      final planMap = jsonDecode(planJson) as Map<String, dynamic>;
      return GeneratedPlan.fromJson(planMap);
    } catch (e) {
      print('Error loading plan: $e');
      return null;
    }
  }

  /// Get all saved plans from history
  static Future<List<GeneratedPlan>> _getPlanHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final historyJson = prefs.getString(_planHistoryKey);
    
    if (historyJson == null) {
      return [];
    }
    
    try {
      final historyList = jsonDecode(historyJson) as List<dynamic>;
      return historyList
          .map((json) => GeneratedPlan.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error loading plan history: $e');
      return [];
    }
  }

  /// Delete the current plan
  static Future<void> deleteCurrentPlan() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_currentPlanKey);
  }

  /// Clear all saved plans
  static Future<void> clearAllPlans() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_currentPlanKey);
    await prefs.remove(_planHistoryKey);
  }

  /// Check if a plan exists
  static Future<bool> hasPlan() async {
    final plan = await getCurrentPlan();
    return plan != null;
  }
}
