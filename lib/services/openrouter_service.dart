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
      
      String rawContent = response['choices'][0]['message']['content'];
      
      // FALLBACK: Extract JSON if AI added text before/after
      // Find first { and last }
      final firstBrace = rawContent.indexOf('{');
      final lastBrace = rawContent.lastIndexOf('}');
      
      if (firstBrace != -1 && lastBrace != -1 && firstBrace < lastBrace) {
        rawContent = rawContent.substring(firstBrace, lastBrace + 1);
        print('🟡 Extracted JSON from response (removed text prefix/suffix)');
      }
      
      final planJson = jsonDecode(rawContent);
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

**KRYTYCZNE - NIE POWTARZAJ HISTORII:**
- Twoja odpowiedź powinna zawierać TYLKO nowe pytanie i ewentualny krótki komentarz do ostatniej odpowiedzi
- NIE wypisuj listy wszystkich poprzednich odpowiedzi użytkownika
- NIE podsumowuj dotychczasowej rozmowy (chyba że użytkownik o to poprosi)
- Historia konwersacji jest zapisywana automatycznie - nie musisz jej powtarzać

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

**KRYTYCZNE - NIE POWTARZAJ HISTORII:**
- Twoja odpowiedź powinna zawierać TYLKO nowe pytanie i ewentualny krótki komentarz do ostatniej odpowiedzi
- NIE wypisuj listy wszystkich poprzednich odpowiedzi użytkownika
- NIE podsumowuj dotychczasowej rozmowy (chyba że użytkownik o to poprosi)
- Historia konwersacji jest zapisywana automatycznie - nie musisz jej powtarzać

INTELIGENTNE POMIJANIE PYTAŃ:
- Jeśli użytkownik w swojej odpowiedzi już odpowiedział na inne pytania z listy, POMIŃ te pytania
- Przykład: Jeśli przy pytaniu 8 użytkownik napisze "Cukrzyca i nadciśnienie. Jestem uczulony na orzechy" - pomiń pytanie 9
- Zawsze sprawdzaj czy w odpowiedzi użytkownika nie ma informacji dotyczących kolejnych pytań
- Jeśli użytkownik podał informacje z wyprzedzeniem, potwierdź je i przejdź do następnego niepokrytego pytania

ZAKOŃCZENIE WYWIADU:
- Jeśli masz już odpowiedzi na WSZYSTKIE pytania (5-30, pomijając 1-4), ZAKOŃCZ wywiad
- Napisz: "Dziękuję! Mam już wszystkie potrzebne informacje. Możesz teraz kliknąć przycisk 'Generuj dietę' aby stworzyć Twój spersonalizowany plan żywieniowy."
- NIE zadawaj więcej pytań jeśli masz już wszystkie odpowiedzi

DANE JUŻ ZNANE (nie pytaj o nie):
- Wiek, wzrost, waga użytkownika są już znane z wcześniejszej ankiety
- PŁEĆ jest również znana - NIE pytaj o płeć!

Lista pytań dietetycznych do zadania:
I. Dane podstawowe i cel (6 pytań - POMIŃ płeć!)
1. [POMINIĘTE - znana płeć z survey]
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
**CRITICAL: Your response MUST be ONLY valid JSON. Do NOT include any text before or after the JSON object. Start directly with { and end with }.**

**CRITICAL: Plan MUSI zawierać DOKŁADNIE 7 DNI (schedule array = 7 elements). Każdy dzień to "Dzień 1", "Dzień 2", ... "Dzień 7". To jest TYGODNIOWY plan żywieniowy, który zostanie powielony na cały miesiąc.**

Jesteś ekspertem dietetyki klinicznej i inżynierii żywieniowej. Twoja rola to stworzenie SPERSONALIZOWANEGO, NAUKOWO OPARTEGO planu dietetycznego na TYDZIEŃ, który nie jest zwykłym kalkulatorem kalorii, ale emuluje pełne wnioskowanie kliniczne (clinical reasoning).

DANE UŻYTKOWNIKA (zweryfikowane):
\${jsonEncode(structuredData)}

═══════════════════════════════════════════════════════════
📊 FUNDAMENT METABOLICZNY - ALGORYTMY ENERGETYCZNE
═══════════════════════════════════════════════════════════

KROK 1: OBLICZ PPM (Podstawowa Przemiana Materii - Basal Metabolic Rate)
Używaj WZORU MIFFLINA-ST JEORA (złoty standard kliniczny, błąd ±10%):

**Dla mężczyzn:**
PPM = (10 × Waga[kg]) + (6.25 × Wzrost[cm]) - (5 × Wiek) + 5

