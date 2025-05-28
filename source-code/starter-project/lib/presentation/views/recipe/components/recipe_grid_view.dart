import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:recipevault/core/constants/app_constants.dart';
import 'package:recipevault/core/utils/responsive_helper.dart';
import 'package:recipevault/domain/entities/recipe.dart';
import 'package:recipevault/presentation/viewmodels/recipe_viewmodel.dart';
import 'package:recipevault/presentation/views/home/home_screen.dart'; 
import 'package:recipevault/presentation/views/recipe/components/recipe_panel.dart';
import 'package:recipevault/presentation/widgets/recipe/grid/recipe_grid_card.dart';

class RecipeGridView extends ConsumerWidget {
  const RecipeGridView({
    super.key,
    this.onRecipeSelected,
    this.scrollController,
    this.storageKey = 'recipeGridView',
    required this.deviceType,
  });

  final ValueChanged<Recipe>? onRecipeSelected;
  final ScrollController? scrollController;
  final String storageKey;
  final ResponsiveSizes deviceType;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(recipeProvider);
    final recipes = state.recipes;
    
    return Scaffold(
      appBar: deviceType == ResponsiveSizes.mobile
          ? null
          : AppBar(
        title: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.grid_view),
            SizedBox(width: 8),
            Text('Recipe Grid'),
          ],
        ),
        centerTitle: true,
      ),
      body: PageStorage(
        bucket: pageStorageBucket,
        child: recipes.isEmpty
            ? Consumer(
                builder: (context, ref, child) {
                  final selectedLetter = ref.watch(selectedLetterProvider);
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.no_meals,
                          size: 64,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          selectedLetter != null
                              ? "No recipes found for letter '${selectedLetter.toUpperCase()}'"
                              : "No recipes found",
                          style: Theme.of(context).textTheme.titleMedium,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                },
              )
            : GridView.builder(
                controller: scrollController,
                key: PageStorageKey<String>(storageKey),
                padding: const EdgeInsets.all(Sizes.spacing),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: ResponsiveHelper.recipeGridColumns(context),
                  mainAxisSpacing: Sizes.spacing,
                  crossAxisSpacing: Sizes.spacing,
                  childAspectRatio: 0.75, 
                ),
                itemCount: recipes.length,
                itemBuilder: (context, index) {
                  final recipe = recipes[index];
                  return RecipeGridCard(
                    recipe: recipe,
                    showBookmarkIcon: true,
                    showFavoriteIcon: true,
                    onTap: () => onRecipeSelected?.call(recipe),
                    onDoubleTap: () => ref.read(recipeProvider.notifier).toggleFavorite(recipe.id),
                    onDragLeft: () => ref.read(recipeProvider.notifier).toggleBookmark(recipe.id),
                  );
                },
              ),
      ),
    );
  }
}
