import 'package:flutter/foundation.dart';
import '../core/models/models.dart';
import '../services/openrouter_service.dart';

/// Provider for managing AI chat/interview state
class ChatProvider with ChangeNotifier {
  final OpenRouterService _openRouterService = OpenRouterService();
  
  List<ChatMessage> _messages = [];
  bool _isLoading = false;
  CreatorMode _currentMode = CreatorMode.WORKOUT;
  bool _isInterviewComplete = false;
  
  List<ChatMessage> get messages => List.unmodifiable(_messages);
  bool get isLoading => _isLoading;
  CreatorMode get currentMode => _currentMode;
  bool get isInterviewComplete => _isInterviewComplete;
  
  /// Start a new interview with the specified mode
  Future<void> startInterview(CreatorMode mode, {int? userAge, double? userHeight, double? userWeight}) async {
    _currentMode = mode;
    _messages.clear();
    _isInterviewComplete = false;
    _isLoading = false;
    notifyListeners();
    
    // Build greeting with pre-answered information
    String greeting;
    if (mode == CreatorMode.WORKOUT) {
      greeting = 'Witaj! Jestem Twoim trenerem personalnym AI. Przeprowadzę Cię przez wywiad, aby stworzyć idealny plan treningowy dopasowany do Twoich potrzeb.\n\n';
      
      // Add pre-answered data
      if (userAge != null && userHeight != null && userWeight != null) {
        greeting += 'Widzę, że mam już podstawowe informacje o Tobie:\n';
        greeting += '- Wiek: $userAge lat\n';
        greeting += '- Wzrost: ${userHeight.toInt()} cm\n';
        greeting += '- Waga: ${userWeight.toInt()} kg\n\n';
        greeting += 'Dzięki temu możemy przejść od razu do szczegółowych pytań treningowych.\n\n';
      }
      
      greeting += 'Zacznijmy od pierwszego pytania:\n\n1. Czy chorujesz obecnie na jakieś choroby przewlekłe lub jesteś w trakcie leczenia?';
    } else {
      // DIET mode
      greeting = 'Witaj! Jestem Twoim dietetykiem AI. Przeprowadzę Cię przez wywiad, aby stworzyć idealny plan żywieniowy dopasowany do Twoich potrzeb.\n\n';
      
      // Add pre-answered data
      if (userAge != null && userHeight != null && userWeight != null) {
        greeting += 'Widzę, że mam już podstawowe informacje o Tobie:\n';
        greeting += '- Wiek: $userAge lat\n';
        greeting += '- Wzrost: ${userHeight.toInt()} cm\n';
        greeting += '- Waga: ${userWeight.toInt()} kg\n\n';
        greeting += 'Dzięki temu możemy przejść od razu do pytań o Twoje cele i preferencje żywieniowe.\n\n';
      }
      
      greeting += 'Zacznijmy od pierwszego pytania:\n\n1. Jaka jest Twoja płeć?';
    }
    
    final greetingMsg = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      role: 'model',
      text: greeting,
      timestamp: DateTime.now(),
    );
    
    _messages.add(greetingMsg);
    notifyListeners();
  }
  
  /// Send a message in the interview
  Future<void> sendMessage(String userMessage) async {
    if (_isLoading || userMessage.trim().isEmpty) return;
    
    // Add user message
    final userMsg = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      role: 'user',
      text: userMessage.trim(),
      timestamp: DateTime.now(),
    );
    
    _messages.add(userMsg);
    _isLoading = true;
    notifyListeners();
    
    try {
      // Get AI response
      final aiResponse = await _openRouterService.sendInterviewMessage(
        _messages,
        userMessage,
        _currentMode,
      );
      
      // Add AI message
      final aiMsg = ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        role: 'model',
        text: aiResponse,
        timestamp: DateTime.now(),
      );
      
      _messages.add(aiMsg);
      
      // Auto-complete interview if we have enough messages
      // Workout: 1 greeting + ~25 Q&A pairs = ~51 messages minimum
      // Diet: 1 greeting + ~27 Q&A pairs = ~55 messages minimum
      final minMessages = _currentMode == CreatorMode.WORKOUT ? 45 : 49;
      
      if (_messages.length >= minMessages && !_isInterviewComplete) {
        // Check if AI response indicates completion
        final lowerResponse = aiResponse.toLowerCase();
        if (lowerResponse.contains('wszystkie') && 
            (lowerResponse.contains('informacje') || lowerResponse.contains('potrzebne')) ||
            lowerResponse.contains('generuj plan') ||
            lowerResponse.contains('generuj dietę')) {
          _isInterviewComplete = true;
        }
      }
      
    } catch (e) {
      // Add error message
      final errorMsg = ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        role: 'model',
        text: 'Przepraszam, wystąpił błąd. Spróbuj ponownie.',
        timestamp: DateTime.now(),
      );
      _messages.add(errorMsg);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  /// Mark interview as complete
  void completeInterview() {
    _isInterviewComplete = true;
    notifyListeners();
  }
  
  /// Reset the chat
  void reset() {
    _messages.clear();
    _isLoading = false;
    _isInterviewComplete = false;
    notifyListeners();
  }
  
  /// Get interview history for plan generation
  List<ChatMessage> getInterviewHistory() {
    return List.from(_messages);
  }
}