**Dla kobiet:**
PPM = (10 × Waga[kg]) + (6.25 × Wzrost[cm]) - (5 × Wiek) - 161

KROK 2: OBLICZ CPM (Całkowita Przemiana Materii - TDEE)
CPM = PPM × PAL (Physical Activity Level)

**Współczynniki PAL:**
- Siedzący tryb życia (brak aktywności): PAL = 1.2
- Lekka aktywność (1-3 treningi/tydzień): PAL = 1.375  
- Umiarkowana (3-5 treningów/tydzień): PAL = 1.55
- Wysoka (6-7 treningów/tydzień): PAL = 1.725
- Bardzo wysoka (2× dziennie): PAL = 1.9

KROK 3: USTAL CEL KALORYCZNY
- **Redukcja (utrata tkanki tłuszczowej):** CPM - 300 do -500 kcal (deficyt 15-25%)
- **Utrzymanie (rekomponozycja):** CPM ± 100 kcal
- **Masa (hipertrofia mięśniowa):** CPM + 200 do +500 kcal (nadwyżka 10-20%)

⚠️ **CRITICAL:** Błąd w PPM propaguje się na wszystkie kolejne obliczenia! Sprawdź płeć, wiek, wagę dokładnie.

═══════════════════════════════════════════════════════════
🥩 OPTYMALIZACJA MAKROSKŁADNIKÓW - EVIDENCE-BASED NUTRITION
═══════════════════════════════════════════════════════════

**BIAŁKO (Proteiny) - Priorytet #1:**
- **Redukcja:** 1.8-2.2 g/kg masy ciała (ochrona mięśni w deficycie)
- **Utrzymanie:** 1.6-1.8 g/kg
- **Masa:** 1.6-2.0 g/kg (więcej nie daje korzyści)
- **Źródła wysokowartościowe:** kurczak, indyk, łosoś, jaja, twaróg, serwatka
- **Biodostępność:** zwierzęce \u003e roślinne (kompletny profil aminokwasowy)

**TŁUSZCZE (Lipidy) - Podstawa hormonalna:**
- **Minimum fizjologiczne:** 0.8-1.0 g/kg (dla produkcji hormonów)
- **Optimal range:** 20-30% całkowitych kalorii
- **Priorytet:** kwasy omega-3 (EPA/DHA z ryb), MUFA (oliwa, awokado)
- **Unikaj:** trans-tłuszczów, nadmiaru omega-6

**WĘGLOWODANY (Carbohydrates) - Reszta kalorii:**
- Wypełniają pozostałe kalorie po ustaleniu białka i tłuszczów
- **Trening siłowy/intensywny:** 3-5 g/kg (paliwo glikogenowe)
- **Niska aktywność:** 2-3 g/kg
- **Źródła:** złożone (ryż, owsianka, ziemniaki), nie proste cukry

═══════════════════════════════════════════════════════════
🏥 PERSONALIZACJA KLINICZNA - DIETOTERAPIA
═══════════════════════════════════════════════════════════

Musisz BEZWZGLĘDNIE uwzględnić jednostki chorobowe i ograniczenia:

**INSULINOOPORNOŚĆ / Cukrzyca:**
- Niski indeks glikemiczny (IG \u003c55)
- Unikaj: białą mąkę, słodycze, sok
- Priorytet: błonnik, białko w każdym posiłku
- Częstotliwość: 4-5 małych posiłków (stabilizacja glukozy)

**HASHIMOTO / Niedoczynność tarczycy:**
- Unikaj: soja (bez fermentacji), gluten (jeśli nietolerancja), surowa brokuł/kalafior
- Priorytet: selen (orzechy brazylijskie), jod (ryby morskie), cynk
- Wzód: goitrogeny (kapustne) tylko gotowane

**IBS / Zespół Jelita Drażliwego:**
- DIETA LOW FODMAP (fermentowalne oligosacharydy)
- Eliminuj: cebula, czosnek, fasola, grzyby, jabłka, mleko laktoza
- Bezpieczne: ryż, kurczak, marchew, banan, bezlaktozowe nabiał

