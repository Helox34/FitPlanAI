// Enums
enum CreatorMode {
  WORKOUT,
  DIET;
  
  @override
  String toString() => name.toLowerCase();
}

// Chat Message
class ChatMessage {
  final String id;
  final String role; // 'user' or 'model'
  final String text;
  final DateTime timestamp;

  ChatMessage({
    required this.id,
    required this.role,
    required this.text,
    required this.timestamp,
  });
  
  // For backward compatibility with existing code
  bool get isUser => role == 'user';
  String get content => text;

  Map<String, dynamic> toJson() => {
    'id': id,
    'role': role,
    'text': text,
    'timestamp': timestamp.toIso8601String(),
  };

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
    id: json['id'],
    role: json['role'],
    text: json['text'],
    timestamp: DateTime.parse(json['timestamp']),
  );
}

// Plan Item (Exercise or Meal)
class PlanItem {
  final String name;
  final String details; // Sets/Reps or Grams/Calories
  final String? note;
  final String? tips; // Technical description

  PlanItem({
    required this.name,
    required this.details,
    this.note,
    this.tips,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'details': details,
    if (note != null) 'note': note,
    if (tips != null) 'tips': tips,
  };

  factory PlanItem.fromJson(Map<String, dynamic> json) => PlanItem(
    name: json['name'],
    details: json['details'],
    note: json['note'],
    tips: json['tips'],
  );
}

// Plan Day
class PlanDay {
  final String dayName;
  final List<PlanItem> items;
  final String? summary;

  PlanDay({
    required this.dayName,
    required this.items,
    this.summary,
  });

  Map<String, dynamic> toJson() => {
    'dayName': dayName,
    'items': items.map((i) => i.toJson()).toList(),
    if (summary != null) 'summary': summary,
  };

  factory PlanDay.fromJson(Map<String, dynamic> json) => PlanDay(
    dayName: json['dayName'],
    items: (json['items'] as List).map((i) => PlanItem.fromJson(i)).toList(),
    summary: json['summary'],
  );
}

// Progress Point
class ProgressPoint {
  final int week;
  final double value;
  final String type; // 'projected' or 'actual'

  ProgressPoint({
    required this.week,
    required this.value,
    required this.type,
  });

  Map<String, dynamic> toJson() => {
    'week': week,
    'value': value,
    'type': type,
  };

  factory ProgressPoint.fromJson(Map<String, dynamic> json) => ProgressPoint(
    week: json['week'],
    value: (json['value'] as num).toDouble(),
    type: json['type'],
  );
}

// Progress Data
class ProgressData {
  final String metricName;
  final String unit;
  final List<ProgressPoint> dataPoints;

  ProgressData({
    required this.metricName,
    required this.unit,
    required this.dataPoints,
  });

  Map<String, dynamic> toJson() => {
    'metricName': metricName,
    'unit': unit,
    'dataPoints': dataPoints.map((p) => p.toJson()).toList(),
  };

  factory ProgressData.fromJson(Map<String, dynamic> json) => ProgressData(
    metricName: json['metricName'],
    unit: json['unit'],
    dataPoints: (json['dataPoints'] as List)
        .map((p) => ProgressPoint.fromJson(p))
        .toList(),
  );
}

// Generated Plan
class GeneratedPlan {
  final String title;
  final String description;
  final CreatorMode mode;
  final List<PlanDay> schedule;
  final ProgressData? progress;

  GeneratedPlan({
    required this.title,
    required this.description,
    required this.mode,
    required this.schedule,
    this.progress,
  });

  Map<String, dynamic> toJson() => {
    'title': title,
    'description': description,
    'mode': mode.toString(),
    'schedule': schedule.map((d) => d.toJson()).toList(),
    if (progress != null) 'progress': progress!.toJson(),
  };

  factory GeneratedPlan.fromJson(Map<String, dynamic> json) => GeneratedPlan(
    title: json['title'],
    description: json['description'],
    mode: json['mode'] == 'workout' ? CreatorMode.WORKOUT : CreatorMode.DIET,
    schedule: (json['schedule'] as List).map((d) => PlanDay.fromJson(d)).toList(),
    progress: json['progress'] != null ? ProgressData.fromJson(json['progress']) : null,
  );
}

// Modification Result
class ModificationResult {
  final bool approved;
  final GeneratedPlan? plan;
  final String validationLog;
  final String? refusalReason;

  ModificationResult({
    required this.approved,
    this.plan,
    required this.validationLog,
    this.refusalReason,
  });

