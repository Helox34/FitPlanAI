enum SubscriptionTier {
  free,
  basic,
  premium,
}

class SubscriptionPlan {
  final SubscriptionTier tier;
  final String name;
  final String monthlyPrice;
  final String yearlyPrice;
  final String? yearlyDiscount; // e.g., "PROMOCJA!"
  final List<String> features;
  final List<String> limitations;

  const SubscriptionPlan({
    required this.tier,
    required this.name,
    required this.monthlyPrice,
    required this.yearlyPrice,
    this.yearlyDiscount,
    required this.features,
    this.limitations = const [],
  });

  static const SubscriptionPlan free = SubscriptionPlan(
    tier: SubscriptionTier.free,
    name: 'Darmowy',
    monthlyPrice: '0 zł',
    yearlyPrice: '0 zł',
    features: [
      'Podstawowy plan treningowy AI (1 plan)',
      'Podstawowy plan żywieniowy AI (1 plan)',
      'Chatbot AI (3 pytania/dzień)',
      'Ograniczona biblioteka ćwiczeń',
    ],
    limitations: [
      'Brak śledzenia postępów',
      'Brak personalizacji',
      'Brak eksportu danych',
      'Reklamy w aplikacji',
    ],
  );

  static const SubscriptionPlan basic = SubscriptionPlan(
    tier: SubscriptionTier.basic,
    name: 'Basic',
    monthlyPrice: '30 zł',
    yearlyPrice: '300 zł',
    yearlyDiscount: 'PROMOCJA!',
    features: [
      '7 DNI ZA DARMO!',
      'Zaawansowane plany treningowe AI',
      'Zaawansowane plany żywieniowe AI',
      'Pełna historia postępów',
      'Chatbot AI (20 pytań/dzień)',
      'Pełna biblioteka ćwiczeń',
      'Powiadomienia o treningach',
      'Eksport danych (PDF)',
    ],
    limitations: [
      'Ograniczone reklamy',
    ],
  );

  static const SubscriptionPlan premium = SubscriptionPlan(
    tier: SubscriptionTier.premium,
    name: 'Premium',
    monthlyPrice: '50 zł',
    yearlyPrice: '500 zł',
    yearlyDiscount: 'PROMOCJA!',
    features: [
      'Wszystko z Basic',
      'Treningi na żywo',
      'Chatbot AI (nieograniczone)',
      'Konsultacje z wirtualnym trenerem',
      'Zaawansowana analityka',
      'Priorytetowe wsparcie',
      'Eksport danych (PDF, Excel, JSON)',
      'Integracje fitness (Apple Health, Google Fit)',
      'Brak reklam',
      'Wczesny dostęp do nowości',
    ],
  );

  static List<SubscriptionPlan> get allPlans => [free, basic, premium];
  
  static SubscriptionPlan fromTier(SubscriptionTier tier) {
    switch (tier) {
      case SubscriptionTier.free:
        return free;
      case SubscriptionTier.basic:
        return basic;
      case SubscriptionTier.premium:
        return premium;
    }
  }
}
