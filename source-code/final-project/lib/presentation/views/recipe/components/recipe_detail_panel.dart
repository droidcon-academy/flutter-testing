import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../domain/entities/recipe.dart';
import '../../../viewmodels/recipe_viewmodel.dart';
import 'recipe_ingredients.dart';

class RecipeDetailPanel extends ConsumerWidget {
  const RecipeDetailPanel({
    super.key,
    this.recipe,
  });

  final Recipe? recipe;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final viewModel = ref.read(recipeProvider.notifier);

    final recipeState = ref.watch(recipeProvider);

    Recipe? currentRecipe = recipe;
    if (recipe != null && recipeState.selectedRecipe != null && 
        recipe!.id == recipeState.selectedRecipe!.id) {
      currentRecipe = recipeState.selectedRecipe;
    }

    if (currentRecipe == null) {
      return const Scaffold(
        body: Center(
          child: Text('Select a recipe to view details'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        title: Text(currentRecipe.name),
        actions: [
          IconButton(
            icon: Icon(
              currentRecipe.isFavorite ? Icons.favorite : Icons.favorite_outline,
              color: currentRecipe.isFavorite ? Colors.red : null,
            ),
            tooltip: currentRecipe.isFavorite ? 'Remove from favorites' : 'Add to favorites',
            onPressed: () => viewModel.toggleFavorite(currentRecipe!.id),
          ),

          IconButton(
            icon: Icon(
              currentRecipe.isBookmarked ? Icons.bookmark : Icons.bookmark_outline,
              color: currentRecipe.isBookmarked ? Colors.blue : null,
            ),
            tooltip: currentRecipe.isBookmarked ? 'Remove bookmark' : 'Add bookmark',
            onPressed: () => viewModel.toggleBookmark(currentRecipe!.id),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(Sizes.spacing),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (currentRecipe.thumbnailUrl != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(Sizes.radiusLarge),
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Container(
                          color: Colors.grey[200],
                          child: const Center(
                            child: Icon(
                              Icons.restaurant,
                              size: 48.0,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                        
                        Image.network(
                          currentRecipe.thumbnailUrl!,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Center(
                              child: CircularProgressIndicator(
                                value: loadingProgress.expectedTotalBytes != null
                                    ? loadingProgress.cumulativeBytesLoaded /
                                        loadingProgress.expectedTotalBytes!
                                    : null,
                              ),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) => Center(
                            child: LayoutBuilder(
                              builder: (context, constraints) {
                                return Container(
                                  padding: const EdgeInsets.all(Sizes.spacing),
                                  width: constraints.maxWidth,
                                  child: const Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.broken_image,
                                        size: 48.0,
                                        color: Colors.grey,
                                      ),
                                      SizedBox(height: Sizes.spacing),
                                      Text(
                                        'Failed to load image',
                                        style: TextStyle(color: Colors.grey),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              const SizedBox(height: Sizes.spacing * 2),

              RecipeIngredients(ingredients: currentRecipe.ingredients),

              const SizedBox(height: Sizes.spacing * 2),

              if (currentRecipe.instructions != null) ...[
                Text(
                  'Instructions',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: Sizes.spacing),
                Text(
                  currentRecipe.instructions!,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ],

              const SizedBox(height: Sizes.spacing * 2),
            ],
          ),
        ),
      ),
    );
  }
}