import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/models/models.dart';

/// Provider for managing user profile and settings
class UserProvider with ChangeNotifier {
  UserProfile? _profile;
  String _currentLanguage = 'pl'; // Default Polish
  String _currentThemeMode = 'light'; // Default Light
  int? _age;
  double? _weight;
  double? _height;
  String? _nickname;
  String? _avatarUrl;
  bool _surveyCompleted = false;

  // Notification Settings
  bool _notifyApp = true;
  bool _notifyPlan = false;
  bool _notifyDiet = true;
  bool _notifyWater = true;
  
  UserProfile? get profile => _profile;
  String get currentLanguage => _currentLanguage;
  bool get isDarkMode => _currentThemeMode == 'dark';
  ThemeMode get themeMode => _currentThemeMode == 'dark' ? ThemeMode.dark : ThemeMode.light;
  int? get age => _age;
  double? get weight => _weight;
  double? get height => _height;
  String? get nickname => _nickname;
  String? get avatarUrl => _avatarUrl;

  // Notification Getters
  bool get notifyApp => _notifyApp;
  bool get notifyPlan => _notifyPlan;
  bool get notifyDiet => _notifyDiet;
  bool get notifyWater => _notifyWater;
  
  // Stretch fields (loaded directly from prefs)
  int _streakCurrent = 0;
  int _streakBest = 0;
  
  int get streakCurrent => _streakCurrent;
  int get streakBest => _streakBest;
  
  bool get hasCompletedInitialSurvey => _surveyCompleted;
  
  /// Load user data from storage
  Future<void> loadUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      _age = prefs.getInt('user_age');
      _weight = prefs.getDouble('user_weight');
      _height = prefs.getDouble('user_height');
      _nickname = prefs.getString('user_nickname');
      _avatarUrl = prefs.getString('user_avatar_url');
      _avatarUrl = prefs.getString('user_avatar_url');
      _currentLanguage = prefs.getString('user_language') ?? 'pl';
      _currentThemeMode = prefs.getString('user_theme') ?? 'light';
      _surveyCompleted = prefs.getBool('survey_completed') ?? false;

      // Load Notifications
      _notifyApp = prefs.getBool('notify_app') ?? true;
      _notifyPlan = prefs.getBool('notify_plan') ?? false;
      _notifyDiet = prefs.getBool('notify_diet') ?? true;
      _notifyWater = prefs.getBool('notify_water') ?? true;
      
      _streakCurrent = prefs.getInt('streak_current') ?? 0;
      _streakBest = prefs.getInt('streak_best') ?? 0;
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading user data: $e');
    }
  }
  
  /// Save initial survey data (age, weight, height)
  Future<void> saveInitialSurvey({
    required int age,
    required double weight,
    required double height,
  }) async {
    _age = age;
    _weight = weight;
    _height = height;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('user_age', age);
    await prefs.setDouble('user_weight', weight);
    await prefs.setDouble('user_height', height);
    
    notifyListeners();
  }
  
  /// Mark initial survey as completed
  Future<void> markSurveyCompleted() async {
    _surveyCompleted = true;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('survey_completed', true);
    
    notifyListeners();
  }
  
  /// Update nickname
  Future<void> updateNickname(String nickname) async {
    _nickname = nickname;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_nickname', nickname);
    
    notifyListeners();
  }
  
  /// Update avatar URL
  Future<void> updateAvatarUrl(String url) async {
    _avatarUrl = url;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_avatar_url', url);
    
    notifyListeners();
  }
  
  /// Update weight
  Future<void> updateWeight(double weight) async {
    _weight = weight;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('user_weight', weight);
    
    notifyListeners();
  }
  
  /// Update height
  Future<void> updateHeight(double height) async {
    _height = height;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('user_height', height);
    
    notifyListeners();
  }
  
  /// Update age
  Future<void> updateAge(int age) async {
    _age = age;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('user_age', age);
    
    notifyListeners();
  }

  /// Change language
  Future<void> changeLanguage(String languageCode) async {
    _currentLanguage = languageCode;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_language', languageCode);
    
    notifyListeners();
  }

  /// Toggle Theme
  Future<void> toggleTheme(bool isDark) async {
    _currentThemeMode = isDark ? 'dark' : 'light';
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_theme', _currentThemeMode);
    
    notifyListeners();
  }

  /// Update Notification Settings
  Future<void> updateNotification({
    bool? app,
    bool? plan,
    bool? diet,
    bool? water,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    
    if (app != null) {
      _notifyApp = app;
      await prefs.setBool('notify_app', app);
    }
    if (plan != null) {
      _notifyPlan = plan;
      await prefs.setBool('notify_plan', plan);
    }
    if (diet != null) {
      _notifyDiet = diet;
      await prefs.setBool('notify_diet', diet);
    }
    if (water != null) {
      _notifyWater = water;
      await prefs.setBool('notify_water', water);
    }
    
    notifyListeners();
  }
  
  /// Set user profile (for Firebase Auth)
  void setProfile(UserProfile profile) {
    _profile = profile;
    notifyListeners();
  }
  
  /// Clear all user data (logout)
  Future<void> clearUserData() async {
    _profile = null;
    _age = null;
    _weight = null;
    _height = null;
    _nickname = null;
    _avatarUrl = null;
    _currentLanguage = 'pl';
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    
    notifyListeners();
  }
  
  /// Increment streak
  Future<void> incrementStreak() async {
    final prefs = await SharedPreferences.getInstance();
    final lastDateStr = prefs.getString('last_workout_date');
    final now = DateTime.now();
    
    // Check if already incremented today
    if (lastDateStr != null) {
      final lastDate = DateTime.parse(lastDateStr);
      if (lastDate.year == now.year && 
          lastDate.month == now.month && 
          lastDate.day == now.day) {
        // Already done today, do not increment streak
        // We can still update the timestamp if we want to track exact last time
        // but for streak protection, we just return.
        return;
      }
    }
    
    // Simple logic: just increment current streak
    // In a real app, check dates (1 day diff)
    int current = prefs.getInt('streak_current') ?? 0;
    int best = prefs.getInt('streak_best') ?? 0;
    
    current++;
    if (current > best) {
      best = current;
    }
    
    await prefs.setInt('streak_current', current);
    await prefs.setInt('streak_best', best);
    
    // Also save last workout date
    await prefs.setString('last_workout_date', now.toIso8601String());
    
    // Update local state
    _streakCurrent = current;
    _streakBest = best;
    
    notifyListeners();
  }
}
