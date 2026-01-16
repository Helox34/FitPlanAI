import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/progress_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/custom_text_field.dart';
import '../../../../core/utils/app_error_helper.dart';
import '../../../providers/user_provider.dart';
import 'register_screen.dart';


class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    
    try {
      // Sign in with timeout
      await context.read<UserProvider>().signIn(
        _emailController.text.trim(),
        _passwordController.text,
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw 'Przekroczono czas logowania. Sprawdź połączenie internetowe.';
        },
      );
      
      if (!mounted) return;
      
      final userProvider = context.read<UserProvider>();
      bool syncSuccess = true;

      // Ensure profile is synced (Best Effort with timeout)
      if (userProvider.firebaseUser != null) {
        try {
          await userProvider.syncUserProfile(userProvider.firebaseUser!).timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              debugPrint('⚠️ Profile sync timeout - continuing anyway');
              syncSuccess = false;
            },
          );
        } catch (e) {
          debugPrint('⚠️ Sync warning: $e');
          syncSuccess = false;
        }
      }
      
      if (!mounted) return;
      
      // Load progress with timeout (only if survey completed)
      if (userProvider.hasCompletedInitialSurvey) {
        try {
          final currentWeight = userProvider.weight;
          await context.read<ProgressProvider>().loadProgress(fallbackWeight: currentWeight).timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              debugPrint('⚠️ Progress load timeout - continuing anyway');
            },
          );
        } catch (e) {
          debugPrint('⚠️ Progress load warning: $e');
        }
        
        if (!mounted) return;
        
        // Navigate even if sync failed
        await Navigator.of(context).pushReplacementNamed('/home');
        
        // Show warning if sync failed
        if (!syncSuccess && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Zalogowano, ale nie udało się zsynchronizować wszystkich danych.'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 3),
            ),
          );
        }
      } else {
        if (!mounted) return;
        // Check if gender selected, if not show gender screen first
        if (userProvider.gender == null) {
          await Navigator.of(context).pushReplacementNamed('/gender');
        } else {
          await Navigator.of(context).pushReplacementNamed('/survey');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppErrorHelper.getFriendlyErrorMessage(e.toString())),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() => _isLoading = true);
    
    try {
      debugPrint('🔵 Starting Google Sign-In...');
      final userProvider = context.read<UserProvider>();
      await userProvider.signInWithGoogle().timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw 'Przekroczono czas logowania przez Google.';
        },
      );
      
      if (!mounted) return;
      
      bool syncSuccess = true;
      
      // Ensure profile is synced (Best Effort with timeout)
      if (userProvider.firebaseUser != null) {
        try {
          await userProvider.syncUserProfile(userProvider.firebaseUser!).timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              debugPrint('⚠️ Profile sync timeout - continuing anyway');
              syncSuccess = false;
            },
          );
        } catch (e) {
          debugPrint('⚠️ Sync warning: $e');
          syncSuccess = false;
        }
      }

      if (!mounted) return;
      
      if (userProvider.hasCompletedInitialSurvey) {
        try {
          final currentWeight = userProvider.weight;
          await context.read<ProgressProvider>().loadProgress(fallbackWeight: currentWeight).timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              debugPrint('⚠️ Progress load timeout - continuing anyway');
            },
          );
        } catch (e) {
          debugPrint('⚠️ Progress load warning: $e');
        }
        
        if (!mounted) return;
        await Navigator.of(context).pushReplacementNamed('/home');
        
        if (!syncSuccess && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Zalogowano, ale nie udało się zsynchronizować wszystkich danych.'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 3),
            ),
          );
        }
      } else {
        if (!mounted) return;
        // Check if gender selected, if not show gender screen first
        if (userProvider.gender == null) {
          await Navigator.of(context).pushReplacementNamed('/gender');
        } else {
          await Navigator.of(context).pushReplacementNamed('/survey');
        }
      }
    } catch (e) {
      debugPrint('🔴 Google Sign-In error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppErrorHelper.getFriendlyErrorMessage(e.toString())),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleFacebookSignIn() async {
    setState(() => _isLoading = true);
    
    try {
      final userProvider = context.read<UserProvider>();
      await userProvider.signInWithFacebook().timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw 'Przekroczono czas logowania przez Facebook.';
        },
      );
      
      if (!mounted) return;
      
      bool syncSuccess = true;
      
      // Ensure profile is synced (Best Effort with timeout)
      if (userProvider.firebaseUser != null) {
        try {
          await userProvider.syncUserProfile(userProvider.firebaseUser!).timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              debugPrint('⚠️ Profile sync timeout - continuing anyway');
              syncSuccess = false;
            },
          );
        } catch (e) {
          debugPrint('⚠️ Sync warning: $e');
          syncSuccess = false;
        }
      }

      if (!mounted) return;

      if (userProvider.hasCompletedInitialSurvey) {
        try {
          final currentWeight = userProvider.weight;
          await context.read<ProgressProvider>().loadProgress(fallbackWeight: currentWeight).timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              debugPrint('⚠️ Progress load timeout - continuing anyway');
            },
          );
        } catch (e) {
          debugPrint('⚠️ Progress load warning: $e');
        }
        
        if (!mounted) return;
        await Navigator.of(context).pushReplacementNamed('/home');
        
        if (!syncSuccess && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Zalogowano, ale nie udało się zsynchronizować wszystkich danych.'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 3),
            ),
          );
        }
      } else {
        if (!mounted) return;
        // Check if gender selected, if not show gender screen first
        if (userProvider.gender == null) {
          await Navigator.of(context).pushReplacementNamed('/gender');
        } else {
          await Navigator.of(context).pushReplacementNamed('/survey');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppErrorHelper.getFriendlyErrorMessage(e.toString())),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA), // Slightly off-white background
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header with Gradient
            Stack(
              children: [
                Container(
                  width: double.infinity,
                  height: 320,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF00C853), Color(0xFF009688)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(40),
                      bottomRight: Radius.circular(40),
                    ),
                  ),
                ),
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.white.withOpacity(0.1), Colors.transparent],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(40),
                        bottomRight: Radius.circular(40),
                      ),
                    ),
                  ),
                ),
                SafeArea(
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 40),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.favorite,
                              size: 40,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'FitPlan AI',
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 1.0,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Twój osobisty trener\ni dietetyk w kieszeni.',
                            style: TextStyle(
                              fontSize: 15,
                              color: Colors.white.withOpacity(0.9),
                              height: 1.4,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            
            // Login Card
            Transform.translate(
              offset: const Offset(0, -20),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 450),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 30,
                        offset: const Offset(0, 15),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                           Center(
                            child: Text(
                              'Witaj ponownie',
                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF2D3142),
                              ),
                            ),
                          ),
                          const SizedBox(height: 32),
                          
                          // Email
                          CustomTextField(
                            label: 'Adres e-mail',
                            hint: 'user@example.com',
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            prefixIcon: const Icon(Icons.email_outlined),
                            validator: (val) => (val == null || !val.contains('@')) ? 'Błędny email' : null,
                          ),
                          const SizedBox(height: 16),
                          
                          // Password
                          CustomTextField(
                            label: 'Hasło',
                            hint: '••••••',
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              icon: Icon(_obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                            ),
                            validator: (val) => (val == null || val.length < 6) ? 'Min 6 znaków' : null,
                          ),
                          const SizedBox(height: 24),
                          
                          // Submit Button
                          CustomButton(
                            text: 'Zaloguj się',
                            onPressed: _handleLogin,
                            isLoading: _isLoading,
                            type: CustomButtonType.primary,
                          ),
                          
                          const SizedBox(height: 24),
                          
                          // Social Divider
                          Row(
                            children: [
                              Expanded(child: Divider(color: Colors.grey[300])),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                child: Text('lub kontynuuj przez', style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                              ),
                              Expanded(child: Divider(color: Colors.grey[300])),
                            ],
                          ),
                          const SizedBox(height: 24),
                          
                          // Social Buttons
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: _handleGoogleSignIn,
                                  icon: const Icon(Icons.g_mobiledata, color: Colors.red, size: 28),
                                  label: const Text('Google', style: TextStyle(color: Color(0xFF4B5563))),
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    side: BorderSide(color: Colors.grey[300]!),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: _handleFacebookSignIn,
                                  icon: const Icon(Icons.facebook, color: Colors.blue, size: 28),
                                  label: const Text('Facebook', style: TextStyle(color: Color(0xFF4B5563))),
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    side: BorderSide(color: Colors.grey[300]!),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          
                          const SizedBox(height: 32),
                          
                          // Register Link
                          Center(
                            child: GestureDetector(
                              onTap: () {
                                Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterScreen()));
                              },
                              child: RichText(
                                text: const TextSpan(
                                  text: 'Nie masz konta? ',
                                  style: TextStyle(color: Color(0xFF6B7280)),
                                  children: [
                                    TextSpan(
                                      text: 'Zarejestruj się',
                                      style: TextStyle(
                                        color: Color(0xFF009688),
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
