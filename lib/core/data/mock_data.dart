import '../models/models.dart';

class MockData {
  // Sample FBW Generated Plan (using new model structure)
  static final GeneratedPlan sampleFBWPlan = GeneratedPlan(
    title: 'Testowy Plan FBW',
    description: 'Szybki plan Full Body Workout wygenerowany na celów testowych. Skupia się na podstawowych wzorcach ruchowych.',
    mode: CreatorMode.WORKOUT,
    schedule: [
      PlanDay(
        dayName: 'Poniedziałek - Siła',
        summary: 'Trening skupiony na budowaniu siły w głównych ćwiczeniach.',
        items: [
          PlanItem(
            name: 'Przysiad ze sztangą',
            details: '3 serie x 5 powtórzeń',
            note: 'Przerwa 3-5 min',
            tips: 'Przysiad poniżej równoległego ustawienia. Trzymaj proste plecy.',
          ),
          PlanItem(
            name: 'Wyciskanie leżąc',
            details: '3 serie x 5 powtórzeń',
            note: 'Przerwa 3-5 min',
            tips: 'Technika pełnego zakresu ruchu. Nie blokuj łokci.',
          ),
          PlanItem(
            name: 'Martwy ciąg',
            details: '1 seria x 5 powtórzeń',
            note: 'Przerwa 5 min',
            tips: 'Zachowanie prostego grzbietu. Kontroluj oddech.',
          ),
        ],
      ),
      PlanDay(
        dayName: 'Środa - Objętość',
        summary: 'Dzień objętościowy - więcej powtórzeń, mniejsze obciążenia.',
        items: [
          PlanItem(
            name: 'Przysiad goblet',
            details: '4 serie x 10 powtórzeń',
            note: 'Przerwa 2-3 min',
          ),
          PlanItem(
            name: 'Pompki',
            details: '4 serie x 12 powtórzeń',
            note: 'Przerwa 2 min',
          ),
          PlanItem(
            name: 'Podciąganie',
            details: '4 serie x 8 powtórzeń',
            note: 'Przerwa 2-3 min',
          ),
          PlanItem(
            name: 'Deska',
            details: '3 serie x 60s',
            note: 'Przerwa 2 min',
          ),
        ],
      ),
      PlanDay(
        dayName: 'Piątek - Moc',
        summary: 'Trening mocy - eksplozywne ruchy.',
        items: [
          PlanItem(
            name: 'Przysiad z wyskokiem',
            details: '5 serie x 3 powtórzenia',
            note: 'Przerwa 3 min',
          ),
          PlanItem(
            name: 'Wyciskanie nad głowę',
            details: '4 serie x 6 powtórzeń',
            note: 'Przerwa 2-3 min',
          ),
          PlanItem(
            name: 'Wiosłowanie sztangą',
            details: '4 serie x 8 powtórzeń',
            note: 'Przerwa 2-3 min',
          ),
        ],
      ),
    ],
    progress: ProgressData(
      metricName: 'Wyciskanie Leżąc',
      unit: 'kg',
      dataPoints: [
        ProgressPoint(week: 0, value: 56, type: 'projected'),
        ProgressPoint(week: 1, value: 58, type: 'projected'),
        ProgressPoint(week: 2, value: 62, type: 'projected'),
        ProgressPoint(week: 3, value: 66, type: 'projected'),
      ],
    ),
  );

  // Sample Achievements
  static final List<Achievement> sampleAchievements = [
    Achievement(
      id: 'ach1',
      title: 'Pierwszy Trening',
      description: 'Ukończ swój pierwszy trening',
      icon: 'trophy',
      unlockedAt: DateTime.now().subtract(const Duration(days: 6)),
    ),
    Achievement(
      id: 'ach2',
      title: 'Tydzień Mocy',
      description: 'Trenuj 7 dni z rzędu',
      icon: 'fire',
    ),
    Achievement(
      id: 'ach3',
      title: 'Silny Start',
      description: 'Ukończ 10 treningów',
      icon: 'trophy',
    ),
    Achievement(
      id: 'ach4',
      title: 'Regularność',
      description: 'Trenuj przez 30 dni',
      icon: 'star',
    ),
  ];

  // Sample User Stats
  static final UserStats sampleProgress = UserStats(
    streakCurrent: 4,
    streakBest: 6,
    totalWorkouts: 6,
    lastWorkoutDate: DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
    achievements: sampleAchievements,
    history: [
      WorkoutLog(
        date: DateTime.now().subtract(const Duration(days: 1)),
        planTitle: 'Testowy Plan FBW',
        durationMinutes: 45,
        completedItems: 3,
        totalItems: 3,
      ),
      WorkoutLog(
        date: DateTime.now().subtract(const Duration(days: 2)),
        planTitle: 'Testowy Plan FBW',
        durationMinutes: 50,
        completedItems: 4,
        totalItems: 4,
      ),
    ],
  );

  // Sample Chat Messages
  static final List<ChatMessage> sampleChatMessages = [
    ChatMessage(
      id: '1',
      role: 'model',
      text: 'Cześć! Bardzo się cieszę, że zdecydowałeś się zacząć w kwiecie zdrowie i formę. Jako Twój trener i dietetyk, przeprowadzimy Tobą szczegółowy wywiad, aby móc przygotować plan idealnie dopasowany do Twoich potrzeb. Przejdziemy przez 27 pytań - będę zadawał je pojedynczo, abyśmy mogli dokładnie omówić każdy aspekt. Zaczynamy od części 1 - Twoje podstawowe informacje. Czy możesz powiedzieć mi jakie jest Twoje imię?',
      timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
    ),
  ];

  // Process Steps
  static final List<Map<String, dynamic>> processSteps = [
    {
      'number': '1',
      'title': 'Wywiad Szczegółowy',
      'description':
          'Odpowiedz na 27+ pytań w kategoriach zdrowia, stylu życia i preferencji.',
    },
    {
      'number': '2',
      'title': 'Kompletowanie Odpowiedzi',
      'description':
          'System zbierze Twoje dane w historii medycznej, diecię i treningu.',
    },
    {
      'number': '3',
      'title': 'Analiza Twoich potrzeb',
      'description':
          'Uporządkujemy zebrane informacje, aby stworzyć spójny obraz Twojej sytuacji.',
    },
    {
      'number': '4',
      'title': 'Weryfikacja Bezpieczeństwa',
      'description':
          'Sprawdzimy, czy Twoje cele są realne i bezpieczne dla Twojego zdrowia.',
    },
    {
      'number': '5',
      'title': 'Gotowy Plan Działania',
      'description':
          'Otrzymasz przystępną strategię (treningową lub dietetyczną) szytą na miarę.',
    },
  ];
}
