import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/home/screens/main_shell.dart';
import 'features/onboarding/screens/process_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load environment variables
  await dotenv.load(fileName: ".env");
  
  runApp(const FitPlanAIApp());
}

class FitPlanAIApp extends StatelessWidget {
  const FitPlanAIApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FitPlan AI',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      // Start with MainShell for testing all screens
      home: const MainShell(),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/process': (context) => const ProcessScreen(),
        '/home': (context) => const MainShell(),
      },
    );
  }
}
