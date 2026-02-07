import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/models/models.dart';
import '../models/subscription_plan.dart';
import '../models/subscription_tier.dart';
import '../services/notification_service.dart';
import '../services/achievement_service.dart';
import '../services/subscription_service.dart';

/// Provider for managing user profile and settings
class UserProvider with ChangeNotifier {
  UserProfile? _profile;
  String _currentLanguage = 'pl'; // Default Polish
  String _preferredCurrency = 'PLN'; // Default Polish Zloty
  // ...
  bool _isPremium = false;
  final SubscriptionService _subscriptionService = SubscriptionService();
  String _currentThemeMode = 'light'; // Default Light
  int? _age;
  double? _weight;
  double? _height;
  String? _nickname;
  String? _avatarUrl;
  String? _gender; // 'male', 'female', 'other'
  bool _surveyCompleted = false;
  
  // Subscription
  SubscriptionTier _subscriptionTier = SubscriptionTier.free;
  DateTime? _subscriptionExpiryDate;

  // Notification Settings
  bool _notifyApp = true;
  bool _notifyPlan = false;
  bool _notifyDiet = true;
  bool _notifyWater = true;
  
  UserProfile? get profile => _profile;
  String get currentLanguage => _currentLanguage;
  String get preferredCurrency => _preferredCurrency;
  bool get isDarkMode => _currentThemeMode == 'dark';
  ThemeMode get themeMode => _currentThemeMode == 'dark' ? ThemeMode.dark : ThemeMode.light;
  int? get age => _age;
  double? get weight => _weight;
  double? get height => _height;
  String? get nickname => _nickname;
  String? get avatarUrl => _avatarUrl;
  String? get gender => _gender;
  
  // Subscription Getters
  SubscriptionTier get subscriptionTier => _subscriptionTier;
  DateTime? get subscriptionExpiryDate => _subscriptionExpiryDate;
  bool get isPremium => _isPremium;

  // Notification Getters
  bool get notifyApp => _notifyApp;
  bool get notifyPlan => _notifyPlan;
  bool get notifyDiet => _notifyDiet;
  bool get notifyWater => _notifyWater;
  
  // Stretch fields (loaded directly from prefs)
  int _streakCurrent = 0;
  int _streakBest = 0;
  int _totalWorkouts = 0;
  List<Achievement> _achievements = [];
  
  int get streakCurrent => _streakCurrent;
  int get streakBest => _streakBest;
  int get totalWorkouts => _totalWorkouts;
  List<Achievement> get achievements => _achievements;
  
  // Goal Timeline fields (3.1 - Fitify feature)
  String? _fitnessGoal; // "lose_weight", "build_muscle", "get_fit"
  double? _goalWeight; // Target weight (if applicable)
  DateTime? _goalDeadline; // User-set or AI-calculated deadline
  DateTime? _goalStartDate; // When user started
  
  String? get fitnessGoal => _fitnessGoal;
  double? get goalWeight => _goalWeight;
  DateTime? get goalDeadline => _goalDeadline;
  DateTime? get goalStartDate => _goalStartDate;
  
  // Calculated goal progress
  int? get daysRemainingToGoal {
    if (_goalDeadline == null) return null;
    final remaining = _goalDeadline!.difference(DateTime.now()).inDays;
    return remaining < 0 ? 0 : remaining;
  }
  
  double? get goalProgressPercent {
    if (_goalStartDate == null || _goalDeadline == null) return null;
    final totalDays = _goalDeadline!.difference(_goalStartDate!).inDays;
    if (totalDays <= 0) return 1.0;
    final daysPassed = DateTime.now().difference(_goalStartDate!).inDays;
    return (daysPassed / totalDays).clamp(0.0, 1.0);
  }

