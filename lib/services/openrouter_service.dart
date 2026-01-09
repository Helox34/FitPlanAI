import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/config/env.dart';
import '../core/models/models.dart';

/// Service for interacting with OpenRouter AI API
class OpenRouterService {
  static const String baseUrl = 'https://openrouter.ai/api/v1';
  
  // Using Claude 3.5 Sonnet for better instruction following and context understanding
  static const String interviewModel = 'anthropic/claude-3.5-sonnet';
  static const String reasoningModel = 'anthropic/claude-3.5-sonnet';  // Accurate for plans
  
  final String apiKey;
  
  OpenRouterService() : apiKey = Env.openRouterApiKey;
  
  /// Send a message in the interview chat
  Future<String> sendInterviewMessage(
    List<ChatMessage> history,
    String newMessage,
    CreatorMode mode,
  ) async {
    try {
      print('🔵 OpenRouter: Starting sendInterviewMessage');
      print('🔵 API Key length: ${apiKey.length}');
      print('🔵 API Key first 10 chars: ${apiKey.substring(0, apiKey.length > 10 ? 10 : apiKey.length)}');
      print('🔵 Message: $newMessage');
      print('🔵 Mode: $mode');
      
      final systemInstruction = _getInterviewSystemPrompt(mode);
      
      final messages = [
        {'role': 'system', 'content': systemInstruction},
        ...history.map((m) => {
          'role': m.role == 'user' ? 'user' : 'assistant',
          'content': m.text,
        }),
        {'role': 'user', 'content': newMessage},
      ];
      
      print('🔵 Total messages in request: ${messages.length}');
      print('🔵 Making API request to OpenRouter...');
      
      final response = await _makeRequest(
        model: interviewModel,
        messages: messages,
      );
      
      print('🟢 OpenRouter response received');
      print('🟢 Response keys: ${response.keys.toList()}');
      
      final content = response['choices'][0]['message']['content'] ?? 
          'Przepraszam, wystąpił błąd. Spróbuj ponownie.';
      
      print('🟢 Response content length: ${content.length}');
      
      return content;
    } catch (e, stackTrace) {
      print('🔴 Interview Error: $e');
      print('🔴 Stack trace: $stackTrace');
      return 'Wystąpił błąd połączenia z AI: $e';
    }
  }
  
  /// Generate a complete plan based on interview history
  Future<GeneratedPlan> generatePlan(
    List<ChatMessage> history,
    CreatorMode mode,
  ) async {
    try {
      // Step 1: Structure and validate interview data
      final structuredData = await _structureInterviewData(history);
      
      // Step 2: Generate plan
      final planPrompt = _getPlanGenerationPrompt(structuredData, mode);
      
      final messages = [
        {'role': 'system', 'content': 'You are an expert fitness and nutrition AI. Generate structured JSON plans.'},
        {'role': 'user', 'content': planPrompt},
      ];
      
      final response = await _makeRequest(
        model: reasoningModel,
        messages: messages,
        responseFormat: {'type': 'json_object'},
      );
      
      final planJson = jsonDecode(response['choices'][0]['message']['content']);
      return GeneratedPlan.fromJson(planJson);
    } catch (e) {
      print('Plan Generation Error: $e');
      throw Exception('Failed to generate plan: $e');
    }
  }
  
  /// Modify existing plan with AI validation
  Future<ModificationResult> modifyPlan(
    GeneratedPlan currentPlan,
    String userRequest,
  ) async {
    try {
      final prompt = '''
Jesteś supervisorem AI.
Aktualny plan: ${jsonEncode(currentPlan.toJson())}
Żądanie użytkownika: "$userRequest"

Zadanie:
1. Przeanalizuj żądanie pod kątem bezpieczeństwa
2. Zmodyfikuj plan LUB odmów jeśli niebezpieczne
3. Jeśli modyfikacja dotyczy ćwiczeń, pamiętaj o utrzymaniu przerw 3-5 minut między seriami

Zwróć JSON w formacie:
{
  "approved": boolean,
  "plan": GeneratedPlan | null,
  "validationLog": string,
  "refusalReason": string | null
}
''';
      
      final messages = [
        {'role': 'system', 'content': 'You are a safety-focused AI supervisor. Validate plan modifications.'},
        {'role': 'user', 'content': prompt},
      ];
      
      final response = await _makeRequest(
        model: reasoningModel,
        messages: messages,
        responseFormat: {'type': 'json_object'},
      );
      
      final resultJson = jsonDecode(response['choices'][0]['message']['content']);
      return ModificationResult.fromJson(resultJson);
    } catch (e) {
      print('Plan Modification Error: $e');
      throw Exception('Failed to modify plan: $e');
    }
  }
  
