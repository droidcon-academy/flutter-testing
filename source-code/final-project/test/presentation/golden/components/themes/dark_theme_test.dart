import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';

import 'package:recipevault/core/themes/app_theme.dart';
import 'package:recipevault/core/constants/app_constants.dart';
import 'package:recipevault/domain/entities/recipe.dart';
import 'package:recipevault/presentation/widgets/navigation/nav_rail.dart';
import 'package:recipevault/presentation/widgets/navigation/bottom_nav_bar.dart';
import 'package:recipevault/presentation/widgets/recipe/grid/recipe_grid_card.dart';
import 'package:recipevault/presentation/widgets/recipe/list/recipe_list_item.dart';

const _testRecipes = [
  Recipe(
    id: '1',
    name: 'Dark Chocolate Mousse',
    ingredients: [
      Ingredient(name: 'Dark Chocolate', measure: '200g'),
      Ingredient(name: 'Heavy Cream', measure: '300ml'),
      Ingredient(name: 'Sugar', measure: '50g'),
    ],
    isFavorite: true,
    isBookmarked: false,
  ),
  Recipe(
    id: '2',
    name: 'Midnight Pasta',
    ingredients: [
      Ingredient(name: 'Black Pasta', measure: '400g'),
      Ingredient(name: 'Squid Ink', measure: '2 tsp'),
      Ingredient(name: 'Garlic', measure: '3 cloves'),
    ],
    isFavorite: false,
    isBookmarked: true,
  ),
  Recipe(
    id: '3',
    name: 'Shadow Salad',
    ingredients: [
      Ingredient(name: 'Mixed Greens', measure: '200g'),
      Ingredient(name: 'Black Olives', measure: '100g'),
    ],
    isFavorite: false,
    isBookmarked: false,
  ),
];

