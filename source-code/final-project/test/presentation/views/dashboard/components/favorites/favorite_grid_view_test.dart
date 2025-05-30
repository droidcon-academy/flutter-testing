import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:recipevault/core/constants/app_constants.dart';
import 'package:recipevault/domain/entities/recipe.dart';
import 'package:recipevault/presentation/viewmodels/recipe_viewmodel.dart';
import 'package:recipevault/presentation/views/dashboard/components/favorites/favorite_grid_view.dart';
import 'package:recipevault/presentation/widgets/recipe/grid/recipe_grid_card.dart';

class MockRecipeViewModel extends Mock implements RecipeViewModel {}

class MockBuildContext extends Mock implements BuildContext {}

class TestGridDelegate extends SliverGridDelegateWithFixedCrossAxisCount {
  TestGridDelegate({
    required super.crossAxisCount,
    super.mainAxisSpacing = 0.0,
    super.crossAxisSpacing = 0.0,
    super.childAspectRatio = 1.0,
  });
}

void main() {
  late List<Recipe> testRecipes;
  late MockRecipeViewModel mockRecipeViewModel;

  setUp(() {
    testRecipes = [
      const Recipe(
        id: '1',
        name: 'Test Recipe 1',
        thumbnailUrl: 'https://example.com/image1.jpg',
        ingredients: [
          Ingredient(name: 'Ingredient 1', measure: '1 cup'),
          Ingredient(name: 'Ingredient 2', measure: '2 tbsp'),
        ],
        instructions: 'Test instructions 1',
        isFavorite: true,
        isBookmarked: false,
      ),
      const Recipe(
        id: '2',
        name: 'Test Recipe 2',
        thumbnailUrl: 'https://example.com/image2.jpg',
        ingredients: [
          Ingredient(name: 'Ingredient 3', measure: '3 oz'),
          Ingredient(name: 'Ingredient 4', measure: '4 pieces'),
        ],
        instructions: 'Test instructions 2',
        isFavorite: true,
        isBookmarked: true,
      ),
    ];
    
    mockRecipeViewModel = MockRecipeViewModel();
    
    when(() => mockRecipeViewModel.toggleFavorite(any())).thenAnswer((_) async {});
  });

  Widget createTestHarness({
    required List<Recipe> recipes,
    Function(Recipe)? onRecipeSelected,
    ScrollController? scrollController,
  }) {
    return ProviderScope(
      overrides: [
        recipeProvider.overrideWithProvider(
          StateNotifierProvider<RecipeViewModel, RecipeState>((ref) => mockRecipeViewModel)),
      ],
      child: MaterialApp(
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        ),
        home: Scaffold(
          body: FavoriteGridView(
            recipes: recipes,
            onRecipeSelected: onRecipeSelected,
            scrollController: scrollController,
          ),
        ),
      ),
    );
  }

  group('FavoriteGridView', () {
    testWidgets('renders recipes in a grid when list is not empty', (WidgetTester tester) async {
      
      await tester.pumpWidget(createTestHarness(recipes: testRecipes));
      await tester.pumpAndSettle(); 
      
    
      expect(find.byType(RecipeGridCard), findsNWidgets(testRecipes.length),
          reason: 'Should render a RecipeGridCard for each recipe');
      
      final gridView = tester.widget<GridView>(find.byType(GridView));
      final delegate = gridView.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;
      
      expect(delegate.childAspectRatio, 0.75,
          reason: 'Grid should have the correct aspect ratio');
      expect(delegate.crossAxisSpacing, Sizes.spacing,
          reason: 'Grid should have correct cross axis spacing');
      expect(delegate.mainAxisSpacing, Sizes.spacing,
          reason: 'Grid should have correct main axis spacing');
      
      expect(gridView.padding, equals(const EdgeInsets.all(Sizes.spacing)),
          reason: 'GridView should have correct padding');
    });

    testWidgets('shows empty state when no recipes are available', (WidgetTester tester) async {

      await tester.pumpWidget(createTestHarness(recipes: []));
      await tester.pumpAndSettle();
      
      expect(find.byType(GridView), findsNothing,
          reason: 'GridView should not be rendered when recipes are empty');
      
      expect(find.byIcon(Icons.favorite_border), findsOneWidget,
          reason: 'Empty state should display the favorite_border icon');
      
      expect(find.text('No favorite recipes yet'), findsOneWidget,
          reason: 'Empty state should display the empty message');
      
      expect(find.text('Add recipes to your favorites to see them here'), findsOneWidget,
          reason: 'Empty state should display the help text');
    });

    testWidgets('triggers onRecipeSelected callback when a recipe is tapped', (WidgetTester tester) async {

      Recipe? selectedRecipe;
      await tester.pumpWidget(createTestHarness(
        recipes: testRecipes,
        onRecipeSelected: (recipe) {
          selectedRecipe = recipe;
        },
      ));
      await tester.pumpAndSettle();
      
      final card = tester.widget<RecipeGridCard>(find.byType(RecipeGridCard).first);
      card.onTap?.call();
      await tester.pump();
      
      expect(selectedRecipe, equals(testRecipes[0]),
          reason: 'onRecipeSelected callback should be triggered with the correct recipe');
    });

    testWidgets('calls toggleFavorite when onDoubleTap callback is triggered', (WidgetTester tester) async {
 
      await tester.pumpWidget(createTestHarness(recipes: testRecipes));
      await tester.pumpAndSettle();
      
      final card = tester.widget<RecipeGridCard>(find.byType(RecipeGridCard).first);
      
      card.onDoubleTap?.call();
      await tester.pump();
      
      verify(() => mockRecipeViewModel.toggleFavorite(testRecipes[0].id)).called(1);
    });
    
    testWidgets('verifies grid properties including column count', (WidgetTester tester) async {
     
      await tester.pumpWidget(createTestHarness(recipes: testRecipes));
      await tester.pumpAndSettle();
      
      final gridView = tester.widget<GridView>(find.byType(GridView));
      final delegate = gridView.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;
      
      expect(delegate.childAspectRatio, 0.75,
          reason: 'Grid should have the correct aspect ratio');
      expect(delegate.crossAxisSpacing, Sizes.spacing,
          reason: 'Grid should have correct cross axis spacing');
      expect(delegate.mainAxisSpacing, Sizes.spacing,
          reason: 'Grid should have correct main axis spacing');
      
      expect(delegate.crossAxisCount, greaterThanOrEqualTo(2),
          reason: 'Grid should have at least 2 columns');
      
      expect(gridView.padding, equals(const EdgeInsets.all(Sizes.spacing)),
          reason: 'GridView should have correct padding');
    });
    
    testWidgets('recipe cards contain the correct recipe information', (WidgetTester tester) async {

      await tester.pumpWidget(createTestHarness(recipes: testRecipes));
      await tester.pumpAndSettle();
      
      final cards = tester.widgetList<RecipeGridCard>(find.byType(RecipeGridCard));
      
      for (int i = 0; i < cards.length; i++) {
        final card = cards.elementAt(i);
        expect(card.recipe, equals(testRecipes[i]),
            reason: 'Each RecipeGridCard should have the correct recipe');
        expect(card.showFavoriteIcon, isTrue,
            reason: 'RecipeGridCard should have showFavoriteIcon set to true');
      }
    });
  });
}