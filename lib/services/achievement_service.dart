import 'package:flutter/foundation.dart';
import '../core/models/models.dart';

/// Service to manage workout achievements
/// Tracks and unlocks achievements based on user's training activity
class AchievementService {
  static final AchievementService _instance = AchievementService._internal();
  factory AchievementService() => _instance;
  AchievementService._internal();

  /// All possible achievements in the app
  static final List<Achievement> allAchievements = [
    // STREAK ACHIEVEMENTS
    Achievement(
      id: 'streak_3',
      title: 'Rozgrzewka! 🔥',
      description: 'Ukończ 3 dni z rzędu',
      icon: 'fire',
    ),
    Achievement(
      id: 'streak_7',
      title: 'Tydzień Mocy! 💪',
      description: 'Ukończ 7 dni z rzędu',
      icon: 'fire',
    ),
    Achievement(
      id: 'streak_14',
      title: 'Dwa Tygodnie! 🔥🔥',
      description: 'Ukończ 14 dni z rzędu',
      icon: 'fire',
    ),
    Achievement(
      id: 'streak_30',
      title: 'Mistrz Miesiąca! 👑',
      description: 'Ukończ 30 dni z rzędu',
      icon: 'fire',
    ),
    Achievement(
      id: 'streak_60',
      title: 'Nieustępliwy! 🏆',
      description: 'Ukończ 60 dni z rzędu',
      icon: 'trophy',
    ),
    Achievement(
      id: 'streak_90',
      title: 'Legenda! ⚡',
      description: 'Ukończ 90 dni z rzędu',
      icon: 'star',
    ),
    Achievement(
      id: 'streak_180',
      title: 'Półroczny Wojownik! 🌟',
      description: 'Ukończ 180 dni z rzędu',
      icon: 'star',
    ),
    
    // TOTAL WORKOUTS ACHIEVEMENTS
    Achievement(
      id: 'workouts_1',
      title: 'Pierwszy Krok! 🎯',
      description: 'Ukończ pierwszy trening',
      icon: 'dumbell',
    ),
    Achievement(
      id: 'workouts_10',
      title: 'Początkujący! 💪',
      description: 'Ukończ 10 treningów',
      icon: 'dumbell',
    ),
    Achievement(
      id: 'workouts_25',
      title: 'Entuzjasta Fitnessu! 🏋️',
      description: 'Ukończ 25 treningów',
      icon: 'dumbell',
    ),
    Achievement(
      id: 'workouts_50',
      title: 'Zaawansowany! 🔱',
      description: 'Ukończ 50 treningów',
      icon: 'dumbell',
    ),
    Achievement(
      id: 'workouts_100',
      title: 'Setka! 🎊',
      description: 'Ukończ 100 treningów',
      icon: 'trophy',
    ),
    Achievement(
      id: 'workouts_250',
      title: 'Mistrz Siłowni! 🏆',
      description: 'Ukończ 250 treningów',
      icon: 'trophy',
    ),
    Achievement(
      id: 'workouts_500',
      title: 'Absolutna Legenda! 👑',
      description: 'Ukończ 500 treningów',
      icon: 'star',
    ),
    
    // SPECIAL ACHIEVEMENTS
    Achievement(
      id: 'comeback',
      title: 'Powrót! 🔄',
      description: 'Wznów treningi po przerwie',
      icon: 'fire',
    ),
    Achievement(
      id: 'consistency',
      title: 'Konsekwencja! ⏰',
      description: 'Trenuj o tej samej porze przez 7 dni',
      icon: 'star',
    ),
    Achievement(
      id: 'weekend_warrior',
      title: 'Weekend Warrior! 🎯',
      description: 'Trenuj w weekend',
      icon: 'dumbell',
    ),
  ];