void main() {
  setUpAll(() async {
    await loadAppFonts();
  });

  Future<void> pumpDarkThemeTest(
    WidgetTester tester, {
    required Size screenSize,
    required Widget testWidget,
  }) async {
    tester.view.physicalSize = screenSize;
    tester.view.devicePixelRatio = 1.0;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: testWidget,
      ),
    );

    await tester.pumpAndSettle(const Duration(milliseconds: 500));
  }

  group('Dark Theme - Real Component Tests', () {
    testGoldens('Dark theme - Mobile recipe layout', (tester) async {
      await pumpDarkThemeTest(
        tester,
        screenSize: const Size(375, 812), 
        testWidget: Scaffold(
          appBar: AppBar(
            title: const Text('Recipes'),
            actions: [
              IconButton(
                icon: const Icon(Icons.search),
                onPressed: () {},
              ),
            ],
          ),
          body: Column(
            children: [
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(Sizes.spacing),
                  itemCount: 3,
                  separatorBuilder: (context, index) => const Divider(),
                  itemBuilder: (context, index) {
                    return RecipeListItem(
                      recipe: _testRecipes[index],
                      showFavoriteIcon: index == 0,
                      showBookmarkIcon: index == 1,
                      onTap: () {},
                    );
                  },
                ),
              ),
            ],
          ),
          bottomNavigationBar: NavBar(
            selectedIndex: 0,
            onDestinationSelected: (_) {},
          ),
        ),
      );

      expect(find.byType(NavBar), findsOneWidget,
          reason: 'Mobile should show bottom navigation in dark theme');
      expect(find.byType(RecipeListItem), findsNWidgets(3),
          reason: 'Recipe list items should be displayed with dark theme');

      await screenMatchesGolden(tester, 'dark_theme_mobile_recipe_layout');
    });

    testGoldens('Dark theme - Desktop recipe layout', (tester) async {
      await pumpDarkThemeTest(
        tester,
        screenSize: const Size(1440, 900), 
        testWidget: Scaffold(
          body: Row(
            children: [
              NavRail(
                selectedIndex: 0,
                onDestinationSelected: (_) {},
              ),
              const VerticalDivider(width: 1),
              Expanded(
                child: Column(
                  children: [
                    Container(
                      height: 60,
                      decoration: BoxDecoration(
                        color: AppTheme.darkTheme.colorScheme.surface,
                        border: const Border(
                          bottom: BorderSide(
                            color: ThemeColors.darkDivider,
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          const SizedBox(width: Sizes.spacing),
                          Text(
                            'Recipe Grid',
                            style: AppTheme.darkTheme.textTheme.titleLarge,
                          ),
                          const Spacer(),
                          IconButton(
                            icon: const Icon(Icons.search),
                            onPressed: () {},
                          ),
                          const SizedBox(width: Sizes.spacing),
                        ],
                      ),
                    ),
                    Expanded(
                      child: GridView.count(
                        padding: const EdgeInsets.all(Sizes.spacing),
                        crossAxisCount: 4,
                        mainAxisSpacing: Sizes.spacing,
                        crossAxisSpacing: Sizes.spacing,
                        childAspectRatio: 0.75,
                        children: [
                          for (final recipe in _testRecipes)
                            RecipeGridCard(
                              recipe: recipe,
                              showFavoriteIcon: recipe.isFavorite,
                              showBookmarkIcon: recipe.isBookmarked,
                              onTap: () {},
                              onDoubleTap: () {},
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );

      expect(find.byType(NavRail), findsOneWidget,
          reason: 'Desktop should show NavRail in dark theme');
      expect(find.byType(VerticalDivider), findsOneWidget,
          reason: 'Desktop should show divider in dark theme');
      expect(find.byType(RecipeGridCard), findsNWidgets(3),
          reason: 'Recipe cards should be displayed with dark theme');

      await screenMatchesGolden(tester, 'dark_theme_desktop_recipe_layout');
    });

    testGoldens('Dark theme - Component showcase', (tester) async {
      await pumpDarkThemeTest(
        tester,
        screenSize: const Size(800, 1000),
        testWidget: Scaffold(
          appBar: AppBar(
            title: const Text('Dark Theme Components'),
            actions: [
              IconButton(
                icon: const Icon(Icons.favorite, color: ThemeColors.favorite),
                onPressed: () {},
              ),
              IconButton(
                icon: const Icon(Icons.bookmark, color: ThemeColors.bookmark),
                onPressed: () {},
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(Sizes.spacing),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Recipe List Items',
                    style: AppTheme.darkTheme.textTheme.titleLarge),
                const SizedBox(height: Sizes.spacing),
                Card(
                  child: Column(
                    children: [
                      RecipeListItem(
                        recipe: _testRecipes[0],
                        showFavoriteIcon: true,
                        onTap: () {},
                      ),
                      const Divider(height: 1),
                      RecipeListItem(
                        recipe: _testRecipes[1],
                        showBookmarkIcon: true,
                        onTap: () {},
                      ),
                      const Divider(height: 1),
                      RecipeListItem(
                        recipe: _testRecipes[2],
                        onTap: () {},
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: Sizes.largeSpacing),
                Text('Recipe Grid Cards',
                    style: AppTheme.darkTheme.textTheme.titleLarge),
                const SizedBox(height: Sizes.spacing),
                SizedBox(
                  height: 250,
                  child: GridView.count(
                    crossAxisCount: 3,
                    mainAxisSpacing: Sizes.spacing,
                    crossAxisSpacing: Sizes.spacing,
                    childAspectRatio: 0.75,
                    children: [
                      RecipeGridCard(
                        recipe: _testRecipes[0],
                        showFavoriteIcon: true,
                        onTap: () {},
                      ),
                      RecipeGridCard(
                        recipe: _testRecipes[1],
                        showBookmarkIcon: true,
                        onTap: () {},
                      ),
                      RecipeGridCard(
                        recipe: _testRecipes[2],
                        onTap: () {},
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: Sizes.largeSpacing),
                Text('Dark Theme Elements',
                    style: AppTheme.darkTheme.textTheme.titleLarge),
                const SizedBox(height: Sizes.spacing),
                Row(
                  children: [
                    _buildThemeElement(
                      'Card',
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(Sizes.spacing),
                          child: Text('Dark Card',
                              style: AppTheme.darkTheme.textTheme.bodyLarge),
                        ),
                      ),
                    ),
                    const SizedBox(width: Sizes.spacing),
                    _buildThemeElement(
                      'Button',
                      ElevatedButton(
                        onPressed: () {},
                        child: const Text('Action'),
                      ),
                    ),
                    const SizedBox(width: Sizes.spacing),
                    _buildThemeElement(
                      'Chip',
                      Chip(
                        label: const Text('Recipe Tag'),
                        backgroundColor:
                            AppTheme.darkTheme.colorScheme.surfaceVariant,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: Sizes.largeSpacing),
                // Color palette
                Text('Dark Theme Colors',
                    style: AppTheme.darkTheme.textTheme.titleLarge),
                const SizedBox(height: Sizes.spacing),
                Wrap(
                  spacing: Sizes.spacing,
                  runSpacing: Sizes.spacing,
                  children: [
                    _buildColorChip('Primary', ThemeColors.primary),
                    _buildColorChip('Secondary', ThemeColors.secondary),
                    _buildColorChip('Surface', ThemeColors.darkCardBackground),
                    _buildColorChip('Error', ThemeColors.error),
                    _buildColorChip('Favorite', ThemeColors.favorite),
                    _buildColorChip('Bookmark', ThemeColors.bookmark),
                  ],
                ),
              ],
            ),
          ),
        ),
      );

      await screenMatchesGolden(tester, 'dark_theme_components_showcase');
    });

    testGoldens('Dark theme - Responsive comparison', (tester) async {
      await pumpDarkThemeTest(
        tester,
        screenSize: const Size(375, 667), 
        testWidget: Scaffold(
          body: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(Sizes.spacing),
                color: AppTheme.darkTheme.colorScheme.surface,
                child: Row(
                  children: [
                    Icon(Icons.phone_android,
                        color: AppTheme.darkTheme.iconTheme.color),
                    const SizedBox(width: Sizes.spacing),
                    Text(
                      'Mobile Dark Theme (375px)',
                      style: AppTheme.darkTheme.textTheme.titleMedium,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: GridView.count(
                  padding: const EdgeInsets.all(Sizes.spacing),
                  crossAxisCount: 2, 
                  mainAxisSpacing: Sizes.spacing,
                  crossAxisSpacing: Sizes.spacing,
                  childAspectRatio: 0.75,
                  children: [
                    RecipeGridCard(recipe: _testRecipes[0], onTap: () {}),
                    RecipeGridCard(recipe: _testRecipes[1], onTap: () {}),
                  ],
                ),
              ),
            ],
          ),
          bottomNavigationBar: NavBar(
            selectedIndex: 0,
            onDestinationSelected: (_) {},
          ),
        ),
      );

      await screenMatchesGolden(tester, 'dark_theme_responsive_mobile');

      await pumpDarkThemeTest(
        tester,
        screenSize: const Size(768, 1024), 
        testWidget: Scaffold(
          body: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(Sizes.spacing),
                color: AppTheme.darkTheme.colorScheme.surface,
                child: Row(
                  children: [
                    Icon(Icons.tablet,
                        color: AppTheme.darkTheme.iconTheme.color),
                    const SizedBox(width: Sizes.spacing),
                    Text(
                      'Tablet Dark Theme (768px)',
                      style: AppTheme.darkTheme.textTheme.titleMedium,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: GridView.count(
                  padding: const EdgeInsets.all(Sizes.spacing),
                  crossAxisCount: 3,
                  mainAxisSpacing: Sizes.spacing,
                  crossAxisSpacing: Sizes.spacing,
                  childAspectRatio: 0.75,
                  children: [
                    RecipeGridCard(recipe: _testRecipes[0], onTap: () {}),
                    RecipeGridCard(recipe: _testRecipes[1], onTap: () {}),
                    RecipeGridCard(recipe: _testRecipes[2], onTap: () {}),
                  ],
                ),
              ),
            ],
          ),
          bottomNavigationBar: NavBar(
            selectedIndex: 0,
            onDestinationSelected: (_) {},
          ),
        ),
      );

      await screenMatchesGolden(tester, 'dark_theme_responsive_tablet');

      await pumpDarkThemeTest(
        tester,
        screenSize: const Size(1440, 900), 
        testWidget: Scaffold(
          body: Row(
            children: [
              NavRail(
                selectedIndex: 0,
                onDestinationSelected: (_) {},
              ),
              const VerticalDivider(width: 1),
              Expanded(
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(Sizes.spacing),
                      color: AppTheme.darkTheme.colorScheme.surface,
                      child: Row(
                        children: [
                          Icon(Icons.desktop_windows,
                              color: AppTheme.darkTheme.iconTheme.color),
                          const SizedBox(width: Sizes.spacing),
                          Text(
                            'Desktop Dark Theme (1440px)',
                            style: AppTheme.darkTheme.textTheme.titleMedium,
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: GridView.count(
                        padding: const EdgeInsets.all(Sizes.spacing),
                        crossAxisCount: 5, 
                        mainAxisSpacing: Sizes.spacing,
                        crossAxisSpacing: Sizes.spacing,
                        childAspectRatio: 0.75,
                        children: [
                          for (int i = 0; i < 5; i++)
                            RecipeGridCard(
                              recipe: _testRecipes[i % _testRecipes.length],
                              onTap: () {},
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );

      await screenMatchesGolden(tester, 'dark_theme_responsive_desktop');
    });

    testGoldens('Dark theme - Empty and error states', (tester) async {
      await pumpDarkThemeTest(
        tester,
        screenSize: const Size(375, 812),
        testWidget: Scaffold(
          appBar: AppBar(
            title: const Text('Dark Theme States'),
          ),
          body: Padding(
            padding: const EdgeInsets.all(Sizes.spacing),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(Sizes.largeSpacing),
                    child: Column(
                      children: [
                        Icon(
                          Icons.no_meals,
                          size: 64,
                          color: AppTheme.darkTheme.iconTheme.color
                              ?.withOpacity(0.5),
                        ),
                        const SizedBox(height: Sizes.spacing),
                        Text(
                          'No recipes found',
                          style: AppTheme.darkTheme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: Sizes.smallSpacing),
                        Text(
                          'Try adjusting your search criteria',
                          style: AppTheme.darkTheme.textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: Sizes.spacing),
                Card(
                  color: AppTheme.darkTheme.colorScheme.errorContainer,
                  child: Padding(
                    padding: const EdgeInsets.all(Sizes.largeSpacing),
                    child: Column(
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 64,
                          color: AppTheme.darkTheme.colorScheme.error,
                        ),
                        const SizedBox(height: Sizes.spacing),
                        Text(
                          'Failed to load recipes',
                          style: AppTheme.darkTheme.textTheme.titleMedium
                              ?.copyWith(
                            color:
                                AppTheme.darkTheme.colorScheme.onErrorContainer,
                          ),
                        ),
                        const SizedBox(height: Sizes.smallSpacing),
                        Text(
                          'Please check your connection and try again',
                          style:
                              AppTheme.darkTheme.textTheme.bodyMedium?.copyWith(
                            color:
                                AppTheme.darkTheme.colorScheme.onErrorContainer,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: Sizes.spacing),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(Sizes.largeSpacing),
                    child: Column(
                      children: [
                        Icon(
                          Icons.hourglass_empty,
                          size: 48,
                          color: AppTheme.darkTheme.colorScheme.primary,
                        ),
                        const SizedBox(height: Sizes.spacing),
                        Text(
                          'Loading recipes...',
                          style: AppTheme.darkTheme.textTheme.titleMedium,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      await screenMatchesGolden(tester, 'dark_theme_states');
    });
  });
}

Widget _buildColorChip(String label, Color color) {
  return Container(
    width: 80,
    height: 80,
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: Colors.white24),
    ),
    child: Center(
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    ),
  );
}

Widget _buildThemeElement(String label, Widget child) {
  return Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(label, style: AppTheme.darkTheme.textTheme.bodySmall),
      const SizedBox(height: 8),
      child,
    ],
  );
}
