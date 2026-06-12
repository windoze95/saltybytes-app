import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_client.dart';
import '../../core/providers/subscription_provider.dart';
import '../../models/subscription.dart';

class SubscriptionScreen extends ConsumerStatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  ConsumerState<SubscriptionScreen> createState() =>
      _SubscriptionScreenState();
}

class _SubscriptionScreenState extends ConsumerState<SubscriptionScreen> {
  bool _isUpgrading = false;

  Future<void> _handleUpgrade() async {
    if (_isUpgrading) return;
    setState(() => _isUpgrading = true);

    String message;
    try {
      await ref.read(subscriptionActionsProvider).upgrade();
      ref.invalidate(subscriptionProvider);
      message = 'Subscription upgraded successfully!';
    } catch (e) {
      final error = e is DioException ? e.error : e;
      message = error is ApiError
          ? error.message
          : 'Could not upgrade subscription. Please try again.';
    }

    if (mounted) {
      setState(() => _isUpgrading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final subscriptionAsync = ref.watch(subscriptionProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Subscription')),
      body: subscriptionAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.cloud_off,
                size: 48,
                color: theme.colorScheme.error.withValues(alpha: 0.5),
              ),
              const SizedBox(height: 12),
              Text(
                'Could not load subscription',
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: () => ref.invalidate(subscriptionProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (subscription) => _SubscriptionBody(
          subscription: subscription,
          isUpgrading: _isUpgrading,
          onUpgrade: _handleUpgrade,
        ),
      ),
    );
  }
}

class _SubscriptionBody extends StatelessWidget {
  const _SubscriptionBody({
    required this.subscription,
    required this.isUpgrading,
    required this.onUpgrade,
  });

  final SubscriptionInfo subscription;
  final bool isUpgrading;
  final VoidCallback onUpgrade;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isPremium = subscription.isPremium;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // Current plan
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Icon(
                  Icons.workspace_premium,
                  size: 48,
                  color: isPremium
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurface.withValues(alpha: 0.5),
                ),
                const SizedBox(height: 12),
                Text(
                  isPremium ? 'Premium' : 'Free Tier',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Your current plan',
                  style: theme.textTheme.bodySmall,
                ),
                if (subscription.monthlyResetAt != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Usage resets ${_formatDate(subscription.monthlyResetAt!)}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color:
                          theme.colorScheme.onSurface.withValues(alpha: 0.55),
                    ),
                  ),
                ],
              ],
            ),
          ),
        )
            .animate()
            .fadeIn(duration: 300.ms)
            .slideY(begin: 0.1, end: 0, duration: 300.ms),
        const SizedBox(height: 16),

        // Usage / limits
        _LimitCard(
          title: 'Allergen Analyses',
          current: subscription.allergenAnalysesUsed,
          limit: isPremium
              ? null
              : SubscriptionInfo.freeAllergenAnalysesLimit,
          unit: 'per month',
          icon: Icons.warning_amber,
          color: theme.colorScheme.error,
        ),
        const SizedBox(height: 8),
        _LimitCard(
          title: 'Web Searches',
          current: subscription.webSearchesUsed,
          limit: isPremium ? null : SubscriptionInfo.freeWebSearchesLimit,
          unit: 'per month',
          icon: Icons.search,
          color: theme.colorScheme.primary,
        ),
        const SizedBox(height: 8),
        _LimitCard(
          title: 'AI Generations',
          current: subscription.aiGenerationsUsed,
          limit: isPremium ? null : SubscriptionInfo.freeAiGenerationsLimit,
          unit: 'per month',
          icon: Icons.auto_awesome,
          color: theme.colorScheme.secondary,
        ),

        if (!isPremium) ...[
          const SizedBox(height: 32),

          // Premium plan
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  theme.colorScheme.primary,
                  theme.colorScheme.secondary,
                ],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.diamond, color: Colors.white, size: 28),
                      const SizedBox(width: 10),
                      Text(
                        'SaltyBytes Premium',
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const _PremiumFeature(label: 'Unlimited allergen analyses'),
                  const _PremiumFeature(label: 'Unlimited web searches'),
                  const _PremiumFeature(
                      label: 'Unlimited AI recipe generations'),
                  const _PremiumFeature(label: 'Priority AI processing'),
                  const _PremiumFeature(label: 'Advanced dietary interview'),
                  const _PremiumFeature(label: 'Recipe version history'),
                  const _PremiumFeature(
                      label: 'Family sharing (up to 10 members)'),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: isUpgrading ? null : onUpgrade,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: theme.colorScheme.primary,
                        elevation: 0,
                      ),
                      child: isUpgrading
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child:
                                  CircularProgressIndicator(strokeWidth: 2.5),
                            )
                          : const Text('Upgrade to Premium'),
                    ),
                  ),
                ],
              ),
            ),
          )
              .animate()
              .fadeIn(duration: 400.ms, delay: 200.ms)
              .slideY(begin: 0.1, end: 0, duration: 400.ms, delay: 200.ms),
        ],
      ],
    );
  }

  String _formatDate(DateTime date) {
    final local = date.toLocal();
    return '${local.month}/${local.day}/${local.year}';
  }
}

class _LimitCard extends StatelessWidget {
  const _LimitCard({
    required this.title,
    required this.current,
    required this.limit,
    required this.unit,
    required this.icon,
    required this.color,
  });

  final String title;
  final int current;

  /// null means unlimited (premium).
  final int? limit;
  final String unit;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isUnlimited = limit == null;
    final progress = isUnlimited
        ? 0.0
        : (limit! > 0 ? (current / limit!).clamp(0.0, 1.0) : 0.0);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: color),
                const SizedBox(width: 8),
                Text(title, style: theme.textTheme.titleSmall),
                const Spacer(),
                Text(
                  isUnlimited ? '$current / Unlimited' : '$current / $limit',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: color.withValues(alpha: 0.1),
                valueColor: AlwaysStoppedAnimation(color),
                minHeight: 6,
              ),
            ),
            const SizedBox(height: 4),
            Text(unit, style: theme.textTheme.labelSmall),
          ],
        ),
      ),
    );
  }
}

class _PremiumFeature extends StatelessWidget {
  const _PremiumFeature({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: Colors.white, size: 18),
          const SizedBox(width: 10),
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white,
                ),
          ),
        ],
      ),
    );
  }
}
