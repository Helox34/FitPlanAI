import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/models/models.dart';

import 'dart:async';

class LiveExerciseView extends StatefulWidget {
  final PlanItem exercise;
  final int setNumber;
  final int totalSets;
  final VoidCallback onComplete;

  const LiveExerciseView({
    super.key,
    required this.exercise,
    required this.setNumber,
    required this.totalSets,
    required this.onComplete,
  });

  @override
  State<LiveExerciseView> createState() => _LiveExerciseViewState();
}

class _LiveExerciseViewState extends State<LiveExerciseView> {
  Timer? _timer;
  int _secondsElapsed = 0;
  bool _isTimerRunning = false;
  bool _hasTimer = false;

  @override
  void initState() {
    super.initState();
    _checkIfTimed();
  }
  
  // Re-check if widget updates (e.g. new exercise)
  @override
  void didUpdateWidget(LiveExerciseView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.exercise != widget.exercise) {
      _stopTimer();
      _secondsElapsed = 0;
      _checkIfTimed();
    }
  }

  void _checkIfTimed() {
    final lower = widget.exercise.details.toLowerCase();
    setState(() {
      _hasTimer = lower.contains('minut') || lower.contains('sekund');
    });
  }

  void _toggleTimer() {
    setState(() {
      _isTimerRunning = !_isTimerRunning;
    });

    if (_isTimerRunning) {
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        setState(() {
          _secondsElapsed++;
        });
      });
    } else {
      _timer?.cancel();
    }
  }
  
  void _stopTimer() {
    _timer?.cancel();
    _isTimerRunning = false;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String get _formattedTime {
    final minutes = (_secondsElapsed / 60).floor();
    final seconds = _secondsElapsed % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Tag
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.2),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.primary.withOpacity(0.5)),
          ),
          child: Text(
            'Seria ${widget.setNumber} / ${widget.totalSets}',
            style: const TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ),
        
        const SizedBox(height: 24),
        
        // Exercise Name
        Text(
          widget.exercise.name,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
        
        const SizedBox(height: 12),
        
         // Details
        Text(
          widget.exercise.details,
          style: const TextStyle(
            color: AppColors.primary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        
        const SizedBox(height: 30),
        
        // Timer Section (if applicable)
        if (_hasTimer) ...[
          Text(
            _formattedTime,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 64,
              fontWeight: FontWeight.bold,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _toggleTimer,
            icon: Icon(_isTimerRunning ? Icons.pause : Icons.play_arrow),
            label: Text(
              _isTimerRunning ? 'Zatrzymaj' : 'Start',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: _isTimerRunning ? Colors.redAccent : AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
        
        // Tips Box
        if (widget.exercise.tips != null || widget.exercise.note != null)
         Expanded(
           child: SingleChildScrollView(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 32),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B), // Dark slate
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.info_outline, color: Colors.amber, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Wskazówka',
                        style: TextStyle(
                          color: Colors.amber,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    widget.exercise.tips ?? widget.exercise.note ?? '',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
         )
         else 
           const Spacer(),
          
        // Done Button
        Padding(
          padding: const EdgeInsets.all(32.0),
          child: SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton.icon(
              onPressed: () {
                _stopTimer();
                widget.onComplete();
              },
              icon: const Icon(Icons.check),
              label: const Text(
                'Zrobione',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
        ),
        
        const SizedBox(height: 20),
      ],
    );
  }
}
