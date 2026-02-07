import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'dart:io' show Platform;

class SubscriptionService {
  static final SubscriptionService _instance = SubscriptionService._internal();
  factory SubscriptionService() => _instance;
  SubscriptionService._internal();

  /// API Keys from RevenueCat Dashboard
  static const _googleApiKey = 'test_kczwnDZcYzXBnQtmkDlhdlxpnoy';
  static const _appleApiKey = 'test_kczwnDZcYzXBnQtmkDlhdlxpnoy';
  
  /// Entitlement ID configured in RevenueCat
  static const _entitlementId = 'Aionix Studio';

  bool _isInitialized = false;
  bool _isWeb = kIsWeb;

  Future<void> initialize() async {
    if (_isInitialized) return;

    // Web doesn't support RevenueCat
    if (_isWeb) {
      _isInitialized = true;
      debugPrint('⚠️ RevenueCat not supported on Web - using mock mode');
      return;
    }

    try {
      await Purchases.setLogLevel(LogLevel.debug);

      PurchasesConfiguration? configuration;
      if (Platform.isAndroid) {
        configuration = PurchasesConfiguration(_googleApiKey);
      } else if (Platform.isIOS) {
        configuration = PurchasesConfiguration(_appleApiKey);
      }

      if (configuration != null) {
        await Purchases.configure(configuration);
        _isInitialized = true;
        debugPrint('✅ RevenueCat initialized');
      }
    } catch (e) {
      debugPrint('❌ RevenueCat initialization failed: $e');
    }
  }

  /// Check if user has active premium access
  Future<bool> checkPremiumStatus() async {
    // Mock always returns false on web
    if (_isWeb) {
      debugPrint('🌐 Web mock: Premium status = false');
      return false;
    }

    try {
      final customerInfo = await Purchases.getCustomerInfo();
      return customerInfo.entitlements.all[_entitlementId]?.isActive ?? false;
    } on PlatformException catch (e) {
      debugPrint('❌ Error checking premium status: $e');
      return false;
    }
  }

  /// Fetch available offerings (products)
  Future<List<Package>> fetchOfferings() async {
    // Return mock packages on web for testing
    if (_isWeb) {
      debugPrint('🌐 Web mock: Returning mock packages');
      return _getMockPackages();
    }

    try {
      final offerings = await Purchases.getOfferings();
      final current = offerings.current;
      return current != null ? current.availablePackages : [];
    } on PlatformException catch (e) {
      debugPrint('❌ Error fetching offerings: $e');
      return [];
    }
  }

  /// Purchase a package
  Future<bool> purchasePackage(Package package) async {
    // Mock purchase on web - always succeeds
    if (_isWeb) {
      debugPrint('🌐 Web mock: Purchase simulated for ${package.identifier}');
      await Future.delayed(const Duration(seconds: 1)); // Simulate API call
      return true;
    }

    try {
      final customerInfo = await Purchases.purchasePackage(package);
      return customerInfo.entitlements.all[_entitlementId]?.isActive ?? false;
    } on PlatformException catch (e) {
      final errorCode = PurchasesErrorHelper.getErrorCode(e);
      if (errorCode == PurchasesErrorCode.purchaseCancelledError) {
        debugPrint('User cancelled purchase');
      } else {
        debugPrint('❌ Purchase error: $e');
      }
      return false;
    }
  }

  /// Restore purchases
  Future<bool> restorePurchases() async {
    // Mock restore on web - returns false (no purchases)
    if (_isWeb) {
      debugPrint('🌐 Web mock: No purchases to restore');
      return false;
    }

    try {
      final customerInfo = await Purchases.restorePurchases();
      return customerInfo.entitlements.all[_entitlementId]?.isActive ?? false;
    } on PlatformException catch (e) {
      debugPrint('❌ Error restoring purchases: $e');
      return false;
    }
  }

  /// Create mock packages for web testing
  List<Package> _getMockPackages() {
    // Since Package is from RevenueCat and can't be constructed directly,
    // we return empty list and handle it in the UI
    // The Paywall will need to show mock data directly
    return [];
  }
}
