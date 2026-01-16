import 'package:flutter/material.dart';
import 'dart:math' show cos, sin, pi;
import '../../../core/theme/app_colors.dart';

class AITrustScreen extends StatelessWidget {
  const AITrustScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Scaffold(
      backgroundColor: colorScheme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: colorScheme.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              const Spacer(),
              // Main Title
              Text(
                'Nasza sztuczna inteligencja zawsze dostosuje się do Twoich postępów, aby osiągnąć optymalne rezultaty',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  height: 1.4,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 50),
              
              // AI Visualization with 6 icons
              _buildAIVisualization(context),
              
              const SizedBox(height: 50),
              
              // Features List
              ..._buildFeatures(colorScheme),
              
              const Spacer(),
              
              // Continue Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    // Navigate to questionnaire/creator
                    Navigator.pushNamed(context, '/creator');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 2,
                  ),
                  child: const Text(
                    'Zacznijmy!',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAIVisualization(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return SizedBox(
      width: 280,
      height: 280,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Circular icons around AI logo
          ..._buildCircularIcons(),
          
          // Center AI logo
          Container(
            width: 130,
            height: 130,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  AppColors.primary,
                  AppColors.primary.withOpacity(0.7),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.3),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.psychology,
                    size: 50,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'AI',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
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

  List<Widget> _buildCircularIcons() {
    final icons = [
      {'icon': Icons.tune, 'color': Colors.purple, 'angle': 0.0},           // Personalizacja
      {'icon': Icons.trending_up, 'color': Colors.green, 'angle': 60.0},    // Progresja
      {'icon': Icons.security, 'color': Colors.blue, 'angle': 120.0},       // Bezpieczeństwo
      {'icon': Icons.speed, 'color': Colors.orange, 'angle': 180.0},        // Optymalizacja
      {'icon': Icons.auto_fix_high, 'color': Colors.pink, 'angle': 240.0},  // Adaptacja
      {'icon': Icons.emoji_events, 'color': Colors.amber, 'angle': 300.0},  // Motywacja
    ];

    return icons.map((iconData) {
      final angle = (iconData['angle'] as double) * pi / 180;
      final radius = 110.0;
      final x = radius * cos(angle);
      final y = radius * sin(angle);
      
      return Positioned(
        left: 140 + x - 25,
        top: 140 + y - 25,
        child: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: (iconData['color'] as Color).withOpacity(0.15),
            border: Border.all(
              color: iconData['color'] as Color,
              width: 2,
            ),
          ),
          child: Icon(
            iconData['icon'] as IconData,
            color: iconData['color'] as Color,
            size: 24,
          ),
        ),
      );
    }).toList();
  }

  List<Widget> _buildFeatures(ColorScheme colorScheme) {
    final features = [
      {'icon': Icons.tune, 'label': 'Personalizacja'},
      {'icon': Icons.trending_up, 'label': 'Progresja'},
      {'icon': Icons.security, 'label': 'Bezpieczeństwo'},
      {'icon': Icons.speed, 'label': 'Optymalizacja'},
      {'icon': Icons.auto_fix_high, 'label': 'Adaptacja'},
      {'icon': Icons.emoji_events, 'label': 'Motywacja'},
    ];

    return features.map((f) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              f['icon'] as IconData,
              color: AppColors.primary,
              size: 22,
            ),
            const SizedBox(width: 12),
            Text(
              f['label'] as String,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: colorScheme.onSurface,
              ),
            ),
          ],
        ),
      );
    }).toList();
  }
}
