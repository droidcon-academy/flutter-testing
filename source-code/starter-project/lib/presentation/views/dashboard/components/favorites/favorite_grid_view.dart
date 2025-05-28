import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:recipevault/core/constants/app_constants.dart';
import 'package:recipevault/core/utils/responsive_helper.dart';
import 'package:recipevault/domain/entities/recipe.dart';
import 'package:recipevault/presentation/viewmodels/recipe_viewmodel.dart';
import 'package:recipevault/presentation/widgets/recipe/grid/recipe_grid_card.dart';

/// A specialized widget that displays favorite recipes in a grid layout
class FavoriteGridView extends ConsumerWidget {
  const FavoriteGridView({
    super.key,
    required this.recipes,
    this.onRecipeSelected,
    this.storageKey = 'favorite_grid',
    this.scrollController,
  });

  final List<Recipe> recipes;
  final ValueChanged<Recipe>? onRecipeSelected;
  final String storageKey;
  final ScrollController? scrollController;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: recipes.isEmpty
          ? _buildEmptyState(context)
          : GridView.builder(
              controller: scrollController,
              key: PageStorageKey<String>(storageKey),
              padding: const EdgeInsets.all(Sizes.spacing),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: ResponsiveHelper.recipeGridColumns(context),
                childAspectRatio: 0.75,
                crossAxisSpacing: Sizes.spacing,
                mainAxisSpacing: Sizes.spacing,
              ),
              itemCount: recipes.length,
              itemBuilder: (context, index) {
                final recipe = recipes[index];
                return RecipeGridCard(
                  recipe: recipe,
                  onTap: () {
                    if (onRecipeSelected != null) {
                      onRecipeSelected!(recipe);
                    }
                  },
                  onDoubleTap: () => ref.read(recipeProvider.notifier).toggleFavorite(recipe.id),
                  showFavoriteIcon: true,
                );
              },
            ),
    );
  }
  
  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.favorite_border,
            size: 64,
            color: Colors.grey,
          ),
          const SizedBox(height: Sizes.spacing),
          Text(
            'No favorite recipes yet',
            style: Theme.of(context).textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: Sizes.spacing),
          Text(
            'Add recipes to your favorites to see them here',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
