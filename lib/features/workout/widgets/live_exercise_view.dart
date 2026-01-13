import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:ui'; // For FontFeature
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/models/models.dart';
import '../../../core/widgets/worm_loader.dart';

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
  int _secondsRemaining = 0;
  int _totalSeconds = 0;
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
      _checkIfTimed();
    }
  }

  void _checkIfTimed() {
    final details = widget.exercise.details.toLowerCase();
    int seconds = 0;

    // Check for minutes (e.g. "20 min", "20-30 min")
    // Regex matches: digits, optional range "-digits", whitespace, "min"
    if (details.contains('min')) {
      final RegExp minRegex = RegExp(r'(\d+)(?:-(\d+))?\s*min');
      final match = minRegex.firstMatch(details);
      if (match != null) {
        // Use the first number (minimum time) as the base
        final int mins = int.parse(match.group(1)!);
        seconds = mins * 60;
      }
    } 
    // Check for seconds (e.g. "30s", "45 sec")
    else if (details.contains('s') || details.contains('sec')) {
      final RegExp secRegex = RegExp(r'(\d+)\s*(?:s|sec|sek)');
      final match = secRegex.firstMatch(details);
      if (match != null) {
        seconds = int.parse(match.group(1)!);
      }
    }

    setState(() {
      if (seconds > 0) {
        _hasTimer = true;
        _totalSeconds = seconds;
        _secondsRemaining = seconds;
        _isTimerRunning = false; // Auto-start disabled, user must click start
      } else {
        _hasTimer = false;
        _totalSeconds = 0;
        _secondsRemaining = 0;
        _isTimerRunning = false;
      }
    });
  }

  void _toggleTimer() {
    setState(() {
      _isTimerRunning = !_isTimerRunning;
    });

    if (_isTimerRunning) {
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        setState(() {
          if (_secondsRemaining > 0) {
            _secondsRemaining--;
          } else {
            _stopTimer();
            // Timer finished
          }
        });
      });
    } else {
      _timer?.cancel();
    }
  }
  
  void _stopTimer() {
    _timer?.cancel();
    setState(() {
      _isTimerRunning = false;
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String get _formattedTime {
    final minutes = (_secondsRemaining / 60).floor();
    final seconds = _secondsRemaining % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    // Calculate progress for the circular indicator: 1.0 (full) -> 0.0 (empty)
    double progress = 0.0;
    if (_totalSeconds > 0) {
      progress = _secondsRemaining / _totalSeconds;
    }

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
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 220,
                height: 220,
                child: CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 10,
                  backgroundColor: Colors.white10,
                  // Change color to red when close to finish (< 10 seconds)
                  color: _secondsRemaining <= 10 && _secondsRemaining > 0 
                      ? Colors.redAccent 
                      : AppColors.primary,
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (widget.exercise.videoUrl != null) ...[
                    // ... video player ...
                    Container(
                      height: 240,
                      width: double.infinity,
                      color: Colors.blueGrey,
                      child: const Center(
                        child: Text('Video Player Here', style: TextStyle(color: Colors.white)),
                      ),
                    ),
                  ] else
                    Container(
                      height: 240, // Adjust height as needed
                      width: double.infinity,
                      color: Colors.black12,
                      child: Center(
                        child: WormLoader(size: 40),
                      ),
                    ),
                  Text(
                    _formattedTime,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 56,
                      fontWeight: FontWeight.bold,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'POZOSTAŁO',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.5),
                      fontSize: 12,
                      letterSpacing: 2.0,
                    ),
                  ),
                ],
              ),
            ],
          ),
          
          const SizedBox(height: 30),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Reset Button (only show if timer has run at least a bit)
              if (_secondsRemaining < _totalSeconds && !_isTimerRunning)
                Padding(
                  padding: const EdgeInsets.only(right: 20),
                  child: IconButton(
                    iconSize: 32,
                    icon: const Icon(Icons.refresh, color: Colors.white54),
                    onPressed: () {
                      _stopTimer();
                      setState(() {
                        _secondsRemaining = _totalSeconds;
                      });
                    },
                    tooltip: 'Resetuj czas',
                  ),
                ),
                
              ElevatedButton.icon(
                onPressed: _secondsRemaining == 0 ? null : _toggleTimer,
                icon: Icon(_isTimerRunning ? Icons.pause : Icons.play_arrow),
                label: Text(
                  _isTimerRunning ? 'PAUZA' : 'START',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isTimerRunning ? Colors.orangeAccent : AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  elevation: 6,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
        ],
        
        // Tips Box (or Spacer)
        if (widget.exercise.tips != null || widget.exercise.note != null)
         Expanded(
           child: SingleChildScrollView(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 32, vertical: 10),
              padding: const EdgeInsets.all(16),
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
                      Icon(Icons.info_outline, color: Colors.amber, size: 18),
                      SizedBox(width: 8),
                      Text(
                        'Wskazówka',
                        style: TextStyle(
                          color: Colors.amber,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.exercise.tips ?? widget.exercise.note ?? '',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 13,
                      height: 1.4,
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
          padding: const EdgeInsets.fromLTRB(32, 0, 32, 32),
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
                // Highlight button green if timer finished
                backgroundColor: (_hasTimer && _secondsRemaining == 0) ? Colors.green : const Color(0xFF2E7D32),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: (_hasTimer && _secondsRemaining == 0) 
                      ? const BorderSide(color: Colors.white, width: 2)
                      : BorderSide.none,
                ),
                elevation: 4,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