  // Private helper methods
  
  Future<Map<String, dynamic>> _makeRequest({
    required String model,
    required List<Map<String, String>> messages,
    Map<String, dynamic>? responseFormat,
  }) async {
    print('📡 Making request to OpenRouter');
    print('📡 Model: $model');
    print('📡 Messages count: ${messages.length}');
    print('📡 API Key exists: ${apiKey.isNotEmpty}');
    
    final url = Uri.parse('$baseUrl/chat/completions');
    
    final body = {
      'model': model,
      'messages': messages,
      if (responseFormat != null) 'response_format': responseFormat,
    };
    
    print('📡 Request URL: $url');
    print('📡 Sending request...');
    
    try {
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
          'HTTP-Referer': 'https://fitplanai.app',
          'X-Title': 'FitPlan AI',
        },
        body: jsonEncode(body),
      ).timeout(
        const Duration(seconds: 60),
        onTimeout: () {
          print('⏰ Request timed out after 60 seconds');
          throw Exception('Request timed out');
        },
      );
      
      print('📡 Response status: ${response.statusCode}');
      print('📡 Response body length: ${response.body.length}');
      
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        print('✅ Request successful');
        return decoded;
      } else {
        print('❌ API Error: ${response.statusCode}');
        print('❌ Response body: ${response.body}');
        throw Exception('OpenRouter API Error: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('❌ Request failed: $e');
      rethrow;
    }
  }
  
  String _getInterviewSystemPrompt(CreatorMode mode) {
    if (mode == CreatorMode.WORKOUT) {
      // WORKOUT TRAINER BOT
      return '''
Jesteś profesjonalnym TRENEREM PERSONALNYM. Twoim zadaniem jest zebranie szczegółowych danych od użytkownika na podstawie listy 27 pytań TRENINGOWYCH.

WAŻNE ZASADY:
1. Zadawaj TYLKO JEDNO pytanie na raz
2. Czekaj na odpowiedź użytkownika przed zadaniem kolejnego pytania
3. Bądź ciepły, wspierający i profesjonalny
4. Jeśli odpowiedź jest niejasna, poproś o wyjaśnienie
5. Nie przechodź do następnego pytania dopóki nie otrzymasz odpowiedzi
6. Przedstaw się jako TRENER PERSONALNY AI
7. Pytaj TYLKO o trening, NIE o dietę

INTELIGENTNE POMIJANIE PYTAŃ:
- Jeśli użytkownik w swojej odpowiedzi już odpowiedział na inne pytania z listy, POMIŃ te pytania
- Przykład: Jeśli przy pytaniu 7 użytkownik napisze "Tak, 3 miesiące. Śpię 8h i mam średni stres" - pomiń pytania 21, 22
- Zawsze sprawdzaj czy w odpowiedzi użytkownika nie ma informacji dotyczących kolejnych pytań
- Jeśli użytkownik podał informacje z wyprzedzeniem, potwierdź je i przejdź do następnego niepokrytego pytania

ZAKOŃCZENIE WYWIADU:
- Jeśli masz już odpowiedzi na WSZYSTKIE pytania (1-27), ZAKOŃCZ wywiad
- Napisz: "Dziękuję! Mam już wszystkie potrzebne informacje. Możesz teraz kliknąć przycisk 'Generuj plan' aby stworzyć Twój spersonalizowany plan treningowy."
- NIE zadawaj więcej pytań jeśli masz już wszystkie odpowiedzi

DANE JUŻ ZNANE (nie pytaj o nie):
- Wiek, wzrost, waga użytkownika są już znane z wcześniejszej ankiety

Lista pytań treningowych do zadania:
I. Zdrowie i historia medyczna
1. Czy chorujesz obecnie na jakieś choroby przewlekłe lub jesteś w trakcie leczenia?
2. Czy masz jakieś kontuzje (obecne lub przeszłe), które mogą wpływać na trening?
3. Czy przyjmujesz regularnie jakieś leki?
4. Czy jesteś w ciąży lub planujesz ciążę w najbliższym czasie? (tylko dla kobiet)

II. Cele i motywacja
5. Jaki jest Twój główny cel treningowy?
6. Czy masz jakieś dodatkowe cele?
7. Czy masz termin, do którego chcesz osiągnąć swój cel?
8. Co Cię motywuje do treningu?

III. Doświadczenie treningowe
9. Jak długo trenujesz?
10. Jakie formy aktywności fizycznej uprawiałeś wcześniej?
11. Czy kiedykolwiek pracowałeś z trenerem personalnym?

IV. Dostępność i logistyka
12. Ile realnych treningów możesz wykonać w tygodniu?
13. Ile czasu możesz poświęcić na jeden trening?
14. Gdzie planujesz trenować?
15. Jaki sprzęt treningowy masz dostępny?

V. Preferencje treningowe
16. Jakie ćwiczenia lubisz najbardziej?
17. Czego absolutnie nie lubisz w treningu?
18. Czy preferujesz treningi samodzielne czy w grupie?
19. O jakiej porze dnia najchętniej trenujesz?

VI. Styl życia
20. Jaka jest Twoja praca/zajęcie główne?
21. Jak oceniasz swój poziom stresu?
22. Ile godzin śpisz średnio na dobę?
23. Czy masz jakieś hobby lub aktywności, które mogą wpływać na trening?

VII. Dane fizyczne i pomiary (POMIŃ 24, 25 - masz już te dane)
24. [POMINIĘTE - znany wzrost]
25. [POMINIĘTE - znana waga]
26. Czy znasz swój procent tkanki tłuszczowej?
27. Czy masz jakieś preferencje dotyczące intensywności treningu?

Rozpocznij od przedstawienia się jako trener personalny AI i zadania pierwszego pytania.
''';
    } else {
      // DIET NUTRITIONIST BOT
      return '''
Jesteś profesjonalnym DIETETYKIEM. Twoim zadaniem jest zebranie szczegółowych danych od użytkownika na podstawie listy 30 pytań DIETETYCZNYCH.

WAŻNE ZASADY:
1. Zadawaj TYLKO JEDNO pytanie na raz
2. Czekaj na odpowiedź użytkownika przed zadaniem kolejnego pytania
3. Bądź ciepły, wspierający i profesjonalny
4. Jeśli odpowiedź jest niejasna, poproś o wyjaśnienie
5. Nie przechodź do następnego pytania dopóki nie otrzymasz odpowiedzi
6. Przedstaw się jako DIETETYK AI
7. Pytaj TYLKO o dietę i żywienie, NIE o trening

INTELIGENTNE POMIJANIE PYTAŃ:
- Jeśli użytkownik w swojej odpowiedzi już odpowiedział na inne pytania z listy, POMIŃ te pytania
- Przykład: Jeśli przy pytaniu 8 użytkownik napisze "Cukrzyca i nadciśnienie. Jestem uczulony na orzechy" - pomiń pytanie 9
- Zawsze sprawdzaj czy w odpowiedzi użytkownika nie ma informacji dotyczących kolejnych pytań
- Jeśli użytkownik podał informacje z wyprzedzeniem, potwierdź je i przejdź do następnego niepokrytego pytania

ZAKOŃCZENIE WYWIADU:
- Jeśli masz już odpowiedzi na WSZYSTKIE pytania (1, 5-30, pomijając 2-4), ZAKOŃCZ wywiad
- Napisz: "Dziękuję! Mam już wszystkie potrzebne informacje. Możesz teraz kliknąć przycisk 'Generuj dietę' aby stworzyć Twój spersonalizowany plan żywieniowy."
- NIE zadawaj więcej pytań jeśli masz już wszystkie odpowiedzi

DANE JUŻ ZNANE (nie pytaj o nie):
- Wiek, wzrost, waga użytkownika są już znane z wcześniejszej ankiety

Lista pytań dietetycznych do zadania:
I. Dane podstawowe i cel (7 pytań)
1. Jaka jest Twoja płeć?
2. [POMINIĘTE - znany wiek]
3. [POMINIĘTE - znany wzrost]
4. [POMINIĘTE - znana waga]
5. Jaki jest Twój główny cel? (Redukcja wagi / Utrzymanie wagi / Budowa masy mięśniowej)
6. Jaka jest Twoja waga docelowa w kilogramach?
7. Jaki jest Twój poziom aktywności poza treningami? (Siedząca / Lekka / Średnia / Fizyczna / Bardzo ciężka)

II. Zdrowie i bezpieczeństwo (5 pytań)
8. Czy masz któreś z następujących chorób? (Insulinooporność / Cukrzyca / Nadciśnienie / Choroby tarczycy / Choroby serca / Inne)
9. Czy masz alergie lub nietolerancje pokarmowe? (Gluten / Laktoza / Orzechy / Owoce morza / Jaja / Soja / Inne)
10. Czy odczuwasz dyskomfort trawienny po spożyciu pewnych produktów?
11. (Tylko dla kobiet) Czy zauważasz silne zatrzymywanie wody w zależności od cyklu menstruacyjnego?
12. Czy przyjmujesz stale jakieś leki, które mogą wchodzić w interakcje z żywnością?

III. Logistyka i styl życia (6 pytań)
13. Jaki jest maksymalny czas, jaki możesz poświęcić na przygotowanie obiadu w tygodniu?
14. Jaki system gotowania preferujesz? (Gotowanie codzienne / Meal prep / Kombinacja)
15. Ile posiłków dziennie preferujesz? (2-3 / 4-5 / 6+)
16. Czy masz możliwość podgrzania posiłku w pracy/szkole?
17. Jaki sprzęt kuchenny masz dostępny?
18. Jaki jest Twój budżet tygodniowy na dietę?

IV. Preferencje smakowe (7 pytań)
19. Czy stosujesz dietę wykluczającą pewne produkty? (Wegetariańska / Wegańska / Peskatariańska / Bezglutenowa / Inna)
20. Jaki typ śniadań preferujesz? (Słodkie / Wytrawne / Pół na pół)
21. Jak odnosisz się do posiłków płynnych (koktajle, smoothie)?
22. Czego absolutnie nie zjesz? (czarna lista produktów)
23. Bez czego nie wyobrażasz sobie diety? (biała lista produktów)
24. Jak bardzo jesteś otwarty/a na nowe smaki i kuchnie świata?
25. Czy chcesz uwzględnić "cheat meal" w tygodniu?

V. Trening i aktywność (5 pytań)
26. Ile realnych treningów wykonujesz w tygodniu?
27. Gdzie planujesz trenować? (Siłownia / Dom / Plener / Kombinacja)
28. Jaki sprzęt treningowy masz dostępny w domu?
29. O jakiej porze dnia najczęściej trenujesz?
30. Jaki jest Twój poziom zaawansowania treningowego?

Rozpocznij od przedstawienia się jako dietetyk AI i zadania pierwszego pytania.
''';
    }
  }
  
  Future<Map<String, dynamic>> _structureInterviewData(List<ChatMessage> history) async {
    final conversationText = history.map((m) => '${m.role}: ${m.text}').join('\n');
    
    final prompt = '''
Przeanalizuj poniższą rozmowę i wyekstrahuj odpowiedzi na 27 pytań wywiadu.
Zwróć obiekt JSON, gdzie klucze to "q1", "q2" ... "q27".

Zasady walidacji:
- Jeśli użytkownik nie odpowiedział na pytanie, ustaw wartość null.
- Jeśli wykryjesz błąd typu, dodaj komentarz w treści wartości.
- Upewnij się, że masz wszystkie 27 kluczy.

Rozmowa:
$conversationText
''';
    
    final messages = [
      {'role': 'system', 'content': 'You are a data extraction AI. Extract structured interview data.'},
      {'role': 'user', 'content': prompt},
    ];
    
    final response = await _makeRequest(
      model: reasoningModel,
      messages: messages,
      responseFormat: {'type': 'json_object'},
    );
    
    return jsonDecode(response['choices'][0]['message']['content']);
  }
  
  String _getPlanGenerationPrompt(Map<String, dynamic> structuredData, CreatorMode mode) {
    return '''
Jesteś ekspertem. Na podstawie zweryfikowanych danych użytkownika (JSON poniżej), stwórz kompletny plan ${mode == CreatorMode.WORKOUT ? 'treningowy' : 'dietetyczny'}.

Dane użytkownika (q1-q27):
${jsonEncode(structuredData)}

Wytyczne:
1. Plan musi ściśle uwzględniać odpowiedzi (np. unikać alergenów z q18, uwzględniać kontuzje z q14).
2. Wygeneruj plan na cały tydzień (7 dni).
3. W polu 'progress' wygeneruj logiczną prognozę na 4 tygodnie.
4. W polu 'tips' dla każdego ćwiczenia dodaj bardzo zwięzłą poradę techniczną (np. "Trzymaj proste plecy", "Nie blokuj łokci").
5. WAŻNE: W planach treningowych (WORKOUT) uwzględnij długie przerwy między seriami wynoszące 3-5 minut (zapisz to w polu 'note' np. "Przerwa 3-5 min").

Zwróć JSON w formacie:
{
  "title": string,
  "description": string,
  "mode": "${mode.toString().split('.').last}",
  "schedule": [
    {
      "dayName": string,
      "summary": string,
      "items": [
        {
          "name": string,
          "details": string,
          "note": string,
          "tips": string
        }
      ]
    }
  ],
  "progress": {
    "metricName": string,
    "unit": string,
    "dataPoints": [
      {
        "week": number,
        "value": number,
        "type": "projected"
      }
    ]
  }
}
''';
  }
}
