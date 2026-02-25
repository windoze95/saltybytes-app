import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers/branch_provider.dart';
import '../../core/providers/recipe_provider.dart';
import '../../models/recipe.dart';
import 'widgets/branch_tree_painter.dart';

class RecipeBranchesScreen extends ConsumerStatefulWidget {
  const RecipeBranchesScreen({super.key, required this.recipeId});

  final String recipeId;

  @override
  ConsumerState<RecipeBranchesScreen> createState() =>
      _RecipeBranchesScreenState();
}

class _RecipeBranchesScreenState extends ConsumerState<RecipeBranchesScreen> {
  void _showCreateBranchDialog({
    String? fromBranch,
    int? fromVersion,
  }) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        return AlertDialog(
          title: const Text('Create Branch'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (fromBranch != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    'From: $fromBranch${fromVersion != null ? ' v$fromVersion' : ''}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface
                          .withValues(alpha: 0.6),
                    ),
                  ),
                ),
              TextField(
                controller: controller,
                decoration: const InputDecoration(
                  labelText: 'Branch name',
                  hintText: 'e.g., vegan-version',
                ),
                autocorrect: false,
                autofocus: true,
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
                final name = controller.text.trim();
                if (name.isEmpty) return;
                Navigator.pop(ctx);
                await _createBranch(
                  name,
                  fromBranch: fromBranch,
                  fromVersion: fromVersion,
                );
              },
              child: const Text('Create'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _createBranch(
    String name, {
    String? fromBranch,
    int? fromVersion,
  }) async {
    try {
      final ops = ref.read(branchOperationsProvider);
      await ops.createBranch(
        widget.recipeId,
        branchName: name,
        fromBranch: fromBranch,
        fromVersion: fromVersion,
      );
      ref.invalidate(recipeBranchesProvider(widget.recipeId));
      ref.invalidate(recipeDetailProvider(widget.recipeId));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create branch: $e')),
        );
      }
    }
  }

  Future<void> _setActiveBranch(String branch) async {
    try {
      final ops = ref.read(branchOperationsProvider);
      await ops.setActiveBranch(widget.recipeId, branch);
      ref.invalidate(recipeBranchesProvider(widget.recipeId));
      ref.invalidate(recipeDetailProvider(widget.recipeId));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Switched to branch: $branch')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to switch branch: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final branchesAsync = ref.watch(recipeBranchesProvider(widget.recipeId));
    final recipeAsync = ref.watch(recipeDetailProvider(widget.recipeId));

    final activeBranch = recipeAsync.whenOrNull(
          data: (r) => r.currentBranch,
        ) ??
        'main';
    final activeVersion = recipeAsync.whenOrNull(
          data: (r) => r.version,
        ) ??
        1;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Branches'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'New Branch',
            onPressed: () => _showCreateBranchDialog(),
          ),
        ],
      ),
      body: branchesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline,
                size: 48,
                color: colors.error.withValues(alpha: 0.5),
              ),
              const SizedBox(height: 12),
              Text(
                'Could not load branches',
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: () =>
                    ref.invalidate(recipeBranchesProvider(widget.recipeId)),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (nodes) {
          if (nodes.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.account_tree_outlined,
                    size: 64,
                    color: colors.primary.withValues(alpha: 0.3),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No branches yet',
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Create a branch to experiment\nwith recipe variations',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colors.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => _showCreateBranchDialog(),
                    icon: const Icon(Icons.add),
                    label: const Text('Create Branch'),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              // Tree visualization
              Expanded(
                flex: 3,
                child: _BranchTree(
                  nodes: nodes,
                  activeBranch: activeBranch,
                  activeVersion: activeVersion,
                ),
              ),

              const Divider(height: 1),

              // Node list
              Expanded(
                flex: 4,
                child: _BranchNodeList(
                  nodes: nodes,
                  activeBranch: activeBranch,
                  onTap: (node) {
                    context.pushNamed(
                      'recipe-detail',
                      pathParameters: {'id': widget.recipeId},
                      queryParameters: {
                        'branch': node.branch,
                        'version': '${node.version}',
                      },
                    );
                  },
                  onLongPress: (node) => _setActiveBranch(node.branch),
                  onCreateBranch: (node) => _showCreateBranchDialog(
                    fromBranch: node.branch,
                    fromVersion: node.version,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _BranchTree extends StatelessWidget {
  const _BranchTree({
    required this.nodes,
    required this.activeBranch,
    required this.activeVersion,
  });

  final List<RecipeNode> nodes;
  final String activeBranch;
  final int activeVersion;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    final painter = BranchTreePainter(
      nodes: nodes,
      activeBranch: activeBranch,
      activeVersion: activeVersion,
      primaryColor: colors.primary,
      onSurfaceColor: colors.onSurface,
      surfaceColor: theme.scaffoldBackgroundColor,
    );

    final treeSize = painter.calculateTreeSize();

    return InteractiveViewer(
      constrained: false,
      boundaryMargin: const EdgeInsets.all(40),
      minScale: 0.5,
      maxScale: 2.0,
      child: CustomPaint(
        painter: painter,
        size: Size(
          treeSize.width.clamp(300, double.infinity),
          treeSize.height.clamp(200, double.infinity),
        ),
      ),
    );
  }
}

class _BranchNodeList extends StatelessWidget {
  const _BranchNodeList({
    required this.nodes,
    required this.activeBranch,
    required this.onTap,
    required this.onLongPress,
    required this.onCreateBranch,
  });

  final List<RecipeNode> nodes;
  final String activeBranch;
  final void Function(RecipeNode) onTap;
  final void Function(RecipeNode) onLongPress;
  final void Function(RecipeNode) onCreateBranch;

  List<RecipeNode> _flatten(RecipeNode node) {
    return [node, ...node.children.expand(_flatten)];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final allNodes = nodes.expand(_flatten).toList();

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: allNodes.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final node = allNodes[index];
        final isActive = node.branch == activeBranch;

        return Card(
          color: isActive
              ? colors.primary.withValues(alpha: 0.08)
              : null,
          child: InkWell(
            onTap: () => onTap(node),
            onLongPress: () => onLongPress(node),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  // Branch icon
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: isActive
                          ? colors.primary.withValues(alpha: 0.15)
                          : colors.onSurface.withValues(alpha: 0.06),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.account_tree_outlined,
                      size: 20,
                      color: isActive
                          ? colors.primary
                          : colors.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                node.branch,
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight:
                                      isActive ? FontWeight.w700 : FontWeight.w500,
                                  color: isActive ? colors.primary : null,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: colors.onSurface
                                    .withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'v${node.version}',
                                style: theme.textTheme.labelSmall,
                              ),
                            ),
                            if (isActive) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: colors.primary
                                      .withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  'ACTIVE',
                                  style:
                                      theme.textTheme.labelSmall?.copyWith(
                                    color: colors.primary,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 9,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        if (node.commitMessage != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            node.commitMessage!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colors.onSurface
                                  .withValues(alpha: 0.6),
                            ),
                          ),
                        ],
                        if (node.createdAt != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            _formatDate(node.createdAt!),
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: colors.onSurface
                                  .withValues(alpha: 0.55),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  // Branch action
                  IconButton(
                    icon: Icon(
                      Icons.add_circle_outline,
                      color: colors.onSurface.withValues(alpha: 0.5),
                      size: 20,
                    ),
                    tooltip: 'Branch from here',
                    onPressed: () => onCreateBranch(node),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${date.month}/${date.day}/${date.year}';
  }
}
