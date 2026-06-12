import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_client.dart';
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
  void _showCreateBranchDialog({required int parentNodeId}) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Create Branch'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              labelText: 'Branch name',
              hintText: 'e.g., vegan-version',
            ),
            autocorrect: false,
            autofocus: true,
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
                await _createBranch(name, parentNodeId: parentNodeId);
              },
              child: const Text('Create'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _createBranch(String name, {required int parentNodeId}) async {
    try {
      final ops = ref.read(branchOperationsProvider);
      await ops.createBranch(
        widget.recipeId,
        branchName: name,
        parentNodeId: parentNodeId,
      );
      ref.invalidate(recipeBranchesProvider(widget.recipeId));
      ref.invalidate(recipeDetailProvider(widget.recipeId));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(userFacingErrorMessage(
              e,
              'Failed to create branch. Please try again.',
            )),
          ),
        );
      }
    }
  }

  Future<void> _setActiveNode(int nodeId) async {
    try {
      final ops = ref.read(branchOperationsProvider);
      await ops.setActiveNode(widget.recipeId, nodeId);
      // Switching the active node rewrites the recipe's definition, so both
      // the tree and the recipe detail (and list) must be refetched.
      ref.invalidate(recipeBranchesProvider(widget.recipeId));
      ref.invalidate(recipeDetailProvider(widget.recipeId));
      ref.invalidate(recipeListProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Switched active node')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(userFacingErrorMessage(
              e,
              'Failed to switch node. Please try again.',
            )),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final branchesAsync = ref.watch(recipeBranchesProvider(widget.recipeId));

    return Scaffold(
      appBar: AppBar(title: const Text('Recipe Tree')),
      body: branchesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 48,
                  color: colors.error.withValues(alpha: 0.5)),
              const SizedBox(height: 12),
              Text('Could not load tree', style: theme.textTheme.titleMedium),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: () =>
                    ref.invalidate(recipeBranchesProvider(widget.recipeId)),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (treeData) {
          final rootNode = treeData?.root;
          if (rootNode == null) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.account_tree_outlined, size: 64,
                      color: colors.primary.withValues(alpha: 0.3)),
                  const SizedBox(height: 16),
                  Text('No tree yet', style: theme.textTheme.titleMedium),
                ],
              ),
            );
          }

          return Column(
            children: [
              // Tree visualization
              Expanded(
                flex: 3,
                child: _BranchTree(rootNode: rootNode),
              ),
              const Divider(height: 1),
              // Node list
              Expanded(
                flex: 4,
                child: _BranchNodeList(
                  rootNode: rootNode,
                  onTap: (node) => _setActiveNode(node.id),
                  onCreateBranch: (node) =>
                      _showCreateBranchDialog(parentNodeId: node.id),
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
  const _BranchTree({required this.rootNode});

  final RecipeNode rootNode;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    final painter = BranchTreePainter(
      rootNode: rootNode,
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
    required this.rootNode,
    required this.onTap,
    required this.onCreateBranch,
  });

  final RecipeNode rootNode;
  final void Function(RecipeNode) onTap;
  final void Function(RecipeNode) onCreateBranch;

  List<RecipeNode> _flatten(RecipeNode node) {
    return [node, ...node.children.expand(_flatten)];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final allNodes = _flatten(rootNode);

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: allNodes.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final node = allNodes[index];

        return Card(
          color: node.isActive
              ? colors.primary.withValues(alpha: 0.08)
              : null,
          child: InkWell(
            onTap: () => onTap(node),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: node.isActive
                          ? colors.primary.withValues(alpha: 0.15)
                          : colors.onSurface.withValues(alpha: 0.06),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.account_tree_outlined,
                      size: 20,
                      color: node.isActive
                          ? colors.primary
                          : colors.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                node.branchName,
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: node.isActive
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  color: node.isActive ? colors.primary : null,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: colors.onSurface.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(node.type,
                                  style: theme.textTheme.labelSmall),
                            ),
                            if (node.isActive) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: colors.primary.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  'ACTIVE',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: colors.primary,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 9,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        if (node.summary.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            node.summary,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colors.onSurface.withValues(alpha: 0.6),
                            ),
                          ),
                        ],
                        if (node.createdAt != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            _formatDate(node.createdAt!),
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: colors.onSurface.withValues(alpha: 0.55),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
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