  // Method to update goal (for 3.1 Goal Timeline)
  Future<void> updateGoal({
    String? goal,
    double? targetWeight,
    DateTime? deadline,
  }) async {
    if (goal != null) _fitnessGoal = goal;
    if (targetWeight != null) _goalWeight = targetWeight;
    if (deadline != null) {
      _goalDeadline = deadline;
      _goalStartDate ??= DateTime.now(); // Set start if first time
    }
    
    // Save to Firestore
    await _updateFirestore({
      'fitnessGoal': _fitnessGoal,
      'goalWeight': _goalWeight,
      'goalDeadline': _goalDeadline?.toIso8601String(),
      'goalStartDate': _goalStartDate?.toIso8601String(),
    });
    
    notifyListeners();
  }
  
  // Initial Survey Methods
  bool get hasCompletedInitialSurvey => _surveyCompleted;
  
  Future<void> updateGender(String gender) async {
    _gender = gender;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('gender', gender);
    
    // Save to Firestore if logged in
    await _updateFirestore({'gender': gender});
    
    notifyListeners();
  }
  
  Future<void> saveInitialSurvey({
    required int age,
    required double weight,
    required double height,
  }) async {
    _age = age;
    _weight = weight;
    _height = height;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('age', age);
    await prefs.setDouble('weight', weight);
    await prefs.setDouble('height', height);
    
    // Save to Firestore if logged in
    await _updateFirestore({
      'age': age,
      'weight': weight,
      'height': height,
    });
    
    notifyListeners();
  }
  
  Future<void> markSurveyCompleted() async {
    _surveyCompleted = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('survey_completed', true);
    
    // Save to Firestore if logged in
    await _updateFirestore({'survey_completed': true});
    
    notifyListeners();
  }

  // Firebase Auth
  final FirebaseAuth _auth = FirebaseAuth.instance;
  User? _firebaseUser;
  
  User? get firebaseUser => _firebaseUser;
  bool get isLoggedIn => _firebaseUser != null;
  
  /// Load user data from storage
  Future<void> loadUserData() async {
    try {
      initAuthListener(); // Start listening to Firebase Auth
      
      final prefs = await SharedPreferences.getInstance();
      
      _currentLanguage = prefs.getString('language') ?? 'pl';
      _preferredCurrency = prefs.getString('user_currency') ?? 'PLN';
      _currentThemeMode = prefs.getString('theme') ?? 'light';
      _age = prefs.getInt('age');
      _weight = prefs.getDouble('weight');
      _height = prefs.getDouble('height');
      _nickname = prefs.getString('nickname');
      _avatarUrl = prefs.getString('avatar_url');
      _gender = prefs.getString('gender'); // Load gender
      _surveyCompleted = prefs.getBool('survey_completed') ?? false;
      
      // Load Streak
      _streakCurrent = prefs.getInt('streak_current') ?? 0;
      _streakBest = prefs.getInt('streak_best') ?? 0;
      
      // Load Total Workouts and Achievements
      _totalWorkouts = prefs.getInt('total_workouts') ?? 0;
      final achievementsJson = prefs.getString('achievements');
      if (achievementsJson != null) {
        try {
          final List<dynamic> decoded = jsonDecode(achievementsJson);
          _achievements = decoded.map((a) => Achievement.fromJson(a)).toList();
        } catch (e) {
          debugPrint('Error loading achievements: $e');
          _achievements = [];
        }
      }
      
      // Load Subscription Data
      final tierString = prefs.getString('subscription_tier');
      _subscriptionTier = tierString != null 
          ? SubscriptionTier.values.firstWhere(
              (e) => e.toString() == tierString,
              orElse: () => SubscriptionTier.free,
            )
          : SubscriptionTier.free;
      final expiryString = prefs.getString('subscription_expiry');
      if (expiryString != null) {
        _subscriptionExpiryDate = DateTime.parse(expiryString);
      }
      
      // Notification Settings
      _notifyApp = prefs.getBool('notify_app') ?? true;
      _notifyPlan = prefs.getBool('notify_plan') ?? false;
      _notifyDiet = prefs.getBool('notify_diet') ?? true;
      _notifyWater = prefs.getBool('notify_water') ?? true;
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading user data: $e');
    }
  }
  
