import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/network/api_client.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/subscription_provider.dart';
import '../../core/providers/user_provider.dart';
import '../../core/utils/external_links.dart';
import '../../models/user.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: userAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
            child: Text(
                userFacingErrorMessage(e, 'Could not load your settings.'))),
        data: (user) {
          if (user == null) {
            return const Center(child: Text('Not signed in'));
          }
          return _SettingsBody(user: user);
        },
      ),
    );
  }
}

class _SettingsBody extends ConsumerStatefulWidget {
  const _SettingsBody({required this.user});

  final User user;

  @override
  ConsumerState<_SettingsBody> createState() => _SettingsBodyState();
}

class _SettingsBodyState extends ConsumerState<_SettingsBody> {
  late bool _wakelockEnabled;
  late String _unitSystem;
  late TextEditingController _requirementsController;

  @override
  void initState() {
    super.initState();
    _wakelockEnabled = widget.user.settings.keepScreenAwake;
    _unitSystem = widget.user.personalization.unitSystem;
    _requirementsController = TextEditingController(
      text: widget.user.personalization.requirements,
    );
  }

  @override
  void dispose() {
    _requirementsController.dispose();
    super.dispose();
  }

  Future<void> _changeUnitSystem(String system) async {
    setState(() => _unitSystem = system);
    await ref.read(currentUserProvider.notifier).updatePersonalization(
          widget.user.personalization.copyWith(unitSystem: system),
        );
  }

  Future<void> _toggleWakelock(bool enabled) async {
    setState(() => _wakelockEnabled = enabled);
    await ref.read(currentUserProvider.notifier).updateSettings(
          widget.user.settings.copyWith(keepScreenAwake: enabled),
        );
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(authStateProvider.notifier).logout();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Profile section
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor:
                      theme.colorScheme.primary.withValues(alpha: 0.12),
                  child: Text(
                    widget.user.username.isNotEmpty
                        ? widget.user.username[0].toUpperCase()
                        : '?',
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.user.firstName ?? widget.user.username,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.user.email,
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Personalization
        _SectionHeader(title: 'Personalization'),
        const SizedBox(height: 8),
        Card(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.straighten),
                title: const Text('Unit System'),
                subtitle: Text(
                  _unitSystem == 'metric' ? 'Metric' : 'US Customary',
                ),
                trailing: SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'us_customary', label: Text('US')),
                    ButtonSegment(value: 'metric', label: Text('Metric')),
                  ],
                  selected: {_unitSystem},
                  onSelectionChanged: (v) => _changeUnitSystem(v.first),
                  style: const ButtonStyle(
                    visualDensity: VisualDensity.compact,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ),
              const Divider(height: 1, indent: 16, endIndent: 16),

              // Dietary preferences
              Padding(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  controller: _requirementsController,
                  decoration: const InputDecoration(
                    labelText: 'Dietary Requirements',
                    hintText: 'e.g. vegetarian, low-sodium',
                    prefixIcon: Icon(Icons.restaurant),
                  ),
                  maxLines: 2,
                  onChanged: (value) {
                    ref
                        .read(currentUserProvider.notifier)
                        .updatePersonalization(
                          widget.user.personalization.copyWith(
                            requirements: value.trim(),
                          ),
                        );
                  },
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Subscription
        _SectionHeader(title: 'Subscription'),
        const SizedBox(height: 8),
        Consumer(
          builder: (context, ref, _) {
            final subscription = ref.watch(subscriptionProvider);
            final tierLabel = subscription.maybeWhen(
              data: (s) => '${s.displayName} Tier',
              orElse: () => 'Free Tier',
            );
            final isPaid = subscription.maybeWhen(
              data: (s) => s.tierRank >= 1,
              orElse: () => false,
            );
            return Card(
              child: ListTile(
                leading: Icon(Icons.workspace_premium,
                    color: theme.colorScheme.secondary),
                title: const Text('Current Plan'),
                subtitle: Text(tierLabel),
                trailing: ElevatedButton(
                  onPressed: () => context.push('/settings/subscription'),
                  child: Text(isPaid ? 'Manage' : 'Upgrade'),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 24),

        // App Settings
        _SectionHeader(title: 'App Settings'),
        const SizedBox(height: 8),
        Card(
          child: Column(
            children: [
              SwitchListTile(
                title: const Text('Keep Screen Awake'),
                subtitle: const Text('During cooking mode'),
                value: _wakelockEnabled,
                onChanged: _toggleWakelock,
                secondary: const Icon(Icons.screen_lock_portrait),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // About
        _SectionHeader(title: 'About'),
        const SizedBox(height: 8),
        Card(
          child: Column(
            children: [
              const ListTile(
                leading: Icon(Icons.info_outline),
                title: Text('SaltyBytes'),
                subtitle: Text('Version 1.0.0'),
              ),
              const Divider(height: 1, indent: 16, endIndent: 16),
              ListTile(
                leading: const Icon(Icons.description_outlined),
                title: const Text('Terms of Service'),
                trailing: const Icon(Icons.open_in_new, size: 16),
                onTap: () => openExternalUrl(ExternalLinks.termsOfUse),
              ),
              const Divider(height: 1, indent: 16, endIndent: 16),
              ListTile(
                leading: const Icon(Icons.privacy_tip_outlined),
                title: const Text('Privacy Policy'),
                trailing: const Icon(Icons.open_in_new, size: 16),
                onTap: () => openExternalUrl(ExternalLinks.privacyPolicy),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Logout
        SizedBox(
          height: 52,
          child: OutlinedButton.icon(
            onPressed: _logout,
            icon: const Icon(Icons.logout),
            label: const Text('Sign Out'),
            style: OutlinedButton.styleFrom(
              foregroundColor: theme.colorScheme.error,
              side: BorderSide(color: theme.colorScheme.error),
            ),
          ),
        ),
        const SizedBox(height: 32),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
            color:
                Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
    );
  }
}
