import 'package:flutter/material.dart';
import 'dart:async';
import '../theme/app_colors.dart';

/// Loading overlay with fitness tips during plan generation
class LoadingOverlay extends StatefulWidget {
  final String message;
  
  const LoadingOverlay({
    super.key,
    this.message = 'Ładowanie...',
  });

  @override
  State<LoadingOverlay> createState() => _LoadingOverlayState();
}

class _LoadingOverlayState extends State<LoadingOverlay> {
  int _currentTipIndex = 0;
  Timer? _timer;
  
  final List<String> _fitnessTips = [
    '💪 Regularność jest ważniejsza niż intensywność',
    '💧 Pij wodę przed, w trakcie i po treningu',
    '🥗 Białko pomaga w regeneracji mięśni',
    '😴 Sen jest kluczowy dla regeneracji',
    '🏃 Rozgrzewka zapobiega kontuzjom',
    '🧘 Stretching poprawia elastyczność',
    '📊 Śledź swoje postępy regularnie',
    '🎯 Wyznaczaj realistyczne cele',
    '🔥 Konsystencja to klucz do sukcesu',
    '⏰ Najlepszy czas na trening to ten, który pasuje do Twojego harmonogramu',
  ];
  
  @override
  void initState() {
    super.initState();
    _startTipRotation();
  }
  
  void _startTipRotation() {
    _timer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (mounted) {
        setState(() {
          _currentTipIndex = (_currentTipIndex + 1) % _fitnessTips.length;
        });
      }
    });
  }
  
  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black54,
      child: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 32),
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
              const SizedBox(height: 24),
              Text(
                widget.message,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              const Text(
                'To może potrwać 30-60 sekund',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 500),
                  child: Text(
                    _fitnessTips[_currentTipIndex],
                    key: ValueKey(_currentTipIndex),
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textPrimary,
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
