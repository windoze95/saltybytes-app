import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../models/recipe.dart';

class BranchTreePainter extends CustomPainter {
  BranchTreePainter({
    required this.nodes,
    required this.activeBranch,
    required this.activeVersion,
    required this.primaryColor,
    required this.onSurfaceColor,
    required this.surfaceColor,
  });

  final List<RecipeNode> nodes;
  final String activeBranch;
  final int activeVersion;
  final Color primaryColor;
  final Color onSurfaceColor;
  final Color surfaceColor;

  static const double nodeRadius = 18.0;
  static const double horizontalSpacing = 100.0;
  static const double verticalSpacing = 70.0;
  static const double startX = 40.0;
  static const double startY = 40.0;

  @override
  void paint(Canvas canvas, Size size) {
    if (nodes.isEmpty) return;

    final linePaint = Paint()
      ..color = onSurfaceColor.withValues(alpha: 0.2)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final activeLinePaint = Paint()
      ..color = primaryColor.withValues(alpha: 0.4)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    // Layout and draw the tree
    _drawNode(
      canvas,
      nodes.first,
      Offset(startX, startY),
      0,
      linePaint,
      activeLinePaint,
    );
  }

  void _drawNode(
    Canvas canvas,
    RecipeNode node,
    Offset position,
    int depth,
    Paint linePaint,
    Paint activeLinePaint,
  ) {
    final isActive =
        node.branch == activeBranch && node.version == activeVersion;

    // Draw connections to children
    for (int i = 0; i < node.children.length; i++) {
      final childPos = Offset(
        position.dx + horizontalSpacing,
        position.dy + (i * verticalSpacing) - ((node.children.length - 1) * verticalSpacing / 2),
      );

      final isChildActive =
          node.children[i].branch == activeBranch;
      final paint = isChildActive ? activeLinePaint : linePaint;

      final path = Path()
        ..moveTo(position.dx + nodeRadius, position.dy)
        ..cubicTo(
          position.dx + horizontalSpacing / 2,
          position.dy,
          position.dx + horizontalSpacing / 2,
          childPos.dy,
          childPos.dx - nodeRadius,
          childPos.dy,
        );

      canvas.drawPath(path, paint);

      _drawNode(
        canvas,
        node.children[i],
        childPos,
        depth + 1,
        linePaint,
        activeLinePaint,
      );
    }

    // Draw node circle
    final nodePaint = Paint()
      ..color = isActive ? primaryColor : surfaceColor
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = isActive ? primaryColor : onSurfaceColor.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = isActive ? 3.0 : 1.5;

    canvas.drawCircle(position, nodeRadius, nodePaint);
    canvas.drawCircle(position, nodeRadius, borderPaint);

    // Draw version number inside node
    final textPainter = TextPainter(
      text: TextSpan(
        text: 'v${node.version}',
        style: TextStyle(
          color: isActive ? Colors.white : onSurfaceColor,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    textPainter.paint(
      canvas,
      Offset(
        position.dx - textPainter.width / 2,
        position.dy - textPainter.height / 2,
      ),
    );

    // Draw branch label below
    final labelPainter = TextPainter(
      text: TextSpan(
        text: node.branch,
        style: TextStyle(
          color: isActive
              ? primaryColor
              : onSurfaceColor.withValues(alpha: 0.6),
          fontSize: 10,
          fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    labelPainter.paint(
      canvas,
      Offset(
        position.dx - labelPainter.width / 2,
        position.dy + nodeRadius + 4,
      ),
    );
  }

  Size calculateTreeSize() {
    if (nodes.isEmpty) return Size.zero;
    final depth = _maxDepth(nodes.first, 0);
    final breadth = _maxBreadth(nodes.first);
    return Size(
      startX * 2 + depth * horizontalSpacing + nodeRadius * 2,
      startY * 2 +
          math.max(breadth - 1, 0) * verticalSpacing +
          nodeRadius * 2 +
          20,
    );
  }

  int _maxDepth(RecipeNode node, int current) {
    if (node.children.isEmpty) return current;
    int max = current;
    for (final child in node.children) {
      final d = _maxDepth(child, current + 1);
      if (d > max) max = d;
    }
    return max;
  }

  int _maxBreadth(RecipeNode node) {
    if (node.children.isEmpty) return 1;
    int total = 0;
    for (final child in node.children) {
      total += _maxBreadth(child);
    }
    return total;
  }

  @override
  bool shouldRepaint(covariant BranchTreePainter oldDelegate) {
    return oldDelegate.activeBranch != activeBranch ||
        oldDelegate.activeVersion != activeVersion ||
        oldDelegate.nodes != nodes;
  }
}
