import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/iap/iap_gateway.dart' show ProductDetails;
import '../../core/iap/iap_products.dart';
import '../../core/iap/purchase_controller.dart';
import '../../core/iap/store_platform.dart';
import '../../core/network/api_client.dart';
import '../../core/providers/subscription_provider.dart';
import '../../core/utils/external_links.dart';
import '../../models/subscription.dart';

class SubscriptionScreen extends ConsumerWidget {
  const SubscriptionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final subscriptionAsync = ref.watch(subscriptionProvider);

    // Surface each purchase outcome once. A fresh PurchaseNotice instance is
    // emitted per event, so identity comparison fires even on repeats.
    ref.listen<PurchaseState>(purchaseControllerProvider, (prev, next) {
      final notice = next.notice;
      if (notice == null || identical(notice, prev?.notice)) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(
          content: Text(notice.message),
          behavior: SnackBarBehavior.floating,
          backgroundColor: notice.isError ? theme.colorScheme.error : null,
        ));
    });

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
                userFacingErrorMessage(error, 'Could not load subscription'),
                style: theme.textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: () => ref.invalidate(subscriptionProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (subscription) => _SubscriptionBody(subscription: subscription),
      ),
    );
  }
}

class _SubscriptionBody extends ConsumerStatefulWidget {
  const _SubscriptionBody({required this.subscription});

  final SubscriptionInfo subscription;

  @override
  ConsumerState<_SubscriptionBody> createState() => _SubscriptionBodyState();
}

class _SubscriptionBodyState extends ConsumerState<_SubscriptionBody> {
  /// Whether the Premium card's yearly plan is selected (vs monthly).
  bool _premiumYearly = false;

  SubscriptionInfo get _subscription => widget.subscription;

