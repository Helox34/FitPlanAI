import 'package:flutter/material.dart';

// Subscription Tier Definitions
enum SubscriptionTier {
  free,
  basic,
  pro,
  lifetime;

  String get displayName {
    switch (this) {
      case SubscriptionTier.free:
        return 'Free';
      case SubscriptionTier.basic:
        return 'Basic';
      case SubscriptionTier.pro:
        return 'Pro';
      case SubscriptionTier.lifetime:
        return 'Lifetime';
    }
  }

  String get displayNamePL {
    switch (this) {
      case SubscriptionTier.free:
        return 'Darmowy';
      case SubscriptionTier.basic:
        return 'Podstawowy';
      case SubscriptionTier.pro:
        return 'Premium';
      case SubscriptionTier.lifetime:
        return 'Dożywotni';
    }
  }

  // Feature limits
  int get aiGenerationsPerMonth {
    switch (this) {
      case SubscriptionTier.free:
        return 3; // 3 free generations
      case SubscriptionTier.basic:
        return 10;
      case SubscriptionTier.pro:
        return -1; // Unlimited
      case SubscriptionTier.lifetime:
        return -1; // Unlimited
    }
  }

  bool get hasAdvancedAnalytics {
    return this == SubscriptionTier.pro || this == SubscriptionTier.lifetime;
  }

  bool get hasPrioritySupport {
    return this == SubscriptionTier.pro || this == SubscriptionTier.lifetime;
  }

  bool get hasNoAds {
    return this != SubscriptionTier.free;
  }

  bool get hasMealReplacements {
    return this != SubscriptionTier.free;
  }

  bool get hasFullDietPlans {
    return this == SubscriptionTier.pro || this == SubscriptionTier.lifetime;
  }

  // Tier color for UI
  Color get tierColor {
    switch (this) {
      case SubscriptionTier.free:
        return const Color(0xFF9E9E9E); // Gray
      case SubscriptionTier.basic:
        return const Color(0xFF42A5F5); // Blue
      case SubscriptionTier.pro:
        return const Color(0xFFFFD700); // Gold
      case SubscriptionTier.lifetime:
        return const Color(0xFFE040FB); // Purple/Diamond
    }
  }

  IconData get tierIcon {
    switch (this) {
      case SubscriptionTier.free:
        return Icons.card_giftcard;
      case SubscriptionTier.basic:
        return Icons.star;
      case SubscriptionTier.pro:
        return Icons.workspace_premium;
      case SubscriptionTier.lifetime:
        return Icons.diamond;
    }
  }
}
