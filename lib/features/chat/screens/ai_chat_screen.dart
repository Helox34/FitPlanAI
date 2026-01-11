import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/models/models.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../providers/chat_provider.dart';
import '../../../providers/plan_provider.dart';
import '../../../providers/user_provider.dart';
import '../../../core/widgets/loading_overlay.dart';

/// AI Chat Screen for conducting interviews
class AIChatScreen extends StatefulWidget {
  final CreatorMode mode;
  
  const AIChatScreen({
    super.key,
    required this.mode,
  });

  @override
  State<AIChatScreen> createState() => _AIChatScreenState();
}

class _AIChatScreenState extends State<AIChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isGeneratingPlan = false;
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userProvider = context.read<UserProvider>();
      context.read<ChatProvider>().startInterview(
        widget.mode,
        userAge: userProvider.age,
        userHeight: userProvider.height,
        userWeight: userProvider.weight,
      );
    });
  }
  
  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
  
  void _sendMessage() {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;
    
    _messageController.clear();
    context.read<ChatProvider>().sendMessage(message);
    
    // Scroll to bottom after sending
    Future.delayed(const Duration(milliseconds: 300), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }
  
  Future<void> _finishInterview() async {
    final chatProvider = context.read<ChatProvider>();
    final planProvider = context.read<PlanProvider>();
    
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(widget.mode == CreatorMode.WORKOUT 
            ? 'Generuj plan treningowy' 
            : 'Generuj plan dietetyczny'),
        content: Text(
          widget.mode == CreatorMode.WORKOUT
              ? 'Czy na pewno chcesz wygenerować plan treningowy na podstawie zebranych informacji? '
                'Proces generowania może potrwać 30-60 sekund.'
              : 'Czy na pewno chcesz wygenerować plan dietetyczny na podstawie zebranych informacji? '
                'Proces generowania może potrwać 30-60 sekund.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Anuluj'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Generuj'),
          ),
        ],
      ),
    );
    
    if (confirmed != true) return;
    
    setState(() {
      _isGeneratingPlan = true;
    });
    
    final history = chatProvider.getInterviewHistory();
    final success = await planProvider.generatePlan(history, widget.mode);
    
    setState(() {
      _isGeneratingPlan = false;
    });
    
    if (success && mounted) {
      chatProvider.completeInterview();
      
      // Show success dialog
      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Plan wygenerowany!'),
          content: Text(
            widget.mode == CreatorMode.WORKOUT
                ? 'Twój plan treningowy jest gotowy! Sprawdź go w zakładce "Mój Plan".'
                : 'Twój plan dietetyczny jest gotowy! Sprawdź go w zakładce "Moja Dieta".',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } else if (mounted) {
      // Show error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(planProvider.generationError ?? 'Wystąpił błąd'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: colorScheme.onSurface),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          widget.mode == CreatorMode.WORKOUT ? 'Wywiad treningowy' : 'Wywiad dietetyczny',
          style: TextStyle(
            color: colorScheme.onSurface,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          Consumer<ChatProvider>(
            builder: (context, chatProvider, child) {
              // Show button if interview is complete OR if we have enough messages OR if last message says "generate"
              final minMessages = widget.mode == CreatorMode.WORKOUT ? 45 : 49;
              
              bool showButton = chatProvider.isInterviewComplete || chatProvider.messages.length >= minMessages;
              
              // Fallback check for current session
              if (!showButton && chatProvider.messages.isNotEmpty) {
                final lastMsg = chatProvider.messages.last;
                if (lastMsg.role == 'model') {
                  final text = lastMsg.text.toLowerCase();
                  if (text.contains('generuj plan') || text.contains('generuj dietę')) {
                    showButton = true;
                  }
                }
              }
              
              if (showButton) {
                return Padding(
                  padding: const EdgeInsets.only(right: 16.0),
                  child: ElevatedButton.icon(
                    onPressed: _finishInterview,
                    icon: const Icon(Icons.auto_awesome, size: 18),
                    label: Text(widget.mode == CreatorMode.WORKOUT ? 'Generuj plan' : 'Generuj dietę'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                  ),
                );
              }
              return const SizedBox();
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              // Messages list
              Expanded(
                child: Consumer<ChatProvider>(
                  builder: (context, chatProvider, _) {
                    if (chatProvider.messages.isEmpty) {
                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    }
                    
                    return ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount: chatProvider.messages.length,
                      itemBuilder: (context, index) {
                        final message = chatProvider.messages[index];
                        return _buildMessage(message);
                      },
                    );
                  },
                ),
              ),
              
              // Input area
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  border: Border(
                    top: BorderSide(color: colorScheme.outline.withOpacity(0.1)),
                  ),
                ),
                child: SafeArea(
                  top: false,
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _messageController,
                          style: TextStyle(color: colorScheme.onSurface),
                          decoration: InputDecoration(
                            hintText: 'Wpisz swoją odpowiedź...',
                            hintStyle: TextStyle(color: colorScheme.onSurfaceVariant),
                            filled: true,
                            fillColor: theme.scaffoldBackgroundColor,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                          ),
                          maxLines: 5,
                          minLines: 1,
                          textInputAction: TextInputAction.send,
                          onSubmitted: (_) => _sendMessage(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Consumer<ChatProvider>(
                        builder: (context, chatProvider, _) {
                          return IconButton(
                            onPressed: chatProvider.isLoading ? null : _sendMessage,
                            icon: Icon(
                              Icons.send,
                              color: chatProvider.isLoading
                                  ? colorScheme.onSurfaceVariant
                                  : AppColors.primary,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          
          // Loading overlay for plan generation
          if (_isGeneratingPlan)
            const LoadingOverlay(
              message: 'Generowanie planu...',
            ),
        ],
      ),
    );
  }
  
  Widget _buildMessage(ChatMessage message) {
    final isUser = message.role == 'user';
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: isUser ? AppColors.primary : colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: isUser ? null : Border.all(color: colorScheme.outline.withOpacity(0.1)),
        ),
        child: Text(
          message.text,
          style: TextStyle(
            color: isUser ? Colors.white : colorScheme.onSurface,
            fontSize: 15,
            height: 1.4,
          ),
        ),
      ),
    );
  }
}