  /// Listen to Auth State Changes
  void initAuthListener() {
    _auth.authStateChanges().listen((User? user) async {
      _firebaseUser = user;
      
      // If user just logged in, restore their profile data from Firebase
      if (user != null) {
        debugPrint('🔵 Auth state changed: User logged in - ${user.email}');
        
        final prefs = await SharedPreferences.getInstance();
        
        // Restore nickname from Firebase displayName
        if (user.displayName != null && user.displayName!.isNotEmpty) {
           _nickname = user.displayName;
           await prefs.setString('user_nickname', user.displayName!);
        }
        
        // Restore avatar from Firebase photoURL
        if (user.photoURL != null && user.photoURL!.isNotEmpty) {
            _avatarUrl = user.photoURL;
            await prefs.setString('user_avatar_url', user.photoURL!);
        }

        // SYNC FROM FIRESTORE
        await syncUserProfile(user);

      } else {
        debugPrint('🔵 Auth state changed: User logged out');
      }
      
      notifyListeners();
    });
  }

  /// Sync user profile from Firestore (public to be callable from LoginScreen)
  Future<void> syncUserProfile(User user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userDocRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
      final doc = await userDocRef.get();
      
      if (doc.exists) {
        final data = doc.data();
        if (data != null) {
          if (data['age'] != null) {
             final a = data['age'];
             _age = a is int ? a : (a as num).toInt();
            await prefs.setInt('user_age', _age!);
          }
          
          if (data['weight'] != null) {
            _weight = (data['weight'] as num).toDouble();
            await prefs.setDouble('user_weight', _weight!);
          } else {
            // RECOVERY: Try to fetch latest weight from history if profile weight is missing
            try {
              final historyUtil = await userDocRef
                  .collection('weight_history')
                  .orderBy('date', descending: true)
                  .limit(1)
                  .get();
                  
              if (historyUtil.docs.isNotEmpty) {
                final latest = historyUtil.docs.first.data();
                if (latest['value'] != null) {
                   _weight = (latest['value'] as num).toDouble();
                   await prefs.setDouble('user_weight', _weight!);
                   debugPrint('🟢 Recovered weight from history: $_weight');
                   // Save back to profile
                   await _updateFirestore({'weight': _weight});
                }
              }
            } catch (e) {
              debugPrint('⚠️ Failed to recover weight from history: $e');
            }
          }

          if (data['height'] != null) {
            _height = (data['height'] as num).toDouble();
            await prefs.setDouble('user_height', _height!);
          }
           if (data['nickname'] != null) {
            _nickname = data['nickname'];
            await prefs.setString('user_nickname', _nickname!);
          }
          
          // Load Goal Timeline data (Feature 3.1)
          if (data['fitnessGoal'] != null) {
            _fitnessGoal = data['fitnessGoal'];
          }
          if (data['goalWeight'] != null) {
            _goalWeight = (data['goalWeight'] as num).toDouble();
          }
          if (data['goalDeadline'] != null) {
            try {
              _goalDeadline = DateTime.parse(data['goalDeadline']);
            } catch (e) {
              debugPrint('Error parsing goalDeadline: $e');
            }
          }
          if (data['goalStartDate'] != null) {
            try {
              _goalStartDate = DateTime.parse(data['goalStartDate']);
            } catch (e) {
              debugPrint('Error parsing goalStartDate: $e');
            }
          }
          
          // Load Gender (NEW!)
          if (data['gender'] != null) {
            _gender = data['gender'];
            await prefs.setString('gender', _gender!);
          }
          
          // Load Avatar URL (NEW!)
          if (data['avatarUrl'] != null) {
            _avatarUrl = data['avatarUrl'];
            await prefs.setString('avatar_url', _avatarUrl!);
          }
          
          // Load Survey Completed flag (NEW!)
          if (data['survey_completed'] != null || data['surveyCompleted'] != null) {
            _surveyCompleted = data['survey_completed'] ?? data['surveyCompleted'] ?? false;
            await prefs.setBool('survey_completed', _surveyCompleted);
          }
          
          // If we have these 3, survey is completed
          if (_age != null && _weight != null && _height != null) {
            _surveyCompleted = true;
            await prefs.setBool('survey_completed', true);
          }
        }
      } else {
        // Doc doesn't exist -> Survey definitely not completed
        // But double check shared prefs, maybe we are just syncing mid-session?
        // Actually this is sync from source of truth.
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error syncing profile from Firestore: $e');
    }
  }

