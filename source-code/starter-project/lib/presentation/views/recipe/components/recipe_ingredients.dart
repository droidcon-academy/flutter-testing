import 'package:flutter/material.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../domain/entities/recipe.dart';

class RecipeIngredients extends StatelessWidget {
  const RecipeIngredients({
    super.key,
    required this.ingredients,
  });

  final List<Ingredient> ingredients;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Ingredients',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: Sizes.spacing),

        if (ingredients.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: Sizes.spacing),
            child: Text(
              'No ingredients available for this recipe.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontStyle: FontStyle.italic,
                    color: Colors.grey[600],
                  ),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: ingredients.length,
            separatorBuilder: (context, index) => const Divider(height: 1.0),
            itemBuilder: (context, index) {
              final ingredient = ingredients[index];
              return ListTile(
                dense: true,
                leading: const Icon(Icons.fiber_manual_record, size: 12.0),
                title: Text(
                  ingredient.name,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                trailing: ingredient.measure != null
                    ? SizedBox(
                        width: 80.0,
                        child: Text(
                          ingredient.measure!,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Theme.of(context).colorScheme.primary,
                              ),
                          textAlign: TextAlign.right,
                        ),
                      )
                    : null,
              );
            },
          ),
      ],
    );
  }
}