import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/subscription_tier.dart';
import '../../../providers/user_provider.dart';
import '../../../services/subscription_service.dart';

class PaywallScreen extends StatefulWidget {
  const PaywallScreen({super.key});

  @override
  State<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends State<PaywallScreen> with TickerProviderStateMixin {
  final _subscriptionService = SubscriptionService();
  bool _isLoading = true;
  List<Package> _packages = [];
  Package? _selectedPackage;
  late AnimationController _shimmerController;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
    
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    
    _loadOfferings();
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _loadOfferings() async {
    setState(() => _isLoading = true);
    try {
      await _subscriptionService.initialize();
      final packages = await _subscriptionService.fetchOfferings();
      
      // If no packages (e.g., on Web), use mock data
      if (packages.isEmpty) {
        debugPrint('📦 No packages from RevenueCat - using mock data for preview');
        setState(() {
          _packages = []; // Will trigger mock UI
          _selectedPackage = null;
          _isLoading = false;
        });
        return;
      }
      
      setState(() {
        _packages = packages;
        // Pre-select monthly if available, otherwise first
        _selectedPackage = _packages.firstWhere(
          (p) => p.packageType == PackageType.monthly,
          orElse: () => _packages.isNotEmpty ? _packages.first : throw Exception(),
        );
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading offerings: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _purchaseSelectedPackage() async {
    if (_selectedPackage == null) return;

    setState(() => _isLoading = true);
    HapticFeedback.mediumImpact();

    final result = await _subscriptionService.purchasePackage(_selectedPackage!);
    
    if (result) {
      if (!mounted) return;
      await context.read<UserProvider>().refreshPremiumStatus();
      
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.celebration, color: Colors.white),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Witaj w FitPlan Premium! 🎉',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 4),
          ),
        );
      }
    } else {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _restorePurchases() async {
    setState(() => _isLoading = true);
    final result = await _subscriptionService.restorePurchases();
    
    if (result) {
      if (!mounted) return;
      await context.read<UserProvider>().refreshPremiumStatus();
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Przywrócono zakupy! Witaj z powrotem.'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } else {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Nie znaleziono aktywnych subskrypcji.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildTopBar(),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                children: [
                  const SizedBox(height: 20),
                  _buildPremiumBadge(),
                  const SizedBox(height: 24),
                  _buildTitle(),
                  const SizedBox(height: 32),
                  _buildSocialProof(),
                  const SizedBox(height: 32),
                  _buildBenefitsGrid(),
                  const SizedBox(height: 40),
                  if (_isLoading && _packages.isEmpty)
                    const SizedBox(
                      height: 200,
                      child: Center(
                        child: CircularProgressIndicator(color: AppColors.primary),
                      ),
                    )
                  else
                    _buildPricingCards(),
                  const SizedBox(height: 24),
                  TextButton(
                    onPressed: _isLoading ? null : _restorePurchases,
                    child: const Text(
                      'Masz już konto Premium? Przywróć zakupy',
                      style: TextStyle(
                        color: Colors.white60,
                        fontSize: 13,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                    child: Text(
                      'Subskrypcja odnawia się automatycznie. Możesz anulować w dowolnym momencie w ustawieniach Google Play / App Store. Regulamin i Polityka Prywatności dostępne w ustawieniach aplikacji.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white24, fontSize: 10, height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
            _buildCTAButton(),
          ],
        ),
      ),
  );
}

Widget _buildAnimatedBackground() {
  return Positioned.fill(
      child: AnimatedBuilder(
        animation: _shimmerController,
        builder: (context, child) {
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: const [
                  Color(0xFF0A0E27),
                  Color(0xFF1A1F3A),
                  Color(0xFF0A0E27),
                ],
                stops: [
                  _shimmerController.value - 0.3,
                  _shimmerController.value,
                  _shimmerController.value + 0.3,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const SizedBox(width: 48), // Balance the close button
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.primary.withOpacity(0.3)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.verified, color: AppColors.primary, size: 14),
                SizedBox(width: 4),
                Text(
                  'Oferta Premiowa',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, color: Colors.white70, size: 20),
            ),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumBadge() {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return Transform.scale(
          scale: 1.0 + (_pulseController.value * 0.05),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppColors.primary.withOpacity(0.3),
                  AppColors.primary.withOpacity(0.1),
                  Colors.transparent,
                ],
              ),
            ),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.2),
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.primary, width: 2),
              ),
              child: const Icon(
                Icons.diamond,
                color: AppColors.primary,
                size: 56,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTitle() {
    return Column(
      children: [
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [AppColors.primary, AppColors.accent],
          ).createShader(bounds),
          child: const Text(
            'Odblokuj Wszystkie Funkcje',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
              height: 1.2,
            ),
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'Zainwestuj w swoją przemianę 💪',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white70,
            fontSize: 17,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildSocialProof() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 80,
            height: 32,
            child: Stack(
              children: List.generate(3, (index) {
                return Positioned(
                  left: index * 20.0,
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primary.withOpacity(0.5),
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Icon(Icons.person, size: 16, color: Colors.white),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(width: 70),
          const Flexible(
            child: Text(
              '10,000+ użytkowników premium',
              style: TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBenefitsGrid() {
    final benefits = [
      {'icon': Icons.all_inclusive, 'title': 'Nielimitowane\nPlany AI'},
      {'icon': Icons.restaurant_menu, 'title': 'Pełne Diety\n28-dniowe'},
      {'icon': Icons.analytics_outlined, 'title': 'Zaawansowana\nAnalityka'},
      {'icon': Icons.psychology, 'title': 'Priorytetowy\nAsystent AI'},
      {'icon': Icons.block, 'title': 'Zero\nReklam'},
      {'icon': Icons.workspace_premium, 'title': 'Wsparcie\nPriority'},
    ];

    // Using Wrap instead of GridView to avoid layout issues in SingleChildScrollView
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      alignment: WrapAlignment.center,
      children: benefits.map((benefit) {
        return Container(
          width: 96,
          height: 96,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.primary.withOpacity(0.15),
                AppColors.primary.withOpacity(0.05),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.primary.withOpacity(0.2),
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                benefit['icon'] as IconData,
                color: AppColors.primary,
                size: 24,
              ),
              const SizedBox(height: 6),
              Text(
                benefit['title'] as String,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  height: 1.2,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPricingCards() {
    // Show mock packages for Web/development
    if (_packages.isEmpty) {
      return _buildMockPricingCards();
    }
    
    return Column(
      children: [
        const Text(
          'Wybierz swój plan',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        ..._packages.map((pkg) => _buildPackageCard(pkg)),
      ],
    );
  }

  Widget _buildMockPricingCards() {
    // Simplified 3-tier pricing model (no duration selector to avoid Web rebuild issues)
    final mockPlans = [
      {
        'title': 'Darmowy Trial',
        'price': 'Za darmo',
        'subtitle': 'Pełny dostęp przez 7 dni',
        'badge': 'JEDNORAZOWO',
      },
      {
        'title': 'Plan Treningowy',
        'price': '15,99 zł',
        'subtitle': 'Miesięczna subskrypcja',
        'badge': null,
      },
      {
        'title': 'Plan Pełny',
        'price': '20,99 zł',
        'subtitle': 'Trening + Dieta / miesiąc',
        'badge': 'NAJPOPULARNIEJSZY',
      },
    ];

    return Column(
      children: [
        const Text(
          'Wybierz swój plan',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        // Web warning banner
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.orange.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.orange.withOpacity(0.5)),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.info_outline, color: Colors.orange, size: 16),
              SizedBox(width: 6),
              Text(
                'Tryb podglądu (Web) - Użyj urządzenia mobilnego do zakupu',
                style: TextStyle(color: Colors.orange, fontSize: 11),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Pricing cards
        ...mockPlans.asMap().entries.map((entry) {
          final index = entry.key;
          final plan = entry.value;
          
          return _buildMockPackageCard(
            title: plan['title'] as String,
            price: plan['price'] as String,
            subtitle: plan['subtitle'] as String,
            badge: plan['badge'] as String?,
            isSelected: index == 2, // Pre-select Full plan
            onTap: () {}, // No-op to avoid setState
            savings: null,
          );
        }),
      ],
    );
  }

  Widget _buildMockPackageCard({
    required String title,
    required String price,
    required String subtitle,
    String? badge,
    required bool isSelected,
    required VoidCallback onTap,
    String? savings,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  colors: [
                    AppColors.primary.withOpacity(0.25),
                    AppColors.primary.withOpacity(0.15),
                  ],
                )
              : null,
          color: isSelected ? null : Colors.white.withOpacity(0.05),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.white10,
            width: isSelected ? 2.5 : 1.5,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Column(
          children: [
            if (badge != null)
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.accent,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  badge,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? AppColors.primary : Colors.white30,
                      width: 2,
                    ),
                    color: isSelected ? AppColors.primary : Colors.transparent,
                  ),
                  child: isSelected
                      ? const Icon(Icons.check, size: 16, color: Colors.white)
                      : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.white70,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      if (subtitle.isNotEmpty)
                        Text(
                          subtitle,
                          style: TextStyle(
                            color: isSelected
                                ? AppColors.accent
                                : AppColors.white40,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                    ],
                  ),
                ),
                // Column to stack price and savings
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      price,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (savings != null && savings.isNotEmpty)
                      Text(
                        savings,
                        style: TextStyle(
                          color: Colors.green.shade300,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPackageCard(Package package) {
    final isSelected = _selectedPackage == package;
    final product = package.storeProduct;
    final userProvider = context.watch<UserProvider>();
    final preferredCurrency = userProvider.preferredCurrency;
    
    // Base prices in PLN (new pricing structure)
    final Map<String, double> basePricesPLN = {
      'monthly': 15.99,  // Plan Treningowy
      'annual': 20.99,   // Plan Pełny
      'lifetime': 20.99,
    };
    
    // Exchange rates (PLN to other currencies)
    final Map<String, double> exchangeRates = {
      'EUR': 0.23,
      'USD': 0.25,
      'GBP': 0.20,
    };
    
    // Helper function: convert price with 5% markup and .99 ending
    String Function(double, String) convertPrice = (plnPrice, currency) {
      if (currency == 'PLN') {
        return '${plnPrice.toStringAsFixed(2).replaceAll('.', ',')} zł';
      }
      
      final rate = exchangeRates[currency]!;
      final converted = (plnPrice * rate * 1.05);
      final rounded = converted.floor();
      final finalPrice = rounded + 0.99;
      
      if (currency == 'USD') return '\$${finalPrice.toStringAsFixed(2)}';
      if (currency == 'EUR') return '${finalPrice.toStringAsFixed(2)} €';
      return '${finalPrice.toStringAsFixed(2)} £';
    };
    
    String price = product.priceString;
    // Override with user's preferred currency using conversion
    if (price.contains('\$') || price.contains('USD')) {
       String packageKey = 'monthly';
       if (package.packageType == PackageType.monthly) packageKey = 'monthly';
       else if (package.packageType == PackageType.annual) packageKey = 'annual';
       else if (package.packageType == PackageType.lifetime) packageKey = 'lifetime';
       
       price = convertPrice(basePricesPLN[packageKey]!, preferredCurrency);
    }
    
    String title = 'Premium';
    String subtitle = '';
    String? badge;
    
    if (package.packageType == PackageType.monthly) {
      title = 'Miesięczny';
      subtitle = 'Odnawiane co miesiąc';
    } else if (package.packageType == PackageType.annual) {
      title = 'Roczny';
      subtitle = 'Oszczędzasz 40%!';
      badge = 'NAJLEPSZA OFERTA';
    } else if (package.packageType == PackageType.lifetime) {
      title = 'Dożywotni';
      subtitle = 'Płać raz, używaj wiecznie';
      badge = 'SUPER OFERTA';
    }

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _selectedPackage = package);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  colors: [
                    AppColors.primary.withOpacity(0.25),
                    AppColors.primary.withOpacity(0.15),
                  ],
                )
              : null,
          color: isSelected ? null : Colors.white.withOpacity(0.05),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.white10,
            width: isSelected ? 2.5 : 1.5,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Column(
          children: [
            if (badge != null)
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.accent,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  badge,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? AppColors.primary : Colors.white30,
                      width: 2,
                    ),
                    color: isSelected ? AppColors.primary : Colors.transparent,
                  ),
                  child: isSelected
                      ? const Icon(Icons.check, size: 16, color: Colors.white)
                      : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.white70,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      if (subtitle.isNotEmpty)
                        Text(
                          subtitle,
                          style: TextStyle(
                            color: isSelected
                                ? AppColors.accent
                                : AppColors.white40,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      price,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (package.packageType == PackageType.annual)
                      const Text(
                        '~3.33/mies',
                        style: TextStyle(
                          color: AppColors.white40,
                          fontSize: 11,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          const Icon(Icons.cloud_off, color: Colors.white30, size: 48),
          const SizedBox(height: 16),
          const Text(
            'Nie można załadować ofert',
            style: TextStyle(color: Colors.white70, fontSize: 16),
          ),
          const SizedBox(height: 8),
          const Text(
            'Sprawdź połączenie internetowe',
            style: TextStyle(color: AppColors.white40, fontSize: 13),
          ),
          const SizedBox(height: 24),
          TextButton.icon(
            onPressed: _loadOfferings,
            icon: const Icon(Icons.refresh, color: AppColors.primary),
            label: const Text(
              'Spróbuj ponownie',
              style: TextStyle(color: AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCTAButton() {
    final isWebMode = _packages.isEmpty;
    
    return Padding(
      padding: const EdgeInsets.all(24),
      child: AnimatedBuilder(
        animation: _pulseController,
        builder: (context, child) {
          return Transform.scale(
            scale: 1.0 + (_pulseController.value * 0.02),
            child: ElevatedButton(
              onPressed: _isLoading
                  ? null
                  : () {
                      if (isWebMode) {
                        // Show alert on Web
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Tryb podglądu'),
                            content: const Text(
                              'Zakupy in-app nie są dostępne w wersji webowej.\n\n'
                              'Aby kupić subskrypcję Premium, użyj aplikacji mobilnej na urządzeniu Android lub iOS.',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('OK'),
                              ),
                            ],
                          ),
                        );
                      } else if (_selectedPackage != null) {
                        _purchaseSelectedPackage();
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 20),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 8,
                shadowColor: AppColors.primary.withOpacity(0.5),
              ),
              child: _isLoading && !isWebMode
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(isWebMode ? Icons.info_outline : Icons.rocket_launch, size: 22),
                        const SizedBox(width: 12),
                        Text(
                          isWebMode ? 'Zobacz Więcej' : 'Rozpocznij Premium Teraz',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
            ),
          );
        },
      ),
    );
  }
}