  /// Check RevenueCat premium status
  Future<void> refreshPremiumStatus() async {
    await _subscriptionService.initialize();
    _isPremium = await _subscriptionService.checkPremiumStatus();
    
    // Update local subscription tier (for backward compatibility if needed)
    if (_isPremium) {
      _subscriptionTier = SubscriptionTier.pro; // Map to your pro tier
    } else {
      _subscriptionTier = SubscriptionTier.free;
    }
    
    debugPrint('💎 Premium Status Check: $_isPremium');
    notifyListeners();
  }

  /// Restore purchases from RevenueCat
  Future<bool> restorePurchases() async {
    try {
      await _subscriptionService.initialize();
      final success = await _subscriptionService.restorePurchases();
      
      if (success) {
        await refreshPremiumStatus();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error restoring purchases: $e');
      return false;
    }
  }

  // FEATURE GATE HELPERS
  
  /// Check if user has access to AI generation
  bool canUseAIGeneration() {
    return _subscriptionTier != SubscriptionTier.free || _isPremium;
  }

  /// Check if user has AI generations remaining this month
  bool hasAIGenerationsRemaining(int usedThisMonth) {
    final limit = _subscriptionTier.aiGenerationsPerMonth;
    if (limit == -1) return true; // Unlimited
    return usedThisMonth < limit;
  }

  /// Get remaining AI generations for this month
  int getRemainingGenerations(int usedThisMonth) {
    final limit = _subscriptionTier.aiGenerationsPerMonth;
    if (limit == -1) return -1; // Unlimited
    final remaining = limit - usedThisMonth;
    return remaining > 0 ? remaining : 0;
  }

  /// Check if user can access advanced analytics
  bool get canAccessAdvancedAnalytics => 
      _subscriptionTier.hasAdvancedAnalytics || _isPremium;

  /// Check if user has priority support
  bool get hasPrioritySupport => 
      _subscriptionTier.hasPrioritySupport || _isPremium;

  /// Check if user has ad-free experience
  bool get isAdFree => 
      _subscriptionTier.hasNoAds || _isPremium;

  /// Check if user can use meal replacements
  bool get canUseMealReplacements => 
      _subscriptionTier.hasMealReplacements || _isPremium;

  /// Check if user can access full 28-day diet plans
  bool get canAccessFullDietPlans => 
      _subscriptionTier.hasFullDietPlans || _isPremium;

  /// Helper to update Firestore user document
  Future<void> _updateFirestore(Map<String, dynamic> data) async {
    final user = _auth.currentUser;
    if (user == null) return;
    
    try {
      // Add timeout to prevent hanging when offline
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set(data, SetOptions(merge: true))
          .timeout(
            const Duration(seconds: 5),
            onTimeout: () {
              debugPrint('⚠️ Firestore update timeout (offline?) - continuing anyway');
            },
          );
    } catch (e) {
      debugPrint('Error updating Firestore: $e');
    }
  }
  
  /// Update nickname
  Future<void> updateNickname(String nickname) async {
    _nickname = nickname;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_nickname', nickname);

    // Sync with Firebase Auth
    await _auth.currentUser?.updateDisplayName(nickname);
    
    // Sync with Firestore
    await _updateFirestore({'nickname': nickname});
    
    notifyListeners();
  }
  
  /// Update avatar URL
  Future<void> updateAvatarUrl(String url) async {
    _avatarUrl = url;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_avatar_url', url);

    // Sync with Firebase
    await _auth.currentUser?.updatePhotoURL(url);
    
    // Optionally update firestore too
    await _updateFirestore({'avatarUrl': url});
    
    notifyListeners();
  }
  
  /// Update weight
  Future<void> updateWeight(double weight) async {
    _weight = weight;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('user_weight', weight);
    
    // Sync with Firestore
    await _updateFirestore({'weight': weight});

    notifyListeners();
  }
  
  /// Update height
  Future<void> updateHeight(double height) async {
    _height = height;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('user_height', height);
    
    // Sync with Firestore
    await _updateFirestore({'height': height});

    notifyListeners();
  }
  
  /// Update age
  Future<void> updateAge(int age) async {
    _age = age;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('user_age', age);
    
    // Sync with Firestore
    await _updateFirestore({'age': age});

    notifyListeners();
  }

  /// Change language
  Future<void> changeLanguage(String languageCode) async {
    _currentLanguage = languageCode;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_language', languageCode);
    
    notifyListeners();
  }

  /// Change preferred currency
  Future<void> changeCurrency(String currencyCode) async {
    _preferredCurrency = currencyCode;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_currency', currencyCode);
    
    // Update Firestore
    await _updateFirestore({'currency': currencyCode});
    
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
      // App notifications general toggle logic if needed
    }
    if (plan != null) {
      _notifyPlan = plan;
      await prefs.setBool('notify_plan', plan);
      await NotificationService().scheduleTrainingReminder(plan);
    }
    if (diet != null) {
      _notifyDiet = diet;
      await prefs.setBool('notify_diet', diet);
      await NotificationService().scheduleDietReminders(diet);
    }
    if (water != null) {
      _notifyWater = water;
      await prefs.setBool('notify_water', water);
      await NotificationService().scheduleWaterReminders(water);
    }
    
    notifyListeners();
  }
  
