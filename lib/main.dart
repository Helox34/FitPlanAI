import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/home/screens/main_shell.dart';
import 'features/onboarding/screens/initial_survey_screen.dart';
import 'features/onboarding/screens/ai_trust_screen.dart';  // Fitify Feature 3.2
import 'features/legal/screens/terms_of_service_screen.dart';
import 'features/legal/screens/privacy_policy_screen.dart';
import 'features/subscription/screens/subscription_screen.dart';
import 'providers/chat_provider.dart';
import 'providers/plan_provider.dart';
import 'providers/user_provider.dart';
import 'providers/progress_provider.dart';
import 'services/notification_service.dart';

import 'providers/live_workout_provider.dart';
import 'core/widgets/worm_loader.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load environment variables
  await dotenv.load(fileName: ".env");
  
  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Initialize Notifications (Safe Mode)
  try {
    final notificationService = NotificationService();
    await notificationService.initialize();
    // Do NOT await permissions here - it can block startup. moved to AppInitializer.
  } catch (e) {
    debugPrint('Error initializing notifications: $e');
  }
  
  runApp(const FitPlanAIApp());
}

class FitPlanAIApp extends StatelessWidget {
  const FitPlanAIApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => PlanProvider()),
        ChangeNotifierProvider(create: (_) => ProgressProvider()),
        ChangeNotifierProvider(create: (_) => ChatProvider()), // Retained ChatProvider as it was not explicitly removed
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
            themeAnimationDuration: const Duration(milliseconds: 300),
            themeAnimationCurve: Curves.easeInOut,
            home: const AppInitializer(),
            routes: {
              '/login': (context) => const LoginScreen(),
              // '/gender' route removed - gender is now part of survey
              '/survey': (context) => const InitialSurveyScreen(),
              '/ai-trust': (context) => const AITrustScreen(),  // Fitify Feature 3.2
              '/home': (context) => MainShell(),
              '/terms': (context) => const TermsOfServiceScreen(),
              '/privacy': (context) => const PrivacyPolicyScreen(),
              '/subscription': (context) => const SubscriptionScreen(),
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
    
    // Load Plans & Progress
    // We do this after user data to ensure we know if user is logged in
    await context.read<PlanProvider>().loadPlans();
    await context.read<ProgressProvider>().loadProgress();

    // Request Notification Permissions & Schedule Notifications
    try {
      debugPrint('🔔 Requesting notification permissions...');
      await NotificationService().requestPermissions();
      
      // If user is logged in, schedule their notifications
      if (userProvider.isLoggedIn) {
        debugPrint('👤 User is logged in - scheduling notifications...');
        await userProvider.scheduleUserNotifications();
      }
    } catch (e) {
      debugPrint('❌ Error with notifications: $e');
    }

    // Give Firebase a moment to restore session if any
    // (UserProvider listener updates _firebaseUser, but we might need a small delay or check currentUser directly)
    await Future.delayed(const Duration(milliseconds: 500));
    
    if (mounted) {
      if (userProvider.isLoggedIn) {
        // User is logged in, check survey
        if (userProvider.hasCompletedInitialSurvey) {
           Navigator.of(context).pushReplacementNamed('/home');
         } else {
           // Not completed survey -> go directly to survey (includes gender question)
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
        child: WormLoader(size: 60),
      ),
    );
  }
}
