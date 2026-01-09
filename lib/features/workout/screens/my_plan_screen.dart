import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/data/mock_data.dart';
import '../../../core/models/models.dart';
import '../../../core/widgets/achievement_badge.dart';
import '../../../core/widgets/workout_card.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../services/plan_service.dart';

class MyPlanScreen extends StatefulWidget {
  const MyPlanScreen({super.key});

  @override
  State<MyPlanScreen> createState() => _MyPlanScreenState();
}

class _MyPlanScreenState extends State<MyPlanScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedDayIndex = 0;
  GeneratedPlan? _workoutPlan;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadPlan();
  }

  Future<void> _loadPlan() async {
    final plan = await PlanService.getCurrentPlan();
    setState(() {
      _workoutPlan = plan ?? MockData.sampleFBWPlan; // Fallback to mock if no plan
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final progress = MockData.sampleProgress;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('Mój Plan'),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Mój Plan'),
      ),
      body: Column(
        children: [
          // Achievements Card
          Container(
            margin: const EdgeInsets.all(16),
            child: StreakBadge(
              days: progress.streakCurrent,
              label: 'Twoje Osiągnięcia',
            ),
          ),

          // Tabs
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(12),
              ),
              labelColor: AppColors.textOnPrimary,
              unselectedLabelColor: AppColors.textSecondary,
              dividerColor: Colors.transparent,
              tabs: const [
                Tab(
                  icon: Icon(Icons.calendar_today),
                  text: 'Harmonogram',
                ),
                Tab(
                  icon: Icon(Icons.show_chart),
                  text: 'Postępy',
                ),
              ],
            ),
          ),

          // Tab Views
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildScheduleTab(_workoutPlan!),
                _buildProgressTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleTab(workoutPlan) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Plan Info Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.description,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              workoutPlan.title,
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              workoutPlan.description,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Day Selector
          Text(
            'Wybierz dzień',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 80,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: workoutPlan.schedule.length,
              itemBuilder: (context, index) {
                final day = workoutPlan.schedule[index];
                final isSelected = _selectedDayIndex == index;

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedDayIndex = index;
                    });
                  },
                  child: Container(
                    width: 100,
                    margin: const EdgeInsets.only(right: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: isSelected
                          ? LinearGradient(
                              colors: [
                                AppColors.primary,
                                AppColors.primary.withOpacity(0.8),
                              ],
                            )
                          : null,
                      color: isSelected ? null : AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.border,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          day.dayName.split(' - ')[0],
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: isSelected
                                        ? AppColors.textOnPrimary
                                        : AppColors.textSecondary,
                                  ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Dzień ${index + 1}',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: isSelected
                                        ? AppColors.textOnPrimary
                                        : AppColors.textTertiary,
                                    fontSize: 10,
                                  ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 24),

          // Selected Day Details
          _buildDayDetails(workoutPlan.schedule[_selectedDayIndex]),
        ],
      ),
    );
  }

  Widget _buildDayDetails(day) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Day Title
        Text(
          day.dayName,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 8),
        if (day.summary != null) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.primary.withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.format_quote,
                  color: AppColors.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    day.summary!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontStyle: FontStyle.italic,
                        ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],

        // Start Training Button
        CustomButton(
          text: 'Rozpocznij Trening Live',
          onPressed: () {
            // Navigate to live workout
          },
          icon: Icons.play_circle_filled,
        ),
        const SizedBox(height: 24),

        // Exercises
        Text(
          'Ćwiczenia',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        ...day.items.map((item) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Card(
              child: ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.fitness_center,
                    color: AppColors.primary,
                    size: 20,
                  ),
                ),
                title: Text(item.name),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (item.tips != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        item.tips!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textTertiary,
                            ),
                      ),
                    ],
                  ],
                ),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    item.details,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.secondary,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                onTap: () {
                  // Show exercise details
                },
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildProgressTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Progress Chart
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.trending_up,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Progres: Wyciskanie Leżąc',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Średnia poziomu wzrostu planu',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    height: 200,
                    child: LineChart(
                      LineChartData(
                        gridData: FlGridData(
                          show: true,
                          drawVerticalLine: false,
                          horizontalInterval: 4,
                          getDrawingHorizontalLine: (value) {
                            return FlLine(
                              color: AppColors.chartGrid,
                              strokeWidth: 1,
                            );
                          },
                        ),
                        titlesData: FlTitlesData(
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 40,
                              getTitlesWidget: (value, meta) {
                                return Text(
                                  value.toInt().toString(),
                                  style: Theme.of(context).textTheme.bodySmall,
                                );
                              },
                            ),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, meta) {
                                return Text(
                                  'Tyg ${value.toInt() + 1}',
                                  style: Theme.of(context).textTheme.bodySmall,
                                );
                              },
                            ),
                          ),
                          rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                        ),
                        borderData: FlBorderData(show: false),
                        lineBarsData: [
                          LineChartBarData(
                            spots: const [
                              FlSpot(0, 56),
                              FlSpot(1, 58),
                              FlSpot(2, 62),
                              FlSpot(3, 66),
                            ],
                            isCurved: true,
                            color: AppColors.chartPrimary,
                            barWidth: 3,
                            dotData: const FlDotData(show: true),
                            belowBarData: BarAreaData(
                              show: true,
                              color: AppColors.chartPrimary.withOpacity(0.1),
                            ),
                          ),
                          LineChartBarData(
                            spots: const [
                              FlSpot(0, 54),
                              FlSpot(1, 56),
                              FlSpot(2, 58),
                              FlSpot(3, 60),
                            ],
                            isCurved: true,
                            color: AppColors.textTertiary,
                            barWidth: 2,
                            dashArray: [5, 5],
                            dotData: const FlDotData(show: false),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildLegendItem('Progres AI', AppColors.chartPrimary),
                      const SizedBox(width: 24),
                      _buildLegendItem('Twoje Wyniki', AppColors.textTertiary),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Stats Summary
          Text(
            'Podsumowanie',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Ukończone Treningi',
                  '${MockData.sampleProgress.totalWorkouts}',
                  Icons.check_circle,
                  AppColors.success,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Dni z Rzędu',
                  '${MockData.sampleProgress.streakCurrent}',
                  Icons.local_fire_department,
                  AppColors.warning,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
