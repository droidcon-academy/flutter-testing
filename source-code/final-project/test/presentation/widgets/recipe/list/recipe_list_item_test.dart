import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recipevault/core/constants/app_constants.dart';
import 'package:recipevault/domain/entities/recipe.dart';
import 'package:recipevault/presentation/widgets/recipe/list/recipe_list_item.dart';

void main() {
  group('RecipeListItem Widget Tests', () {
    // Test recipe with all fields populated
    const testRecipe = Recipe(
      id: '1',
      name: 'Test Recipe',
      thumbnailUrl: 'https://example.com/image.jpg',
      ingredients: [
        Ingredient(name: 'Ingredient 1', measure: '1 cup'),
        Ingredient(name: 'Ingredient 2', measure: '2 tbsp'),
        Ingredient(name: 'Ingredient 3', measure: '3 tsp'),
      ],
      instructions: 'Test instructions',
      isFavorite: true,
      isBookmarked: true,
    );

    // Test recipe with minimal fields
    const minimalRecipe = Recipe(
      id: '2',
      name: 'Minimal Recipe',
      ingredients: [],
    );

    // Create a test harness to consistently render the RecipeListItem
    Widget createTestHarness({
      required Recipe recipe,
      bool showFavoriteIcon = false,
      bool showBookmarkIcon = false,
      VoidCallback? onTap,
    }) {
      return MaterialApp(
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        ),
        home: Scaffold(
          body: Center(
            child: RecipeListItem(
              recipe: recipe,
              showFavoriteIcon: showFavoriteIcon,
              showBookmarkIcon: showBookmarkIcon,
              onTap: onTap,
            ),
          ),
        ),
      );
    }

    testWidgets('renders basic recipe list item with all elements', (WidgetTester tester) async {
      await tester.pumpWidget(createTestHarness(recipe: testRecipe));

      // Verify the ListTile is rendered
      expect(find.byType(ListTile), findsOneWidget, 
          reason: 'RecipeListItem should render a ListTile');
      
      // Verify recipe name is displayed
      expect(find.text('Test Recipe'), findsOneWidget,
          reason: 'Recipe name should be displayed');
      
      // Verify leading image/avatar is present
      expect(find.byType(CircleAvatar), findsOneWidget,
          reason: 'CircleAvatar should be displayed as leading widget');
      
      // Verify ingredient preview is shown in subtitle
      expect(find.textContaining('Ingredient 1, Ingredient 2, Ingredient 3'), findsOneWidget,
          reason: 'Ingredient preview should be displayed in subtitle');
    });

    testWidgets('renders minimal recipe with no ingredients properly', (WidgetTester tester) async {
      await tester.pumpWidget(createTestHarness(recipe: minimalRecipe));

      // Verify recipe name is displayed
      expect(find.text('Minimal Recipe'), findsOneWidget,
          reason: 'Recipe name should be displayed');
      
      // Verify empty ingredient text
      expect(find.byWidgetPredicate((widget) => 
        widget is Text && 
        (widget.data?.isEmpty ?? false) && 
        widget != find.text('Minimal Recipe').evaluate().first
      ), findsOneWidget,
          reason: 'Empty ingredient list should display empty text');
    });

    testWidgets('truncates ingredient preview for recipes with many ingredients', (WidgetTester tester) async {
      const manyIngredientsRecipe = Recipe(
        id: '3',
        name: 'Many Ingredients Recipe',
        ingredients: const [
          Ingredient(name: 'Ingredient 1'),
          Ingredient(name: 'Ingredient 2'),
          Ingredient(name: 'Ingredient 3'),
          Ingredient(name: 'Ingredient 4'),
          Ingredient(name: 'Ingredient 5'),
        ],
      );

      await tester.pumpWidget(createTestHarness(recipe: manyIngredientsRecipe));

      // Verify ingredient preview is truncated
      expect(find.textContaining('Ingredient 1, Ingredient 2, Ingredient 3, and 2 more'), findsOneWidget,
          reason: 'Ingredient preview should be truncated for recipes with more than 3 ingredients');
    });

    testWidgets('handles missing thumbnailUrl gracefully', (WidgetTester tester) async {
      await tester.pumpWidget(createTestHarness(recipe: minimalRecipe));

      // Verify restaurant icon is shown as fallback
      expect(find.byIcon(Icons.restaurant), findsOneWidget,
          reason: 'Restaurant icon should be displayed when thumbnailUrl is null');
    });

    testWidgets('calls onTap callback when tapped', (WidgetTester tester) async {
      bool wasTapped = false;
      
      await tester.pumpWidget(createTestHarness(
        recipe: testRecipe,
        onTap: () {
          wasTapped = true;
        },
      ));

      // Tap the list item
      await tester.tap(find.byType(ListTile));
      await tester.pump();

      // Verify callback was called
      expect(wasTapped, isTrue, reason: 'onTap callback should be triggered when list item is tapped');
    });

    testWidgets('has proper constraints for width', (WidgetTester tester) async {
      await tester.pumpWidget(createTestHarness(recipe: testRecipe));

      // Find the ConstrainedBox that wraps the ListTile
      final constrainedBox = tester.widget<ConstrainedBox>(
        find.ancestor(
          of: find.byType(ListTile),
          matching: find.byType(ConstrainedBox),
        ),
      );
      expect(constrainedBox.constraints.minWidth, 300.0,
          reason: 'RecipeListItem should have a minimum width constraint of 300.0');
    });

    testWidgets('has correct content padding', (WidgetTester tester) async {
      await tester.pumpWidget(createTestHarness(recipe: testRecipe));

      // Find the ListTile and verify its content padding
      final listTile = tester.widget<ListTile>(find.byType(ListTile));
      
      // Verify horizontal and vertical padding based on Sizes constants
      expect(listTile.contentPadding, equals(const EdgeInsets.symmetric(
        horizontal: Sizes.spacing,
        vertical: Sizes.spacing / 2,
      )), reason: 'ListTile should have correct content padding');
    });

    testWidgets('is tappable and properly structured', (WidgetTester tester) async {
      bool wasTapped = false;
      
      await tester.pumpWidget(createTestHarness(
        recipe: testRecipe,
        onTap: () {
          wasTapped = true;
        },
      ));

      // Verify that we can find the key components
      expect(find.text('Test Recipe'), findsOneWidget,
          reason: 'Recipe name should be displayed');
      expect(find.byType(CircleAvatar), findsOneWidget,
          reason: 'CircleAvatar should be displayed as leading widget');
      
      // Tap the list tile and verify callback was triggered
      await tester.tap(find.byType(ListTile));
      await tester.pump();
      expect(wasTapped, isTrue, 
          reason: 'The list item should be tappable');
    });

    // Note: The current implementation of RecipeListItem doesn't actually show icons for 
    // favorite/bookmark status even when the flags are set to true. If these were to be
    // implemented, we would add tests to verify their visibility here.
  });
}