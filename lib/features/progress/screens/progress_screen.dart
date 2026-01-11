import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/models/models.dart';
import '../../../providers/plan_provider.dart';
import '../../../providers/progress_provider.dart';
import '../../onboarding/screens/plan_type_selection_screen.dart';

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
      context.read<ProgressProvider>().loadProgress().then((_) {
        _checkPrompts();
      });
    });
  }

  void _checkPrompts() {
    final provider = context.read<ProgressProvider>();
    if (provider.shouldPromptWeight) {
      _showEntryDialog(isWeight: true, title: 'Czas na pomiar wagi!', subtitle: 'Minął tydzień od ostatniego wpisu.');
    } else if (provider.shouldPromptStrength) {
      _showEntryDialog(isWeight: false, title: 'Czas na test siły!', subtitle: 'Sprawdź swoje postępy siłowe.');
    }
  }

  void _navigateToCreatePlan(BuildContext context, CreatorMode mode) {
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
        title: Text(title ?? (isWeight ? 'Aktualna waga' : 'Progres siłowy')),
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
              decoration: InputDecoration(
                labelText: isWeight ? 'Waga (kg)' : 'Wynik (kg/pkt)',
                border: const OutlineInputBorder(),
                suffixText: isWeight ? 'kg' : '',
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
                if (isWeight) {
                  context.read<ProgressProvider>().addWeightEntry(val);
                } else {
                  context.read<ProgressProvider>().addStrengthEntry(val);
                }
                Navigator.pop(context);
              }
            },
            child: const Text('Zapisz'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Postępy'),
        scrolledUnderElevation: 0,
      ),
      body: Consumer2<PlanProvider, ProgressProvider>(
        builder: (context, planProvider, progressProvider, _) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
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
                      'Dzienniczek Postępów',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: const Icon(Icons.refresh),
                      onPressed: () => _checkPrompts(), // Manual check or just refresh
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                _buildChartCard(
                  title: 'Waga Ciała',
                  entries: progressProvider.weightEntries,
                  color: Colors.blueAccent,
                  isWeight: true,
                  onAdd: () => _showEntryDialog(isWeight: true),
                ),
                const SizedBox(height: 24),
                _buildChartCard(
                  title: 'Progres Siłowy',
                  subtitle: 'Szacowany wzrost siły ogólnej',
                  entries: progressProvider.strengthEntries,
                  color: AppColors.primary,
                  isWeight: false,
                  onAdd: () => _showEntryDialog(isWeight: false),
                ),
                const SizedBox(height: 40),
              ],
            ),
          );
        },
      ),
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
          'Zarządzaj swoimi planami treningowymi i dietetycznymi',
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
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.withOpacity(0.2)),
      ),
      child: ListTile(
        onTap: isActive ? null : onTap,
        contentPadding: const EdgeInsets.all(16),
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
    String? subtitle,
    required List<dynamic> entries, // List of ProgressEntry
    required Color color,
    required bool isWeight,
    required VoidCallback onAdd,
  }) {
    if (entries.isEmpty) {
      return Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              if (subtitle != null) Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.grey)),
              const SizedBox(height: 24),
              Icon(Icons.show_chart, size: 48, color: Colors.grey[300]),
              const SizedBox(height: 16),
              Text('Brak danych. Dodaj pierwszy wpis!', style: TextStyle(color: Colors.grey[600])),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: onAdd,
                icon: const Icon(Icons.add),
                label: const Text('Dodaj wpis'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: color,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Prepare chart data
    List<FlSpot> spots = [];
    double minY = double.infinity;
    double maxY = double.negativeInfinity;

    for (int i = 0; i < entries.length; i++) {
        final val = entries[i].value;
        if (val < minY) minY = val;
        if (val > maxY) maxY = val;
        spots.add(FlSpot(i.toDouble(), val));
    }
    
    // Adjust Y axis range for better visualization
    double yMargin = (maxY - minY) * 0.2;
    if (yMargin == 0) yMargin = 5; 
    minY -= yMargin;
    maxY += yMargin;

    return Card(
      elevation: 4,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    if (subtitle != null) 
                      Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${entries.last.value} ${isWeight ? "kg" : "pkt"}',
                    style: TextStyle(color: color, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (value) => 
                      FlLine(color: Colors.grey.withOpacity(0.1), strokeWidth: 1, dashArray: [5, 5]),
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        interval: 1,
                        getTitlesWidget: (value, meta) {
                          if (value % 1 != 0) return const SizedBox();
                          int index = value.toInt();
                          if (index >= 0 && index < entries.length) {
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
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: const FlDotData(show: true),
                      belowBarData: BarAreaData(
                        show: true,
                        color: color.withOpacity(0.1),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onAdd,
                icon: const Icon(Icons.add),
                label: const Text('Dodaj nowy wpis'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: color,
                  side: BorderSide(color: color),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
