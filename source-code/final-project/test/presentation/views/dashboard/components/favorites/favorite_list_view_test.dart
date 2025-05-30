// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:recipevault/core/constants/app_constants.dart';
import 'package:recipevault/domain/entities/recipe.dart';
import 'package:recipevault/presentation/viewmodels/recipe_viewmodel.dart';
import 'package:recipevault/presentation/views/dashboard/components/favorites/favorite_list_view.dart';
import 'package:recipevault/presentation/widgets/recipe/list/recipe_list_item.dart';
import 'package:flutter_slidable/flutter_slidable.dart';


class MockRecipeViewModel extends Mock implements RecipeViewModel {}

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
          body: FavoriteListView(
            recipes: recipes,
            onRecipeSelected: onRecipeSelected,
            scrollController: scrollController,
          ),
        ),
      ),
    );
  }

  group('FavoriteListView', () {
    testWidgets('renders recipes when list is not empty', (WidgetTester tester) async {
      
      await tester.pumpWidget(createTestHarness(recipes: testRecipes));
      await tester.pumpAndSettle(); 
      
      expect(find.byType(RecipeListItem), findsNWidgets(testRecipes.length),
          reason: 'Should render a RecipeListItem for each recipe');
      
      for (final recipe in testRecipes) {
        expect(find.text(recipe.name), findsOneWidget,
            reason: 'Each recipe name should be displayed');
      }
      
      final listView = tester.widget<ListView>(
        find.byType(ListView),
      );
      expect(listView.padding, equals(const EdgeInsets.symmetric(vertical: Sizes.spacing)),
          reason: 'ListView should have the correct padding');
    });

    testWidgets('shows empty state when no recipes are available', (WidgetTester tester) async {
     
      await tester.pumpWidget(createTestHarness(recipes: []));
      await tester.pumpAndSettle();
    
      expect(find.byType(ListView), findsNothing,
          reason: 'ListView should not be rendered when recipes are empty');
      
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
      
      await tester.tap(find.text('Test Recipe 1'));
      await tester.pumpAndSettle();
      
      expect(selectedRecipe, equals(testRecipes[0]),
          reason: 'onRecipeSelected callback should be triggered with the correct recipe');
    });

    testWidgets('calls toggleFavorite when slidable action is used', (WidgetTester tester) async {

      await tester.pumpWidget(createTestHarness(recipes: testRecipes));
      await tester.pumpAndSettle();
      
      final slidableFinder = find.byType(Slidable).first;
      expect(slidableFinder, findsOneWidget, reason: 'Should find a Slidable widget');
      
      await tester.drag(slidableFinder, const Offset(-500.0, 0.0));
      await tester.pumpAndSettle();
      
      final actionFinder = find.text('Remove');
      expect(actionFinder, findsOneWidget, reason: 'Should find the Remove action');
      await tester.tap(actionFinder);
      await tester.pumpAndSettle();
      
    
      verify(() => mockRecipeViewModel.toggleFavorite(testRecipes[0].id)).called(1);
    });

    testWidgets('enforces minimum width constraint of 300', (WidgetTester tester) async {

      tester.binding.window.physicalSizeTestValue = const Size(200 * 3, 600 * 3);
      tester.binding.window.devicePixelRatioTestValue = 3.0;
      addTearDown(tester.binding.window.clearPhysicalSizeTestValue);
      
      await tester.pumpWidget(createTestHarness(recipes: testRecipes));
      await tester.pumpAndSettle();
      
      final sizedBox = tester.widget<SizedBox>(
        find.descendant(
          of: find.byType(LayoutBuilder),
          matching: find.byType(SizedBox),
        ).first,
      );
      
      expect(sizedBox.width, greaterThanOrEqualTo(300.0),
          reason: 'SizedBox should enforce a minimum width of 300');
    });

    testWidgets('has proper semantic properties for accessibility', (WidgetTester tester) async {

      await tester.pumpWidget(createTestHarness(recipes: testRecipes));
      await tester.pumpAndSettle();
      
      for (final recipe in testRecipes) {
        expect(
          find.bySemanticsLabel(RegExp(recipe.name, caseSensitive: false)), 
          findsOneWidget,
          reason: 'Recipe name "${recipe.name}" should be accessible via semantics',
        );
      }
      
      for (final recipe in testRecipes) {
        expect(
          find.byKey(Key(recipe.id)),
          findsOneWidget,
          reason: 'Each recipe item should have a key matching its ID',
        );
      }
      final firstRecipeListItem = find.byType(ListTile).first;
      expect(firstRecipeListItem, findsOneWidget, 
          reason: 'Recipe list item should be found');
      await tester.tap(firstRecipeListItem);
      await tester.pumpAndSettle();
    });
  });
}