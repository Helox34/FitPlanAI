class InterviewQuestions {
  static const List<QuestionCategory> categories = [
    QuestionCategory(
      name: 'I. Zdrowie i historia medyczna',
      questions: [
        'Czy chorujesz obecnie na jakieś choroby przewlekłe lub jesteś w trakcie leczenia?',
        'Czy w przeszłości występowały u Ciebie poważne problemy zdrowotne, urazy lub operacje?',
        'Czy masz zdiagnozowane problemy hormonalne, metaboliczne lub trawienne (np. tarczyca, insulinooporność, IBS)?',
        'Czy w Twojej rodzinie występują choroby cywilizacyjne (cukrzyca, nadciśnienie, choroby serca)?',
      ],
    ),
    QuestionCategory(
      name: 'II. Leki, suplementy i używki',
      questions: [
        'Jakie leki przyjmujesz regularnie i w jakich dawkach?',
        'Czy stosujesz suplementy diety? Jeśli tak – jakie i dlaczego?',
        'Jak często spożywasz alkohol, kofeinę lub inne używki?',
      ],
    ),
    QuestionCategory(
      name: 'III. Cele treningowe i zdrowotne',
      questions: [
        'Jaki jest Twój główny cel na najbliższe 3–6 miesięcy?',
        'Czy masz cele drugorzędne (np. poprawa kondycji, zdrowia, sylwetki)?',
        'Po czym poznasz, że plan jest dla Ciebie skuteczny?',
      ],
    ),
    QuestionCategory(
      name: 'IV. Aktywność fizyczna',
      questions: [
        'Jak wygląda Twoja aktualna aktywność fizyczna w skali tygodnia?',
        'Jakie formy ruchu sprawiają Ci przyjemność, a jakich nie lubisz?',
        'Czy trenowałeś/aś wcześniej regularnie? Jeśli tak – co i jak długo?',
        'Czy masz jakieś ograniczenia ruchowe lub bóle podczas ćwiczeń?',
      ],
    ),
    QuestionCategory(
      name: 'V. Aktualny sposób odżywiania',
      questions: [
        'Jak wygląda Twój typowy dzień jedzenia (posiłki, godziny, ilość)?',
        'Czy zdarza Ci się pomijać posiłki lub jeść bardzo nieregularnie?',
        'Jak często jesz na mieście lub sięgasz po żywność przetworzoną?',
      ],
    ),
    QuestionCategory(
      name: 'VI. Preferencje żywieniowe i ograniczenia',
      questions: [
        'Czy masz alergie, nietolerancje lub produkty, których nie jesz?',
        'Czy stosujesz lub stosowałeś/aś konkretne diety (np. keto, wege)?',
        'Jakie produkty lub posiłki szczególnie lubisz?',
      ],
    ),
    QuestionCategory(
      name: 'VII. Styl życia i tryb dnia',
      questions: [
        'Jak wygląda Twój typowy dzień pracy/nauki (ruch, siedzenie, stres)?',
        'Ile czasu realnie możesz poświęcić na trening i przygotowanie posiłków?',
      ],
    ),
    QuestionCategory(
      name: 'VIII. Sen, regeneracja i stres',
      questions: [
        'Ile godzin śpisz średnio i jak oceniasz jakość snu?',
        'Jak często odczuwasz stres i jak sobie z nim radzisz?',
        'Czy zauważasz spadki energii w ciągu dnia? Kiedy?',
      ],
    ),
    QuestionCategory(
      name: 'IX. Dodatkowe informacje',
      questions: [
        'Czy masz jakieś wcześniejsze doświadczenia z dietetykiem lub trenerem?',
        'Czy jest coś jeszcze, co Twoim zdaniem może mieć wpływ na Twoje zdrowie lub formę?',
      ],
    ),
  ];

  // Flatten all questions into a single list with numbering
  static List<String> getAllQuestions() {
    final List<String> allQuestions = [];
    for (var category in categories) {
      allQuestions.addAll(category.questions);
    }
    return allQuestions;
  }

  // Get total number of questions
  static int get totalQuestions => getAllQuestions().length;

  // Get question by index (0-based)
  static String getQuestion(int index) {
    final questions = getAllQuestions();
    if (index >= 0 && index < questions.length) {
      return questions[index];
    }
    return '';
  }
}

class QuestionCategory {
  final String name;
  final List<String> questions;

  const QuestionCategory({
    required this.name,
    required this.questions,
  });
}
