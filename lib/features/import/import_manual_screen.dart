import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers/recipe_provider.dart';
import '../../core/utils/unit_converter.dart';

class ImportManualScreen extends ConsumerStatefulWidget {
  const ImportManualScreen({super.key});

  @override
  ConsumerState<ImportManualScreen> createState() => _ImportManualScreenState();
}

class _ImportManualScreenState extends ConsumerState<ImportManualScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _cookTimeController = TextEditingController();
  final _portionsController = TextEditingController(text: '4');

  final List<_IngredientRow> _ingredients = [_IngredientRow()];
  final List<TextEditingController> _instructions = [TextEditingController()];

  bool _isSaving = false;

  static const _units = [
    '',
    'tsp',
    'tbsp',
    'cup',
    'oz',
    'lb',
    'g',
    'kg',
    'ml',
    'l',
    'pinch',
    'clove',
    'slice',
    'piece',
    'can',
    'bunch',
    'sprig',
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _cookTimeController.dispose();
    _portionsController.dispose();
    for (final i in _ingredients) {
      i.dispose();
    }
    for (final c in _instructions) {
      c.dispose();
    }
    super.dispose();
  }

  void _addIngredient() {
    setState(() => _ingredients.add(_IngredientRow()));
  }

  void _removeIngredient(int index) {
    if (_ingredients.length > 1) {
      setState(() {
        _ingredients[index].dispose();
        _ingredients.removeAt(index);
      });
    }
  }

  void _addInstruction() {
    setState(() => _instructions.add(TextEditingController()));
  }

  void _removeInstruction(int index) {
    if (_instructions.length > 1) {
      setState(() {
        _instructions[index].dispose();
        _instructions.removeAt(index);
      });
    }
  }

  /// Builds the snake_case manualImportRequest body for
  /// POST /v1/recipes/import/manual.
  Map<String, dynamic> _buildRequestBody() {
    return {
      'title': _titleController.text.trim(),
      'ingredients': _ingredients
          .where((i) => i.nameController.text.trim().isNotEmpty)
          .map((i) => {
                'name': i.nameController.text.trim(),
                'unit': i.selectedUnit,
                'amount':
                    parseFractionalAmount(i.amountController.text.trim()) ?? 0,
              })
          .toList(),
      'instructions': _instructions
          .map((c) => c.text.trim())
          .where((t) => t.isNotEmpty)
          .toList(),
      'cook_time': int.tryParse(_cookTimeController.text) ?? 0,
      'portions': int.tryParse(_portionsController.text) ?? 4,
    };
  }

  Future<void> _saveRecipe() async {
    if (_isSaving) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final recipe =
          await ref.read(recipeCrudProvider).importManual(_buildRequestBody());
      ref.invalidate(recipeListProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Recipe created successfully!')),
        );
        context.go('/recipe/${recipe.id}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manual Entry'),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _saveRecipe,
            child: _isSaving
                ? SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: theme.colorScheme.primary,
                    ),
                  )
                : const Text('Save'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Title
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Recipe Title',
                hintText: 'e.g. Grandma\'s Chocolate Cake',
              ),
              textInputAction: TextInputAction.next,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Title is required' : null,
            ),
            const SizedBox(height: 16),

            // Cook time & portions row
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _cookTimeController,
                    decoration: const InputDecoration(
                      labelText: 'Cook Time (min)',
                      prefixIcon: Icon(Icons.timer_outlined),
                    ),
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.next,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _portionsController,
                    decoration: const InputDecoration(
                      labelText: 'Portions',
                      prefixIcon: Icon(Icons.people_outline),
                    ),
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.next,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32),

            // Ingredients section
            Row(
              children: [
                Text('Ingredients', style: theme.textTheme.titleMedium),
                const Spacer(),
                TextButton.icon(
                  onPressed: _addIngredient,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...List.generate(_ingredients.length, (index) {
              final row = _ingredients[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    SizedBox(
                      width: 60,
                      child: TextField(
                        controller: row.amountController,
                        decoration: const InputDecoration(
                          hintText: 'Amt',
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 8, vertical: 12),
                        ),
                        keyboardType: TextInputType.text,
                        textInputAction: TextInputAction.next,
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 72,
                      child: DropdownButtonFormField<String>(
                        value: row.selectedUnit,
                        decoration: const InputDecoration(
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 8, vertical: 12),
                        ),
                        isExpanded: true,
                        items: _units
                            .map((u) => DropdownMenuItem(
                                  value: u,
                                  child:
                                      Text(u.isEmpty ? 'Unit' : u, style: theme.textTheme.bodySmall),
                                ))
                            .toList(),
                        onChanged: (v) => row.selectedUnit = v ?? '',
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: row.nameController,
                        decoration: const InputDecoration(
                          hintText: 'Ingredient name',
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 8, vertical: 12),
                        ),
                        textInputAction: TextInputAction.next,
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.remove_circle_outline,
                          size: 20,
                          color: theme.colorScheme.error.withValues(alpha: 0.6)),
                      onPressed: () => _removeIngredient(index),
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
              );
            }),

            const SizedBox(height: 32),

            // Instructions section
            Row(
              children: [
                Text('Instructions', style: theme.textTheme.titleMedium),
                const Spacer(),
                TextButton.icon(
                  onPressed: _addInstruction,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add Step'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...List.generate(_instructions.length, (index) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      margin: const EdgeInsets.only(top: 12),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Center(
                        child: Text(
                          '${index + 1}',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _instructions[index],
                        decoration: InputDecoration(
                          hintText: 'Step ${index + 1}',
                        ),
                        maxLines: 3,
                        minLines: 1,
                        textInputAction: TextInputAction.newline,
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.remove_circle_outline,
                          size: 20,
                          color: theme.colorScheme.error.withValues(alpha: 0.6)),
                      onPressed: () => _removeInstruction(index),
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
              );
            }),

            const SizedBox(height: 32),

            // Save button
            SizedBox(
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _isSaving ? null : _saveRecipe,
                icon: _isSaving
                    ? SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: theme.colorScheme.onPrimary,
                        ),
                      )
                    : const Icon(Icons.save),
                label: Text(_isSaving ? 'Saving...' : 'Save Recipe'),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _IngredientRow {
  final nameController = TextEditingController();
  final amountController = TextEditingController();
  String selectedUnit = '';

  void dispose() {
    nameController.dispose();
    amountController.dispose();
  }
}
