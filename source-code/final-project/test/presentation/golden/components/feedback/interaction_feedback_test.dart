import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';

import 'package:recipevault/core/themes/app_theme.dart';
import 'package:recipevault/domain/entities/recipe.dart';
import 'package:recipevault/presentation/widgets/recipe/grid/recipe_grid_card.dart';
import 'package:recipevault/presentation/widgets/overlays/heart_overlay.dart';

const _testRecipes = [
  Recipe(
    id: '1',
    name: 'Apple Pie',
    ingredients: [
      Ingredient(name: 'Apples', measure: '6 large'),
      Ingredient(name: 'Sugar', measure: '1 cup'),
    ],
    instructions: 'Bake at 350°F for 45 minutes.',
    isFavorite: false,
    isBookmarked: false,
  ),
  Recipe(
    id: '2',
    name: 'Chocolate Cake',
    ingredients: [
      Ingredient(name: 'Chocolate', measure: '200g'),
      Ingredient(name: 'Flour', measure: '2 cups'),
    ],
    instructions: 'Bake at 180°C for 30 minutes.',
    isFavorite: true,
    isBookmarked: false,
  ),
];

void main() {
  group('Interaction Feedback Golden Tests - Real Components', () {
    setUpAll(() async {
      await loadAppFonts();
    });

    Future<void> pumpInteractionFeedback(
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

    group('HeartOverlay Real Component Tests', () {
      testGoldens('HeartOverlay - Visible feedback state', (tester) async {
        await pumpInteractionFeedback(
          tester,
          screenSize: const Size(375, 600), 
          testWidget: Container(
            width: 300,
            height: 300,
            color: Colors.grey[100],
            child: const Stack(
              children: [
                Center(
                  child: Card(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text('Recipe Card'),
                    ),
                  ),
                ),
                HeartOverlay(
                  isVisible: true,
                  position: Offset(150, 150),
                ),
              ],
            ),
          ),
        );

        expect(find.byType(HeartOverlay), findsOneWidget,
            reason: 'Should display real HeartOverlay component');
        expect(find.byIcon(Icons.favorite), findsOneWidget,
            reason: 'Should display heart icon feedback');

        await screenMatchesGolden(tester, 'heart_overlay_visible_feedback');
      });

      testGoldens('HeartOverlay - Multiple states and positions',
          (tester) async {
        await pumpInteractionFeedback(
          tester,
          screenSize: const Size(375, 600), 
          testWidget: Container(
            width: 375,
            height: 400,
            color: Colors.grey[50],
            child: const Stack(
              children: [
                Positioned(
                  left: 50,
                  top: 50,
                  child: Card(
                    child: SizedBox(
                      width: 100,
                      height: 80,
                      child: Center(child: Text('Recipe 1')),
                    ),
                  ),
                ),
                Positioned(
                  right: 50,
                  top: 50,
                  child: Card(
                    child: SizedBox(
                      width: 100,
                      height: 80,
                      child: Center(child: Text('Recipe 2')),
                    ),
                  ),
                ),
                HeartOverlay(
                  isVisible: true,
                  position: Offset(100, 90),
                  size: 32.0,
                ),
                HeartOverlay(
                  isVisible: true,
                  position: Offset(275, 90),
                  color: Colors.pink,
                  size: 40.0,
                ),
              ],
            ),
          ),
        );

        expect(find.byType(HeartOverlay), findsNWidgets(2),
            reason: 'Should display multiple HeartOverlay components');

        await screenMatchesGolden(tester, 'heart_overlay_multiple_states');
      });

      testGoldens('HeartOverlay - Dark theme feedback', (tester) async {
        await pumpInteractionFeedback(
          tester,
          screenSize: const Size(375, 600), 
          theme: AppTheme.darkTheme,
          testWidget: Container(
            width: 300,
            height: 300,
            child: const Stack(
              children: [
                Center(
                  child: Card(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text('Recipe Card Dark'),
                    ),
                  ),
                ),
                HeartOverlay(
                  isVisible: true,
                  position: Offset(150, 150),
                ),
              ],
            ),
          ),
        );

        expect(find.byType(HeartOverlay), findsOneWidget,
            reason: 'Should display HeartOverlay in dark theme');

        await screenMatchesGolden(tester, 'heart_overlay_dark_theme_feedback');
      });
    });

    group('RecipeGridCard Real Interaction Feedback', () {
      testGoldens('RecipeGridCard - Normal and favorite states',
          (tester) async {
        await pumpInteractionFeedback(
          tester,
          screenSize: const Size(375, 600),
          testWidget: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Expanded(
                  child: RecipeGridCard(
                    recipe: _testRecipes[0],
                    onTap: () {},
                    onDoubleTap: () {},
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: RecipeGridCard(
                    recipe: _testRecipes[1], 
                    onTap: () {},
                    onDoubleTap: () {},
                    showFavoriteIcon: true,
                  ),
                ),
              ],
            ),
          ),
        );

        expect(find.byType(RecipeGridCard), findsNWidgets(2),
            reason: 'Should display real RecipeGridCard components');
        expect(find.text('Apple Pie'), findsOneWidget,
            reason: 'Should display normal recipe card');
        expect(find.text('Chocolate Cake'), findsOneWidget,
            reason: 'Should display favorited recipe card');

        await screenMatchesGolden(tester, 'recipe_grid_feedback_states');
      });

      testGoldens('RecipeGridCard - Responsive feedback behavior',
          (tester) async {
        await pumpInteractionFeedback(
          tester,
          screenSize: const Size(375, 600), 
          testWidget: RecipeGridCard(
            recipe: _testRecipes[0],
            onTap: () {},
            onDoubleTap: () {},
          ),
        );

        expect(find.byType(RecipeGridCard), findsOneWidget,
            reason: 'Should display recipe card in mobile layout');

        await screenMatchesGolden(tester, 'recipe_grid_feedback_mobile');

        tester.view.physicalSize = const Size(800, 1024); 
        tester.view.devicePixelRatio = 1.0;

        await tester.pump();
        await tester.pumpAndSettle();

        expect(find.byType(RecipeGridCard), findsOneWidget,
            reason: 'Should display recipe card in tablet layout');

        await screenMatchesGolden(tester, 'recipe_grid_feedback_tablet');
      });

      testGoldens('RecipeGridCard - With bookmark and favorite icons',
          (tester) async {
        await pumpInteractionFeedback(
          tester,
          screenSize: const Size(375, 600),
          testWidget: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Expanded(
                  child: RecipeGridCard(
                    recipe: _testRecipes[1],
                    onTap: () {},
                    onDoubleTap: () {},
                    showFavoriteIcon: true,
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: RecipeGridCard(
                    recipe: const Recipe(
                      id: '3',
                      name: 'Banana Bread',
                      ingredients: [
                        Ingredient(name: 'Bananas', measure: '3 ripe')
                      ],
                      instructions: 'Bake for 60 minutes.',
                      isFavorite: false,
                      isBookmarked: true,
                    ),
                    onTap: () {},
                    onDoubleTap: () {},
                    showBookmarkIcon: true,
                  ),
                ),
              ],
            ),
          ),
        );

        expect(find.byType(RecipeGridCard), findsNWidgets(2),
            reason: 'Should display recipe cards with feedback icons');

        await screenMatchesGolden(tester, 'recipe_grid_feedback_icons');
      });

      testGoldens('RecipeGridCard - Dark theme with feedback', (tester) async {
        await pumpInteractionFeedback(
          tester,
          screenSize: const Size(375, 600),
          theme: AppTheme.darkTheme,
          testWidget: RecipeGridCard(
            recipe: _testRecipes[1],
            onTap: () {},
            onDoubleTap: () {},
            showFavoriteIcon: true,
          ),
        );

        expect(find.byType(RecipeGridCard), findsOneWidget,
            reason: 'Should display recipe card in dark theme');

        await screenMatchesGolden(tester, 'recipe_grid_feedback_dark_theme');
      });
    });

    group('Interaction Feedback Integration', () {
      testGoldens('Recipe feedback components showcase', (tester) async {
        await pumpInteractionFeedback(
          tester,
          screenSize: const Size(375, 700), 
          testWidget: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Recipe Feedback States',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),

                const Text('Normal Recipe:'),
                const SizedBox(height: 8),
                Expanded(
                  child: RecipeGridCard(
                    recipe: _testRecipes[0],
                    onTap: () {},
                  ),
                ),

                const SizedBox(height: 16),

                const Text('Favorited Recipe:'),
                const SizedBox(height: 8),
                Expanded(
                  child: RecipeGridCard(
                    recipe: _testRecipes[1],
                    onTap: () {},
                    showFavoriteIcon: true,
                  ),
                ),

                const SizedBox(height: 16),

                const Text('Bookmarked Recipe:'),
                const SizedBox(height: 8),
                Expanded(
                  child: RecipeGridCard(
                    recipe: const Recipe(
                      id: '3',
                      name: 'Vegetable Soup',
                      ingredients: [
                        Ingredient(name: 'Vegetables', measure: '2 cups')
                      ],
                      instructions: 'Simmer for 30 minutes.',
                      isFavorite: false,
                      isBookmarked: true,
                    ),
                    onTap: () {},
                    showBookmarkIcon: true,
                  ),
                ),
              ],
            ),
          ),
        );

        expect(find.byType(RecipeGridCard), findsNWidgets(3),
            reason:
                'Should display multiple recipe cards with different states');

        await screenMatchesGolden(tester, 'recipe_feedback_showcase');
      });
    });

    tearDownAll(() async {
    });
  });
}
