import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../workout/screens/my_plan_screen.dart';
import '../../diet/screens/my_diet_screen.dart';
import '../../profile/screens/profile_screen.dart';
import '../../progress/screens/progress_screen.dart';
import '../../../core/models/models.dart';

// Global key to access MainShell state
final GlobalKey<_MainShellState> mainShellKey = GlobalKey<_MainShellState>();

class MainShell extends StatefulWidget {
  MainShell({Key? key}) : super(key: key ?? mainShellKey);

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _selectedIndex = 0;

  final List<Widget> _screens = const [
    MyPlanScreen(),
    MyDietScreen(),
    ProgressScreen(),
    ProfileScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }
  
  // Public method to change tab from outside
  void changeTab(int index) {
    if (index >= 0 && index < _screens.length) {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: AppColors.shadow,
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          type: BottomNavigationBarType.fixed,
          backgroundColor: AppColors.surface,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: AppColors.textTertiary,
          selectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
          unselectedLabelStyle: const TextStyle(
            fontSize: 12,
          ),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.fitness_center),
              activeIcon: Icon(Icons.fitness_center),
              label: 'Mój Plan',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.restaurant),
              activeIcon: Icon(Icons.restaurant),
              label: 'Moja Dieta',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.trending_up),
              activeIcon: Icon(Icons.trending_up),
              label: 'Postępy',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Profil',
            ),
          ],
        ),
      ),
    );
  }
}
