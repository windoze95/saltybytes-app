import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/network/api_client.dart';
import '../../core/providers/family_provider.dart';
import '../../models/family.dart';

class FamilyScreen extends ConsumerWidget {
  const FamilyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final familyAsync = ref.watch(familyProvider);
    final hasFamily = familyAsync.valueOrNull != null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Family'),
      ),
      body: familyAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _ErrorState(
          error: error.toString(),
          onRetry: () => ref.invalidate(familyProvider),
        ),
        data: (family) {
          if (family == null) {
            return const _CreateFamilyState();
          }
          if (family.members.isEmpty) {
            return const _EmptyState();
          }
          return _MemberList(members: family.members);
        },
      ),
      floatingActionButton: hasFamily
          ? FloatingActionButton(
              onPressed: () => _showAddMemberDialog(context, ref),
              tooltip: 'Add Member',
              child: const Icon(Icons.person_add),
            )
          : null,
    );
  }

  void _showAddMemberDialog(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    final relationshipController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Family Member'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Name',
                hintText: 'Enter member name',
              ),
              autofocus: true,
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: relationshipController,
              decoration: const InputDecoration(
                labelText: 'Relationship (optional)',
                hintText: 'e.g. spouse, daughter',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = nameController.text.trim();
              if (name.isEmpty) return;
              final relationship = relationshipController.text.trim();
              Navigator.pop(ctx);
              try {
                await ref.read(familyProvider.notifier).addMember(
                      name: name,
                      relationship: relationship,
                    );
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(userFacingErrorMessage(
                        e,
                        'Failed to add member. Please try again.',
                      )),
                    ),
                  );
                }
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}

/// Shown when the user has no family yet -- lets them create one so the
/// member-add flow becomes available.
class _CreateFamilyState extends ConsumerStatefulWidget {
  const _CreateFamilyState();

  @override
  ConsumerState<_CreateFamilyState> createState() => _CreateFamilyStateState();
}

class _CreateFamilyStateState extends ConsumerState<_CreateFamilyState> {
  final _nameController = TextEditingController();
  bool _isCreating = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _createFamily() async {
    final name = _nameController.text.trim();
    if (name.isEmpty || _isCreating) return;

    setState(() => _isCreating = true);
    try {
      await ref.read(familyProvider.notifier).createFamily(name);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(userFacingErrorMessage(
              e,
              'Failed to create family. Please try again.',
            )),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isCreating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.family_restroom,
              size: 80,
              color: theme.colorScheme.primary.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 24),
            Text(
              'Create your family',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Set up a family to track dietary needs and get personalized '
              'allergen warnings for everyone you cook for.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 32),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Family name',
                hintText: 'e.g. The Smiths',
              ),
              textCapitalization: TextCapitalization.words,
              onSubmitted: (_) => _createFamily(),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: _isCreating ? null : _createFamily,
                icon: _isCreating
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: theme.colorScheme.onPrimary,
                        ),
                      )
                    : const Icon(Icons.add),
                label: Text(_isCreating ? 'Creating...' : 'Create Family'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MemberList extends ConsumerWidget {
  const _MemberList({required this.members});

  final List<FamilyMember> members;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      itemCount: members.length,
      itemBuilder: (context, index) {
        final member = members[index];
        return Dismissible(
          key: ValueKey(member.id),
          direction: DismissDirection.endToStart,
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            margin: const EdgeInsets.symmetric(vertical: 4),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.error,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.delete, color: Colors.white),
          ),
          confirmDismiss: (_) async {
            return await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('Remove Member'),
                content: Text('Remove ${member.name} from your family?'),
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
                    child: const Text('Remove'),
                  ),
                ],
              ),
            );
          },
          onDismissed: (_) {
            ref.read(familyProvider.notifier).removeMember(member.id);
          },
          child: _MemberCard(member: member)
              .animate()
              .fadeIn(duration: 300.ms, delay: (50 * index).ms)
              .slideX(begin: 0.05, end: 0, duration: 300.ms, delay: (50 * index).ms),
        );
      },
    );
  }
}

class _MemberCard extends StatelessWidget {
  const _MemberCard({required this.member});

  final FamilyMember member;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final profile = member.dietaryProfile;
    final allergyCount = profile.allergies.length;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: InkWell(
        onTap: () => context.push('/family/${member.id}'),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor:
                    theme.colorScheme.primary.withValues(alpha: 0.12),
                child: Text(
                  member.name.isNotEmpty ? member.name[0].toUpperCase() : '?',
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
                      member.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (member.relationship.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        member.relationship,
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                    if (profile.allergies.isNotEmpty ||
                        profile.restrictions.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          if (allergyCount > 0)
                            _Badge(
                              label:
                                  '$allergyCount ${allergyCount == 1 ? 'allergy' : 'allergies'}',
                              color: theme.colorScheme.error,
                            ),
                          ...profile.restrictions.take(3).map(
                                (r) => _Badge(
                                  label: r,
                                  color: theme.colorScheme.tertiary,
                                ),
                              ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.people_outline,
              size: 80,
              color: theme.colorScheme.primary.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 24),
            Text(
              'No family members yet',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Add family members to track dietary needs and get personalized allergen warnings.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.error, required this.onRetry});

  final String error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off, size: 64,
                color: theme.colorScheme.error.withValues(alpha: 0.5)),
            const SizedBox(height: 16),
            Text('Something went wrong', style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(error, textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }
}
