import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/subscription_plan.dart';
import '../../../models/subscription_tier.dart';
import '../../../providers/user_provider.dart';

class SubscriptionScreen extends StatelessWidget {
  const SubscriptionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final userProvider = context.watch<UserProvider>();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(
          'Zarządzaj Subskrypcją',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Current Plan Section
            _buildCurrentPlanCard(context, userProvider),
            
            const SizedBox(height: 32),
            
            Text(
              'Dostępne plany',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Subscription Plans
            ...SubscriptionPlan.allPlans.map((plan) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _buildPlanCard(context, plan, userProvider),
            )),
            
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentPlanCard(BuildContext context, UserProvider userProvider) {
    final colorScheme = Theme.of(context).colorScheme;
    final currentPlan = SubscriptionPlan.fromTier(userProvider.subscriptionTier ?? SubscriptionTier.free);
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, Color(0xFF00D9A5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.star, color: Colors.white, size: 24),
              const SizedBox(width: 8),
              Text(
                'Twój obecny plan',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            currentPlan.name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            currentPlan.tier == SubscriptionTier.free
                ? 'Bezpłatny plan'
                : 'Ważny do: ${_formatExpiryDate(userProvider.subscriptionExpiryDate)}',
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanCard(BuildContext context, SubscriptionPlan plan, UserProvider userProvider) {
    final colorScheme = Theme.of(context).colorScheme;
    final isCurrentPlan = userProvider.subscriptionTier == plan.tier;
    final isPremium = plan.tier == SubscriptionTier.pro;
    
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCurrentPlan 
              ? AppColors.primary 
              : colorScheme.outline.withOpacity(0.2),
          width: isCurrentPlan ? 2 : 1,
        ),
        boxShadow: [
          if (isPremium)
            BoxShadow(
              color: Colors.amber.withOpacity(0.2),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with icon and name
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isPremium 
                  ? Colors.amber.withOpacity(0.1)
                  : colorScheme.surfaceContainerHighest.withOpacity(0.3),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                _getPlanIcon(plan.tier),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        plan.name,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      if (isCurrentPlan)
                        Container(
                          margin: const EdgeInsets.only(top: 4),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'Aktualny plan',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Pricing
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      plan.monthlyPrice,
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    if (plan.tier != SubscriptionTier.free) ...[
                      Text(
                        ' / miesiąc',
                        style: TextStyle(
                          fontSize: 14,
                          color: colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ],
                ),
                
                if (plan.yearlyDiscount != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          plan.yearlyDiscount!,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${plan.yearlyPrice} / rok (oszczędź ${_calculateSavings(plan)})',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ],
                
                const SizedBox(height: 20),
                const Divider(),
                const SizedBox(height: 16),
                
                // Features
                ...plan.features.map((feature) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.check_circle,
                        color: AppColors.success,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          feature,
                          style: TextStyle(
                            fontSize: 14,
                            color: colorScheme.onSurface,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                )),
                
                // Limitations
                if (plan.limitations.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  ...plan.limitations.map((limitation) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.cancel,
                          color: colorScheme.onSurface.withOpacity(0.4),
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            limitation,
                            style: TextStyle(
                              fontSize: 14,
                              color: colorScheme.onSurface.withOpacity(0.6),
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )),
                ],
                
                const SizedBox(height: 20),
                
                // Action Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isCurrentPlan 
                        ? null 
                        : () => _handleUpgrade(context, plan, userProvider),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isCurrentPlan 
                          ? colorScheme.surfaceContainerHighest 
                          : (isPremium ? Colors.amber : AppColors.primary),
                      foregroundColor: isCurrentPlan 
                          ? colorScheme.onSurface.withOpacity(0.5)
                          : Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: isCurrentPlan ? 0 : 2,
                    ),
                    child: Text(
                      isCurrentPlan 
                          ? 'Aktualny plan' 
                          : (plan.tier == SubscriptionTier.free 
                              ? 'Przejdź na darmowy' 
                              : 'Wybierz plan'),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _getPlanIcon(SubscriptionTier tier) {
    switch (tier) {
      case SubscriptionTier.free:
        return Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.grey.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.card_giftcard, color: Colors.grey, size: 24),
        );
      case SubscriptionTier.basic:
        return Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.star, color: AppColors.primary, size: 24),
        );
      case SubscriptionTier.pro:
        return Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.amber.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.diamond, color: Colors.amber, size: 24),
        );
      case SubscriptionTier.lifetime:
        return Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.purple.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.diamond, color: Colors.purple, size: 24),
        );
    }
  }

  String _calculateSavings(SubscriptionPlan plan) {
    if (plan.tier == SubscriptionTier.basic) {
      return '60 zł'; // 30*12 - 300 = 360 - 300 = 60
    } else if (plan.tier == SubscriptionTier.pro) {
      return '100 zł'; // 50*12 - 500 = 600 - 500 = 100
    }
    return '0 zł';
  }

  String _formatExpiryDate(DateTime? date) {
    if (date == null) return 'Brak daty wygaśnięcia';
    return '${date.day}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }

  void _handleUpgrade(BuildContext context, SubscriptionPlan plan, UserProvider userProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Zmień plan na ${plan.name}'),
        content: Text(
          'Czy na pewno chcesz zmienić plan na ${plan.name}?\n\n'
          'Cena: ${plan.monthlyPrice}/miesiąc\n'
          '${plan.yearlyDiscount != null ? "Roczna: ${plan.yearlyPrice} (${plan.yearlyDiscount})" : ""}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Anuluj'),
          ),
          ElevatedButton(
            onPressed: () {
              userProvider.upgradeSubscription(plan.tier);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Plan zmieniony na ${plan.name}!'),
                  backgroundColor: AppColors.success,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
            ),
            child: const Text('Potwierdź'),
          ),
        ],
      ),
    );
  }
}
