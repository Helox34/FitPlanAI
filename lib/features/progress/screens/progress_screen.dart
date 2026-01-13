import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/models/models.dart';
import '../../../providers/plan_provider.dart';
import '../../../providers/progress_provider.dart';
import '../../../providers/user_provider.dart';
import '../../onboarding/screens/plan_type_selection_screen.dart';
import '../../../core/widgets/worm_loader.dart';

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userProvider = context.read<UserProvider>();
      final progressProvider = context.read<ProgressProvider>();
      
      // Load progress with fallback, then check for reminders
      progressProvider.loadProgress(fallbackWeight: userProvider.weight).then((_) {
        if (mounted) {
           _checkPrompts();
        }
      });
    });
  }

  void _checkPrompts() {
    final provider = context.read<ProgressProvider>();
    if (provider.shouldPromptWeight) {
      _showEntryDialog(isWeight: true, title: 'Czas na pomiar wagi!', subtitle: 'Minął tydzień od ostatniego wpisu.');
    }
  }

  void _navigateToCreatePlan(BuildContext context, CreatorMode mode) {
    // Check if email is verified
    if (!context.read<UserProvider>().isEmailVerified) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Weryfikacja wymagana'),
          content: const Text('Musisz zweryfikować adres email, aby wygenerować plan dietetyczny lub treningowy.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                try {
                   await context.read<UserProvider>().sendVerificationEmail();
                   if (context.mounted) {
                     ScaffoldMessenger.of(context).showSnackBar(
                       const SnackBar(content: Text('Wysłano link weryfikacyjny.')),
                     );
                   }
                } catch (e) {
                   // ignore
                }
              },
              child: const Text('Wyślij ponownie'),
            ),
          ],
        ),
      );
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => PlanTypeSelectionScreen(preselectedMode: mode),
      ),
    );
  }

  void _showEntryDialog({required bool isWeight, String? title, String? subtitle}) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title ?? 'Aktualna waga'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (subtitle != null) ...[
              Text(subtitle, style: const TextStyle(fontSize: 13, color: Colors.grey)),
              const SizedBox(height: 16),
            ],
            TextField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Waga (kg)',
                border: OutlineInputBorder(),
                suffixText: 'kg',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Anuluj'),
          ),
          ElevatedButton(
            onPressed: () {
              final val = double.tryParse(controller.text.replaceAll(',', '.'));
              if (val != null) {
                // Add to history
                context.read<ProgressProvider>().addWeightEntry(val);
                // Sync with User Profile
                context.read<UserProvider>().updateWeight(val);
                Navigator.pop(context);
              }
            },
            child: const Text('Zapisz'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Usuń wpis'),
        content: const Text('Czy na pewno chcesz usunąć ten pomiar?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Anuluj'),
          ),
          TextButton(
            onPressed: () {
              context.read<ProgressProvider>().deleteWeightEntry(index);
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Usuń'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Postępy'),
        scrolledUnderElevation: 0,
      ),
      body: Consumer2<PlanProvider, ProgressProvider>(
        builder: (context, planProvider, progressProvider, _) {
          if (progressProvider.isLoading && progressProvider.weightEntries.isEmpty) {
            return Center(child: WormLoader(size: 40));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16), // Reduced padding for wider chart
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildPlansSection(context, planProvider),
                const SizedBox(height: 32),
                
                // Progress Section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Dzienniczek Wagi',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_circle, color: AppColors.primary, size: 28),
                      onPressed: () => _showEntryDialog(isWeight: true),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                _buildChartCard(
                  title: 'Waga Ciała',
                  entries: progressProvider.weightEntries,
                  color: Colors.blueAccent,
                ),
                
                const SizedBox(height: 24),
                const Text(
                  'Historia pomiarów',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                _buildHistoryList(progressProvider),
                const SizedBox(height: 40),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHistoryList(ProgressProvider provider) {
    final entries = provider.weightEntries.reversed.toList(); // Show newest first
    
    if (entries.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Text('Brak pomiarów w historii.', style: TextStyle(color: Colors.grey)),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: entries.length,
      itemBuilder: (context, index) {
        final entry = entries[index];
        // Calculate original index for deletion (since we reversed the list)
        final originalIndex = provider.weightEntries.length - 1 - index;
        
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          elevation: 0,
          color: Theme.of(context).cardColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.grey.withOpacity(0.1)),
          ),
          child: ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blueAccent.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.monitor_weight_outlined, size: 20, color: Colors.blueAccent),
            ),
            title: Text(
              '${entry.value} kg',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              DateFormat('d MMMM yyyy, HH:mm').format(entry.date),
              style: const TextStyle(fontSize: 12),
            ),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: () => _confirmDelete(context, originalIndex),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPlansSection(BuildContext context, PlanProvider planProvider) {
    final hasWorkoutPlan = planProvider.hasWorkoutPlan;
    final hasDietPlan = planProvider.hasDietPlan;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Twoje plany',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        const Text(
          'Zarządzaj swoimi planami',
          style: TextStyle(color: Colors.grey),
        ),
        const SizedBox(height: 16),
        _buildPlanCard(
          context,
          title: 'Plan Treningowy',
          description: hasWorkoutPlan ? 'Aktywny' : 'Stwórz plan',
          icon: Icons.fitness_center,
          color: AppColors.primary,
          isActive: hasWorkoutPlan,
          onTap: () => _navigateToCreatePlan(context, CreatorMode.WORKOUT),
        ),
        const SizedBox(height: 12),
        _buildPlanCard(
          context,
          title: 'Plan Dietetyczny',
          description: hasDietPlan ? 'Aktywny' : 'Stwórz plan',
          icon: Icons.restaurant,
          color: const Color(0xFF10B981),
          isActive: hasDietPlan,
          onTap: () => _navigateToCreatePlan(context, CreatorMode.DIET),
        ),
      ],
    );
  }

  Widget _buildPlanCard(
    BuildContext context, {
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    // ... (This part remains similar or simplified)
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.withOpacity(0.2)),
      ),
      child: ListTile(
        onTap: isActive ? null : onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(description),
        trailing: isActive 
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
              child: Text('Aktywny', style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
            ) 
          : const Icon(Icons.arrow_forward_ios, size: 16),
      ),
    );
  }

  Widget _buildChartCard({
    required String title,
    required List<dynamic> entries, 
    required Color color,
  }) {
    if (entries.isEmpty) {
      return Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.grey.withOpacity(0.2)),
        ),
        child: const Padding(
          padding: EdgeInsets.all(32.0),
          child: Center(child: Text('Brak danych do wykresu')),
        ),
      );
    }

    // Chart Data Preparation
    List<FlSpot> spots = [];
    double minY = double.infinity;
    double maxY = double.negativeInfinity;

    for (int i = 0; i < entries.length; i++) {
        final val = entries[i].value;
        if (val < minY) minY = val;
        if (val > maxY) maxY = val;
        spots.add(FlSpot(i.toDouble(), val));
    }
    
    // Dynamic Y axis margins
    double yMargin = (maxY - minY) * 0.2;
    if (yMargin == 0) yMargin = 5; 
    minY -= yMargin;
    maxY += yMargin;

    return Card(
      elevation: 4,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 24, 24, 24), // Right padding for labels
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Text('${entries.last.value} kg', style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 18)),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 220,
              width: double.infinity,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (value) => 
                      FlLine(color: Colors.grey.withOpacity(0.1), strokeWidth: 1),
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        interval: entries.length > 5 ? (entries.length / 5).toDouble() : 1, // Avoid crowding
                        getTitlesWidget: (value, meta) {
                          int index = value.toInt();
                          if (index >= 0 && index < entries.length) {
                             // Only show ~5 dates max
                             return Padding(
                               padding: const EdgeInsets.only(top: 8.0),
                               child: Text(
                                 DateFormat('d MMM').format(entries[index].date),
                                 style: const TextStyle(color: Colors.grey, fontSize: 10),
                               ),
                             );
                          }
                          return const SizedBox();
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: (maxY - minY) / 4,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            value.toStringAsFixed(1),
                            style: const TextStyle(color: Colors.grey, fontSize: 10),
                          );
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  minX: 0,
                  maxX: (entries.length - 1).toDouble(),
                  minY: minY,
                  maxY: maxY,
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      color: color,
                      barWidth: 4,
                      isStrokeCapRound: true,
                      dotData: const FlDotData(show: true),
                      belowBarData: BarAreaData(
                        show: true,
                        color: color.withOpacity(0.15),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [color.withOpacity(0.5), color.withOpacity(0.0)],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