  Map<String, dynamic> toJson() => {
    'approved': approved,
    if (plan != null) 'plan': plan!.toJson(),
    'validationLog': validationLog,
    if (refusalReason != null) 'refusalReason': refusalReason,
  };

  factory ModificationResult.fromJson(Map<String, dynamic> json) => ModificationResult(
    approved: json['approved'],
    plan: json['plan'] != null ? GeneratedPlan.fromJson(json['plan']) : null,
    validationLog: json['validationLog'],
    refusalReason: json['refusalReason'],
  );
}

// Workout Log
class WorkoutLog {
  final DateTime date;
  final String planTitle;
  final int durationMinutes;
  final int completedItems;
  final int totalItems;

  WorkoutLog({
    required this.date,
    required this.planTitle,
    required this.durationMinutes,
    required this.completedItems,
    required this.totalItems,
  });

  Map<String, dynamic> toJson() => {
    'date': date.toIso8601String(),
    'planTitle': planTitle,
    'durationMinutes': durationMinutes,
    'completedItems': completedItems,
    'totalItems': totalItems,
  };

  factory WorkoutLog.fromJson(Map<String, dynamic> json) => WorkoutLog(
    date: DateTime.parse(json['date']),
    planTitle: json['planTitle'],
    durationMinutes: json['durationMinutes'],
    completedItems: json['completedItems'],
    totalItems: json['totalItems'],
  );
}

// Achievement
class Achievement {
  final String id;
  final String title;
  final String description;
  final String icon; // 'trophy', 'fire', 'dumbell', 'star'
  final DateTime? unlockedAt;

  Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    this.unlockedAt,
  });
  
  bool get isUnlocked => unlockedAt != null;

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'icon': icon,
    if (unlockedAt != null) 'unlockedAt': unlockedAt!.toIso8601String(),
  };

  factory Achievement.fromJson(Map<String, dynamic> json) => Achievement(
    id: json['id'],
    title: json['title'],
    description: json['description'],
    icon: json['icon'],
    unlockedAt: json['unlockedAt'] != null 
        ? DateTime.parse(json['unlockedAt']) 
        : null,
  );
}

// User Stats
class UserStats {
  final int streakCurrent;
  final int streakBest;
  final int totalWorkouts;
  final String? lastWorkoutDate;
  final List<Achievement> achievements;
  final List<WorkoutLog> history;

  UserStats({
    required this.streakCurrent,
    required this.streakBest,
    required this.totalWorkouts,
    this.lastWorkoutDate,
    required this.achievements,
    required this.history,
  });
  
  factory UserStats.initial() => UserStats(
    streakCurrent: 0,
    streakBest: 0,
    totalWorkouts: 0,
    lastWorkoutDate: null,
    achievements: [],
    history: [],
  );

  Map<String, dynamic> toJson() => {
    'streakCurrent': streakCurrent,
    'streakBest': streakBest,
    'totalWorkouts': totalWorkouts,
    if (lastWorkoutDate != null) 'lastWorkoutDate': lastWorkoutDate,
    'achievements': achievements.map((a) => a.toJson()).toList(),
    'history': history.map((h) => h.toJson()).toList(),
  };

  factory UserStats.fromJson(Map<String, dynamic> json) => UserStats(
    streakCurrent: json['streakCurrent'],
    streakBest: json['streakBest'],
    totalWorkouts: json['totalWorkouts'],
    lastWorkoutDate: json['lastWorkoutDate'],
    achievements: (json['achievements'] as List)
        .map((a) => Achievement.fromJson(a))
        .toList(),
    history: (json['history'] as List)
        .map((h) => WorkoutLog.fromJson(h))
        .toList(),
  );
}

// User Profile
class UserProfile {
  final String uid;
  final String name;
  final String email;
  final String? avatarUrl;
  final bool isLoggedIn;

  UserProfile({
    required this.uid,
    required this.name,
    required this.email,
    this.avatarUrl,
    this.isLoggedIn = true,
  });

  Map<String, dynamic> toJson() => {
    'uid': uid,
    'name': name,
    'email': email,
    if (avatarUrl != null) 'avatarUrl': avatarUrl,
    'isLoggedIn': isLoggedIn,
  };

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
    uid: json['uid'],
    name: json['name'],
    email: json['email'],
    avatarUrl: json['avatarUrl'],
    isLoggedIn: json['isLoggedIn'] ?? true,
  );
}
