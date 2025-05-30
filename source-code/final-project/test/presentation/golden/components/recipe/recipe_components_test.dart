import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';

import 'package:recipevault/core/themes/app_theme.dart';
import 'package:recipevault/core/constants/app_constants.dart';
import 'package:recipevault/core/utils/responsive_helper.dart';
import 'package:recipevault/domain/entities/recipe.dart';
import 'package:recipevault/presentation/widgets/recipe/list/recipe_list_item.dart';
import 'package:recipevault/presentation/widgets/recipe/grid/recipe_grid_card.dart';
import 'package:recipevault/presentation/widgets/overlays/heart_overlay.dart';

const testRecipe1 = Recipe(
  id: '1',
  name: 'Classic Apple Pie',
  ingredients: [
    Ingredient(name: 'Apples', measure: '6 large'),
    Ingredient(name: 'Sugar', measure: '1 cup'),
    Ingredient(name: 'Flour', measure: '2 cups'),
    Ingredient(name: 'Butter', measure: '1/2 cup'),
  ],
  instructions: 'Mix ingredients and bake at 350°F for 45 minutes.',
  isFavorite: true,
  isBookmarked: false,
);

const testRecipe2 = Recipe(
  id: '2',
  name: 'Banana Bread',
  ingredients: [
    Ingredient(name: 'Bananas', measure: '3 ripe'),
    Ingredient(name: 'Flour', measure: '1.5 cups'),
    Ingredient(name: 'Sugar', measure: '3/4 cup'),
  ],
  instructions: 'Mash bananas, mix with dry ingredients, bake 60 minutes.',
  isFavorite: false,
  isBookmarked: true,
);

const testRecipe3 = Recipe(
  id: '3',
  name: 'Quick Salad',
  ingredients: [
    Ingredient(name: 'Lettuce', measure: '1 head'),
    Ingredient(name: 'Tomatoes', measure: '2 medium'),
  ],
  instructions: 'Chop and mix vegetables.',
  isFavorite: false,
  isBookmarked: false,
);

const minimalRecipe = Recipe(
  id: '4',
  name: 'Minimal Recipe',
  ingredients: [],
);

const longNameRecipe = Recipe(
  id: '5',
  name: 'Very Long Recipe Name That Should Ellipsize Properly in UI Components',
  ingredients: [
    Ingredient(name: 'Ingredient with very long name that might overflow'),
    Ingredient(name: 'Another long ingredient name'),
    Ingredient(name: 'Third long ingredient'),
    Ingredient(name: 'Fourth ingredient'),
    Ingredient(name: 'Fifth ingredient for overflow test'),
  ],
);

