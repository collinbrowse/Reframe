import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/app_providers.dart';

class SubscriptionScreen extends ConsumerWidget {
  const SubscriptionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('Upgrade'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Center(
              child: Column(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      gradient: AppTheme.primaryGradient,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(
                      Icons.star,
                      size: 40,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Reframe Premium',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Unlock the full power of content creation',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Features list
            _buildFeaturesList(),
            const SizedBox(height: 32),

            // Pricing plans
            const Text(
              'Choose Your Plan',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),

            // Monthly plan
            _PlanCard(
              title: 'Monthly',
              price: '\$9.99',
              period: '/month',
              features: const ['All premium features', 'Cancel anytime'],
              onTap: () => _subscribe(context, 'monthly'),
            ),
            const SizedBox(height: 12),

            // Annual plan (best value)
            _PlanCard(
              title: 'Annual',
              price: '\$79.99',
              period: '/year',
              features: const ['Save 33%', 'All premium features'],
              isPopular: true,
              onTap: () => _subscribe(context, 'annual'),
            ),
            const SizedBox(height: 12),

            // Lifetime plan
            _PlanCard(
              title: 'Lifetime',
              price: '\$199.99',
              period: 'one-time',
              features: const ['Pay once, use forever', 'All future updates'],
              onTap: () => _subscribe(context, 'lifetime'),
            ),

            const SizedBox(height: 32),

            // Terms
            Center(
              child: Column(
                children: [
                  Text(
                    'Start with a 7-day free trial',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Cancel anytime. Subscription auto-renews.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.5),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TextButton(
                        onPressed: () {},
                        child: const Text('Terms of Service'),
                      ),
                      Text(
                        '•',
                        style: TextStyle(color: Colors.white.withOpacity(0.3)),
                      ),
                      TextButton(
                        onPressed: () {},
                        child: const Text('Privacy Policy'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildFeaturesList() {
    final features = [
      _FeatureItem(
        icon: Icons.cloud_upload,
        title: 'Cloud Sync',
        description: 'Sync projects across all your devices',
      ),
      _FeatureItem(
        icon: Icons.auto_awesome,
        title: 'AI Narration',
        description: 'Generate voiceovers with AI',
      ),
      _FeatureItem(
        icon: Icons.music_note,
        title: 'Premium Music',
        description: 'Access royalty-free music library',
      ),
      _FeatureItem(
        icon: Icons.high_quality,
        title: '4K Export',
        description: 'Export in ultra-high definition',
      ),
      _FeatureItem(
        icon: Icons.tune,
        title: 'Advanced Editing',
        description: 'Pro-level filters and transitions',
      ),
      _FeatureItem(
        icon: Icons.block,
        title: 'No Watermark',
        description: 'Export without Reframe branding',
      ),
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Premium Features',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          ...features.map((feature) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: feature,
              )),
        ],
      ),
    );
  }

  void _subscribe(BuildContext context, String plan) {
    // Track analytics
    // TODO: Implement RevenueCat purchase
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$plan subscription coming soon!'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

class _FeatureItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _FeatureItem({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withOpacity(0.2),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppTheme.primaryColor, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              Text(
                description,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.white.withOpacity(0.5),
                ),
              ),
            ],
          ),
        ),
        const Icon(Icons.check, color: AppTheme.success, size: 20),
      ],
    );
  }
}

class _PlanCard extends StatelessWidget {
  final String title;
  final String price;
  final String period;
  final List<String> features;
  final bool isPopular;
  final VoidCallback onTap;

  const _PlanCard({
    required this.title,
    required this.price,
    required this.period,
    required this.features,
    this.isPopular = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.surfaceDark,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isPopular ? AppTheme.primaryColor : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                if (isPopular) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'BEST VALUE',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
                const Spacer(),
                Text(
                  price,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  period,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.5),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: features
                  .map((f) => Padding(
                        padding: const EdgeInsets.only(right: 16),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.check,
                              size: 16,
                              color: AppTheme.success,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              f,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.white.withOpacity(0.7),
                              ),
                            ),
                          ],
                        ),
                      ))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }
}
