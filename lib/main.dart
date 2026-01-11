import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/home/screens/main_shell.dart';
import 'features/onboarding/screens/initial_survey_screen.dart';
import 'providers/chat_provider.dart';
import 'providers/plan_provider.dart';
import 'providers/user_provider.dart';

import 'providers/live_workout_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load environment variables
  await dotenv.load(fileName: ".env");
  
  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  runApp(const FitPlanAIApp());
}

class FitPlanAIApp extends StatelessWidget {
  const FitPlanAIApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ChatProvider()),
        ChangeNotifierProvider(create: (_) => PlanProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProxyProvider<PlanProvider, LiveWorkoutProvider>(
          create: (context) => LiveWorkoutProvider(context.read<PlanProvider>()),
          update: (context, planProvider, previous) => 
               previous ?? LiveWorkoutProvider(planProvider),
        ),
      ],
      child: Consumer<UserProvider>(
        builder: (context, userProvider, child) {
          return MaterialApp(
            title: 'FitPlan AI',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: userProvider.themeMode,
            home: const AppInitializer(),
            routes: {
              '/login': (context) => const LoginScreen(),
              '/survey': (context) => const InitialSurveyScreen(),
              '/home': (context) => MainShell(),
            },
          );
        },
      ),
    );
  }
}

/// Widget to determine initial route based on user state
class AppInitializer extends StatefulWidget {
  const AppInitializer({super.key});

  @override
  State<AppInitializer> createState() => _AppInitializerState();
}

class _AppInitializerState extends State<AppInitializer> {
  @override
  void initState() {
    super.initState();
    _initialize();
  }
  
  Future<void> _initialize() async {
    final userProvider = context.read<UserProvider>();
    await userProvider.loadUserData();
    
    // Give Firebase a moment to restore session if any
    // (UserProvider listener updates _firebaseUser, but we might need a small delay or check currentUser directly)
    await Future.delayed(const Duration(milliseconds: 500));
    
    if (mounted) {
      if (userProvider.isLoggedIn) {
        // User is logged in, check survey
        if (userProvider.hasCompletedInitialSurvey) {
           Navigator.of(context).pushReplacementNamed('/home');
        } else {
           Navigator.of(context).pushReplacementNamed('/survey');
        }
      } else {
        // Not logged in -> Login Screen
        Navigator.of(context).pushReplacementNamed('/login');
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
