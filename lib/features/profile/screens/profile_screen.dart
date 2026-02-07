import 'dart:typed_data';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../providers/user_provider.dart';
import '../../../providers/progress_provider.dart';
import '../../../models/subscription_plan.dart';
import '../../../models/subscription_tier.dart';
import '../../../services/notification_service.dart';
import '../../../core/widgets/worm_loader.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  int _selectedColorIndex = 2;
  
  // Image Picker state
  final ImagePicker _picker = ImagePicker();
  Uint8List? _imageBytes;

  // Notification State
  bool? _isNotificationsExpanded;


  // Measurements State
  bool? _isMeasurementsExpanded;
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  bool? _isWeightEditing; // Nullable to handle hot reload state
  bool? _isHeightEditing;
  bool? _isAgeEditing;

  // Language State
  bool? _isLanguageExpanded;

  // Currency State
  bool? _isCurrencyExpanded;

  // Appearance State
  bool? _isAppearanceExpanded;

  // Info State
  bool? _isInfoExpanded;
  bool? _isSecurityExpanded;

  // Safe getters
  bool get isMeasurementsExpanded => _isMeasurementsExpanded ?? false;
  bool get isAppearanceExpanded => _isAppearanceExpanded ?? false;
  bool get isLanguageExpanded => _isLanguageExpanded ?? false;
  bool get isCurrencyExpanded => _isCurrencyExpanded ?? false; // For currency selector
  bool get isInfoExpanded => _isInfoExpanded ?? false;
  bool get isSecurityExpanded => _isSecurityExpanded ?? false;
  bool get isNotificationsExpanded => _isNotificationsExpanded ?? false;
  
  // Subscription State
  bool? _isSubscriptionExpanded;
  bool get isSubscriptionExpanded => _isSubscriptionExpanded ?? false;

  Widget _buildPremiumCard() {
    final isPremium = context.watch<UserProvider>().isPremium;
    if (isPremium) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: const LinearGradient(
            colors: [Color(0xFF2E3192), Color(0xFF1BFFFF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF1BFFFF).withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
             Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.star, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Przejdź na Premium',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                       Text(
                        'Odblokuj plany i asystenta AI',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 16),
              ],
            ),
          ],
        ),
      ),
    );
  }



  Widget _buildSubscriptionSection() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Column(
      children: [
        ListTile(
          leading: Icon(Icons.star_outline, color: colorScheme.onSurface),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
          title: Text(
            'Subskrypcja',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: colorScheme.onSurface,
            ),
          ),
          trailing: AnimatedRotation(
            turns: isSubscriptionExpanded ? 0.25 : 0.0,
             duration: const Duration(milliseconds: 200),
            child: const Icon(Icons.chevron_right, color: AppColors.primary),
          ),
          onTap: () {
            setState(() {
              _isSubscriptionExpanded = !isSubscriptionExpanded;
            });
          },
        ),
        if (isSubscriptionExpanded) ...[
          _buildSecurityItem(
            label: 'Przywróć zakupy',
            actionText: 'Przywróć',
            actionColor: AppColors.primary,
            onTap: _handleRestorePurchases,
          ),
          // Smart subscription management based on premium status
          _buildSecurityItem(
            label: context.watch<UserProvider>().isPremium 
                ? 'Zarządzaj subskrypcją w Google Play'
                : 'Kup subskrypcję Premium',
            actionText: context.watch<UserProvider>().isPremium ? 'Otwórz' : 'Zobacz',
            actionColor: AppColors.primary,
            onTap: () => _handleManageSubscription(context),
          ),
          const SizedBox(height: 8),
        ],
      ],
    );
  }

  Future<void> _handleRestorePurchases() async {
    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: WormLoader(size: 40)),
    );
    
    try {
      final success = await context.read<UserProvider>().restorePurchases();
      if (!mounted) return;
      Navigator.pop(context); // Close loader
      
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pomyślnie przywrócono zakupy!'),
            backgroundColor: AppColors.success,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Nie znaleziono aktywnych subskrypcji do przywrócenia.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Close loader
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Błąd podczas przywracania: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _handleManageSubscription(BuildContext context) {
    final isPremium = context.read<UserProvider>().isPremium;
    
    if (isPremium) {
      // Premium users: Show dialog with info and link to Google Play
      showDialog(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Zarządzanie Subskrypcją'),
          content: const SizedBox(
            width: 500,
            child: Text(
              'Aby zarządzać swoją subskrypcją (anulować, zmienić plan, itp.), przejdź do Google Play Store.\n\n'
              'Kliknij "Otwórz Google Play" poniżej aby przejść do ustawień subskrypcji.',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Zamknij'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(dialogContext);
                // TODO: Open Google Play subscription page
                // For now just show a snackbar
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Otwórz Google Play Store > Konto > Płatności i subskrypcje > Subskrypcje'),
                      duration: Duration(seconds: 5),
                    ),
                  );
                }
              },
              child: const Text('Otwórz Google Play'),
            ),
          ],
        ),
      );
    } else {
      // Free users: Show paywall
      Navigator.of(context).pushNamed('/paywall');
    }
  }

  Widget _buildAppearanceSection() {
    final user = context.watch<UserProvider>();
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Column(
      children: [
        ListTile(
          leading: Icon(Icons.palette_outlined, color: colorScheme.onSurface),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
          title: Text(
            'Wygląd',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: colorScheme.onSurface,
            ),
          ),
          trailing: AnimatedRotation(
            turns: isAppearanceExpanded ? 0.25 : 0.0,
             duration: const Duration(milliseconds: 200),
            child: const Icon(Icons.chevron_right, color: AppColors.primary),
          ),
          onTap: () {
            setState(() {
              _isAppearanceExpanded = !isAppearanceExpanded;
            });
          },
        ),
        if (isAppearanceExpanded) ...[
          _buildSwitchItem('Tryb Ciemny', user.isDarkMode, (v) {
            user.toggleTheme(v);
          }),
          const SizedBox(height: 8),
        ],
      ],
    );
  }

  Widget _buildSecuritySection() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Column(
      children: [
        ListTile(
          leading: Container(
             padding: const EdgeInsets.all(8),
             decoration: BoxDecoration(
               color: Colors.orange.withOpacity(0.1),
               borderRadius: BorderRadius.circular(8),
             ),
             child: const Icon(Icons.lock_outline, color: Colors.orange, size: 20),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          title: Text(
            'Hasło i bezpieczeństwo',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: colorScheme.onSurface,
            ),
          ),
          subtitle: Text(
            'Zapomniane hasło? Możesz je zresetować.',
             style: TextStyle(color: Colors.grey[500], fontSize: 11),
          ),
          trailing: AnimatedRotation(
            turns: isSecurityExpanded ? 0.25 : 0.0,
             duration: const Duration(milliseconds: 200),
            child: const Icon(Icons.chevron_right, color: AppColors.primary),
          ),
          onTap: () {
            setState(() {
              _isSecurityExpanded = !isSecurityExpanded;
            });
          },
        ),
        if (isSecurityExpanded) ...[
          // Only show password/email options if user logged in via password
          if (context.watch<UserProvider>().firebaseUser?.providerData.any((p) => p.providerId == 'password') ?? false) ...[
            _buildSecurityItem(
              label: 'zapomniałeś hasło',
              actionText: 'Zmień hasło',
              actionColor: AppColors.primary,
              onTap: _handleResetPassword,
            ),
            _buildSecurityItem(
              label: 'zmień email',
              actionText: 'zmień email',
              actionColor: AppColors.primary,
              onTap: _handleChangeEmail,
            ),
          ],
          _buildSecurityItem(
            label: 'usuń konto',
            actionText: 'usuń konto',
            actionColor: Colors.red,
            onTap: _handleDeleteAccount,
          ),
          const SizedBox(height: 12),
        ],
      ],
    );
  }

  Widget _buildSecurityItem({
    required String label,
    required String actionText,
    required Color actionColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          children: [
            const SizedBox(width: 40), // Indent to align with title text
            Icon(Icons.chevron_right, size: 16, color: AppColors.primary.withOpacity(0.5)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
            Text(
              actionText,
              style: TextStyle(
                color: actionColor,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }



  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadUserData();
    });
  }
  
  void _loadUserData() {
    final user = context.read<UserProvider>();
    
    setState(() {
      if (user.nickname != null && user.nickname!.isNotEmpty) {
         _nameController.text = user.nickname!;
      }
      
      // Load email from Firebase
      if (user.firebaseUser?.email != null) {
        _emailController.text = user.firebaseUser!.email!;
      }
      
      // Load measurements
      _weightController.text = user.weight != null ? '${user.weight} kg' : '';
      _heightController.text = user.height != null ? '${user.height} cm' : '';
      _ageController.text = user.age != null ? '${user.age} lat' : '';
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Safely sync text fields with provider data when dependencies change
    // This won't cause infinite loops like doing it in build() did
    final userProvider = context.watch<UserProvider>();
    
    if (!(_isWeightEditing ?? false) && userProvider.weight != null) {
      final text = '${userProvider.weight} kg';
      if (_weightController.text != text) {
        _weightController.text = text;
      }
    }
    if (!(_isHeightEditing ?? false) && userProvider.height != null) {
      final text = '${userProvider.height} cm';
      if (_heightController.text != text) {
        _heightController.text = text;
      }
    }
    if (!(_isAgeEditing ?? false) && userProvider.age != null) {
      final text = '${userProvider.age} lat';
      if (_ageController.text != text) {
        _ageController.text = text;
      }
    }
  }
  
  // Helpers to safely get boolean values

  Future<void> _pickImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
      );

      if (pickedFile != null) {
        final bytes = await pickedFile.readAsBytes();
        setState(() {
          _imageBytes = bytes;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Błąd podczas wybierania zdjęcia: $e')),
        );
      }
    }
  }

  void _saveChanges() {
    if (_formKey.currentState!.validate()) {
      final user = context.read<UserProvider>();
      
      // Parse numerical values from text (removing units)
      final weightStr = _weightController.text.replaceAll(RegExp(r'[^0-9.]'), '');
      final heightStr = _heightController.text.replaceAll(RegExp(r'[^0-9.]'), '');
      final ageStr = _ageController.text.replaceAll(RegExp(r'[^0-9]'), '');
      
      final weight = double.tryParse(weightStr);
      final height = double.tryParse(heightStr);
      final age = int.tryParse(ageStr);
      
      if (weight != null) user.updateWeight(weight);
      if (height != null) user.updateHeight(height);
      if (age != null) user.updateAge(age);
      
      user.updateNickname(_nameController.text);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Zmiany zostały zapisane'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  Future<void> _handleResetPassword() async {
    try {
      await context.read<UserProvider>().sendPasswordResetEmail();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Wysłano email resetujący hasło. Sprawdź swoją skrzynkę.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Błąd: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  void _handleChangeEmail() {
    final emailController = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Zmień email'),
        content: SizedBox(
          width: 500,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Wpisz nowy adres email:'),
              const SizedBox(height: 10),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(
                  hintText: 'Nowy email',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Anuluj'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              if (emailController.text.isNotEmpty) {
                try {
                  await context.read<UserProvider>().updateEmail(emailController.text.trim());
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Email został zaktualizowany!')),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                     ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Błąd: $e'), backgroundColor: AppColors.error),
                    );
                  }
                }
              }
            },
            child: const Text('Zmień'),
          ),
        ],
      ),
    );
  }

  void _handleDeleteAccount() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Usuń konto', style: TextStyle(color: Colors.red)),
        content: const SizedBox(
          width: 500,
          child: Text(
            'UWAGA: Ta operacja jest nieodwracalna. Wszystkie Twoje dane zostaną usunięte. Czy na pewno chcesz kontynuować?'
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Anuluj'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext); // Close first dialog
              
              final user = context.read<UserProvider>().firebaseUser;
              if (user == null) return;
              
              // Check providers
              bool isGoogle = user.providerData.any((info) => info.providerId == 'google.com');
              bool isFacebook = user.providerData.any((info) => info.providerId == 'facebook.com');
              
              if (isGoogle) {
                 _showSocialDeleteDialog('Google', () => context.read<UserProvider>().reauthenticateWithGoogle());
              } else if (isFacebook) {
                 _showSocialDeleteDialog('Facebook', () => context.read<UserProvider>().reauthenticateWithFacebook());
              } else {
                 // Default to password
                 _showPasswordDeleteDialog();
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('USUŃ'),
          ),
        ],
      ),
    );
  }

  void _showPasswordDeleteDialog() {
    final passwordController = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Potwierdź hasło'),
        content: SizedBox(
          width: 500,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Aby usunąć konto, wprowadź swoje hasło:'),
              const SizedBox(height: 16),
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Hasło',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Anuluj'),
          ),
          TextButton(
            onPressed: () async {
              if (passwordController.text.isEmpty) return;
              
              // Close password dialog
              Navigator.pop(dialogContext);
              
              // Show loading dialog
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (loadingContext) => Center(child: WormLoader(size: 40)),
              );
              
              try {
                // 1. Re-authenticate
                await context.read<UserProvider>().reauthenticateWithPassword(passwordController.text);
                
                // 2. Delete Account
                await context.read<UserProvider>().deleteAccount();
                
                // 3. Success -> Navigate to Login
                if (mounted) {
                   Navigator.of(context).pop(); // Close loading
                   Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
                   ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Konto zostało trwale usunięte.')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  Navigator.of(context).pop(); // Close loading
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Błąd: $e'), backgroundColor: AppColors.error),
                  );
                }
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('POTWIERDŹ I USUŃ'),
          ),
        ],
      ),
    );
  }
  
  void _showSocialDeleteDialog(String providerName, Future<void> Function() verifyAction) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Weryfikacja $providerName'),
        content: SizedBox(
           width: 500,
           child: Text('Aby usunąć konto, musisz potwierdzić tożsamość logując się ponownie przez $providerName.'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Anuluj'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (loadingContext) => Center(child: WormLoader(size: 40)),
              );

              try {
                // 1. Re-authenticate
                await verifyAction();
                
                // 2. Delete Account
                await context.read<UserProvider>().deleteAccount();
                
                 if (mounted) {
                   Navigator.of(context).pop(); // Close loading
                   Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
                   ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Konto zostało trwale usunięte.')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  Navigator.of(context).pop(); // Close loading
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Błąd: $e'), backgroundColor: AppColors.error),
                  );
                }
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('ZWERYFIKUJ I USUŃ'),
          ),
        ],
      ),
    );
  }

  void _logout() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Wyloguj się'),
        content: const SizedBox(
           width: 500,
           child: Text('Czy na pewno chcesz się wylogować?'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Anuluj'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext); // Close dialog
              await context.read<UserProvider>().signOut();
              if (mounted) {
                Navigator.of(context).pushNamedAndRemoveUntil(
                  '/login',
                  (route) => false, // Remove all previous routes
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Wyloguj się'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        // REMOVED: Controller text synchronization from build() 
        // This was causing infinite rebuild loops on Flutter Web
        // Controllers are now only updated in initState and when user manually edits

        final theme = Theme.of(context);
        final colorScheme = theme.colorScheme;
        final isDark = theme.brightness == Brightness.dark;

        return Scaffold(
          backgroundColor: theme.scaffoldBackgroundColor,
          appBar: AppBar(
            title: Text(
              'Twój Profil',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: colorScheme.onSurface),
            ),
        centerTitle: true,
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Premium Card
              GestureDetector(
                onTap: () => Navigator.pushNamed(context, '/paywall'),
                child: _buildPremiumCard(),
              ),

              // Avatar Section
              Consumer<UserProvider>(
                builder: (context, user, child) {
                  // Get subscription tier info
                  final tier = user.subscriptionTier ?? SubscriptionTier.free;
                  final tierName = tier == SubscriptionTier.free 
                      ? 'Darmowy' 
                      : tier == SubscriptionTier.basic 
                          ? 'Basic' 
                          : 'Premium';
                  final tierColor = tier == SubscriptionTier.free 
                      ? Colors.grey 
                      : tier == SubscriptionTier.basic 
                          ? AppColors.primary 
                          : Colors.amber;
                  
                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      // Subscription Badge (above avatar)
                      Positioned(
                        top: 0,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: tierColor,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: tierColor.withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                tier == SubscriptionTier.free 
                                    ? Icons.card_giftcard 
                                    : tier == SubscriptionTier.basic 
                                        ? Icons.star 
                                        : Icons.diamond,
                                color: Colors.white,
                                size: 14,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                tierName,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      // Avatar (moved down to make space for badge)
                      Padding(
                        padding: const EdgeInsets.only(top: 45),
                        child: Container(
                          width: 100,
                          height: 100,
                          child: ClipOval(
                            child: _imageBytes != null
                                ? Image.memory(
                                    _imageBytes!,
                                    fit: BoxFit.cover,
                                    width: 100,
                                    height: 100,
                                  )
                                : user.avatarUrl != null
                                    ? CachedNetworkImage(
                                        imageUrl: user.avatarUrl!,
                                        fit: BoxFit.cover,
                                        width: 100,
                                        height: 100,
                                        placeholder: (context, url) => Container(
                                          color: AppColors.avatarColors[_selectedColorIndex],
                                          child: const Icon(
                                            Icons.person,
                                            size: 50,
                                            color: Colors.white,
                                          ),
                                        ),
                                        errorWidget: (context, url, error) {
                                          return Container(
                                            color: AppColors.avatarColors[_selectedColorIndex],
                                            child: const Icon(
                                              Icons.person,
                                              size: 50,
                                              color: Colors.white,
                                            ),
                                          );
                                        },
                                      )
                                    : Container(
                                        color: AppColors.avatarColors[_selectedColorIndex],
                                        child: const Icon(
                                          Icons.person,
                                          size: 50,
                                          color: Colors.white,
                                        ),
                                      ),
                          ),
                        ),
                      ),
                      
                      // Camera Icon (adjusted position)
                      Positioned(
                        bottom: 0, 
                        right: 0,
                        child: GestureDetector(
                          onTap: _pickImage,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: const Icon(Icons.camera_alt, size: 16, color: Colors.white),
                          ),
                        ),
                      )
                    ],
                  );
                },
              ),
              
              const SizedBox(height: 12),
              
              ValueListenableBuilder<TextEditingValue>(
                valueListenable: _nameController,
                builder: (context, value, child) {
                  return Text(
                    value.text.isEmpty ? 'Nazwa użytkownika' : value.text,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                  );
                },
              ),
              
              const Text(
                'Nazwa użytkownika',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textTertiary,
                ),
              ),
              
              const SizedBox(height: 32),

              // Form Fields
              Column(
                 crossAxisAlignment: CrossAxisAlignment.start,
                 children: [
                   Padding(
                     padding: const EdgeInsets.only(bottom: 8.0, left: 4),
                     child: Text('Nazwa użytkownika', style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant)),
                   ),
                   CustomTextField(
                    controller: _nameController,
                    prefixIcon: const Icon(Icons.person_outline),
                    validator: (value) => value!.isEmpty ? 'Wymagane' : null,
                  ),
                  const SizedBox(height: 16),
                  Padding(
                     padding: const EdgeInsets.only(bottom: 8.0, left: 4),
                     child: Text('Adres e-mail', style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant)),
                   ),
                  CustomTextField(
                    controller: _emailController,
                    enabled: false,
                    prefixIcon: const Icon(Icons.email_outlined),
                    suffixIcon: userProvider.isEmailVerified
                        ? Container(
                            margin: const EdgeInsets.all(8),
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.success.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                 Icon(Icons.check_circle, size: 14, color: AppColors.success),
                                 SizedBox(width: 4),
                                 Text('Zweryfikowany', style: TextStyle(color: AppColors.success, fontSize: 10, fontWeight: FontWeight.bold))
                              ],
                            ),
                          )
                        : InkWell(
                            onTap: () async {
                              try {
                                await userProvider.sendVerificationEmail();
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Wysłano link weryfikacyjny. Sprawdź pocztę.'),
                                      backgroundColor: AppColors.primary,
                                    ),
                                  );
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Błąd: $e'), backgroundColor: AppColors.error),
                                  );
                                }
                              }
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              margin: const EdgeInsets.all(8),
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: AppColors.error.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.error.withOpacity(0.3)),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                   Icon(Icons.touch_app, size: 14, color: AppColors.error),
                                   SizedBox(width: 4),
                                   Text('Kliknij, aby zweryfikować', style: TextStyle(color: AppColors.error, fontSize: 10, fontWeight: FontWeight.bold))
                                ],
                              ),
                            ),
                          ),
                  ),
                 ],
              ),

              const SizedBox(height: 24),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: CustomButton(
                      text: 'Anuluj',
                      onPressed: () {
                        // Unfocus keyboard
                        FocusScope.of(context).unfocus();
                        // Reset fields to original values
                        _loadUserData();
                        // Optional: Show feedback
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Zmiany zostały anulowane')),
                        );
                      },
                      type: CustomButtonType.outline,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: CustomButton(
                      text: 'Zapisz zmiany',
                      onPressed: _saveChanges,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),
              _buildSectionHeader('USTAWIENIA'),
              Container(
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    _buildNotificationSection(),
                    _buildDivider(),
                    _buildSubscriptionSection(),
                    _buildDivider(),
                    _buildMeasurementsSection(),
                    _buildDivider(),
                    _buildAppearanceSection(),
                    _buildDivider(),
                    _buildCurrencySection(), // Moved between Appearance and Language
                    _buildDivider(),
                    _buildLanguageSection(),
                    _buildDivider(),
                    _buildInfoSection(),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              // ...

              
              const SizedBox(height: 24),

              // Security Section
              Container(
                 decoration: BoxDecoration(
                   color: colorScheme.surface,
                   borderRadius: BorderRadius.circular(16),
                 ),
                 child: _buildSecuritySection(),
              ),

              const SizedBox(height: 32),

              // Subscription Management Button
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 2,
                ),
                onPressed: () => Navigator.of(context).pushNamed('/subscription'),
                icon: const Icon(Icons.card_membership, size: 20),
                label: const Text('Zarządzaj subskrypcją', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              
              const SizedBox(height: 12),
              
              // Logout Button
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error.withOpacity(0.1),
                  foregroundColor: AppColors.error,
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                onPressed: _logout,
                icon: const Icon(Icons.logout, size: 20),
                label: const Text('Wyloguj się', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
      },
    );
  }

  Widget _buildSectionHeader(String title) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: AppColors.textSecondary, // Secondary text usually fine in both modes if contrast is ok, but let's check
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildNotificationSection() {
    final colorScheme = Theme.of(context).colorScheme;
    final user = context.watch<UserProvider>();
    
    return Column(
      children: [
        ListTile(
          leading: Icon(Icons.notifications_none, color: colorScheme.onSurface),
          title: Text(
            'Powiadomienia',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: colorScheme.onSurface,
            ),
          ),
          trailing: AnimatedRotation(
            turns: isNotificationsExpanded ? 0.25 : 0.0,
            duration: const Duration(milliseconds: 200),
            child: const Icon(Icons.chevron_right, color: AppColors.primary),
          ),
          onTap: () {
            setState(() {
              _isNotificationsExpanded = !isNotificationsExpanded;
            });
          },
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        ),
        if (isNotificationsExpanded) ...[
          _buildSwitchItem('Powiadomienia Aplikacji', user.notifyApp, (v) => user.updateNotification(app: v)),
          _buildSwitchItem(
            'Powiadomienia Zakładki Mój Plan', 
            user.notifyPlan, 
            (v) => user.updateNotification(plan: v),
            isEnabled: user.notifyApp
          ),
          _buildSwitchItem(
            'Powiadomienia Zakładki Moja Dieta', 
            user.notifyDiet, 
            (v) => user.updateNotification(diet: v),
            isEnabled: user.notifyApp
          ),
          _buildSwitchItem(
            'Przypomnienie o Piciu Wody', 
            user.notifyWater, 
            (v) => user.updateNotification(water: v),
            isEnabled: user.notifyApp
          ),
          const SizedBox(height: 8), 
        ],
      ],
    );
  }
  
  Widget _buildMeasurementsSection() {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        ListTile(
          leading: Icon(Icons.favorite_border, color: colorScheme.onSurface),
          title: Text(
            'Pomiary',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: colorScheme.onSurface,
            ),
          ),
          trailing: AnimatedRotation(
            turns: isMeasurementsExpanded ? 0.25 : 0.0,
             duration: const Duration(milliseconds: 200),
            child: const Icon(Icons.chevron_right, color: AppColors.primary),
          ),
          onTap: () {
            setState(() {
              _isMeasurementsExpanded = !isMeasurementsExpanded;
            });
          },
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        ),
        if (isMeasurementsExpanded) ...[
          _buildMeasurementItem(
            label: 'Waga', 
            controller: _weightController,
            isEditing: _isWeightEditing ?? false,
            onEditToggle: () => setState(() => _isWeightEditing = !(_isWeightEditing ?? false)),
            onSave: () async {
              // Handle comma as decimal separator and remove non-numeric chars (except dot)
              String cleanText = _weightController.text.replaceAll(',', '.');
              cleanText = cleanText.replaceAll(RegExp(r'[^0-9.]'), '');
              
              final val = double.tryParse(cleanText);
              
              if (val != null) {
                // Update User Profile
                await context.read<UserProvider>().updateWeight(val);
                
                // Add to Progress Diary
                if (context.mounted) {
                   await context.read<ProgressProvider>().addWeightEntry(val);
                   
                   ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Zaktualizowano wagę i dodano wpis do dziennika!'),
                      backgroundColor: AppColors.success,
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              }
            },
          ),
          _buildMeasurementItem(
            label: 'Wzrost', 
            controller: _heightController,
            isEditing: _isHeightEditing ?? false,
            onEditToggle: () => setState(() => _isHeightEditing = !(_isHeightEditing ?? false)),
            onSave: () {
              final val = double.tryParse(_heightController.text.replaceAll(RegExp(r'[^0-9.]'), ''));
              if (val != null) {
                context.read<UserProvider>().updateHeight(val);
              }
            },
          ),
          _buildMeasurementItem(
            label: 'Wiek', 
            controller: _ageController,
            isEditing: _isAgeEditing ?? false,
            onEditToggle: () => setState(() => _isAgeEditing = !(_isAgeEditing ?? false)),
            onSave: () {
              final val = int.tryParse(_ageController.text.replaceAll(RegExp(r'[^0-9]'), ''));
              if (val != null) {
                context.read<UserProvider>().updateAge(val);
              }
            },
          ),
          _buildGenderItem(),
          const SizedBox(height: 8),
        ],
      ],
    );
  }

  Widget _buildGenderItem() {
    final user = context.watch<UserProvider>();
    final gender = user.gender;
    final colorScheme = Theme.of(context).colorScheme;
    
    String genderLabel = 'Nie wybrano';
    IconData genderIcon = Icons.help_outline;
    Color genderColor = Colors.grey;
    
    if (gender == 'male') {
      genderLabel = 'Mężczyzna';
      genderIcon = Icons.male;
      genderColor = const Color(0xFF3B82F6);
    } else if (gender == 'female') {
      genderLabel = 'Kobieta';
      genderIcon = Icons.female;
      genderColor = const Color(0xFFEC4899);
    }
    
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
      child: Row(
        children: [
          SizedBox(
            width: 70,
            child: Text(
              'Płeć',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
          ),
          Expanded(
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.light 
                    ? Colors.grey[100] 
                    : AppColors.surfaceVariantDark,
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Icon(genderIcon, color: genderColor, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    genderLabel,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.normal,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            height: 32,
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(8),
            ),
            child: TextButton(
              onPressed: () => _showGenderPicker(context),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                foregroundColor: AppColors.primary,
              ),
              child: const Text(
                'Zmień',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showGenderPicker(BuildContext context) {
    final user = context.read<UserProvider>();
    String? selectedGender = user.gender;
    
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Wybierz płeć'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Female option
            Card(
              color: selectedGender == 'female' ? const Color(0xFFEC4899).withOpacity(0.1) : null,
              child: InkWell(
                onTap: () {
                  user.updateGender('female');
                  Navigator.pop(dialogContext);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Płeć zaktualizowana: Kobieta'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEC4899).withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.female,
                          color: Color(0xFFEC4899),
                          size: 32,
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Text(
                        'Kobieta',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Male option
            Card(
              color: selectedGender == 'male' ? const Color(0xFF3B82F6).withOpacity(0.1) : null,
              child: InkWell(
                onTap: () {
                  user.updateGender('male');
                  Navigator.pop(dialogContext);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Płeć zaktualizowana: Mężczyzna'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF3B82F6).withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.male,
                          color: Color(0xFF3B82F6),
                          size: 32,
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Text(
                        'Mężczyzna',
                        style: TextStyle(
                          fontSize: 18,
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
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Anuluj'),
          ),
        ],
      ),
    );
  }

  Widget _buildMeasurementItem({
    required String label,
    required TextEditingController controller,
    required bool isEditing,
    required VoidCallback onEditToggle,
    required VoidCallback onSave,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    // Input BG: light grey in light mode, dark surface variant in dark mode
    final inputBg = isEditing 
        ? theme.colorScheme.surface 
        : (theme.brightness == Brightness.light ? Colors.grey[100] : AppColors.surfaceVariantDark);
    
    final borderColor = isEditing ? AppColors.primary : Colors.transparent;
    
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
      child: Row(
        children: [
          SizedBox(
            width: 70, 
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
          ),
          Expanded(
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: inputBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: borderColor),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Center(
                child: TextFormField(
                  controller: controller,
                  enabled: isEditing,
                  keyboardType: TextInputType.number,
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.normal, color: colorScheme.onSurface),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                  onFieldSubmitted: (_) {
                    onSave();
                    onEditToggle();
                  },
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            height: 32,
            decoration: BoxDecoration(
              color: isEditing ? AppColors.primary : const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(8),
            ),
            child: TextButton(
              onPressed: () {
                if (isEditing) {
                  onSave();
                }
                onEditToggle();
              },
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                foregroundColor: isEditing ? Colors.white : AppColors.primary,
              ),
              child: Text(
                isEditing ? 'Zapisz' : 'Edytuj',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchItem(String title, bool value, ValueChanged<bool> onChanged, {bool isEnabled = true}) {
    // For sub-items, we use the theme text color
    final colorScheme = Theme.of(context).colorScheme;
    final contentColor = isEnabled ? colorScheme.onSurface : colorScheme.onSurface.withOpacity(0.5);
    
    return Padding(
      padding: const EdgeInsets.fromLTRB(60, 0, 20, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 13, 
                fontWeight: FontWeight.w600,
                color: contentColor,
              ),
            ),
          ),
          Transform.scale(
            scale: 0.8,
            child: Switch(
              value: isEnabled ? value : false, // Visually uncheck if disabled
              onChanged: isEnabled ? onChanged : null,
              activeColor: Colors.white,
              activeTrackColor: AppColors.primary,
              inactiveThumbColor: Colors.white,
              inactiveTrackColor: isEnabled ? Colors.grey[300] : Colors.grey[200],
              trackOutlineColor: MaterialStateProperty.all(Colors.transparent),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsItem({
    required IconData icon, 
    required String title, 
    required VoidCallback onTap
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return ListTile(
      leading: Icon(icon, color: colorScheme.onSurface),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.bold, // Bolder font as in design
          fontSize: 15,
          color: colorScheme.onSurface,
        ),
      ),
      trailing: const Icon(Icons.chevron_right, color: AppColors.primary),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
    );
  }

  Widget _buildDivider() {
    return const Divider(height: 1, indent: 20, endIndent: 20); // Uses Theme divider color
  }

  Widget _buildLanguageSection() {
    final user = context.watch<UserProvider>();
    final currentLang = user.currentLanguage;
    final colorScheme = Theme.of(context).colorScheme;
    
    return Column(
      children: [
        ListTile(
          leading: Icon(Icons.language, color: colorScheme.onSurface),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
          title: Text(
            'Język Aplikacji',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: colorScheme.onSurface,
            ),
          ),
          trailing: AnimatedRotation(
            turns: isLanguageExpanded ? 0.25 : 0.0,
             duration: const Duration(milliseconds: 200),
            child: const Icon(Icons.chevron_right, color: AppColors.primary),
          ),
          onTap: () {
            setState(() {
              _isLanguageExpanded = !isLanguageExpanded;
            });
          },
        ),
        if (isLanguageExpanded) ...[
          _buildSwitchItem('Polski', currentLang == 'pl', (v) {
            if (v && currentLang != 'pl') user.changeLanguage('pl');
          }),
          _buildSwitchItem('Angielski', currentLang == 'en', (v) {
            _showComingSoonSnackBar();
          }),
          _buildSwitchItem('Niemiecki', currentLang == 'de', (v) {
             _showComingSoonSnackBar();
          }),
          const SizedBox(height: 8),
        ],
      ],
    );
  }

  Widget _buildCurrencySection() {
    final user = context.watch<UserProvider>();
    final currentCurrency = user.preferredCurrency;
    final colorScheme = Theme.of(context).colorScheme;
    
    // Currency icons and names
    final currencies = {
      'PLN': {'icon': '🇵🇱', 'name': 'Polski Złoty (zł)'},
      'EUR': {'icon': '🇪🇺', 'name': 'Euro (€)'},
      'USD': {'icon': '🇺🇸', 'name': 'US Dollar (\$)'},
      'GBP': {'icon': '🇬🇧', 'name': 'Funt brytyjski (£)'},
    };
    
    return Column(
      children: [
        ListTile(
          leading: Icon(Icons.payments_outlined, color: colorScheme.onSurface),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
          title: Text(
            'Preferencje płatności',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: colorScheme.onSurface,
            ),
          ),
          trailing: AnimatedRotation(
            turns: isCurrencyExpanded ? 0.25 : 0.0,
             duration: const Duration(milliseconds: 200),
            child: const Icon(Icons.chevron_right, color: AppColors.primary),
          ),
          onTap: () {
            setState(() {
              _isCurrencyExpanded = !isCurrencyExpanded;
            });
          },
        ),
        if (isCurrencyExpanded) ...[
          ...currencies.entries.map((entry) {
            final code = entry.key;
            final info = entry.value;
            return _buildSwitchItem(
              '${info['icon']} ${info['name']}',
              currentCurrency == code,
              (v) {
                if (v && currentCurrency != code) user.changeCurrency(code);
              },
            );
          }).toList(),
          const SizedBox(height: 8),
        ],
      ],
    );
  }

  Widget _buildInfoSection() {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        ListTile(
          leading: Icon(Icons.description_outlined, color: colorScheme.onSurface),
          title: Text(
            'INFORMACJE', 
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: colorScheme.onSurface,
            ),
          ),
          trailing: AnimatedRotation(
            turns: isInfoExpanded ? 0.25 : 0.0,
             duration: const Duration(milliseconds: 200),
            child: const Icon(Icons.chevron_right, color: AppColors.primary),
          ),
          onTap: () {
            setState(() {
              _isInfoExpanded = !isInfoExpanded;
            });
          },
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        ),
        if (isInfoExpanded) ...[
          _buildInfoItem('Polityka prywatności', '/privacy'),
          _buildInfoItem('Regulamin', '/terms'),
          // Test Notification Button (Debug)
          ListTile(
            leading: const Icon(Icons.notifications_active, color: Colors.amber),
            title: const Text(
              'Przetestuj powiadomienie',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
            onTap: () async {
              try {
                await NotificationService().showTestNotification();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('✅ Wysłano testowe powiadomienie! Sprawdź pasek powiadomień.'),
                      backgroundColor: AppColors.success,
                      duration: Duration(seconds: 3),
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('❌ Błąd: $e'),
                      backgroundColor: AppColors.error,
                      duration: const Duration(seconds: 5),
                    ),
                  );
                }
              }
            },
            contentPadding: const EdgeInsets.symmetric(horizontal: 20),
          ),
          const SizedBox(height: 8),
        ],
      ],
    );
  }

  Widget _buildInfoItem(String title, String route) {
    final colorScheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: () => Navigator.of(context).pushNamed(route),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
        child: Row(
          children: [
            const Icon(Icons.chevron_right, size: 20, color: AppColors.primary),
            const SizedBox(width: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: colorScheme.onSurface,
              ),
            ),
            const Spacer(),
            Icon(
              Icons.arrow_forward_ios,
              size: 14,
              color: colorScheme.onSurface.withOpacity(0.4),
            ),
          ],
        ),
      ),
    );
  }


  void _showComingSoonSnackBar() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Ta opcja językowa będzie dostępna wkrótce!'),
        duration: Duration(seconds: 2),
      ),
    );
  }
}