  /// Schedule all user notifications based on their preferences
  /// Called automatically after login and permission grant
  Future<void> scheduleUserNotifications() async {
    debugPrint('📅 Scheduling user notifications...');
    debugPrint('   - notifyApp: $_notifyApp');
    debugPrint('   - notifyWater: $_notifyWater');
    debugPrint('   - notifyPlan: $_notifyPlan');
    debugPrint('   - notifyDiet: $_notifyDiet');
    
    final notificationService = NotificationService();
    
    // Verify NotificationService is initialized
    if (!notificationService.isInitialized) {
      debugPrint('⚠️ NotificationService not initialized - initializing now...');
      await notificationService.initialize();
    }
    
    // Schedule based on user preferences
    if (_notifyApp && _notifyWater) {
      debugPrint('💧 Scheduling water reminders...');
      await notificationService.scheduleWaterReminders(true);
    } else {
      await notificationService.scheduleWaterReminders(false);
    }
    
    if (_notifyApp && _notifyPlan) {
      debugPrint('💪 Scheduling training reminders...');
      await notificationService.scheduleTrainingReminder(true);
    } else {
      await notificationService.scheduleTrainingReminder(false);
    }
    
    if (_notifyApp && _notifyDiet) {
      debugPrint('🍽️ Scheduling diet reminders...');
      await notificationService.scheduleDietReminders(true);
    } else {
      await notificationService.scheduleDietReminders(false);
    }
    
    // Verify scheduled notifications
    await _verifyScheduledNotifications();
    
    debugPrint('✅ All user notifications scheduled successfully');
  }

