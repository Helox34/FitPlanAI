import 'dart:convert';
import '../core/models/models.dart';
import 'openrouter_service.dart';

/// Service for generating meal replacement alternatives
class MealReplacementService {
  final OpenRouterService _aiService = OpenRouterService();

  /// Generate 3 alternative meals for a given meal
  Future<List<PlanItem>> generateMealAlternatives({
    required PlanItem currentMeal,
    required Map<String, dynamic> userContext,
  }) async {
    try {
      print('🔄 Requesting meal alternatives from AI...');
      print('🍽️ Current meal: ${currentMeal.name}');
      
      final systemPrompt = '''
Jesteś ekspertem dietetyki. Twoim zadaniem jest zaproponować 3 BEZPIECZNE alternatywne posiłki które:
1. Mają podobną wartość kaloryczną (±100 kcal)
2. Uwzględniają kontekst użytkownika (alergie, preferencje, ograniczenia)
3. Są łatwe do przygotowania
4. Mają podobny profil makroskładników

KONTEKST UŻYTKOWNIKA:
${_formatUserContext(userContext)}

OBECNY POSIŁEK DO ZAMIANY:
Nazwa: ${currentMeal.name}
Szczegóły: ${currentMeal.details}
${currentMeal.note != null ? 'Wartości: ${currentMeal.note}' : ''}

ZASADY:
- Uwzględnij alergie i nietolerancje użytkownika
- Szanuj preferencje dietetyczne (wegańska, wegetariańska, etc.)
- Proponuj produkty dostępne w Polsce
- Zachowaj podobną porę dnia posiłku

FORMAT ODPOWIEDZI (STRICT JSON):
{
  "alternatives": [
    {
      "name": "Nazwa posiłku po polsku",
      "details": "Składniki i gramatura, np: 150g kurczaka, 80g ryżu, warzywa",
      "note": "Kalorie i makro: 520 kcal | B: 45g W: 52g T: 12g",
      "tips": "Krótka wskazówka przygotowania (max 15 słów)",
      "reason": "Dlaczego to dobra alternatywa"
    }
  ]
}
''';

      final response = await _aiService.sendInterviewMessage(
        [], // Empty history for single-shot request
        'Zaproponuj 3 bezpieczne alternatywy dla posiłku zgodnie z systemowym promptem.',
        CreatorMode.DIET, // Use diet mode context
      );

      // Parse JSON from response
      final responseJson = _parseJson(response);
      print('✅ AI response received');
      print('📋 Alternatives count: ${responseJson['alternatives']?.length ?? 0}');

      // Parse alternatives into PlanItem objects
      final alternatives = <PlanItem>[];
      final alternativesData = responseJson['alternatives'] as List? ?? [];

      for (var alt in alternativesData) {
        alternatives.add(PlanItem(
          name: alt['name'] ?? 'Alternatywny posiłek',
          details: alt['details'] ?? '',
          note: alt['note'],
          tips: alt['tips'],
        ));
      }

      print('✅ Parsed ${alternatives.length} alternative meals');
      return alternatives;
    } catch (e, stackTrace) {
      print('🔴 Meal Replacement Error: $e');
      print('🔴 Stack trace: $stackTrace');
      throw Exception('Nie udało się wygenerować alternatyw: $e');
    }
  }

  Map<String, dynamic> _parseJson(String content) {
    try {
      // Try to parse directly
      return jsonDecode(content);
    } catch (e) {
      // Fallback: Extract JSON if AI added text before/after
      final firstBrace = content.indexOf('{');
      final lastBrace = content.lastIndexOf('}');
      
      if (firstBrace != -1 && lastBrace != -1 && firstBrace < lastBrace) {
        final extracted = content.substring(firstBrace, lastBrace + 1);
        return jsonDecode(extracted);
      }
      rethrow;
    }
  }

  String _formatUserContext(Map<String, dynamic> context) {
    final buffer = StringBuffer();
    
    if (context.containsKey('allergies')) {
      buffer.writeln('Alergie: ${context['allergies']}');
    }
    if (context.containsKey('diet_type')) {
      buffer.writeln('Typ diety: ${context['diet_type']}');
    }
    if (context.containsKey('goal')) {
      buffer.writeln('Cel: ${context['goal']}');
    }
    if (context.containsKey('calories_target')) {
      buffer.writeln('Docelowe kalorie: ${context['calories_target']} kcal');
    }
    
    return buffer.toString();
  }
}
