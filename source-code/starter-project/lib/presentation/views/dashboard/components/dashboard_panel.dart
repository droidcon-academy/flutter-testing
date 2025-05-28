import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:recipevault/core/utils/responsive_helper.dart';
import 'package:recipevault/domain/entities/recipe.dart';
import 'package:recipevault/presentation/viewmodels/recipe_viewmodel.dart';
import 'package:recipevault/presentation/views/recipe/components/recipe_detail_panel.dart';
import 'dashboard_split_view.dart';
import 'dashboard_tab_layout.dart';

final PageStorageBucket dashboardPageStorageBucket = PageStorageBucket();

class DashboardPanel extends ConsumerStatefulWidget {
  const DashboardPanel({
    super.key,
    this.recipes = const [],
    this.onRecipeSelected,
  });

  final List<Recipe> recipes;
  final ValueChanged<Recipe>? onRecipeSelected;

  @override
  ConsumerState<DashboardPanel> createState() => _DashboardPanelState();
}

class _DashboardPanelState extends ConsumerState<DashboardPanel> {
  @override
  Widget build(BuildContext context) {
    
    return switch (ResponsiveSizes.whichDevice()) {
      ResponsiveSizes.mobile => Navigator(
          onGenerateRoute: (settings) {
            return MaterialPageRoute(
              builder: (context) => DashboardTabLayout(
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
      ResponsiveSizes.desktopWeb => DashboardSplitView(
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