  void _buy(ProductDetails product) {
    final controller = ref.read(purchaseControllerProvider.notifier);
    // On Android, moving to a different product from an existing store
    // subscription needs the old purchase so Play can prorate the switch.
    final replacing = _subscription.hasStoreSubscription
        ? controller.activeStorePurchase
        : null;
    controller.buy(product, replacing: replacing);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final subscription = _subscription;
    final limits = subscription.limits;
    final hasPaidLook = subscription.tierRank >= 1;

    final store = ref.watch(storePlatformProvider);
    final productsAsync = ref.watch(storeProductsProvider);
    final products = productsAsync.valueOrNull;
    final purchaseState = ref.watch(purchaseControllerProvider);

    final canPurchase = store.canPurchase;
    ProductDetails? productFor(String id) => products?[id];

    // Whether to explain that live store prices/buying aren't available.
    final showUnavailableNote = subscription.tierRank < 2 &&
        productsAsync.hasValue &&
        !(products?.available ?? false);

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _CurrentPlanCard(subscription: subscription, hasPaidLook: hasPaidLook)
            .animate()
            .fadeIn(duration: 300.ms)
            .slideY(begin: 0.1, end: 0, duration: 300.ms),

        if (subscription.hasStoreSubscription) ...[
          const SizedBox(height: 12),
          _ManageSubscriptionCard(
            store: subscription.store!,
            deviceKind: store.kind,
          ),
        ],

        const SizedBox(height: 16),

        // Usage / limits
        _LimitCard(
          title: 'AI Generations',
          current: subscription.aiGenerationsUsed,
          limit: limits.aiGenerations < 0 ? null : limits.aiGenerations,
          unit: 'per month',
          icon: Icons.auto_awesome,
          color: theme.colorScheme.secondary,
        ),
        const SizedBox(height: 8),
        _LimitCard(
          title: 'Recipe Agent Searches',
          current: subscription.webSearchesUsed,
          limit: limits.webSearches < 0 ? null : limits.webSearches,
          unit: 'per month',
          icon: Icons.search,
          color: theme.colorScheme.primary,
        ),
        const SizedBox(height: 8),
        _LimitCard(
          title: 'Allergen Analyses',
          current: subscription.allergenAnalysesUsed,
          limit: limits.allergenAnalyses < 0 ? null : limits.allergenAnalyses,
          unit: 'per month',
          icon: Icons.warning_amber,
          color: theme.colorScheme.error,
        ),
        const SizedBox(height: 8),
        _LimitCard(
          title: 'Video Imports',
          current: subscription.videoImportsUsed,
          limit: limits.videoImports < 0 ? null : limits.videoImports,
          unit: 'per month',
          icon: Icons.play_circle_outline,
          color: theme.colorScheme.tertiary,
        ),
        const SizedBox(height: 8),
        _LimitCard(
          title: 'AI Imports (photo, voice, text)',
          current: subscription.aiImportsUsed,
          limit: limits.aiImports < 0 ? null : limits.aiImports,
          unit: 'per month',
          icon: Icons.document_scanner_outlined,
          color: theme.colorScheme.secondary,
        ),

        if (showUnavailableNote) ...[
          const SizedBox(height: 16),
          _StoreUnavailableNote(reason: products?.reason),
        ],

        if (subscription.tierRank < 1) ...[
          const SizedBox(height: 32),
          _PlusCard(
            product: productFor(IapProducts.plusMonthly),
            canPurchase: canPurchase,
            busy: purchaseState.isBusy,
            isActive:
                purchaseState.activeProductId == IapProducts.plusMonthly,
            onBuy: _buy,
          )
              .animate()
              .fadeIn(duration: 400.ms, delay: 100.ms)
              .slideY(begin: 0.1, end: 0, duration: 400.ms, delay: 100.ms),
        ],

        if (subscription.tierRank < 2) ...[
          const SizedBox(height: 32),
          _PremiumCard(
            yearly: _premiumYearly,
            onPeriodChanged: (v) => setState(() => _premiumYearly = v),
            monthlyProduct: productFor(IapProducts.premiumMonthly),
            yearlyProduct: productFor(IapProducts.premiumYearly),
            canPurchase: canPurchase,
            busy: purchaseState.isBusy,
            activeProductId: purchaseState.activeProductId,
            onBuy: _buy,
          )
              .animate()
              .fadeIn(duration: 400.ms, delay: 200.ms)
              .slideY(begin: 0.1, end: 0, duration: 400.ms, delay: 200.ms),
        ],

        if (canPurchase) ...[
          const SizedBox(height: 20),
          Center(
            child: TextButton.icon(
              onPressed: purchaseState.isBusy
                  ? null
                  : () =>
                      ref.read(purchaseControllerProvider.notifier).restore(),
              icon: const Icon(Icons.restore, size: 18),
              label: const Text('Restore Purchases'),
            ),
          ),
        ],

        const SizedBox(height: 8),
        const _LegalDisclosure(),
        const SizedBox(height: 24),
      ],
    );
  }
}

/// Current plan summary card.
class _CurrentPlanCard extends StatelessWidget {
  const _CurrentPlanCard({required this.subscription, required this.hasPaidLook});

