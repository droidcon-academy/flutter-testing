import 'package:flutter/material.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../domain/entities/recipe.dart';

class RecipeDetailView extends StatelessWidget {
  const RecipeDetailView({
    super.key,
    required this.recipe,
  });

  final Recipe recipe;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(recipe.name),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(Sizes.spacing),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (recipe.thumbnailUrl != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(8.0),
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Image.network(
                    recipe.thumbnailUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: Colors.grey[200],
                      child: const Center(
                        child: Icon(
                          Icons.broken_image,
                          size: 48.0,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

            const SizedBox(height: Sizes.spacing * 2),

            Text(
              'Ingredients',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: Sizes.spacing),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: recipe.ingredients.length,
              itemBuilder: (context, index) {
                final ingredient = recipe.ingredients[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.fiber_manual_record,
                        size: 8.0,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 8.0),
                      Expanded(
                        child: Text(
                          ingredient.measure != null 
                              ? '${ingredient.measure} ${ingredient.name}'
                              : ingredient.name,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),

            const SizedBox(height: Sizes.spacing * 2),

            if (recipe.instructions != null) ...[
              Text(
                'Instructions',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: Sizes.spacing),
              Text(
                recipe.instructions!,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: Sizes.spacing * 2),
            ],
          ],
        ),
      ),
    );
  }
}