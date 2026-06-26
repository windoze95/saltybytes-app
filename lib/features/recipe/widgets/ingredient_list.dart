import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/user_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/unit_converter.dart';
import '../../../models/recipe.dart';

class IngredientList extends ConsumerWidget {
  const IngredientList({
    super.key,
    required this.ingredients,
    this.recipeUnitSystem = 'us_customary',
  });

  final List<Ingredient> ingredients;
  final String recipeUnitSystem;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final userAsync = ref.watch(currentUserProvider);
    final userUnitSystem =
        userAsync.valueOrNull?.personalization.unitSystem ?? 'us_customary';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: ingredients
          .map((ing) => _IngredientRow(
                ingredient: ing,
                recipeUnitSystem: recipeUnitSystem,
                userUnitSystem: userUnitSystem,
              ))
          .toList(),
    );
  }
}

class _IngredientRow extends StatelessWidget {
  const _IngredientRow({
    required this.ingredient,
    required this.recipeUnitSystem,
    required this.userUnitSystem,
  });

  final Ingredient ingredient;
  final String recipeUnitSystem;
  final String userUnitSystem;

  String _formatQuantity() {
    return formatIngredientQuantityWithAlternate(
      ingredient,
      recipeUnitSystem: recipeUnitSystem,
      userUnitSystem: userUnitSystem,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final quantity = _formatQuantity();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 8),
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.6),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          if (quantity.isNotEmpty) ...[
            Text(
              quantity,
              style: theme.textTheme.ingredientQuantity,
            ),
            const SizedBox(width: 6),
          ],
          Expanded(
            child: Text(
              ingredient.name,
              style: theme.textTheme.ingredientItem,
            ),
          ),
        ],
      ),
    );
  }
}