  final SubscriptionInfo subscription;
  final bool hasPaidLook;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(
              Icons.workspace_premium,
              size: 48,
              color: hasPaidLook
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurface.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 12),
            Text(
              '${subscription.displayName} Plan',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text('Your current plan', style: theme.textTheme.bodySmall),
            if (subscription.monthlyResetAt != null) ...[
              const SizedBox(height: 4),
              Text(
                'Usage resets ${_formatDate(subscription.monthlyResetAt!)}',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// "Manage Subscription" affordance, shown when the tier is backed by a store
/// purchase. Opens the platform's subscription page, or explains where to
/// manage it when the purchase was made on a different platform.
class _ManageSubscriptionCard extends StatelessWidget {
  const _ManageSubscriptionCard({required this.store, required this.deviceKind});

  final StoreInfo store;
  final StoreKind deviceKind;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onThisDevice = (store.isApple && deviceKind == StoreKind.apple) ||
        (store.isGoogle && deviceKind == StoreKind.google);

    if (!onThisDevice) {
      final where = store.isApple ? 'iPhone or iPad' : 'Android device';
      return Card(
        child: ListTile(
          leading: const Icon(Icons.info_outline),
          title: const Text('Subscription managed elsewhere'),
          subtitle: Text(
            'You subscribed on your $where. Manage or cancel it there.',
          ),
        ),
      );
    }

    return Card(
      child: ListTile(
        leading: Icon(Icons.credit_card, color: theme.colorScheme.primary),
        title: const Text('Manage Subscription'),
        subtitle: Text(_statusLine(store)),
        trailing: const Icon(Icons.open_in_new, size: 16),
        onTap: () => openExternalUrl(
          store.isApple
              ? ExternalLinks.appleManageSubscriptions
              : ExternalLinks.playManageSubscription(store.productId),
        ),
      ),
    );
  }

  String _statusLine(StoreInfo store) {
    final expires = store.expiresAt;
    if (expires != null) {
      final when = _formatDate(expires);
      if (store.autoRenew == false) return 'Expires $when';
      return 'Renews $when';
    }
    final status = store.status;
    return (status == null || status.isEmpty) ? 'Active' : status;
  }
}

/// Explains that live store prices / purchasing aren't available (simulator,
/// Play not signed in, or iOS too old) — prices shown are informational.
class _StoreUnavailableNote extends StatelessWidget {
  const _StoreUnavailableNote({this.reason});

  final String? reason;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline,
              size: 18, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              reason ??
                  'The store is unavailable right now. Prices shown are '
                      'approximate; try again to subscribe.',
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Plus plan — the budget step up.
class _PlusCard extends StatelessWidget {
  const _PlusCard({
    required this.product,
    required this.canPurchase,
    required this.busy,
    required this.isActive,
    required this.onBuy,
  });

  final ProductDetails? product;
  final bool canPurchase;
  final bool busy;
  final bool isActive;
  final void Function(ProductDetails product) onBuy;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final price = product != null ? '${product!.price}/mo' : '\$1.99/mo';
    final enabled = canPurchase && product != null && !busy;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.add_circle_outline,
                    color: theme.colorScheme.primary, size: 26),
                const SizedBox(width: 10),
                Text(
                  'SaltyBytes Plus',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                Text(
                  price,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const _PlanFeature(label: '15 AI generations a month'),
            const _PlanFeature(label: '20 recipe agent searches'),
            const _PlanFeature(label: '25 AI imports'),
            const _PlanFeature(label: '5 allergen analyses'),
            const _PlanFeature(label: '2 video imports'),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton(
                onPressed: enabled ? () => onBuy(product!) : null,
                child: isActive
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2.5),
                      )
                    : const Text('Get Plus'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Premium plan with a monthly/yearly selector.
class _PremiumCard extends StatelessWidget {
  const _PremiumCard({
    required this.yearly,
    required this.onPeriodChanged,
    required this.monthlyProduct,
    required this.yearlyProduct,
    required this.canPurchase,
    required this.busy,
    required this.activeProductId,
    required this.onBuy,
  });

  final bool yearly;
  final ValueChanged<bool> onPeriodChanged;
  final ProductDetails? monthlyProduct;
  final ProductDetails? yearlyProduct;
  final bool canPurchase;
  final bool busy;
  final String? activeProductId;
  final void Function(ProductDetails product) onBuy;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selected = yearly ? yearlyProduct : monthlyProduct;
    final selectedId =
        yearly ? IapProducts.premiumYearly : IapProducts.premiumMonthly;
    final isActive = activeProductId == selectedId;

    final priceText = selected != null
        ? '${selected.price}${yearly ? '/yr' : '/mo'}'
        : (yearly ? '\$39.99/yr' : '\$4.99/mo');

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [theme.colorScheme.primary, theme.colorScheme.secondary],
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
                const Spacer(),
                Text(
                  priceText,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _PeriodToggle(
              yearly: yearly,
              onChanged: onPeriodChanged,
              monthlyProduct: monthlyProduct,
              yearlyProduct: yearlyProduct,
            ),
            const SizedBox(height: 20),
            const _PremiumFeature(label: '30 AI generations a month'),
            const _PremiumFeature(label: '50 recipe agent searches'),
            const _PremiumFeature(label: '60 AI imports'),
            const _PremiumFeature(label: '20 video imports'),
            const _PremiumFeature(
                label: 'Deeper allergen analysis (12 a month)'),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: (canPurchase && !busy && selected != null)
                    ? () => onBuy(selected)
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: theme.colorScheme.primary,
                  elevation: 0,
                ),
                child: isActive
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(strokeWidth: 2.5),
                      )
                    : const Text('Upgrade to Premium'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Monthly / yearly selector for Premium, with a "save" hint on the yearly
/// option computed from the real store prices when both are known.
class _PeriodToggle extends StatelessWidget {
  const _PeriodToggle({
    required this.yearly,
    required this.onChanged,
    required this.monthlyProduct,
    required this.yearlyProduct,
  });

  final bool yearly;
  final ValueChanged<bool> onChanged;
  final ProductDetails? monthlyProduct;
  final ProductDetails? yearlyProduct;

  @override
  Widget build(BuildContext context) {
    final saveLabel = _savingsLabel();
    return Row(
      children: [
        Expanded(
          child: _PeriodChip(
            label: 'Monthly',
            selected: !yearly,
            onTap: () => onChanged(false),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _PeriodChip(
            label: 'Yearly',
            badge: saveLabel,
            selected: yearly,
            onTap: () => onChanged(true),
          ),
        ),
      ],
    );
  }

  /// e.g. "Save 33%" from the real prices, or a static hint when only one price
  /// is known.
  String? _savingsLabel() {
    final monthly = monthlyProduct?.rawPrice;
    final annual = yearlyProduct?.rawPrice;
    if (monthly != null && annual != null && monthly > 0) {
      final full = monthly * 12;
      if (annual < full) {
        final pct = ((1 - annual / full) * 100).round();
        if (pct > 0) return 'Save $pct%';
      }
      return null;
    }
    return 'Best value';
  }
}

class _PeriodChip extends StatelessWidget {
  const _PeriodChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.badge,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        decoration: BoxDecoration(
          color:
              selected ? Colors.white : Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white.withValues(alpha: 0.6)),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: theme.textTheme.labelLarge?.copyWith(
                color: selected ? theme.colorScheme.primary : Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (badge != null)
              Text(
                badge!,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: selected
                      ? theme.colorScheme.primary
                      : Colors.white.withValues(alpha: 0.85),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Required auto-renewal disclosure with tappable legal links (App Store
/// guideline 3.1.2).
class _LegalDisclosure extends StatelessWidget {
  const _LegalDisclosure();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.textTheme.labelSmall?.copyWith(
      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
      height: 1.4,
    );

    return Column(
      children: [
        Text(
          'Subscriptions renew automatically unless canceled at least 24 hours '
          'before the end of the current period. Your store account is charged '
          'on confirmation and again each period until you cancel. Manage or '
          'cancel anytime in your account settings.',
          style: muted,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextButton(
              onPressed: () => openExternalUrl(ExternalLinks.privacyPolicy),
              child: const Text('Privacy Policy'),
            ),
            Text('·', style: muted),
            TextButton(
              onPressed: () => openExternalUrl(ExternalLinks.termsOfUse),
              child: const Text('Terms of Use'),
            ),
          ],
        ),
      ],
    );
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

class _PlanFeature extends StatelessWidget {
  const _PlanFeature({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(Icons.check_circle, color: theme.colorScheme.primary, size: 18),
          const SizedBox(width: 10),
          Text(label, style: theme.textTheme.bodyMedium),
        ],
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

String _formatDate(DateTime date) {
  final local = date.toLocal();
  return '${local.month}/${local.day}/${local.year}';
}
