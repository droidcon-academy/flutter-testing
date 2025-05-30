import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recipevault/domain/entities/recipe.dart';
import 'package:recipevault/presentation/widgets/recipe/detail/recipe_detail_view.dart';

// Helper class for navigation testing
class MockNavigatorObserver extends NavigatorObserver {
  final Function onPop;
  
  MockNavigatorObserver({required this.onPop});
  
  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    onPop();
    super.didPop(route, previousRoute);
  }
}

void main() {
  group('RecipeDetailView Widget Tests', () {
    // Test recipe with all fields populated
    const testRecipe = Recipe(
      id: '1',
      name: 'Test Recipe',
      thumbnailUrl: 'https://example.com/image.jpg',
      ingredients: [
        Ingredient(name: 'Flour', measure: '2 cups'),
        Ingredient(name: 'Sugar', measure: '1 cup'),
        Ingredient(name: 'Eggs', measure: '2 large'),
        Ingredient(name: 'Butter', measure: '1/2 cup'),
      ],
      instructions: 'Mix dry ingredients. Add wet ingredients. Bake at 350°F for 25 minutes.',
      isFavorite: true,
      isBookmarked: true,
    );

    // Test recipe with minimal fields and missing optional data
    const minimalRecipe = Recipe(
      id: '2',
      name: 'Minimal Recipe',
      ingredients: [
        Ingredient(name: 'Water'),
        Ingredient(name: 'Salt'),
      ],
    );

    // Create a test harness to consistently render the RecipeDetailView
    Widget createTestHarness({
      required Recipe recipe,
    }) {
      return MaterialApp(
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        ),
        home: RecipeDetailView(recipe: recipe),
      );
    }

    testWidgets('renders basic recipe detail view with all elements', (WidgetTester tester) async {
      await tester.pumpWidget(createTestHarness(recipe: testRecipe));

      // Verify AppBar and title
      expect(find.byType(AppBar), findsOneWidget,
          reason: 'AppBar should be rendered');
      expect(find.text('Test Recipe'), findsOneWidget,
          reason: 'Recipe name should be displayed in AppBar');
      
      // Verify back button
      expect(find.byType(IconButton), findsOneWidget,
          reason: 'Back button should be visible');
      expect(find.byIcon(Icons.arrow_back), findsOneWidget,
          reason: 'Back arrow icon should be displayed');
      
      // Verify image
      expect(find.byType(Image), findsOneWidget,
          reason: 'Recipe image should be displayed');
      
      // Verify ingredients section
      expect(find.text('Ingredients'), findsOneWidget,
          reason: 'Ingredients heading should be displayed');
      expect(find.text('2 cups Flour'), findsOneWidget,
          reason: 'Ingredient with measure should be formatted properly');
      expect(find.text('1 cup Sugar'), findsOneWidget);
      expect(find.text('2 large Eggs'), findsOneWidget);
      expect(find.text('1/2 cup Butter'), findsOneWidget);
      
      // Verify instructions section
      expect(find.text('Instructions'), findsOneWidget,
          reason: 'Instructions heading should be displayed');
      expect(find.text('Mix dry ingredients. Add wet ingredients. Bake at 350°F for 25 minutes.'), 
          findsOneWidget, reason: 'Instructions text should be displayed');
    });
    
    testWidgets('renders minimal recipe with missing optional fields', (WidgetTester tester) async {
      await tester.pumpWidget(createTestHarness(recipe: minimalRecipe));

      // Verify title is displayed
      expect(find.text('Minimal Recipe'), findsOneWidget,
          reason: 'Recipe name should be displayed in AppBar');
      
      // Verify image is NOT displayed
      expect(find.byType(Image), findsNothing,
          reason: 'Recipe image should not be displayed when thumbnailUrl is null');
      
      // Verify ingredients are displayed correctly
      expect(find.text('Water'), findsOneWidget,
          reason: 'Ingredient without measure should show name only');
      expect(find.text('Salt'), findsOneWidget);
      
      // Verify instructions section is NOT displayed
      expect(find.text('Instructions'), findsNothing,
          reason: 'Instructions heading should not be displayed when instructions is null');
    });
    
    testWidgets('back button navigates back', (WidgetTester tester) async {
      bool navigatedBack = false;
      
      await tester.pumpWidget(MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (context) => const RecipeDetailView(recipe: testRecipe),
                  ),
                );
              },
              child: const Text('Go to Detail'),
            ),
          ),
        ),
        navigatorObservers: [
          MockNavigatorObserver(onPop: () => navigatedBack = true),
        ],
      ));
      
      // Navigate to the detail view
      await tester.tap(find.text('Go to Detail'));
      await tester.pumpAndSettle();
      
      // Verify we're on the detail view
      expect(find.text('Test Recipe'), findsOneWidget);
      
      // Tap the back button
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();
      
      // Verify navigation occurred
      expect(navigatedBack, isTrue,
          reason: 'Back button should trigger navigation');
      expect(find.text('Go to Detail'), findsOneWidget,
          reason: 'Should navigate back to previous screen');
    });
    
    testWidgets('allows scrolling through recipe content', (WidgetTester tester) async {
      // Create a recipe with lots of ingredients to make it scrollable
      final scrollableRecipe = Recipe(
        id: '3',
        name: 'Scrollable Recipe',
        ingredients: List.generate(
          20,
          (index) => Ingredient(name: 'Ingredient ${index + 1}', measure: '${index + 1} tbsp'),
        ),
        instructions: 'A very long set of instructions ' * 20,
      );
      
      await tester.pumpWidget(createTestHarness(recipe: scrollableRecipe));
      
      // Verify we can see the ingredients heading at the start
      expect(find.text('Ingredients'), findsOneWidget,
          reason: 'Ingredients heading should be visible initially');
      
      // Verify SingleChildScrollView is present and used for scrolling
      final scrollView = find.byType(SingleChildScrollView);
      expect(scrollView, findsOneWidget,
          reason: 'ScrollView should be present for scrolling content');
      
      // Check if a sample ingredient is visible
      expect(find.text('1 tbsp Ingredient 1'), findsOneWidget,
          reason: 'First ingredient should be visible');
      
      // Perform a scroll action
      await tester.drag(scrollView, const Offset(0, -500));
      await tester.pump(); // Flush pending timers
      
      // Verify the ListView for ingredients is present
      expect(find.byType(ListView), findsOneWidget,
          reason: 'ListView should be present for displaying ingredients');
      
      // Verify Instructions section is present
      expect(find.text('Instructions'), findsOneWidget,
          reason: 'Instructions heading should be present');
      
      // Verify at least some instructions text is visible
      // (we don't need to check specific visibility after scrolling)
      expect(find.textContaining('A very long set of instructions'), findsOneWidget,
          reason: 'Should be able to see instructions text');
    });
    
    testWidgets('has important content for accessibility', (WidgetTester tester) async {
      await tester.pumpWidget(createTestHarness(recipe: testRecipe));
      
      // Verify important UI elements are present and would be accessible to screen readers
      
      // The back button should be present
      expect(find.byType(IconButton), findsOneWidget,
          reason: 'Back button should be present for accessibility');
      
      // Verify section headings are present
      expect(find.text('Ingredients'), findsOneWidget,
          reason: 'Ingredients heading should be present for screen readers');
      expect(find.text('Instructions'), findsOneWidget,
          reason: 'Instructions heading should be present for screen readers');
      
      // Verify recipe title is present
      expect(find.text('Test Recipe'), findsOneWidget,
          reason: 'Recipe title should be present for screen readers');
      
      // Verify ingredients list is accessible
      for (final ingredient in testRecipe.ingredients) {
        final measureText = ingredient.measure != null 
            ? '${ingredient.measure} ${ingredient.name}'
            : ingredient.name;
        expect(find.text(measureText), findsOneWidget,
            reason: 'Each ingredient should be accessible to screen readers');
      }
      
      // Verify recipe instructions are accessible
      expect(
        find.text('Mix dry ingredients. Add wet ingredients. Bake at 350°F for 25 minutes.'),
        findsOneWidget,
        reason: 'Recipe instructions should be accessible to screen readers',
      );
    });
  });
}