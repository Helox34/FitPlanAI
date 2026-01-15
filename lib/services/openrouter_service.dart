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
        temperature: 0.4,
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
        temperature: 0.2,
        timeout: const Duration(seconds: 420), // 7 minutes for 14-day plans
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
        temperature: 0.2,
      );
      
      final resultJson = jsonDecode(response['choices'][0]['message']['content']);
      return ModificationResult.fromJson(resultJson);
    } catch (e) {
      print('Plan Modification Error: $e');
      throw Exception('Failed to modify plan: $e');
    }
  }
  
  /// Modify single exercise with AI suggestions based on user context
  Future<List<PlanItem>> modifyExercise({
    required PlanItem currentExercise,
    required String userRequest,
    required Map<String, dynamic> userContext,
  }) async {
    try {
      print('🔄 Requesting exercise modification from AI...');
      print('📝 User request: $userRequest');
      print('👤 User context keys: ${userContext.keys.toList()}');
      
      final systemPrompt = '''
Jesteś ekspertem inżynierii treningowej (S&C Coach) w aplikacji FitPlan AI.
Twoim zadaniem jest zaproponować 2-3 BEZPIECZNE alternatywne ćwiczenia, które:
1. Są zgodne z zasadami naukowego treningu (Volume Landmarks, Progressive Overload)
2. Uwzględniają pełny kontekst użytkownika (zdrowie, kontuzje, sprzęt)
3. Zachowują spójność z aktualnym planem treningowym

KONTEKST UŻYTKOWNIKA:
${jsonEncode(userContext)}

OBECNE ĆWICZENIE DO ZAMIANY:
Nazwa: ${currentExercise.name}
Detale: ${currentExercise.details}
${currentExercise.tips != null ? 'Wskazówki: ${currentExercise.tips}' : ''}

PROŚBA UŻYTKOWNIKA: "$userRequest"

═══════════════════════════════════════════════════════════════
FUNDAMENTY LOGIKI (CRITICAL RULES - BEZPIECZEŃSTWO I NAUKA)
═══════════════════════════════════════════════════════════════

1. **BEZPIECZEŃSTWO (Priorytet #1):**
   - NIE proponuj ćwiczeń obciążających części ciała z 'injuries'
   - NIE proponuj ćwiczeń sprzecznych z 'limitations'
   - Jeśli health_conditions zawiera choroby (cukrzyca, astma), wybieraj ćwiczenia niskointensywne
   - Przy kontuzjach ZAWSZE preferuj izolację nad ćwiczenia złożone

2. **VOLUME LANDMARKS (Dr. Mike Israetel):**
   Proponowane ćwiczenia muszą mieścić się w odpowiednich ramach objętości:
   - **Klatka**: MEV: 8, MAV: 12-16, MRV: 22 serie/tydzień
   - **Plecy**: MEV: 10, MAV: 14-22, MRV: 25
   - **Nogi (Czworogłowe)**: MEV: 8, MAV: 12-18, MRV: 20
   - **Pośladki/Dwugłowe**: MEV: 6, MAV: 10-16
   - **Barki**: MEV: 8, MAV: 16-22
   - **Ramiona**: MEV: 8, MAV: 12-20
   
   *Początkujący (\u003c1 rok): trzymaj się MEV. Zaawansowani: celuj w MAV.*

3. **PROGRESSIVE OVERLOAD (Model Progresji):**
   - **Początkujący**: Linear Progression - stałe 3x5 lub 3x8, +2.5kg/+5kg co sesję
   - **Średniozaawansowani**: Dynamic Double Progression - zakres powt (8-12), najpierw reps, potem waga
   - W alternatywach używaj **tego samego modelu** co obecne ćwiczenie (jeśli możliwe)

4. **PLATE MATH (Realizm Obciążeń):**
   - NIE sugeruj ciężarów jak "31.7 kg" lub "17.3 kg"
   - Używaj skoków: 1.25kg, 2.5kg, 5kg
   - Hantle: co 2.5kg (15kg, 17.5kg, 20kg)
   - Jeśli nie można zwiększyć ciężaru → zwiększ powtórzenia lub zmniejsz przerwy

5. **JUNK VOLUME (Unikaj Śmieciowej Objętości):**
   - Max 8-10 ciężkich serii na partię w jednej sesji
   - Uwzględniaj liczenie pośrednie (Wyciskanie = Klatka + 0.5 Triceps + 0.5 Bark Przedni)
   - Jeśli zamiana zwiększa objętość \u003e MRV → OSTRZEŻ użytkownika

6. **SPRZĘT I DOSTĘPNOŚĆ:**
   - 'equipment' pokazuje co user ma dostępne
   - Jeśli "home_basic" → proponuj bodyweight, hantle, gumy
   - Jeśli "full_gym" → wszystko dostępne
   - Zawsze zaproponuj przynajmniej JEDNĄ opcję z dostępnym sprzętem

═══════════════════════════════════════════════════════════════
PRZYKŁADY INTELIGENTNYCH ZAMIAN
═══════════════════════════════════════════════════════════════

**Kontuzja kolana + Przysiad:**
✅ DOBRZE: Hip Thrust, Martwy Ciąg Rumuński, Mostek Biodrowy
❌ ŹLE: Wykroki, Przysiady Bułgarskie (nadal obciążają kolano)

**Brak sztangi + Wyciskanie:**
✅ DOBRZE: Wyciskanie Hantli, Pompki z Obciążeniem, Rozpiętki
❌ ŹLE: Wyciskanie Sztangą (user nie ma!)

**Początkujący + Ciężkie ćwiczenie:**
✅ DOBRZE: Wersja maszynowa, Ćwiczenie z asystą, Regresja (np. Pompki z kolan)
❌ ŹLE: Jeszcze trudniejszy wariant

**Zaawansowany + "Zbyt łatwe":**
✅ DOBRZE: Dodaj pauzę izometryczną, Zwiększ zakres ruchu, Dodaj tempo
❌ ŹLE: Po prostu więcej serii (może przekroczyć MRV)

═══════════════════════════════════════════════════════════════
FORMAT ODPOWIEDZI (STRICT JSON)
═══════════════════════════════════════════════════════════════

{
  "alternatives": [
    {
      "name": "Dokładna nazwa ćwiczenia po polsku",
      "details": "3 serie x 8-12 powtórzeń @ RPE 7-8 | Przerwa 90s",
      "tips": "Model: DDP. Tempo 3010. [Krótka wskazówka techniczna]",
      "reason": "Dlaczego to ćwiczenie jest zgodne z kontekstem użytkownika i zasadami naukowymi (Volume Landmarks + bezpieczeństwo)",
      "volume_impact": "Dodaje X serii na [partia]. User w MAV/MEV/MRV",
      "progression_note": "LP/DDP - szczegóły progresji"
    }
  ],
  "safety_notes": "Dodatkowe ostrzeżenia dotyczące zdrowia/kontuzji (jeśli są)",
  "volume_warning": "OSTRZEŻENIE jeśli zmiana może przekroczyć MRV lub naruszyć Junk Volume (null jeśli OK)"
}

═══════════════════════════════════════════════════════════════
ZASADY DECISION-MAKING
═══════════════════════════════════════════════════════════════

1. SAFETY FIRST: Lepiej zaproponować łatwiejsze ćwiczenie niż ryzykować kontuzję.
2. SCIENCE SECOND: Alternatywy muszą mieć sens z punktu widzenia Volume Landmarks i Progressive Overload.
3. CONTEXT THIRD: Uwzględnij goals, equipment, fitness_level.
4. USER INTENT LAST: Jeśli user prosi o coś niebezpiecznego/nieefektywnego → zaproponuj bezpieczniejszą wersję + wyjaśnij dlaczego.

Jeśli nie możesz znaleźć 2-3 bezpiecznych alternatyw (np. wszystkie opcje konfliktują z kontuzjami), zwróć 1 opcję + szczegółowe wyjaśnienie w safety_notes.
''';
      
      final messages = [
        {'role': 'system', 'content': systemPrompt},
        {'role': 'user', 'content': 'Zaproponuj bezpieczne alternatywy.'},
      ];
      
      final response = await _makeRequest(
        model: reasoningModel,
        messages: messages,
        responseFormat: {'type': 'json_object'},
        temperature: 0.3, // Slightly higher for creativity in alternatives
        timeout: const Duration(seconds: 60),
      );
      
      final responseJson = jsonDecode(response['choices'][0]['message']['content']);
      print('✅ AI response received');
      print('📋 Alternatives count: ${responseJson['alternatives']?.length ?? 0}');
      
      // Check for volume warning from AI
      final volumeWarning = responseJson['volume_warning'];
      if (volumeWarning != null && volumeWarning.toString().isNotEmpty) {
        print('⚠️ Volume Warning: $volumeWarning');
      }
      
      // Parse alternatives into PlanItem objects
      final alternatives = <PlanItem>[];
      final alternativesData = responseJson['alternatives'] as List? ?? [];
      
      for (var alt in alternativesData) {
        // Build comprehensive tips combining all information
        final tipsComponents = <String>[];
        
        if (alt['tips'] != null) {
          tipsComponents.add(alt['tips']);
        }
        
        if (alt['progression_note'] != null) {
          tipsComponents.add('📊 ${alt['progression_note']}');
        }
        
        if (alt['volume_impact'] != null) {
          tipsComponents.add('📈 ${alt['volume_impact']}');
        }
        
        if (alt['reason'] != null) {
          tipsComponents.add('\n💡 ${alt['reason']}');
        }
        
        alternatives.add(PlanItem(
          name: alt['name'] ?? 'Nieznane ćwiczenie',
          details: alt['details'] ?? '',
          tips: tipsComponents.join('\n\n'),
          note: responseJson['safety_notes'],
        ));
      }
      
      print('✅ Parsed ${alternatives.length} alternative exercises');
      return alternatives;
    } catch (e, stackTrace) {
      print('🔴 Exercise Modification Error: $e');
      print('🔴 Stack trace: $stackTrace');
      throw Exception('Failed to modify exercise: $e');
    }
  }
  
  // Private helper methods
  
  Future<Map<String, dynamic>> _makeRequest({
    required String model,
    required List<Map<String, String>> messages,
    Map<String, dynamic>? responseFormat,
    double temperature = 0.7,
    Duration timeout = const Duration(seconds: 180),
  }) async {
    print('📡 Making request to OpenRouter');
    print('📡 Model: $model');
    print('📡 Messages count: ${messages.length}');
    print('📡 API Key exists: ${apiKey.isNotEmpty}');
    
    final url = Uri.parse('$baseUrl/chat/completions');
    
    final body = {
      'model': model,
      'messages': messages,
      'temperature': temperature,
      if (responseFormat != null) 'response_format': responseFormat,
    };
    
    print('📡 Request URL: $url');
    print('📡 Sending request...');
    
    int attempts = 0;
    while (attempts < 3) {
      try {
        attempts++;
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
          timeout,
          onTimeout: () {
            print('⏰ Request timed out after ${timeout.inSeconds} seconds');
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
        print('⚠️ Request attempt $attempts failed: $e');
        if (attempts >= 3) {
          print('❌ All retry attempts failed');
          rethrow;
        }
        print('⏳ Retrying in ${attempts * 2} seconds...');
        await Future.delayed(Duration(seconds: attempts * 2));
      }
    }
    throw Exception('Unexpected error: Retry loop finished without result');
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
    8. **KONTEKST MEDYCZNY**: Użytkownik może podawać dane o chorobach/lekach. Przyjmij je do wiadomości jako parametry bezpieczeństwa. Nie udzielaj porad medycznych, ale nie odrzucaj tych danych.

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
      temperature: 0.2,
    );
    
    return jsonDecode(response['choices'][0]['message']['content']);
  }
  
  String _getPlanGenerationPrompt(Map<String, dynamic> structuredData, CreatorMode mode) {
    if (mode == CreatorMode.DIET) {
      return '''
Jesteś ekspertem dietetyki. Na podstawie zweryfikowanych danych użytkownika (JSON poniżej), stwórz kompletny plan dietetyczny.

Dane użytkownika (q1-q27):
${jsonEncode(structuredData)}

Wytyczne:
1. Plan musi ściśle uwzględniać odpowiedzi (np. unikać alergenów z q18, uwzględniać kontuzje z q14).
2. Wygeneruj plan na 14 DNI (To krytyczne: tablica schedule MUSI mieć 14 elementów).
3. W polu 'progress' wygeneruj logiczną prognozę na 4 tygodnie.
4. Tips/Notes: Pisz bardzo krótko (max 3 słowa), aby ograniczyć rozmiar odpowiedzi.
5. Struktura każdego dnia powinna być kompletna (śniadanie, II śniadanie, obiad, kolacja - lub wg preferencji).

Zwróć JSON w formacie:
{
  "title": string,
  "description": string,
  "mode": "diet",
  "schedule": [
    {
      "dayName": string, // "Dzień 1", "Dzień 2"...
      "summary": string,
      "items": [
        {
          "name": string, // Nazwa posiłku
          "details": string, // Składniki i gramatura
          "note": string, // Kaloryczność/Makro
          "tips": string // Krótka porada
        }
      ]
    }
  ],
  "progress": {
    "metricName": "Waga",
    "unit": "kg",
    "dataPoints": [{ "week": number, "value": number, "type": "projected" }]
  }
}
''';
    }

    // WORKOUT PLAN LOGIC - UPDATED BASED ON "VOLUME LANDMARKS" & OPTIMIZATION DOCS
    // WORKOUT PLAN LOGIC - ADVANCED PROGRESSION SYSTEM (SCIENTIFIC EVIDENCE-BASED)
    return '''
Jesteś ekspertem inżynierii treningowej (S&C Coach) i głównym architektem systemu progresji w aplikacji FitPlan AI.
Twój cel: Stworzyć "żywy", adaptacyjny plan treningowy na 14 DNI (2 mikrocykle), który zmusi organizm użytkownika do rozwoju (Progressive Overload), unikając stagnacji i "śmieciowej objętości" (Junk Volume).

DANE UŻYTKOWNIKA (Context):
${jsonEncode(structuredData)}

FUNDAMENTY LOGIKI (CRITICAL RULES - DO NOT BREAK):

1. **VOLUME LANDMARKS (Punkty Orientacyjne Objętości - Dr. Mike Israetel):**
   Musisz dostosować liczbę serii roboczych (tygodniowo/partię) do tych sztywnych ram:
   - **Klatka Piersiowa**: MEV: 8, MAV: 12-16, MRV: 22.
   - **Plecy (Grzbiet)**: MEV: 10, MAV: 14-22, MRV: 25 (Duża odporność).
   - **Nogi (Czworogłowe)**: MEV: 8, MAV: 12-18, MRV: 20 (Wysoki koszt systemowy).
   - **Pośladki/Dwugłowe**: MEV: 6, MAV: 10-16.
   - **Barki (Bok/Tył)**: MEV: 8, MAV: 16-22 (Szybka regeneracja).
   - **Ramiona**: MEV: 8, MAV: 12-20.
   *Jeśli użytkownik jest początkujący (<1 rok), trzymaj się MEV. Jeśli zaawansowany, celuj w górne granice MAV.*

2. **MODEL PROGRESJI (Algorytm Doboru Obciążeń):**
   - **Dla Początkujących (Novice): LINEAR PROGRESSION (LP)**
     - Logika: "W każdym treningu dodaj ciężar, jeśli technika jest poprawna."
     - Strategia: Stałe 3x5 lub 3x8 na ćwiczeniach głównych.
     - Przyrost (Tydzień 2): +2.5kg (Góra) / +5kg (Dół).
   
   - **Dla Średniozaawansowanych (Intermediate): DYNAMIC DOUBLE PROGRESSION (DDP)**
     - Logika: "Najpierw buduj powtórzenia, potem ciężar. Każda seria żyje własnym życiem."
     - Strategia: Zakres powtórzeń (np. 8-12). Gdy w pierwszej serii zrobisz 12 -> zwiększ ciężar.
     - Przyrost (Tydzień 2): Symuluj progresję (np. Tydzień 1: 50kg x 12,10,9 -> Tydzień 2: 52.5kg x 8,8,8).

3. **ZASADA "JUNK VOLUME" & FRAKTALNE ZLICZANIE:**
   - **Limit Sesyjny:** Max 8-10 ciężkich serii na partię w jednej sesji. Jeśli więcej -> podziel na 2 dni (Góra/Dół lub PPL).
   - **Liczenie Pośrednie:** 
     - Wyciskanie Leżąc = 1 seria Klatki + 0.5 serii Tricepsa + 0.5 serii Przedniego Barku.
     - Podciąganie = 1 seria Pleców + 0.5 serii Bicepsa.
     - *Nie przepisuj 15 serii na bicepsy po dniu pleców!*

4. **MATEMATYKA TALERZY (Plate Math - Realizm):**
   - Nie sugeruj ciężarów typu "31.7 kg".
   - Używaj skoków: 1.25kg, 2.5kg, 5kg.
   - Hantle: Skoki co 2.5kg (np. 15kg, 17.5kg, 20kg).
   - Jeśli skok ciężaru jest niemożliwy (np. wznosy bokiem), zwiększaj powtórzenia lub skracaj przerwy (Density).

5. **WYMAGANIA OBJĘTOŚCI NA SESJĘ (CRITICAL - DO NOT IGNORE):**
   Volume Landmarks (MEV/MAV/MRV) to limity TYGODNIOWE, nie per-sesję!
   
   Każdy dzień treningowy MUSI zawierać odpowiednią ilość ćwiczeń:
   
   **Początkujący (<1 rok doświadczenia):**
   - 4-5 ćwiczeń GŁÓWNYCH
   - 3 serie każde
   - TOTAL: 12-15 serii roboczych/sesję
   - Czas trwania: 45-60 minut
   
   **Średniozaawansowani (1-3 lata):**
   - 5-7 ćwiczeń
   - 3-4 serie każde
   - TOTAL: 18-25 serii roboczych/sesję
   - Czas trwania: 60-75 minut
   
   **Zaawansowani (>3 lata):**
   - 6-9 ćwiczeń
   - 3-5 serii każde
   - TOTAL: 22-35 serii roboczych/sesję
   - Czas trwania: 75-90 minut
   
   **JAK DZIELIĆ WEEKLY VOLUME:**
   - 3 sesje/tydzień → każda sesja = ~33% weekly volume
   - 4 sesje/tydzień → każda sesja = ~25% weekly volume
   - 5 sesji/tydzień → każda sesja = ~20% weekly volume
   
   **PRZYKŁAD dla intermediate, 3 sesje/tydzień, MAV=16 serii/tydzień na klatkę:**
   - Sesja 1 (Push): 5-6 serii klatki
   - Sesja 2 (Pull): 0 serii klatki
   - Sesja 3 (Push): 5-6 serii klatki
   - TOTAL: 10-12 serii klatki/tydzień ✅ (bliskie MAV)
   
   **WALIDACJA:** 
   Jeśli plan treningowy zawiera <10 serii/sesję → TO BŁĄD! Za mało!
   Jeśli plan treningowy zawiera >40 serii/sesję → TO BŁĄD! Za dużo!

FORMAT JSON (Ściśle przestrzegaj):
{
  "title": string, // Np. "Hipertrofia: Faza Akumulacji (DDP)"
  "description": string, // Krótkie wyjaśnienie strategii, np. "Zastosowano Dynamic Double Progression. Priorytet na Klatkę."
  "mode": "workout",
  "schedule": [
    {
      "dayName": string, // "Dzień 1 - Siła Góry", "Dzień 2 - Hipertrofia Dołu"...
      "summary": string, // Cel dnia
      "items": [
        {
          "name": string, // "Przysiad ze sztangą (High-bar)"
          "details": string, // "3 serie x 6-8 powt @ RPE 8" (Używaj RPE)
          "note": string, // "Tempo 3010 | Przerwa 3 min"
          "tips": string, // "Model: LP. Dodaj 2.5kg jeśli zrobisz 8 powt."
          "videoUrl": string // Opcjonalnie URL do wideo (pozostaw puste lub null jeśli niepewne)
        }
      ]
    }
  ],
  "progress": {
    "metricName": "Siła Relatywna (Total)",
    "unit": "kg",
    "dataPoints": [] 
  }
}

Wygeneruj plan na 14 DNI (Schedule musi mieć tablicę 14 elementów). Dni nietreningowe oznacz jako "Odpoczynek" w dayName.
Tydzień 2 ma symulować progresję względem Tygodnia 1 (np. zwiększony ciężar lub liczba powtórzeń).

PAMIĘTAJ: Każdy dzień TRENINGOWY musi mieć 12-35 serii w zależności od poziomu użytkownika!
''';
  }
}
