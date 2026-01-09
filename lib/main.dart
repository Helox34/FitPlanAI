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
      ],
      child: MaterialApp(
        title: 'FitPlan AI',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const AppInitializer(),
        routes: {
          '/login': (context) => const LoginScreen(),
          '/survey': (context) => const InitialSurveyScreen(),
          '/home': (context) => MainShell(),
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
    
    if (mounted) {
      // Check if user has completed initial survey
      if (userProvider.hasCompletedInitialSurvey) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => MainShell()),
        );
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const InitialSurveyScreen()),
        );
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
