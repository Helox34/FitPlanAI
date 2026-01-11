import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../providers/user_provider.dart';
import '../../../providers/progress_provider.dart';
import '../../../models/subscription_plan.dart';
import '../../../services/notification_service.dart';

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

  // Appearance State
  bool? _isAppearanceExpanded;

  // Info State
  bool? _isInfoExpanded;

  // Safe getters
  bool get isMeasurementsExpanded => _isMeasurementsExpanded ?? false;
  bool get isAppearanceExpanded => _isAppearanceExpanded ?? false;
  bool get isLanguageExpanded => _isLanguageExpanded ?? false;
  bool get isInfoExpanded => _isInfoExpanded ?? false;
  bool get isNotificationsExpanded => _isNotificationsExpanded ?? false;



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

  void _changePassword() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Zmień hasło'),
        content: const Text('Funkcja zmiany hasła będzie dostępna wkrótce.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _logout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Wyloguj się'),
        content: const Text('Czy na pewno chcesz się wylogować?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Anuluj'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context); // Close dialog
              await context.read<UserProvider>().signOut();
              if (context.mounted) {
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
        // Sync text fields with provider if not currently editing
        if (!(_isWeightEditing ?? false) && userProvider.weight != null) {
          final text = '${userProvider.weight} kg';
          if (_weightController.text != text) _weightController.text = text;
        }
        if (!(_isHeightEditing ?? false) && userProvider.height != null) {
          final text = '${userProvider.height} cm';
          if (_heightController.text != text) _heightController.text = text;
        }
        if (!(_isAgeEditing ?? false) && userProvider.age != null) {
          final text = '${userProvider.age} lat';
          if (_ageController.text != text) _ageController.text = text;
        }

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
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: colorScheme.onSurface),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
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
                                    ? Image.network(
                                        user.avatarUrl!,
                                        fit: BoxFit.cover,
                                        width: 100,
                                        height: 100,
                                        errorBuilder: (context, error, stackTrace) {
                                          debugPrint('Error loading avatar: $error');
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
                    suffixIcon: Container(
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
                      onPressed: () => Navigator.pop(context),
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
                    _buildSettingsItem(
                      icon: Icons.emoji_events_outlined, 
                      title: 'Preferencje wyzwań',
                      onTap: () {},
                    ),
                    _buildDivider(),
                    _buildMeasurementsSection(),
                    _buildDivider(),
                    _buildAppearanceSection(),
                    _buildDivider(),
                    _buildSettingsItem(
                      icon: Icons.card_membership,
                      title: 'Zarządzaj subskrypcją',
                      onTap: () {
                         ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Funkcja zarządzania subskrypcją wkrótce dostępna')),
                        );
                      },
                    ),
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

              // Security Banner
              Container(
                 padding: const EdgeInsets.all(16),
                 decoration: BoxDecoration(
                   color: colorScheme.surface,
                   borderRadius: BorderRadius.circular(16),
                 ),
                 child: Row(
                   children: [
                     Container(
                       padding: const EdgeInsets.all(10),
                       decoration: BoxDecoration(
                         color: Colors.orange.withOpacity(0.1),
                         borderRadius: BorderRadius.circular(12),
                       ),
                       child: const Icon(Icons.lock, color: Colors.orange),
                     ),
                     const SizedBox(width: 16),
                     Expanded(
                       child: Column(
                         crossAxisAlignment: CrossAxisAlignment.start,
                         children: [
                           const Text(
                             'Hasło i bezpieczeństwo',
                             style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                           ),
                           const SizedBox(height: 4),
                           Text(
                             'Zapomniane hasło? Możesz je zresetować.',
                             style: TextStyle(color: Colors.grey[400], fontSize: 11),
                           ),
                         ],
                       ),
                     ),
                     TextButton(
                       onPressed: _changePassword,
                       child: const Text('Zmień hasło', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                     )
                   ],
                 ),
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
          const SizedBox(height: 8),
        ],
      ],
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
              await NotificationService().showTestNotification();
              if (mounted) {
                 ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Wysłano testowe powiadomienie! Sprawdź pasek powiadomień.')),
                );
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