  /// Verify and log currently scheduled notifications
  Future<void> _verifyScheduledNotifications() async {
    try {
      final notificationService = NotificationService();
      final pending = await notificationService.flutterLocalNotificationsPlugin.pendingNotificationRequests();
      
      debugPrint('📋 Currently scheduled notifications: ${pending.length}');
      for (var notif in pending) {
        debugPrint('   - ID: ${notif.id}, Title: ${notif.title}');
      }
    } catch (e) {
      debugPrint('⚠️ Could not verify scheduled notifications: $e');
    }
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
    _surveyCompleted = false;
    
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
        return;
      }
    }
    
    int current = prefs.getInt('streak_current') ?? 0;
    int best = prefs.getInt('streak_best') ?? 0;
    int totalWorkouts = prefs.getInt('total_workouts') ?? 0;
    
    current++;
    if (current > best) {
      best = current;
    }
    totalWorkouts++;
    
    await prefs.setInt('streak_current', current);
    await prefs.setInt('streak_best', best);
    await prefs.setInt('total_workouts', totalWorkouts);
    
    // Also save last workout date
    await prefs.setString('last_workout_date', now.toIso8601String());
    
    // Sync with Firestore (Streak)  
    await _updateFirestore({
      'streak': current,
      'bestStreak': best,
      'totalWorkouts': totalWorkouts,
      'lastWorkoutDate': now.toIso8601String(),
    });

    // Update local state
    _streakCurrent = current;
    _streakBest = best;
    _totalWorkouts = totalWorkouts;
    
    // CHECK AND UNLOCK ACHIEVEMENTS
    final achievementService = AchievementService();
    final newAchievements = achievementService.checkAndUnlockAchievements(
      currentStreak: current,
      totalWorkouts: totalWorkouts,
      currentAchievements: _achievements,
      lastWorkoutDate: lastDateStr != null ? DateTime.parse(lastDateStr) : null,
    );
    
    if (newAchievements.isNotEmpty) {
      // Merge new achievements with existing ones
      final allAchievements = [..._achievements];
      for (var newAch in newAchievements) {
        // Replace or add
        final index = allAchievements.indexWhere((a) => a.id == newAch.id);
        if (index >= 0) {
          allAchievements[index] = newAch;
        } else {
          allAchievements.add(newAch);
        }
      }
      _achievements = allAchievements;
      
      // Save to SharedPreferences
      final achievementsJson = jsonEncode(_achievements.map((a) => a.toJson()).toList());
      await prefs.setString('achievements', achievementsJson);
      
      // Sync to Firestore
      await _updateFirestore({
        'achievements': _achievements.map((a) => a.toJson()).toList(),
      });
      
      debugPrint('🎉 NEW ACHIEVEMENTS UNLOCKED: ${newAchievements.length}');
    }
    
    notifyListeners();
  }

  /// Sign In with Email & Password
  Future<void> signIn(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthError(e);
    } catch (e) {
      throw 'Wystąpił nieoczekiwany błąd logowania.';
    }
  }

  /// Sign Up with Email & Password
  Future<void> signUp(String email, String password) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(email: email, password: password);
      // Send verification email
      if (userCredential.user != null && !userCredential.user!.emailVerified) {
        await userCredential.user!.sendEmailVerification();
      }
    } on FirebaseAuthException catch (e) {
      throw _handleAuthError(e);
    } catch (e) {
      throw 'Wystąpił nieoczekiwany błąd rejestracji.';
    }
  }

  /// Sign In with Google
  Future<void> signInWithGoogle() async {
    try {
      debugPrint('🔵 UserProvider: Starting Google Sign-In');
      // For web, we need to specify the clientId and use minimal scopes
      final GoogleSignIn googleSignIn = GoogleSignIn(
        clientId: kIsWeb ? '733835310780-skijm4f6hmjcctrrb4s2hfnq052lvo2m.apps.googleusercontent.com' : null,
        scopes: ['email'],
      );
      
      debugPrint('🔵 UserProvider: Calling googleSignIn.signIn()');
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      
      if (googleUser == null) {
        debugPrint('🟡 UserProvider: User cancelled Google Sign-In');
        throw 'Anulowano logowanie przez Google.';
      }
      
      debugPrint('🔵 UserProvider: Got Google user: ${googleUser.email}');
      debugPrint('🔵 UserProvider: Getting authentication');
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      
      debugPrint('🔵 UserProvider: Creating Firebase credential');
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      
      debugPrint('🔵 UserProvider: Signing in with Firebase credential');
      final userCredential = await _auth.signInWithCredential(credential);
      debugPrint('🟢 UserProvider: Firebase sign-in successful! UID: ${userCredential.user?.uid}');
      
      // Update nickname from Google display name if available
      if (userCredential.user?.displayName != null) {
        debugPrint('🔵 UserProvider: Updating nickname to: ${userCredential.user!.displayName}');
        await updateNickname(userCredential.user!.displayName!);
      }
      
      // Update avatar from Google photo if available
      if (userCredential.user?.photoURL != null) {
        debugPrint('🔵 UserProvider: Updating avatar from Google: ${userCredential.user!.photoURL}');
        await updateAvatarUrl(userCredential.user!.photoURL!);
      } else if (googleUser.photoUrl != null) {
        // Fallback to GoogleSignInAccount photo if Firebase doesn't have it
        debugPrint('🔵 UserProvider: Updating avatar from GoogleSignInAccount: ${googleUser.photoUrl}');
        await updateAvatarUrl(googleUser.photoUrl!);
      }
      
      debugPrint('🟢 UserProvider: Google Sign-In completed successfully');
    } on FirebaseAuthException catch (e) {
      debugPrint('🔴 UserProvider: FirebaseAuthException: ${e.code} - ${e.message}');
      throw _handleAuthError(e);
    } catch (e) {
      debugPrint('🔴 UserProvider: Error during Google Sign-In: $e');
      if (e.toString().contains('popup_closed')) {
        throw 'Błąd logowania przez Google: anulowano logowanie';
      }
      throw 'Błąd logowania przez Google: $e';
    }
  }

  /// Sign In with Facebook
  Future<void> signInWithFacebook() async {
    try {
      final LoginResult result = await FacebookAuth.instance.login(
        permissions: ['public_profile'],
      );
      
      if (result.status != LoginStatus.success) {
        throw 'Anulowano logowanie przez Facebook.';
      }
      
      final OAuthCredential credential = FacebookAuthProvider.credential(result.accessToken!.tokenString);
      await _auth.signInWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthError(e);
    } catch (e) {
      throw 'Błąd logowania przez Facebook: $e';
    }
  }

  /// SECURITY METHODS

  /// Send Password Reset Email
  Future<void> sendPasswordResetEmail() async {
    if (_firebaseUser?.email == null) return;
    try {
      await _auth.sendPasswordResetEmail(email: _firebaseUser!.email!);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthError(e);
    }
  }

  /// Update Email
  Future<void> updateEmail(String newEmail) async {
    if (_firebaseUser == null) return;
    
    if (newEmail == _firebaseUser!.email) {
      throw 'Ten adres email jest już aktualny.';
    }

    try {
      await _firebaseUser!.verifyBeforeUpdateEmail(newEmail);
      await _firebaseUser!.reload();
      _firebaseUser = _auth.currentUser;
      notifyListeners();
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        throw 'Ze względów bezpieczeństwa ta akcja wymaga ponownego zalogowania. Wyloguj się i zaloguj ponownie.';
      }
      throw _handleAuthError(e);
    }
  }
  
  /// Send Verification Email
  Future<void> sendVerificationEmail() async {
    final user = _auth.currentUser;
    if (user != null && !user.emailVerified) {
      await user.sendEmailVerification();
    }
  }

  /// Check if email is verified
  bool get isEmailVerified => _auth.currentUser?.emailVerified ?? false;

  /// Delete Account
  Future<void> deleteAccount() async {
    if (_firebaseUser == null) return;
    
    final uid = _firebaseUser!.uid;
    
    // 1. Try Delete Firestore data (best effort, allow timeout)
    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).delete().timeout(const Duration(seconds: 5));
    } catch (e) {
      debugPrint('Warning: Firestore data delete failed or timed out: $e');
    }

    // 2. Delete Auth Account
    try {
      await _firebaseUser!.delete();
      await clearUserData();
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        throw 'Ze względów bezpieczeństwa usuwanie konta wymaga ponownego zalogowania. Wyloguj się i zaloguj ponownie.';
      }
      throw _handleAuthError(e);
    } catch (e) {
       throw 'Wystąpił nieoczekiwany błąd podczas usuwania konta: $e';
    }
  }
  
  /// Upgrade Subscription
  Future<void> upgradeSubscription(SubscriptionTier newTier) async {
    try {
      _subscriptionTier = newTier;
      
      // Set expiry date based on tier
      if (newTier != SubscriptionTier.free) {
        _subscriptionExpiryDate = DateTime.now().add(const Duration(days: 30));
      } else {
        _subscriptionExpiryDate = null;
      }
      
      // Save to SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('subscription_tier', newTier.index);
      if (_subscriptionExpiryDate != null) {
        await prefs.setInt('subscription_expiry', _subscriptionExpiryDate!.millisecondsSinceEpoch);
      } else {
        await prefs.remove('subscription_expiry');
      }
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error upgrading subscription: $e');
      throw 'Błąd zmiany subskrypcji: $e';
    }
  }
  
  /// Cancel Subscription (downgrade to free)
  Future<void> cancelSubscription() async {
    await upgradeSubscription(SubscriptionTier.free);
  }

  /// Sign Out
  Future<void> signOut() async {
    try {
      await _auth.signOut();
      
      if (kIsWeb) {
        try {
          final googleSignIn = GoogleSignIn(
            clientId: '733835310780-skijm4f6hmjcctrrb4s2hfnq052lvo2m.apps.googleusercontent.com',
          );
          await googleSignIn.signOut();
        } catch (e) {
          debugPrint('Google sign out error: $e');
        }
      } else {
        await GoogleSignIn().signOut();
      }
      
      await FacebookAuth.instance.logOut();
      await clearUserData();
    } catch (e) {
      debugPrint('Sign out error: $e');
      await clearUserData();
    }
  }

  /// Re-authenticate with Password
  Future<void> reauthenticateWithPassword(String password) async {
    if (_firebaseUser?.email == null) return;
    try {
      final credential = EmailAuthProvider.credential(email: _firebaseUser!.email!, password: password);
      await _firebaseUser!.reauthenticateWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthError(e);
    }
  }

  /// Re-authenticate with Google
  Future<void> reauthenticateWithGoogle() async {
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn(
        clientId: kIsWeb ? '733835310780-skijm4f6hmjcctrrb4s2hfnq052lvo2m.apps.googleusercontent.com' : null,
        scopes: ['email'],
      );
      
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser == null) throw 'Anulowano weryfikację Google.';
      
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      
      await _firebaseUser!.reauthenticateWithCredential(credential);
    } catch (e) {
      throw 'Błąd weryfikacji Google: $e';
    }
  }

  /// Re-authenticate with Facebook
  Future<void> reauthenticateWithFacebook() async {
    try {
      final LoginResult result = await FacebookAuth.instance.login();
      if (result.status != LoginStatus.success) throw 'Anulowano weryfikację Facebook.';
      
      final OAuthCredential credential = FacebookAuthProvider.credential(result.accessToken!.tokenString);
      await _firebaseUser!.reauthenticateWithCredential(credential);
    } catch (e) {
      throw 'Błąd weryfikacji Facebook: $e';
    }
  }

  String _handleAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'Nie znaleziono użytkownika o podanym adresie e-mail.';
      case 'wrong-password':
        return 'Nieprawidłowe hasło.';
      case 'email-already-in-use':
        return 'Ten adres e-mail jest już zajęty.';
      case 'invalid-email':
        return 'Nieprawidłowy format adresu e-mail.';
      case 'weak-password':
        return 'Hasło jest zbyt słabe.';
      case 'network-request-failed':
        return 'Błąd połączenia. Sprawdź internet.';
      case 'operation-not-allowed':
        return 'Logowanie hasłem nie jest włączone w konsoli Firebase.';
      case 'too-many-requests':
        return 'Zbyt wiele nieudanych prób. Spróbuj później.';
      default:
        return 'Błąd uwierzytelniania (${e.code}): ${e.message}';
    }
  }
}
