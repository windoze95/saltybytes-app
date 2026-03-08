import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers/family_provider.dart';
import '../../models/family.dart';

class FamilyMemberDetailScreen extends ConsumerStatefulWidget {
  const FamilyMemberDetailScreen({super.key, required this.memberId});

  final String memberId;

  @override
  ConsumerState<FamilyMemberDetailScreen> createState() =>
      _FamilyMemberDetailScreenState();
}

class _FamilyMemberDetailScreenState
    extends ConsumerState<FamilyMemberDetailScreen> {
  bool _isEditing = false;

  late TextEditingController _nameController;
  late TextEditingController _roleController;
  late List<Allergy> _allergies;
  late List<String> _intolerances;
  late List<String> _restrictions;
  late List<String> _dislikes;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _roleController = TextEditingController();
    _allergies = [];
    _intolerances = [];
    _restrictions = [];
    _dislikes = [];
  }

  @override
  void dispose() {
    _nameController.dispose();
    _roleController.dispose();
    super.dispose();
  }

  void _startEditing(FamilyMember member) {
    setState(() {
      _isEditing = true;
      _nameController.text = member.name;
      _roleController.text = member.role;
      _allergies = List<Allergy>.from(member.dietaryProfile.allergies);
      _intolerances = List<String>.from(member.dietaryProfile.intolerances);
      _restrictions = List<String>.from(member.dietaryProfile.restrictions);
      _dislikes = List<String>.from(member.dietaryProfile.preferences);
    });
  }

  Future<void> _saveChanges() async {
    final member = ref.read(familyMemberProvider(widget.memberId));
    if (member == null) return;

    final updated = member.copyWith(
      name: _nameController.text.trim(),
      role: _roleController.text.trim(),
      dietaryProfile: DietaryProfile(
        allergies: _allergies,
        intolerances: _intolerances,
        restrictions: _restrictions,
        preferences: _dislikes,
      ),
    );

    try {
      await ref.read(familyProvider.notifier).updateMember(updated);
      setState(() => _isEditing = false);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save: $e')),
        );
      }
    }
  }

  void _addItemDialog(String title, List<String> list) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Add $title'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(hintText: 'Enter $title'),
          textCapitalization: TextCapitalization.words,
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final val = controller.text.trim();
              if (val.isNotEmpty) {
                setState(() => list.add(val));
              }
              Navigator.pop(ctx);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _addAllergyDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add allergy'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Enter allergy'),
          textCapitalization: TextCapitalization.words,
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final val = controller.text.trim();
              if (val.isNotEmpty) {
                setState(() => _allergies.add(Allergy(name: val)));
              }
              Navigator.pop(ctx);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final member = ref.watch(familyMemberProvider(widget.memberId));

    if (member == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Member')),
        body: const Center(child: Text('Member not found')),
      );
    }

    final profile = _isEditing
        ? DietaryProfile(
            allergies: _allergies,
            intolerances: _intolerances,
            restrictions: _restrictions,
            preferences: _dislikes,
          )
        : member.dietaryProfile;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Member' : member.name),
        actions: [
          if (_isEditing)
            TextButton(
              onPressed: () => setState(() => _isEditing = false),
              child: const Text('Cancel'),
            ),
          if (_isEditing)
            TextButton(onPressed: _saveChanges, child: const Text('Save')),
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => _startEditing(member),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Header
          if (_isEditing) ...[
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Name'),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _roleController,
              decoration: const InputDecoration(labelText: 'Relationship'),
            ),
          ] else ...[
            Row(
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundColor:
                      theme.colorScheme.primary.withValues(alpha: 0.12),
                  child: Text(
                    member.name.isNotEmpty
                        ? member.name[0].toUpperCase()
                        : '?',
                    style: theme.textTheme.headlineMedium?.copyWith(
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
                      Text(member.name,
                          style: theme.textTheme.headlineSmall
                              ?.copyWith(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 4),
                      Text(member.role, style: theme.textTheme.bodyMedium),
                    ],
                  ),
                ),
              ],
            ),
          ],

          const SizedBox(height: 32),

          // AI Interview button
          if (!_isEditing) ...[
            OutlinedButton.icon(
              onPressed: () =>
                  context.push('/family/${widget.memberId}/interview'),
              icon: const Icon(Icons.smart_toy),
              label: const Text('AI Dietary Interview'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
            const SizedBox(height: 24),
          ],

          // Allergies
          _DietarySection(
            title: 'Allergies',
            items: profile.allergies.map((a) => a.name).toList(),
            icon: Icons.warning_amber,
            severityColors: true,
            isEditing: _isEditing,
            onAdd: _isEditing
                ? () => _addAllergyDialog()
                : null,
            onRemove:
                _isEditing ? (i) => setState(() => _allergies.removeAt(i)) : null,
          ),

          // Intolerances
          _DietarySection(
            title: 'Intolerances',
            items: profile.intolerances,
            icon: Icons.not_interested,
            isEditing: _isEditing,
            onAdd: _isEditing
                ? () => _addItemDialog('intolerance', _intolerances)
                : null,
            onRemove: _isEditing
                ? (i) => setState(() => _intolerances.removeAt(i))
                : null,
          ),

          // Restrictions
          _DietarySection(
            title: 'Dietary Restrictions',
            items: profile.restrictions,
            icon: Icons.block,
            isEditing: _isEditing,
            useChips: true,
            onAdd: _isEditing
                ? () => _addItemDialog('restriction', _restrictions)
                : null,
            onRemove: _isEditing
                ? (i) => setState(() => _restrictions.removeAt(i))
                : null,
          ),

          // Dislikes
          _DietarySection(
            title: 'Preferences',
            items: profile.preferences,
            icon: Icons.thumb_down_alt_outlined,
            isEditing: _isEditing,
            useChips: true,
            onAdd: _isEditing
                ? () => _addItemDialog('dislike', _dislikes)
                : null,
            onRemove:
                _isEditing ? (i) => setState(() => _dislikes.removeAt(i)) : null,
          ),
        ],
      ),
    );
  }
}

