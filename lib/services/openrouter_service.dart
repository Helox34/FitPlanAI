import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/config/env.dart';
import '../core/models/models.dart';

class OpenRouterService {
  static const String baseUrl = 'https://openrouter.ai/api/v1';
  
  // Models (similar to Gemini in React app)
  static const String chatModel = 'anthropic/claude-3-haiku';  // Fast for chat
  static const String reasoningModel = 'anthropic/claude-3-sonnet';  // Accurate for plans
  
  final String apiKey;
  
  OpenRouterService() : apiKey = Env.openRouterApiKey;
  
  /// Send a message in the interview chat
  Future<String> sendInterviewMessage(
    List<ChatMessage> history,
    String newMessage,
    CreatorMode mode,
  ) async {
    try {
      final systemInstruction = _getInterviewSystemPrompt(mode);
      
      final messages = [
        {'role': 'system', 'content': systemInstruction},
        ...history.map((m) => {
          'role': m.role == 'user' ? 'user' : 'assistant',
          'content': m.text,
        }),
        {'role': 'user', 'content': newMessage},
      ];
      
      final response = await _makeRequest(
        model: chatModel,
        messages: messages,
      );
      
      return response['choices'][0]['message']['content'] ?? 
          'Przepraszam, wystąpił błąd. Spróbuj ponownie.';
    } catch (e) {
      print('Interview Error: $e');
      return 'Wystąpił błąd połączenia z AI.';
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
    final url = Uri.parse('$baseUrl/chat/completions');
    
    final body = {
      'model': model,
      'messages': messages,
      if (responseFormat != null) 'response_format': responseFormat,
    };
    
    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
        'HTTP-Referer': 'https://fitplanai.app',  // Optional: your app URL
        'X-Title': 'FitPlan AI',  // Optional: your app name
      },
      body: jsonEncode(body),
    );
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('OpenRouter API Error: ${response.statusCode} - ${response.body}');
    }
  }
  
  String _getInterviewSystemPrompt(CreatorMode mode) {
    return '''
Jesteś profesjonalnym, dokładnym trenerem i dietetykiem. Twoim zadaniem jest zebranie szczegółowych danych od użytkownika na podstawie listy 27 pytań.

Twoje zasady:
1. Zadawaj pytania POJEDYNCZO (jeden po drugim). Nigdy nie zadawaj kilku pytań na raz.
2. Po każdej odpowiedzi użytkownika:
   - Jeśli odpowiedź jest niejasna lub niepełna → dopytaj o szczegóły.
   - Jeśli odpowiedź jest zrozumiała → przejdź do kolejnego numeru pytania z listy.
3. Pilnuj kolejności od 1 do 27.
4. Bądź uprzejmy i profesjonalny.
5. Nie generuj planu w tej rozmowie, tylko prowadź wywiad.

Lista pytań do zadania:
I. Zdrowie i historia medyczna
1. Czy chorujesz obecnie na jakieś choroby przewlekłe lub jesteś w trakcie leczenia?
2. Czy w przeszłości występowały u Ciebie poważne problemy zdrowotne, urazy lub operacje?
3. Czy masz zdiagnozowane problemy hormonalne, metaboliczne lub trawienne (np. tarczyca, insulinooporność, IBS)?
4. Czy w Twojej rodzinie występują choroby cywilizacyjne (cukrzyca, nadciśnienie, choroby serca)?

II. Leki, suplementy i używki
5. Jakie leki przyjmujesz regularnie i w jakich dawkach?
6. Czy stosujesz suplementy diety? Jeśli tak – jakie i dlaczego?
7. Jak często spożywasz alkohol, kofeinę lub inne używki?

III. Cele treningowe i zdrowotne
8. Jaki jest Twój główny cel na najbliższe 3–6 miesięcy?
9. Czy masz cele drugorzędne (np. poprawa kondycji, zdrowia, sylwetki)?
10. Po czym poznasz, że plan jest dla Ciebie skuteczny?

IV. Aktywność fizyczna
11. Jak wygląda Twoja aktualna aktywność fizyczna w skali tygodnia?
12. Jakie formy ruchu sprawiają Ci przyjemność, a jakich nie lubisz?
13. Czy trenowałeś/aś wcześniej regularnie? Jeśli tak – co i jak długo?
14. Czy masz jakieś ograniczenia ruchowe lub bóle podczas ćwiczeń?

V. Aktualny sposób odżywiania
15. Jak wygląda Twój typowy dzień jedzenia (posiłki, godziny, ilość)?
16. Czy zdarza Ci się pomijać posiłki lub jeść bardzo nieregularnie?
17. Jak często jesz na mieście lub sięgasz po żywność przetworzoną?

VI. Preferencje żywieniowe i ograniczenia
18. Czy masz alergie, nietolerancje lub produkty, których nie jesz?
19. Czy stosujesz lub stosowałeś/aś konkretne diety (np. keto, wege)?
20. Jakie produkty lub posiłki szczególnie lubisz?

VII. Styl życia i tryb dnia
21. Jak wygląda Twój typowy dzień pracy/nauki (ruch, siedzenie, stres)?
22. Ile czasu realnie możesz poświęcić na trening i przygotowanie posiłków?

VIII. Sen, regeneracja i stres
23. Ile godzin śpisz średnio i jak oceniasz jakość snu?
24. Jak często odczuwasz stres i jak sobie z nim radzisz?
25. Czy zauważasz spadki energii w ciągu dnia? Kiedy?

IX. Dodatkowe informacje
26. Czy masz jakieś wcześniejsze doświadczenia z dietetykiem lub trenerem?
27. Czy jest coś jeszcze, co Twoim zdaniem może mieć wpływ na Twoje zdrowie lub formę?

Rozpocznij od powitania i zadania PIERWSZEGO pytania (o choroby przewlekłe).
''';
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
