/// Diet-specific interview questions (30 questions organized by category)
class DietInterviewQuestions {
  static const List<Map<String, dynamic>> questions = [
    // I. Dane podstawowe i cel (7 pytań)
    {
      'id': 1,
      'category': 'Dane podstawowe i cel',
      'question': 'Jaka jest Twoja płeć?',
      'type': 'choice',
      'options': ['Kobieta', 'Mężczyzna'],
    },
    {
      'id': 2,
      'category': 'Dane podstawowe i cel',
      'question': 'Podaj swoją datę urodzenia (DD-MM-RRRR):',
      'type': 'text',
    },
    {
      'id': 3,
      'category': 'Dane podstawowe i cel',
      'question': 'Jaki jest Twój wzrost w centymetrach?',
      'type': 'number',
    },
    {
      'id': 4,
      'category': 'Dane podstawowe i cel',
      'question': 'Jaka jest Twoja aktualna waga w kilogramach?',
      'type': 'number',
    },
    {
      'id': 5,
      'category': 'Dane podstawowe i cel',
      'question': 'Jaki jest Twój główny cel?',
      'type': 'choice',
      'options': ['Redukcja wagi', 'Utrzymanie wagi', 'Budowa masy mięśniowej'],
    },
    {
      'id': 6,
      'category': 'Dane podstawowe i cel',
      'question': 'Jaka jest Twoja waga docelowa w kilogramach?',
      'type': 'number',
    },
    {
      'id': 7,
      'category': 'Dane podstawowe i cel',
      'question': 'Jaki jest Twój poziom aktywności poza treningami?',
      'type': 'choice',
      'options': ['Siedząca', 'Lekka', 'Średnia', 'Fizyczna', 'Bardzo ciężka'],
    },
    
    // II. Zdrowie i bezpieczeństwo (5 pytań)
    {
      'id': 8,
      'category': 'Zdrowie i bezpieczeństwo',
      'question': 'Czy masz któreś z następujących chorób? (możesz wybrać kilka)',
      'type': 'multiple_choice',
      'options': [
        'Brak',
        'Insulinooporność',
        'Cukrzyca',
        'Nadciśnienie',
        'Choroby tarczycy',
        'Choroby serca',
        'Inne',
      ],
    },
    {
      'id': 9,
      'category': 'Zdrowie i bezpieczeństwo',
      'question': 'Czy masz alergie lub nietolerancje pokarmowe?',
      'type': 'multiple_choice',
      'options': [
        'Brak',
        'Gluten',
        'Laktoza',
        'Orzechy',
        'Owoce morza',
        'Jaja',
        'Soja',
        'Inne',
      ],
    },
    {
      'id': 10,
      'category': 'Zdrowie i bezpieczeństwo',
      'question': 'Czy odczuwasz dyskomfort trawienny po spożyciu pewnych produktów?',
      'type': 'multiple_choice',
      'options': [
        'Nie',
        'Rośliny strączkowe',
        'Nabiał',
        'Produkty pełnoziarniste',
        'Warzywa kapustne',
        'Inne',
      ],
    },
    {
      'id': 11,
      'category': 'Zdrowie i bezpieczeństwo',
      'question': '(Tylko dla kobiet) Czy zauważasz silne zatrzymywanie wody w zależności od cyklu menstruacyjnego?',
      'type': 'choice',
      'options': ['Tak', 'Nie', 'Nie dotyczy'],
      'conditional': {'gender': 'Kobieta'},
    },
    {
      'id': 12,
      'category': 'Zdrowie i bezpieczeństwo',
      'question': 'Czy przyjmujesz stale jakieś leki, które mogą wchodzić w interakcje z żywnością? (pole opcjonalne)',
      'type': 'text',
      'optional': true,
    },
    
    // III. Logistyka i styl życia (6 pytań)
    {
      'id': 13,
      'category': 'Logistyka i styl życia',
      'question': 'Jaki jest maksymalny czas, jaki możesz poświęcić na przygotowanie obiadu w tygodniu?',
      'type': 'choice',
      'options': ['Do 15 minut', '15-30 minut', '30-60 minut', 'Powyżej 60 minut'],
    },
    {
      'id': 14,
      'category': 'Logistyka i styl życia',
      'question': 'Jaki system gotowania preferujesz?',
      'type': 'choice',
      'options': [
        'Gotowanie codzienne',
        'Meal prep (gotowanie na kilka dni)',
        'Kombinacja obu',
      ],
    },
    {
      'id': 15,
      'category': 'Logistyka i styl życia',
      'question': 'Ile posiłków dziennie preferujesz?',
      'type': 'choice',
      'options': ['2-3 posiłki', '4-5 posiłków', '6+ posiłków'],
    },
    {
      'id': 16,
      'category': 'Logistyka i styl życia',
      'question': 'Czy masz możliwość podgrzania posiłku w pracy/szkole?',
      'type': 'choice',
      'options': ['Tak', 'Nie'],
    },
    {
      'id': 17,
      'category': 'Logistyka i styl życia',
      'question': 'Jaki sprzęt kuchenny masz dostępny?',
      'type': 'multiple_choice',
      'options': [
        'Piekarnik',
        'Płyta indukcyjna/gazowa',
        'Mikrofalówka',
        'Multicooker',
        'Grill',
        'Blender',
        'Inne',
      ],
    },
    {
      'id': 18,
      'category': 'Logistyka i styl życia',
      'question': 'Jaki jest Twój budżet tygodniowy na dietę?',
      'type': 'choice',
      'options': ['Ekonomiczny (do 150 zł)', 'Standard (150-300 zł)', 'Premium (powyżej 300 zł)'],
    },
    
    // IV. Preferencje smakowe (7 pytań)
    {
      'id': 19,
      'category': 'Preferencje smakowe',
      'question': 'Czy stosujesz dietę wykluczającą pewne produkty?',
      'type': 'choice',
      'options': [
        'Nie',
        'Wegetariańska',
        'Wegańska',
        'Peskatariańska',
        'Bezglutenowa',
        'Inna',
      ],
    },
    {
      'id': 20,
      'category': 'Preferencje smakowe',
      'question': 'Jaki typ śniadań preferujesz?',
      'type': 'choice',
      'options': ['Słodkie', 'Wytrawne', 'Pół na pół'],
    },
    {
      'id': 21,
      'category': 'Preferencje smakowe',
      'question': 'Jak odnosisz się do posiłków płynnych (koktajle, smoothie)?',
      'type': 'choice',
      'options': [
        'Lubię i chętnie jem',
        'Akceptuję okazjonalnie',
        'Wolę posiłki stałe',
      ],
    },
    {
      'id': 22,
      'category': 'Preferencje smakowe',
      'question': 'Czego absolutnie nie zjesz? (czarna lista produktów)',
      'type': 'text',
      'optional': true,
    },
    {
      'id': 23,
      'category': 'Preferencje smakowe',
      'question': 'Bez czego nie wyobrażasz sobie diety? (biała lista produktów)',
      'type': 'text',
      'optional': true,
    },
    {
      'id': 24,
      'category': 'Preferencje smakowe',
      'question': 'Jak bardzo jesteś otwarty/a na nowe smaki i kuchnie świata?',
      'type': 'choice',
      'options': [
        'Bardzo otwarty/a - lubię eksperymentować',
        'Umiarkowanie - czasem spróbuję',
        'Wolę tradycyjne posiłki',
      ],
    },
    {
      'id': 25,
      'category': 'Preferencje smakowe',
      'question': 'Czy chcesz uwzględnić "cheat meal" w tygodniu?',
      'type': 'choice',
      'options': ['Tak', 'Nie'],
    },
    
    // V. Trening i aktywność (5 pytań)
    {
      'id': 26,
      'category': 'Trening i aktywność',
      'question': 'Ile realnych treningów wykonujesz w tygodniu?',
      'type': 'choice',
      'options': ['0-1', '2-3', '4-5', '6+'],
    },
    {
      'id': 27,
      'category': 'Trening i aktywność',
      'question': 'Gdzie planujesz trenować?',
      'type': 'choice',
      'options': ['Siłownia', 'Dom', 'Plener', 'Kombinacja'],
    },
    {
      'id': 28,
      'category': 'Trening i aktywność',
      'question': 'Jaki sprzęt treningowy masz dostępny w domu?',
      'type': 'multiple_choice',
      'options': [
        'Brak',
        'Hantle',
        'Guma oporowa',
        'Mata',
        'Drążek',
        'Kettlebell',
        'Inne',
      ],
    },
    {
      'id': 29,
      'category': 'Trening i aktywność',
      'question': 'O jakiej porze dnia najczęściej trenujesz?',
      'type': 'choice',
      'options': ['Rano', 'Południe', 'Wieczór', 'Różnie'],
    },
    {
      'id': 30,
      'category': 'Trening i aktywność',
      'question': 'Jaki jest Twój poziom zaawansowania treningowego?',
      'type': 'choice',
      'options': ['Początkujący', 'Średniozaawansowany', 'Zaawansowany'],
    },
  ];
  
  /// Get question by ID
  static Map<String, dynamic>? getQuestionById(int id) {
    try {
      return questions.firstWhere((q) => q['id'] == id);
    } catch (e) {
      return null;
    }
  }
  
  /// Get all questions for a specific category
  static List<Map<String, dynamic>> getQuestionsByCategory(String category) {
    return questions.where((q) => q['category'] == category).toList();
  }
  
  /// Get all categories
  static List<String> getCategories() {
    return questions
        .map((q) => q['category'] as String)
        .toSet()
        .toList();
  }
}