class _DietarySection extends StatelessWidget {
  const _DietarySection({
    required this.title,
    required this.items,
    required this.icon,
    this.severityColors = false,
    this.isEditing = false,
    this.useChips = false,
    this.onAdd,
    this.onRemove,
  });

  final String title;
  final List<String> items;
  final IconData icon;
  final bool severityColors;
  final bool isEditing;
  final bool useChips;
  final VoidCallback? onAdd;
  final void Function(int)? onRemove;

  Color _severityColor(int index, ThemeData theme) {
    if (!severityColors) return theme.colorScheme.error;
    // First items = more severe
    if (index == 0) return const Color(0xFFC62828); // red severe
    if (index == 1) return const Color(0xFFE65100); // orange moderate
    return const Color(0xFFF9A825); // yellow mild
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 20,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
            const SizedBox(width: 8),
            Text(title, style: theme.textTheme.titleMedium),
            if (isEditing && onAdd != null) ...[
              const Spacer(),
              TextButton.icon(
                onPressed: onAdd,
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Add'),
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        if (items.isEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Text(
              'None recorded',
              style: theme.textTheme.bodySmall,
            ),
          )
        else if (useChips)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Wrap(
              spacing: 8,
              runSpacing: 6,
              children: List.generate(items.length, (i) {
                return Chip(
                  label: Text(items[i]),
                  onDeleted: isEditing && onRemove != null
                      ? () => onRemove!(i)
                      : null,
                );
              }),
            ),
          )
        else
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(
              children: List.generate(items.length, (i) {
                final color = _severityColor(i, theme);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(items[i],
                            style: theme.textTheme.bodyMedium),
                      ),
                      if (isEditing && onRemove != null)
                        IconButton(
                          icon: Icon(Icons.close, size: 16,
                              color: theme.colorScheme.error),
                          onPressed: () => onRemove!(i),
                          visualDensity: VisualDensity.compact,
                        ),
                    ],
                  ),
                );
              }),
            ),
          ),
        const Divider(),
        const SizedBox(height: 8),
      ],
    );
  }
}
