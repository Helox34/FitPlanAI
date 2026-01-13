import 'package:flutter/material.dart';
import 'dart:async';
import '../theme/app_colors.dart';
import 'worm_loader.dart';

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

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
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
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withOpacity(0.8),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // WormLoader is not const because it has internal state/animations
            WormLoader(size: 60, color: Colors.white),
            const SizedBox(height: 32),
            
            // Tips Container
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 32),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white10),
              ),
              child: Column(
                children: [
                  Text(
                    widget.message,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 500),
                    child: Text(
                      _fitnessTips[_currentTipIndex],
                      key: ValueKey(_currentTipIndex),
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                        height: 1.4,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