void main() {
  setUpAll(() async {
    await loadAppFonts();
  });

  Future<void> pumpRecipeComponentTest(
    WidgetTester tester, {
    required Size screenSize,
    required Widget testWidget,
    ThemeData? theme,
  }) async {
    tester.view.physicalSize = screenSize;
    tester.view.devicePixelRatio = 1.0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: testWidget),
        theme: theme ?? AppTheme.lightTheme,
      ),
    );

    await tester.pumpAndSettle(const Duration(milliseconds: 500));
  }

  group('RecipeListItem Component - Real Implementation Tests', () {
    testGoldens('RecipeListItem - Mobile list context', (tester) async {
      await pumpRecipeComponentTest(
        tester,
        screenSize: const Size(375, 667), 
        testWidget: ListView(
          padding: const EdgeInsets.all(Sizes.spacing),
          children: [
            RecipeListItem(
              recipe: testRecipe1,
              showFavoriteIcon: true,
              onTap: () {},
            ),
            const Divider(),
            RecipeListItem(
              recipe: testRecipe2,
              showBookmarkIcon: true,
              onTap: () {},
            ),
            const Divider(),
            RecipeListItem(
              recipe: testRecipe3,
              onTap: () {},
            ),
          ],
        ),
      );

      expect(find.byType(RecipeListItem), findsNWidgets(3),
          reason: 'Should display 3 RecipeListItem components');
      expect(find.text('Classic Apple Pie'), findsOneWidget);
      expect(find.text('Banana Bread'), findsOneWidget);
      expect(find.text('Quick Salad'), findsOneWidget);

      await screenMatchesGolden(tester, 'recipe_list_item_mobile_context');
    });

    testGoldens('RecipeListItem - With states', (tester) async {
      await pumpRecipeComponentTest(
        tester,
        screenSize: const Size(375, 667), 
        testWidget: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(Sizes.spacing),
              child: Text(
                'Recipe List Item States',
                style: AppTheme.lightTheme.textTheme.titleMedium,
              ),
            ),
            const Divider(),
            RecipeListItem(
              recipe: testRecipe3,
              onTap: () {},
            ),
            const Divider(),
            RecipeListItem(
              recipe: testRecipe1,
              showFavoriteIcon: true,
              onTap: () {},
            ),
            const Divider(),
            RecipeListItem(
              recipe: testRecipe2,
              showBookmarkIcon: true,
              onTap: () {},
            ),
          ],
        ),
      );

      await screenMatchesGolden(tester, 'recipe_list_item_states');
    });

    testGoldens('RecipeListItem - Edge cases', (tester) async {
      await pumpRecipeComponentTest(
        tester,
        screenSize: const Size(375, 667), 
        testWidget: ListView(
          padding: const EdgeInsets.all(Sizes.spacing),
          children: [
            RecipeListItem(
              recipe: minimalRecipe,
              onTap: () {},
            ),
            const Divider(),
            RecipeListItem(
              recipe: longNameRecipe,
              onTap: () {},
            ),
          ],
        ),
      );

      expect(find.text('Minimal Recipe'), findsOneWidget);

      await screenMatchesGolden(tester, 'recipe_list_item_edge_cases');
    });

    testGoldens('RecipeListItem - Dark theme', (tester) async {
      await pumpRecipeComponentTest(
        tester,
        screenSize: const Size(375, 667), 
        theme: AppTheme.darkTheme,
        testWidget: ListView(
          padding: const EdgeInsets.all(Sizes.spacing),
          children: [
            RecipeListItem(
              recipe: testRecipe1,
              showFavoriteIcon: true,
              onTap: () {},
            ),
            const Divider(),
            RecipeListItem(
              recipe: testRecipe2,
              showBookmarkIcon: true,
              onTap: () {},
            ),
          ],
        ),
      );

      await screenMatchesGolden(tester, 'recipe_list_item_dark_theme');
    });
  });

  group('RecipeGridCard Component - Real Implementation Tests', () {
    testGoldens('RecipeGridCard - Mobile grid context', (tester) async {
      await pumpRecipeComponentTest(
        tester,
        screenSize: const Size(375, 667), 
        testWidget: GridView.count(
          padding: const EdgeInsets.all(Sizes.spacing),
          crossAxisCount: 2,
          mainAxisSpacing: Sizes.spacing,
          crossAxisSpacing: Sizes.spacing,
          childAspectRatio: 0.75,
          children: [
            RecipeGridCard(
              recipe: testRecipe1,
              showFavoriteIcon: true,
              onTap: () {},
              onDoubleTap: () {},
            ),
            RecipeGridCard(
              recipe: testRecipe2,
              showBookmarkIcon: true,
              onTap: () {},
              onDoubleTap: () {},
            ),
            RecipeGridCard(
              recipe: testRecipe3,
              onTap: () {},
              onDoubleTap: () {},
            ),
            RecipeGridCard(
              recipe: minimalRecipe,
              onTap: () {},
              onDoubleTap: () {},
            ),
          ],
        ),
      );

      expect(find.byType(RecipeGridCard), findsNWidgets(4),
          reason: 'Should display 4 RecipeGridCard components');
      expect(find.byIcon(Icons.favorite), findsOneWidget,
          reason: 'Should show favorite icon');
      expect(find.byIcon(Icons.bookmark), findsOneWidget,
          reason: 'Should show bookmark icon');

      await screenMatchesGolden(tester, 'recipe_grid_card_mobile_context');
    });

    testGoldens('RecipeGridCard - Tablet grid context', (tester) async {
      await pumpRecipeComponentTest(
        tester,
        screenSize: const Size(768, 1024), 
        testWidget: GridView.count(
          padding: const EdgeInsets.all(Sizes.spacing),
          crossAxisCount: 3,
          mainAxisSpacing: Sizes.spacing,
          crossAxisSpacing: Sizes.spacing,
          childAspectRatio: 0.75,
          children: [
            RecipeGridCard(
              recipe: testRecipe1,
              showFavoriteIcon: true,
              onTap: () {},
              onDoubleTap: () {},
            ),
            RecipeGridCard(
              recipe: testRecipe2,
              showBookmarkIcon: true,
              onTap: () {},
              onDoubleTap: () {},
            ),
            RecipeGridCard(
              recipe: testRecipe3,
              showFavoriteIcon: true,
              showBookmarkIcon: true,
              onTap: () {},
              onDoubleTap: () {},
            ),
          ],
        ),
      );

      await screenMatchesGolden(tester, 'recipe_grid_card_tablet_context');
    });

    testGoldens('RecipeGridCard - Desktop grid context', (tester) async {
      await pumpRecipeComponentTest(
        tester,
        screenSize: const Size(1440, 900), 
        testWidget: GridView.count(
          padding: const EdgeInsets.all(Sizes.spacing),
          crossAxisCount: 5,
          mainAxisSpacing: Sizes.spacing,
          crossAxisSpacing: Sizes.spacing,
          childAspectRatio: 0.75,
          children: List.generate(5, (index) {
            final recipes = [
              testRecipe1,
              testRecipe2,
              testRecipe3,
              minimalRecipe,
              testRecipe1
            ];
            return RecipeGridCard(
              recipe: recipes[index],
              showFavoriteIcon: index % 2 == 0,
              showBookmarkIcon: index % 3 == 0,
              onTap: () {},
              onDoubleTap: () {},
            );
          }),
        ),
      );

      await screenMatchesGolden(tester, 'recipe_grid_card_desktop_context');
    });

    testGoldens('RecipeGridCard - HeartOverlay integration', (tester) async {
      await pumpRecipeComponentTest(
        tester,
        screenSize: const Size(375, 667), 
        testWidget: Center(
          child: SizedBox(
            width: 300,
            height: 400,
            child: RecipeGridCard(
              recipe: testRecipe1,
              showFavoriteIcon: true,
              onTap: () {},
              onDoubleTap: () {},
            ),
          ),
        ),
      );

      expect(find.byType(RecipeGridCard), findsOneWidget,
          reason: 'Should display RecipeGridCard');

      expect(find.byType(HeartOverlay), findsNothing,
          reason: 'HeartOverlay should not be visible initially');

      await screenMatchesGolden(tester, 'recipe_grid_card_heart_overlay_ready');
    });

    testGoldens('RecipeGridCard - Dark theme', (tester) async {
      await pumpRecipeComponentTest(
        tester,
        screenSize: const Size(375, 667), 
        theme: AppTheme.darkTheme,
        testWidget: GridView.count(
          padding: const EdgeInsets.all(Sizes.spacing),
          crossAxisCount: 2,
          mainAxisSpacing: Sizes.spacing,
          crossAxisSpacing: Sizes.spacing,
          childAspectRatio: 0.75,
          children: [
            RecipeGridCard(
              recipe: testRecipe1,
              showFavoriteIcon: true,
              onTap: () {},
              onDoubleTap: () {},
            ),
            RecipeGridCard(
              recipe: testRecipe2,
              showBookmarkIcon: true,
              onTap: () {},
              onDoubleTap: () {},
            ),
          ],
        ),
      );

      await screenMatchesGolden(tester, 'recipe_grid_card_dark_theme');
    });
  });

  group('Recipe Components Responsive Behavior', () {
    testGoldens('Recipe grid - Mobile to tablet responsive columns',
        (tester) async {
      await pumpRecipeComponentTest(
        tester,
        screenSize: const Size(600, 800), 
        testWidget: GridView.count(
          padding: const EdgeInsets.all(Sizes.spacing),
          crossAxisCount: 2, 
          mainAxisSpacing: Sizes.spacing,
          crossAxisSpacing: Sizes.spacing,
          childAspectRatio: 0.75,
          children: [
            RecipeGridCard(
              recipe: testRecipe1,
              onTap: () {},
            ),
            RecipeGridCard(
              recipe: testRecipe2,
              onTap: () {},
            ),
            RecipeGridCard(
              recipe: testRecipe3,
              onTap: () {},
            ),
            RecipeGridCard(
              recipe: minimalRecipe,
              onTap: () {},
            ),
          ],
        ),
      );

      await screenMatchesGolden(tester, 'recipe_components_mobile_boundary');
    });

    testGoldens('Recipe components - List vs Grid comparison', (tester) async {
      await pumpRecipeComponentTest(
        tester,
        screenSize: const Size(768, 600),
        testWidget: Row(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(Sizes.spacing),
                children: [
                  RecipeListItem(
                    recipe: testRecipe1,
                    showFavoriteIcon: true,
                    onTap: () {},
                  ),
                  const Divider(),
                  RecipeListItem(
                    recipe: testRecipe2,
                    showBookmarkIcon: true,
                    onTap: () {},
                  ),
                  const Divider(),
                  RecipeListItem(
                    recipe: testRecipe3,
                    onTap: () {},
                  ),
                ],
              ),
            ),
            Container(
              width: 1,
              color: Colors.grey,
            ),
            Expanded(
              child: GridView.count(
                padding: const EdgeInsets.all(Sizes.spacing),
                crossAxisCount: 2,
                mainAxisSpacing: Sizes.spacing,
                crossAxisSpacing: Sizes.spacing,
                childAspectRatio: 0.75,
                children: [
                  RecipeGridCard(
                    recipe: testRecipe1,
                    showFavoriteIcon: true,
                    onTap: () {},
                  ),
                  RecipeGridCard(
                    recipe: testRecipe2,
                    showBookmarkIcon: true,
                    onTap: () {},
                  ),
                  RecipeGridCard(
                    recipe: testRecipe3,
                    onTap: () {},
                  ),
                  RecipeGridCard(
                    recipe: minimalRecipe,
                    onTap: () {},
                  ),
                ],
              ),
            ),
          ],
        ),
      );

      await screenMatchesGolden(
          tester, 'recipe_components_list_grid_comparison');
    });
  });

  group('Recipe Components State Showcase', () {
    testGoldens('Recipe components - All states showcase', (tester) async {
      await pumpRecipeComponentTest(
        tester,
        screenSize: const Size(800, 1000),
        testWidget: SingleChildScrollView(
          padding: const EdgeInsets.all(Sizes.spacing),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Recipe Component States',
                style: AppTheme.lightTheme.textTheme.headlineSmall,
              ),
              const SizedBox(height: Sizes.largeSpacing),
              Text(
                'List Item States',
                style: AppTheme.lightTheme.textTheme.titleMedium,
              ),
              const SizedBox(height: Sizes.spacing),
              RecipeListItem(
                recipe: testRecipe1,
                showFavoriteIcon: true,
                onTap: () {},
              ),
              const Divider(),
              RecipeListItem(
                recipe: testRecipe2,
                showBookmarkIcon: true,
                onTap: () {},
              ),
              const Divider(),
              RecipeListItem(
                recipe: testRecipe3,
                onTap: () {},
              ),
              const Divider(),
              RecipeListItem(
                recipe: minimalRecipe,
                onTap: () {},
              ),
              const SizedBox(height: Sizes.largeSpacing),
              Text(
                'Grid Card States',
                style: AppTheme.lightTheme.textTheme.titleMedium,
              ),
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
                      recipe: testRecipe1,
                      showFavoriteIcon: true,
                      onTap: () {},
                    ),
                    RecipeGridCard(
                      recipe: testRecipe2,
                      showBookmarkIcon: true,
                      onTap: () {},
                    ),
                    RecipeGridCard(
                      recipe: testRecipe3,
                      showFavoriteIcon: true,
                      showBookmarkIcon: true,
                      onTap: () {},
                    ),
                  ],
                ),
              ),
              const SizedBox(height: Sizes.largeSpacing),
              Text(
                'Edge Cases',
                style: AppTheme.lightTheme.textTheme.titleMedium,
              ),
              const SizedBox(height: Sizes.spacing),
              RecipeListItem(
                recipe: longNameRecipe,
                onTap: () {},
              ),
              const Divider(),
              SizedBox(
                height: 200,
                child: RecipeGridCard(
                  recipe: longNameRecipe,
                  showFavoriteIcon: true,
                  onTap: () {},
                ),
              ),
            ],
          ),
        ),
      );

      expect(find.byType(RecipeListItem), findsNWidgets(5),
          reason: 'Should display 5 list items with different states');
      expect(find.byType(RecipeGridCard), findsNWidgets(4),
          reason: 'Should display 4 grid cards with different states');

      await screenMatchesGolden(tester, 'recipe_components_all_states');
    });
  });
}
