import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import '../core/models/models.dart';
import '../models/subscription_plan.dart';
import '../services/notification_service.dart';

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
  bool get isDarkMode => _currentThemeMode == 'dark';
  ThemeMode get themeMode => _currentThemeMode == 'dark' ? ThemeMode.dark : ThemeMode.light;
  int? get age => _age;
  double? get weight => _weight;
  double? get height => _height;
  String? get nickname => _nickname;
  String? get avatarUrl => _avatarUrl;
  
  // Subscription Getters
  SubscriptionTier get subscriptionTier => _subscriptionTier;
  DateTime? get subscriptionExpiryDate => _subscriptionExpiryDate;

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
      initAuthListener(); // Start listening to Firebase Auth
      
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
      
      // Load Subscription
      final tierIndex = prefs.getInt('subscription_tier') ?? 0;
      _subscriptionTier = SubscriptionTier.values[tierIndex];
      final expiryMillis = prefs.getInt('subscription_expiry');
      if (expiryMillis != null) {
        _subscriptionExpiryDate = DateTime.fromMillisecondsSinceEpoch(expiryMillis);
      }
      
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
    _surveyCompleted = true;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('user_age', age);
    await prefs.setDouble('user_weight', weight);
    await prefs.setDouble('user_height', height);
    await prefs.setBool('survey_completed', true);

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

    // Sync with Firebase
    await _auth.currentUser?.updateDisplayName(nickname);
    
    notifyListeners();
  }
  
  /// Update avatar URL
  Future<void> updateAvatarUrl(String url) async {
    _avatarUrl = url;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_avatar_url', url);

    // Sync with Firebase
    await _auth.currentUser?.updatePhotoURL(url);
    
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

  // ===========================================================================
  // FIREBASE AUTHENTICATION
  // ===========================================================================

  final FirebaseAuth _auth = FirebaseAuth.instance;
  User? _firebaseUser;
  
  User? get firebaseUser => _firebaseUser;
  bool get isLoggedIn => _firebaseUser != null;

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
          if (_nickname != user.displayName) {
            debugPrint('🔵 Restoring nickname from Firebase: ${user.displayName}');
            _nickname = user.displayName;
            await prefs.setString('nickname', user.displayName!);
          }
        }
        
        // Restore avatar from Firebase photoURL
        if (user.photoURL != null && user.photoURL!.isNotEmpty) {
          if (_avatarUrl != user.photoURL) {
            debugPrint('🔵 Restoring avatar from Firebase: ${user.photoURL}');
            _avatarUrl = user.photoURL;
            await prefs.setString('avatarUrl', user.photoURL!);
          }
        }
      } else {
        debugPrint('🔵 Auth state changed: User logged out');
      }
      
      notifyListeners();
    });
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
      await _auth.createUserWithEmailAndPassword(email: email, password: password);
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
        scopes: ['email'], // Only request email scope to avoid People API requirement
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
      final LoginResult result = await FacebookAuth.instance.login();
      
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
  
  /// Upgrade Subscription
  Future<void> upgradeSubscription(SubscriptionTier newTier) async {
    try {
      _subscriptionTier = newTier;
      
      // Set expiry date based on tier
      if (newTier != SubscriptionTier.free) {
        // For demo: set expiry to 30 days from now
        // In production, this would be set by payment processor
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
      
      // Only sign out from Google if on web (to avoid initialization error)
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
      // Still clear local data even if remote sign out fails
      await clearUserData();
    }
  }

  /// Delete Account
  Future<void> deleteAccount() async {
    try {
      await _auth.currentUser?.delete();
      await clearUserData();
    } catch (e) {
      throw 'Nie udało się usunąć konta. Zaloguj się ponownie i spróbuj jeszcze raz.';
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