  /// Check and unlock achievements based on current stats
  /// Returns list of newly unlocked achievements
  List<Achievement> checkAndUnlockAchievements({
    required int currentStreak,
    required int totalWorkouts,
    required List<Achievement> currentAchievements,
    DateTime? lastWorkoutDate,
  }) {
    final List<Achievement> newlyUnlocked = [];
    final Set<String> unlockedIds = currentAchievements
        .where((a) => a.isUnlocked)
        .map((a) => a.id)
        .toSet();

    // Check streak achievements
    final streakMilestones = {
      3: 'streak_3',
      7: 'streak_7',
      14: 'streak_14',
      30: 'streak_30',
      60: 'streak_60',
      90: 'streak_90',
      180: 'streak_180',
    };

    streakMilestones.forEach((milestone, id) {
      if (currentStreak >= milestone && !unlockedIds.contains(id)) {
        final achievement = allAchievements.firstWhere((a) => a.id == id);
        newlyUnlocked.add(Achievement(
          id: achievement.id,
          title: achievement.title,
          description: achievement.description,
          icon: achievement.icon,
          unlockedAt: DateTime.now(),
        ));
        unlockedIds.add(id);
      }
    });

    // Check total workouts achievements
    final workoutMilestones = {
      1: 'workouts_1',
      10: 'workouts_10',
      25: 'workouts_25',
      50: 'workouts_50',
      100: 'workouts_100',
      250: 'workouts_250',
      500: 'workouts_500',
    };

    workoutMilestones.forEach((milestone, id) {
      if (totalWorkouts >= milestone && !unlockedIds.contains(id)) {
        final achievement = allAchievements.firstWhere((a) => a.id == id);
        newlyUnlocked.add(Achievement(
          id: achievement.id,
          title: achievement.title,
          description: achievement.description,
          icon: achievement.icon,
          unlockedAt: DateTime.now(),
        ));
        unlockedIds.add(id);
      }
    });

    // Check comeback achievement (if returned after 7+ days break)
    if (lastWorkoutDate != null && !unlockedIds.contains('comeback')) {
      final daysSinceLastWorkout = DateTime.now().difference(lastWorkoutDate).inDays;
      if (daysSinceLastWorkout >= 7 && totalWorkouts > 1) {
        final achievement = allAchievements.firstWhere((a) => a.id == 'comeback');
        newlyUnlocked.add(Achievement(
          id: achievement.id,
          title: achievement.title,
          description: achievement.description,
          icon: achievement.icon,
          unlockedAt: DateTime.now(),
        ));
        unlockedIds.add('comeback');
      }
    }

    // Check weekend warrior (workout on Saturday or Sunday)
    final now = DateTime.now();
    if ((now.weekday == 6 || now.weekday == 7) && !unlockedIds.contains('weekend_warrior')) {
      final achievement = allAchievements.firstWhere((a) => a.id == 'weekend_warrior');
      newlyUnlocked.add(Achievement(
        id: achievement.id,
        title: achievement.title,
        description: achievement.description,
        icon: achievement.icon,
        unlockedAt: DateTime.now(),
      ));
      unlockedIds.add('weekend_warrior');
    }

    if (newlyUnlocked.isNotEmpty) {
      debugPrint('🏆 Unlocked ${newlyUnlocked.length} new achievements!');
      for (var achievement in newlyUnlocked) {
        debugPrint('  - ${achievement.title}');
      }
    }

    return newlyUnlocked;
  }

  /// Get next achievement for user to unlock
  Achievement? getNextAchievement({
    required int currentStreak,
    required int totalWorkouts,
    required List<Achievement> currentAchievements,
  }) {
    final unlockedIds = currentAchievements
        .where((a) => a.isUnlocked)
        .map((a) => a.id)
        .toSet();

    // Find next streak achievement
    final streakMilestones = [3, 7, 14, 30, 60, 90, 180];
    for (var milestone in streakMilestones) {
      final id = 'streak_$milestone';
      if (!unlockedIds.contains(id) && currentStreak < milestone) {
        return allAchievements.firstWhere((a) => a.id == id);
      }
    }

    // Find next workout count achievement
    final workoutMilestones = [1, 10, 25, 50, 100, 250, 500];
    for (var milestone in workoutMilestones) {
      final id = 'workouts_$milestone';
      if (!unlockedIds.contains(id) && totalWorkouts < milestone) {
        return allAchievements.firstWhere((a) => a.id == id);
      }
    }

    return null;
  }

  /// Get progress to next achievement (0.0 to 1.0)
  double getProgressToNextAchievement({
    required int currentStreak,
    required int totalWorkouts,
    required List<Achievement> currentAchievements,
  }) {
    final next = getNextAchievement(
      currentStreak: currentStreak,
      totalWorkouts: totalWorkouts,
      currentAchievements: currentAchievements,
    );

    if (next == null) return 1.0;

    // Determine which metric to use
    if (next.id.startsWith('streak_')) {
      final target = int.parse(next.id.split('_')[1]);
      return (currentStreak / target).clamp(0.0, 1.0);
    } else if (next.id.startsWith('workouts_')) {
      final target = int.parse(next.id.split('_')[1]);
      return (totalWorkouts / target).clamp(0.0, 1.0);
    }

    return 0.0;
  }

  /// Get icon for achievement type
  static String getIconEmoji(String iconType) {
    switch (iconType) {
      case 'fire':
        return '🔥';
      case 'trophy':
        return '🏆';
      case'dumbell':
        return '🏋️';
      case 'star':
        return '⭐';
      default:
        return '🎯';
    }
  }
}