**ALERGIE POKARMOWE (z czatu użytkownika):**
- CAŁKOWICIE eliminuj alergeny (nie „ograniczaj")
- Sprawdź ukryte źródła (np. gluten w sosach)

**DIETY ELIMINACYJNE:**
- **Wegańska:** Suplementacja B12 OBOWIĄZKOWA, cynk, żelazo, omega-3 (algi DHA)
- **Wegetariańska:** Kontrola żelaza (heme vs non-heme), B12 z jaj/nabiału
- **Ketogeniczna:** \u003c50g węgli, 70-80% kcal z tłuszczów, ketoza po 2-4 dniach

═══════════════════════════════════════════════════════════
⏰ CHRONOBIOLOGIA ŻYWIENIA
═══════════════════════════════════════════════════════════

**Częstotliwość posiłków:**
- **Tradycyjny model:** 4-5 posiłków/dzień (kontrola głodu, stabilna glukoza)
- **Intermittent Fasting (IF):** okno 16:8 lub 18:6 (opcjonalne, jeśli użytkownik preferuje)
- **Nie ma „magii"** - liczy się CAŁKOWITA kaloryczność dnia

**Timing wokół treningu (jeśli aktywność wysoka):**
- Pre-workout (1-2h przed): węgle + białko (energia + anty-katabolizm)
- Post-workout (do 2h po): białko + węgle (okno anaboliczne - mit, ale wygodny timing)

═══════════════════════════════════════════════════════════
📋 IMPLEMENTACJA - TWORZENIE JADŁOSPISU
═══════════════════════════════════════════════════════════

Wytyczne strukturalne:
1. Plan na **7 DNI** (jeden tydzień) - tablica schedule MUSI mieć 7 elementów
2. Każdy dzień: 4-5 posiłków (śniadanie, II śniadanie, obiad, podwieczorek, kolacja)
3. **Gramatura konkretna** - np. "150g piersi kurczaka, 80g ryżu, 10ml oliwy"
4. **Kalorie i makro PER POSIŁEK** w polu note, np: "520 kcal | B: 45g W: 52g T: 12g"
5. **Tips:** Krótkie (max 10 słów), praktyczne, np: "Podgrzej 2 min mikrofalówce"
6. **Różnorodność:** Każdy dzień tygodnia powinien być unikalny
7. **Sezonowość i dostępność:** Polski rynek, produkty dostępne przez cały rok
8. **Zero waste:** Wykorzystuj składniki między dniami (np. kurczak dzień 1→sałatka dzień 2)
9. **Balans:** Tydzień powinien być zrównoważony pod kątem różnych źródeł białka i węglowodanów

═══════════════════════════════════════════════════════════
📈 PROGNOZY WAGI - SCIENTIFIC PROJECTIONS (CRITICAL!)
═══════════════════════════════════════════════════════════

**TY MUSISZ wygenerować realistyczną 12-tygodniową prognozę wagi w polu `progress.dataPoints`!**
**🚨 CRITICAL: CEL UŻYTKOWNIKA DYKTUJE KIERUNEK! 🚨**

KROK 1: ODCZYTAJ CEL UŻYTKOWNIKA Z DANYCH
- Szukaj w `structuredData` pola związanego z celem ("cel", "goal", "Jaki jest Twój główny cel")
- Możliwe wartości: "Redukcja wagi" / "Utrzymanie wagi" / "Budowa masy mięśniowej"

KROK 2: OBLICZ TYGODNIOWĄ ZMIANĘ WAGI

**Dla REDUKCJI (utrata wagi) - WARTOŚCI MALEJĄ ⬇️:**
- Deficyt: 300-500 kcal/dzień = 2100-3500 kcal/tydzień
- 1 kg tłuszczu ≈ 7700 kcal
- **Tygodniowa utrata:** 2100-3500 ÷ 7700 = 0.27-0.45 kg
- **Procentowo:** -0.5% do -1% masy/tydzień (MINUS!)
- **Przykład:** 80kg → 80 - 0.4 = 79.6 kg (tydzień 1), 79.6 - 0.4 = 79.2 kg (tydzień 2)

**Dla MASY (przyrost) - WARTOŚCI ROSNĄ ⬆️:**
- Nadwyżka: 200-500 kcal/dzień
- **Przyrost:** +0.25% do +0.5% masy/tydzień (PLUS!)
- **Przykład:** 70kg → 70 + 0.25 = 70.25 kg (tydzień 1), 70.25 + 0.25 = 70.5 kg (tydzień 2)

**Dla UTRZYMANIA:**
- Waga pozostaje stabilna ±0.3 kg (fluktuacje wody)

KROK 3: WYGENERUJ 12 DATA POINTS

Format JSON:
```json
"progress": {
  "dataPoints": [
    {"week": 1, "value": [OBLICZONA_WAGA_TYG_1], "type": "projected"},
    {"week": 2, "value": [OBLICZONA_WAGA_TYG_2], "type": "projected"},
    ...
    {"week": 12, "value": [OBLICZONA_WAGA_TYG_12], "type": "projected"}
  ]
}
```

**VALIDATION RULES:**
1. LINEAR progression - nie exponential!
2. 12 data points (weeks 1-12)
3. type MUSI być "projected"
4. **KIERUNEK musi być zgodny z celem:**
   - REDUKCJA: value[12] < value[1] < currentWeight ✅
   - MASA: value[12] > value[1] > currentWeight ✅
   - UTRZYMANIE: value[12] ≈ currentWeight ± 0.5 kg ✅

**PRZYKŁADY:**

Przykład 1 (REDUKCJA, 80kg, -0.4kg/tydzień):
- Week 1: 79.6 (80 - 0.4)
- Week 2: 79.2 (79.6 - 0.4)
- Week 3: 78.8 (79.2 - 0.4)
- Week 12: 75.2 (80 - 12*0.4) ✅ Spada!

Przykład 2 (MASA, 70kg, +0.3kg/tydzień):
- Week 1: 70.3 (70 + 0.3)
- Week 2: 70.6 (70.3 + 0.3)  
- Week 3: 70.9 (70.6 + 0.3)
- Week 12: 73.6 (70 + 12*0.3) ✅ Rośnie!

═══════════════════════════════════════════════════════════

**PRZYKŁAD STRUKTURY DNIA:**
{
  "dayName": "Dzień 1",
  "summary": "2100 kcal | B: 165g | W: 210g | T: 65g",
  "items": [
    {
      "name": "Owsianka proteinowa z owocami",
      "details": "60g płatków owsianych, 25g białka serwatkowego, 100g borówek, 10g migdałów",
      "note": "485 kcal | B: 32g W: 58g T: 12g",
      "tips": "Gotuj na mleku migdałowym"
    },
    // ... 3-4 kolejne posiłki
  ]
}

**Progress (Projekcja 4 tygodnie):**
- Redukcja: -0.5 do -1% masy/tydzień (np. 80kg → 78kg po 4 tyg)
- Masa: +0.25-0.5% masy/tydzień (np. 70kg → 71kg po 4 tyg)
- Utrzymanie: ±0.5kg (woda, glikogen)

═══════════════════════════════════════════════════════════
🚨 ZASADY BEZPIECZEŃSTWA
═══════════════════════════════════════════════════════════

1. NIE generuj deficytu \u003e25% (ryzyko zaburzeń metabolicznych)
2. Minimum 0.8g tłuszczu/kg (ochrona układu hormonalnego)
3. Sprawdź WSZYSTKIE alergeny z danych użytkownika.
4. Przy chorobach (Hashimoto, IBS) - dodaj DISCLAIMER: "Skonsultuj z dietetykiem klinicznym"

═══════════════════════════════════════════════════════════

Zwróć JSON w formacie:
{
  "title": string, // np. "Plan Redukcyjny 2100 kcal - Spersonalizowany"
  "description": string, // 2-3 zdania podsumowania (cel, podejście)
  "mode": "diet",
  "schedule": [
    {
      "dayName": string,
      "summary": string, // Suma makro/kcal dnia
      "items": [
        {
          "name": string,
          "details": string, // Gramatura składników
          "note": string, // Kaloryczność + makro posiłku
          "tips": string // Praktyczna wskazówka
        }
      ]
    }
  ],
  "progress": {
    "metricName": "Waga",
    "unit": "kg",
    "dataPoints": [
      { "week": 1, "value": number, "type": "projected" },
      { "week": 2, "value": number, "type": "projected" },
      { "week": 3, "value": number, "type": "projected" },
      { "week": 4, "value": number, "type": "projected" },
      { "week": 5, "value": number, "type": "projected" },
      { "week": 6, "value": number, "type": "projected" },
      { "week": 7, "value": number, "type": "projected" },
      { "week": 8, "value": number, "type": "projected" },
      { "week": 9, "value": number, "type": "projected" },
      { "week": 10, "value": number, "type": "projected" },
      { "week": 11, "value": number, "type": "projected" },
      { "week": 12, "value": number, "type": "projected" }
    ]
  }
}
''';
    }

    // WORKOUT PLAN LOGIC - UPDATED BASED ON "VOLUME LANDMARKS" & OPTIMIZATION DOCS
    // WORKOUT PLAN LOGIC - ADVANCED PROGRESSION SYSTEM (SCIENTIFIC EVIDENCE-BASED)
    return '''
**CRITICAL: Your response MUST be ONLY valid JSON. Do NOT include any text before or after the JSON object. Start directly with { and end with }.**

**CRITICAL: Plan MUSI zawierać DOKŁADNIE 14 DNI (schedule array = 14 elements). Każdy dzień to "Dzień 1", "Dzień 2", ... "Dzień 14". Workout plans pozostają 2-tygodniowe.**

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
