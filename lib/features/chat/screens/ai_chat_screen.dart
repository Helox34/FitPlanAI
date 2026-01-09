import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/models/models.dart';
import '../../../core/data/mock_data.dart';
import '../../../services/openrouter_service.dart';
import '../../../services/plan_service.dart';

class AIChatScreen extends StatefulWidget {
  const AIChatScreen({super.key});

  @override
  State<AIChatScreen> createState() => _AIChatScreenState();
}

class _AIChatScreenState extends State<AIChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = List.from(MockData.sampleChatMessages);
  final OpenRouterService _aiService = OpenRouterService();
  bool _isTyping = false;
  bool _isGeneratingPlan = false;
  String? _errorMessage;
  GeneratedPlan? _generatedPlan;

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      Future.delayed(const Duration(milliseconds: 100), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    final userMessage = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      role: 'user',
      text: _messageController.text.trim(),
      timestamp: DateTime.now(),
    );

    setState(() {
      _messages.add(userMessage);
      _messageController.clear();
      _isTyping = true;
      _errorMessage = null;
    });

    _scrollToBottom();

    try {
      // Call real OpenRouter AI service
      final aiResponseText = await _aiService.sendInterviewMessage(
        _messages,
        userMessage.text,
        CreatorMode.WORKOUT, // Default to workout mode
      );

      final aiResponse = ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        role: 'model',
        text: aiResponseText,
        timestamp: DateTime.now(),
      );

      setState(() {
        _messages.add(aiResponse);
        _isTyping = false;
      });

      _scrollToBottom();
    } catch (e) {
      setState(() {
        _isTyping = false;
        _errorMessage = 'Błąd połączenia z AI: ${e.toString()}';
      });
      
      // Add error message to chat
      final errorResponse = ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        role: 'model',
        text: 'Przepraszam, wystąpił błąd. Sprawdź czy API key jest poprawny w pliku .env',
        timestamp: DateTime.now(),
      );
      
      setState(() {
        _messages.add(errorResponse);
      });
      
      _scrollToBottom();
    }
  }

  Future<void> _finishInterviewAndGeneratePlan() async {
    setState(() {
      _isGeneratingPlan = true;
    });

    try {
      // Generate plan from interview history
      final plan = await _aiService.generatePlan(
        _messages,
        CreatorMode.WORKOUT, // Default to workout mode
      );

      setState(() {
        _generatedPlan = plan;
        _isGeneratingPlan = false;
      });

      // Save plan to persistent storage
      try {
        await PlanService.savePlan(plan);
      } catch (e) {
        print('Error saving plan: $e');
      }

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Plan zapisany! Tytuł: ${plan.title}'),
            backgroundColor: AppColors.success,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isGeneratingPlan = false;
        _errorMessage = 'Błąd generowania planu: ${e.toString()}';
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Błąd: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: AppColors.success,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            const Text('Wirtualny Trener (Wywiad)'),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.secondary,
                  AppColors.secondary.withOpacity(0.8),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.auto_awesome, size: 16),
                const SizedBox(width: 4),
                Text(
                  'Test',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textOnPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Messages List
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length + (_isTyping ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _messages.length && _isTyping) {
                  return _buildTypingIndicator();
                }

                final message = _messages[index];
                return _buildMessageBubble(message);
              },
            ),
          ),

          // Finish Interview Button (shows after 3+ user messages)
          if (_messages.where((m) => m.role == 'user').length >= 3 && _generatedPlan == null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                border: Border(
                  top: BorderSide(color: AppColors.border, width: 1),
                ),
              ),
              child: SafeArea(
                top: false,
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isGeneratingPlan ? null : _finishInterviewAndGeneratePlan,
                    icon: _isGeneratingPlan
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.textOnPrimary,
                            ),
                          )
                        : const Icon(Icons.check_circle, size: 20),
                    label: Text(
                      _isGeneratingPlan
                          ? 'Generowanie...'
                          : 'Wygeneruj plan',
                      style: const TextStyle(fontSize: 14),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      foregroundColor: AppColors.textOnPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ),
            ),

          // Show generated plan summary
          if (_generatedPlan != null)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.1),
                border: Border(
                  top: BorderSide(color: AppColors.success, width: 2),
                ),
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.check_circle, color: AppColors.success),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Plan wygenerowany!',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: AppColors.success,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _generatedPlan!.title,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _generatedPlan!.description,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Dni: ${_generatedPlan!.schedule.length}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                  ],
                ),
              ),
            ),

          // Input Area
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              boxShadow: [
                BoxShadow(
                  color: AppColors.shadow,
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: 'Twoja odpowiedź...',
                        filled: true,
                        fillColor: AppColors.surfaceVariant,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                      ),
                      minLines: 1,
                      maxLines: 5,
                      textCapitalization: TextCapitalization.sentences,
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primary,
                          AppColors.primary.withOpacity(0.8),
                        ],
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.send),
                      color: AppColors.textOnPrimary,
                      onPressed: _sendMessage,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    final isUser = message.isUser;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary,
                    AppColors.primary.withOpacity(0.8),
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.psychology,
                size: 20,
                color: AppColors.textOnPrimary,
              ),
            ),
            const SizedBox(width: 12),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isUser
                    ? AppColors.primary
                    : AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.shadow,
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                message.content,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: isUser
                          ? AppColors.textOnPrimary
                          : AppColors.textPrimary,
                    ),
              ),
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 12),
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.secondary,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.person,
                size: 20,
                color: AppColors.textOnPrimary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary,
                  AppColors.primary.withOpacity(0.8),
                ],
              ),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.psychology,
              size: 20,
              color: AppColors.textOnPrimary,
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppColors.shadow,
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDot(0),
                const SizedBox(width: 4),
                _buildDot(1),
                const SizedBox(width: 4),
                _buildDot(2),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDot(int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 600),
      builder: (context, value, child) {
        return Opacity(
          opacity: (value + index * 0.3) % 1.0,
          child: Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: AppColors.textTertiary,
              shape: BoxShape.circle,
            ),
          ),
        );
      },
    );
  }
}
