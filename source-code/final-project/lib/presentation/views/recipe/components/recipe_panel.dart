import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:recipevault/presentation/viewmodels/recipe_viewmodel.dart';
import 'package:recipevault/presentation/views/recipe/components/recipe_detail_panel.dart';
import 'package:recipevault/presentation/views/recipe/components/recipe_split_view.dart';
import 'package:recipevault/presentation/views/recipe/components/recipe_tab_layout.dart';
import '../../../../core/utils/responsive_helper.dart';
import '../../../../domain/entities/recipe.dart';

final PageStorageBucket pageStorageBucket = PageStorageBucket();

class RecipePanel extends ConsumerStatefulWidget {
  const RecipePanel({
    super.key,
    this.recipes = const [],
    this.onRecipeSelected,
  });

  final List<Recipe> recipes;
  final ValueChanged<Recipe>? onRecipeSelected;

  @override
  ConsumerState<RecipePanel> createState() => _RecipePanelState();
}

class _RecipePanelState extends ConsumerState<RecipePanel> {
  @override
  Widget build(BuildContext context) {
    return switch (ResponsiveSizes.whichDevice()) {
      ResponsiveSizes.mobile => Navigator(
          onGenerateRoute: (settings) {
            return MaterialPageRoute(
              builder: (context) => RecipeListTab(
                onRecipeSelected: (recipe) {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => RecipeDetailPanel(recipe: recipe),
                    ),
                  );
                  ref.read(recipeProvider.notifier).setSelectedRecipe(recipe);
                },
              ),
            );
          },
        ),
      ResponsiveSizes.tablet ||
      ResponsiveSizes.desktopWeb =>
        RecipeSplitView(
          onRecipeSelected: (recipe) {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => RecipeDetailPanel(recipe: recipe),
            ),
          );
          ref.read(recipeProvider.notifier).setSelectedRecipe(recipe);
        },
      ),
    };
  }
}
