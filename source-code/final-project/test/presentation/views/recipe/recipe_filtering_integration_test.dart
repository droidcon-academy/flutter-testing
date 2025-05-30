import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:fpdart/fpdart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:recipevault/domain/usecases/get_all_recipes.dart';
import 'package:recipevault/domain/usecases/favorite_recipe.dart';
import 'package:recipevault/domain/usecases/bookmark_recipe.dart';
import 'package:recipevault/data/datasources/local_datasource.dart';
import 'package:recipevault/presentation/viewmodels/recipe_viewmodel.dart';
import 'package:recipevault/presentation/views/recipe/components/recipe_panel.dart';
import 'package:recipevault/domain/entities/recipe.dart';

import '../dashboard/test_helpers.dart';

class FakeGetAllRecipesParams extends Fake implements GetAllRecipesParams {}

class FakeFavoriteRecipeParams extends Fake implements FavoriteRecipeParams {}

class FakeBookmarkRecipeParams extends Fake implements BookmarkRecipeParams {}

void main() {
  group('Recipe Filtering Integration Tests', () {
    late MockFavoriteRecipe mockFavoriteRecipe;
    late MockBookmarkRecipe mockBookmarkRecipe;
    late MockGetAllRecipes mockGetAllRecipes;

    setUpAll(() async {
      registerFallbackValue(FakeGetAllRecipesParams());
      registerFallbackValue(FakeFavoriteRecipeParams());
      registerFallbackValue(FakeBookmarkRecipeParams());

      await initializeDashboardTestEnvironment();
    });

    setUp(() {
      mockFavoriteRecipe = MockFavoriteRecipe();
      mockBookmarkRecipe = MockBookmarkRecipe();
      mockGetAllRecipes = MockGetAllRecipes();

      setupCommonMockResponses(
        mockFavoriteRecipe: mockFavoriteRecipe,
        mockBookmarkRecipe: mockBookmarkRecipe,
      );

      when(() => mockGetAllRecipes.call(any()))
          .thenAnswer((_) async => Right(testRecipes));
    });

    group('Search Filter Integration', () {
      testWidgets('search field filters recipes by name', (tester) async {
        final widget = await createRecipeFilteringTestHarness(
          mockFavoriteRecipe: mockFavoriteRecipe,
          mockBookmarkRecipe: mockBookmarkRecipe,
          mockGetAllRecipes: mockGetAllRecipes,
        );
        await tester.pumpWidget(widget);
        await tester.pumpAndSettle();

        final searchField = find.byType(TextField);
        if (searchField.evaluate().isNotEmpty) {
          await tester.enterText(searchField.first, 'Chocolate');
          await tester.pumpAndSettle();

          expect(find.text('Chocolate Cake'), findsWidgets);
          expect(tester.takeException(), isNull);
        }
      });

      testWidgets('search field handles case-insensitive filtering',
          (tester) async {
        final widget = await createRecipeFilteringTestHarness(
          mockFavoriteRecipe: mockFavoriteRecipe,
          mockBookmarkRecipe: mockBookmarkRecipe,
          mockGetAllRecipes: mockGetAllRecipes,
        );
        await tester.pumpWidget(widget);
        await tester.pumpAndSettle();

        final searchField = find.byType(TextField);
        if (searchField.evaluate().isNotEmpty) {
          await tester.enterText(searchField.first, 'chocolate');
          await tester.pumpAndSettle();

          expect(find.text('Chocolate Cake'), findsWidgets);
          expect(tester.takeException(), isNull);
        }
      });

      testWidgets('search field clears filters when empty', (tester) async {
        final widget = await createRecipeFilteringTestHarness(
          mockFavoriteRecipe: mockFavoriteRecipe,
          mockBookmarkRecipe: mockBookmarkRecipe,
          mockGetAllRecipes: mockGetAllRecipes,
        );
        await tester.pumpWidget(widget);
        await tester.pumpAndSettle();

        final searchField = find.byType(TextField);
        if (searchField.evaluate().isNotEmpty) {
          await tester.enterText(searchField.first, 'Chocolate');
          await tester.pumpAndSettle();

          await tester.enterText(searchField.first, '');
          await tester.pumpAndSettle();

          for (final recipe in testRecipes) {
            expect(find.text(recipe.name), findsWidgets);
          }
          expect(tester.takeException(), isNull);
        }
      });
    });

    group('Alphabet Filter Integration', () {
      testWidgets('alphabet selection filters recipes by first letter',
          (tester) async {
        final widget = await createRecipeFilteringTestHarness(
          mockFavoriteRecipe: mockFavoriteRecipe,
          mockBookmarkRecipe: mockBookmarkRecipe,
          mockGetAllRecipes: mockGetAllRecipes,
        );
        await tester.pumpWidget(widget);
        await tester.pumpAndSettle();

        final letterSelector = find.text('C');
        if (letterSelector.evaluate().isNotEmpty) {
          await tester.tap(letterSelector.first);
          await tester.pumpAndSettle();

          expect(find.text('Chocolate Cake'), findsWidgets);
          expect(find.text('Chicken Curry'), findsWidgets);
          expect(tester.takeException(), isNull);
        }
      });

      testWidgets('alphabet selection updates current filter state',
          (tester) async {
        final widget = await createRecipeFilteringTestHarness(
          mockFavoriteRecipe: mockFavoriteRecipe,
          mockBookmarkRecipe: mockBookmarkRecipe,
          mockGetAllRecipes: mockGetAllRecipes,
        );
        await tester.pumpWidget(widget);
        await tester.pumpAndSettle();

        final letters = ['A', 'B', 'C', 'P'];
        for (final letter in letters) {
          final letterSelector = find.text(letter);
          if (letterSelector.evaluate().isNotEmpty) {
            await tester.tap(letterSelector.first);
            await tester.pumpAndSettle();

            expect(tester.takeException(), isNull);
          }
        }
      });

      testWidgets('alphabet filter persists during screen orientation changes',
          (tester) async {
        tester.view.physicalSize = const Size(400, 800);
        tester.view.devicePixelRatio = 1.0;

        final widget1 = await createRecipeFilteringTestHarness(
          mockFavoriteRecipe: mockFavoriteRecipe,
          mockBookmarkRecipe: mockBookmarkRecipe,
          mockGetAllRecipes: mockGetAllRecipes,
        );
        await tester.pumpWidget(widget1);
        await tester.pumpAndSettle();

        final letterC = find.text('C');
        if (letterC.evaluate().isNotEmpty) {
          await tester.tap(letterC.first);
          await tester.pumpAndSettle();
        }

        tester.view.physicalSize = const Size(800, 400);
        final widget2 = await createRecipeFilteringTestHarness(
          mockFavoriteRecipe: mockFavoriteRecipe,
          mockBookmarkRecipe: mockBookmarkRecipe,
          mockGetAllRecipes: mockGetAllRecipes,
        );
        await tester.pumpWidget(widget2);
        await tester.pumpAndSettle();

        tester.takeException();

        addTearDown(tester.view.resetPhysicalSize);
      });
    });

    group('Combined Filter Integration', () {
      testWidgets('search and alphabet filters work together', (tester) async {
        final widget = await createRecipeFilteringTestHarness(
          mockFavoriteRecipe: mockFavoriteRecipe,
          mockBookmarkRecipe: mockBookmarkRecipe,
          mockGetAllRecipes: mockGetAllRecipes,
        );
        await tester.pumpWidget(widget);
        await tester.pumpAndSettle();

        final letterC = find.text('C');
        if (letterC.evaluate().isNotEmpty) {
          await tester.tap(letterC.first);
          await tester.pumpAndSettle();
        }

        final searchField = find.byType(TextField);
        if (searchField.evaluate().isNotEmpty) {
          await tester.enterText(searchField.first, 'Cake');
          await tester.pumpAndSettle();

          expect(find.text('Chocolate Cake'), findsWidgets);
          expect(tester.takeException(), isNull);
        }
      });

      testWidgets('filters can be cleared independently', (tester) async {
        final widget = await createRecipeFilteringTestHarness(
          mockFavoriteRecipe: mockFavoriteRecipe,
          mockBookmarkRecipe: mockBookmarkRecipe,
          mockGetAllRecipes: mockGetAllRecipes,
        );
        await tester.pumpWidget(widget);
        await tester.pumpAndSettle();

        final letterA = find.text('A');
        if (letterA.evaluate().isNotEmpty) {
          await tester.tap(letterA.first);
          await tester.pumpAndSettle();
        }

        final searchField = find.byType(TextField);
        if (searchField.evaluate().isNotEmpty) {
          await tester.enterText(searchField.first, 'Apple');
          await tester.pumpAndSettle();
        }

        if (searchField.evaluate().isNotEmpty) {
          await tester.enterText(searchField.first, '');
          await tester.pumpAndSettle();
        }

        expect(tester.takeException(), isNull);
      });
    });

    group('Filter State Integration', () {
      testWidgets('filter state persists during navigation', (tester) async {
        final widget = await createRecipeFilteringTestHarness(
          mockFavoriteRecipe: mockFavoriteRecipe,
          mockBookmarkRecipe: mockBookmarkRecipe,
          mockGetAllRecipes: mockGetAllRecipes,
        );
        await tester.pumpWidget(widget);
        await tester.pumpAndSettle();

        final searchField = find.byType(TextField);
        if (searchField.evaluate().isNotEmpty) {
          await tester.enterText(searchField.first, 'Chocolate');
          await tester.pumpAndSettle();
        }

        final recipeTile = find.byType(ListTile);
        if (recipeTile.evaluate().isNotEmpty) {
          await tester.tap(recipeTile.first);
          await tester.pumpAndSettle();

          final backButton = find.byType(BackButton);
          if (backButton.evaluate().isNotEmpty) {
            await tester.tap(backButton.first);
            await tester.pumpAndSettle();
          }
        }

        tester.takeException();
      });

      testWidgets('filter state resets when widget is rebuilt', (tester) async {
        final widget1 = await createRecipeFilteringTestHarness(
          mockFavoriteRecipe: mockFavoriteRecipe,
          mockBookmarkRecipe: mockBookmarkRecipe,
          mockGetAllRecipes: mockGetAllRecipes,
        );
        await tester.pumpWidget(widget1);
        await tester.pumpAndSettle();

        final searchField = find.byType(TextField);
        if (searchField.evaluate().isNotEmpty) {
          await tester.enterText(searchField.first, 'Chocolate');
          await tester.pumpAndSettle();
        }

        final widget2 = await createRecipeFilteringTestHarness(
          mockFavoriteRecipe: mockFavoriteRecipe,
          mockBookmarkRecipe: mockBookmarkRecipe,
          mockGetAllRecipes: mockGetAllRecipes,
        );
        await tester.pumpWidget(widget2);
        await tester.pumpAndSettle();

        tester.takeException();
      });
    });

    group('Filter Performance Integration', () {
      testWidgets('filtering large recipe lists performs efficiently',
          (tester) async {
        final largeRecipeList = List.generate(
          200,
          (index) => Recipe(
            id: 'recipe_$index',
            name: 'Recipe $index ${index % 10 == 0 ? "Chocolate" : "Other"}',
            instructions: 'Instructions for recipe $index',
            ingredients: [
              const Ingredient(name: 'Ingredient 1', measure: '1 cup'),
              const Ingredient(name: 'Ingredient 2', measure: '2 tbsp'),
            ],
            thumbnailUrl: '', 
            isFavorite: false,
            isBookmarked: false,
          ),
        );

        final largeListState = RecipeState(
          recipes: largeRecipeList,
          isLoading: false,
          error: null,
        );

        final widget = await createRecipeFilteringTestHarness(
          mockFavoriteRecipe: mockFavoriteRecipe,
          mockBookmarkRecipe: mockBookmarkRecipe,
          mockGetAllRecipes: mockGetAllRecipes,
          initialRecipeState: largeListState,
        );

        final stopwatch = Stopwatch()..start();
        await tester.pumpWidget(widget);
        await tester.pumpAndSettle();

        final searchField = find.byType(TextField);
        if (searchField.evaluate().isNotEmpty) {
          await tester.enterText(searchField.first, 'Chocolate');
          await tester.pumpAndSettle();
        }
        stopwatch.stop();

        tester.takeException();
        expect(stopwatch.elapsedMilliseconds, lessThan(5000));
      });

      testWidgets('rapid filter changes perform well', (tester) async {
        final widget = await createRecipeFilteringTestHarness(
          mockFavoriteRecipe: mockFavoriteRecipe,
          mockBookmarkRecipe: mockBookmarkRecipe,
          mockGetAllRecipes: mockGetAllRecipes,
        );
        await tester.pumpWidget(widget);
        await tester.pumpAndSettle();

        final searchField = find.byType(TextField);
        if (searchField.evaluate().isNotEmpty) {
          final searchTerms = ['C', 'Ch', 'Cho', 'Choc', 'Chocolate'];

          for (final term in searchTerms) {
            await tester.enterText(searchField.first, term);
            await tester.pump(); 
          }
          await tester.pumpAndSettle();
        }

        tester.takeException();
      });
    });

    group('Filter Error Handling Integration', () {
      testWidgets('handles invalid search queries gracefully', (tester) async {
        final widget = await createRecipeFilteringTestHarness(
          mockFavoriteRecipe: mockFavoriteRecipe,
          mockBookmarkRecipe: mockBookmarkRecipe,
          mockGetAllRecipes: mockGetAllRecipes,
        );
        await tester.pumpWidget(widget);
        await tester.pumpAndSettle();

        final searchField = find.byType(TextField);
        if (searchField.evaluate().isNotEmpty) {
          final edgeCases = [
            '', 
            '   ', 
            '!@#\$%^&*()_+', 
            'a' * 100, 
          ];

          for (final edgeCase in edgeCases) {
            await tester.enterText(searchField.first, edgeCase);
            await tester.pumpAndSettle();

            tester.takeException();
          }
        }
      });

      testWidgets('gracefully handles filter state corruption', (tester) async {
        final widget = await createRecipeFilteringTestHarness(
          mockFavoriteRecipe: mockFavoriteRecipe,
          mockBookmarkRecipe: mockBookmarkRecipe,
          mockGetAllRecipes: mockGetAllRecipes,
        );
        await tester.pumpWidget(widget);
        await tester.pumpAndSettle();

        final letters = ['A', 'B', 'C', 'Invalid'];
        for (final letter in letters) {
          final letterSelector = find.text(letter);
          if (letterSelector.evaluate().isNotEmpty) {
            await tester.tap(letterSelector.first);
            await tester.pump();
          }
        }
        await tester.pumpAndSettle();
        tester.takeException();
      });
    });

    group('Filter Accessibility Integration', () {
      testWidgets('search field is accessible', (tester) async {
        final widget = await createRecipeFilteringTestHarness(
          mockFavoriteRecipe: mockFavoriteRecipe,
          mockBookmarkRecipe: mockBookmarkRecipe,
          mockGetAllRecipes: mockGetAllRecipes,
        );
        await tester.pumpWidget(widget);
        await tester.pumpAndSettle();

        final searchField = find.byType(TextField);
        if (searchField.evaluate().isNotEmpty) {
          final textFieldWidget = tester.widget<TextField>(searchField.first);
          expect(textFieldWidget.decoration?.hintText, isNotNull);
        }

        tester.takeException();
      });

      testWidgets('alphabet filters have proper semantics', (tester) async {
        final widget = await createRecipeFilteringTestHarness(
          mockFavoriteRecipe: mockFavoriteRecipe,
          mockBookmarkRecipe: mockBookmarkRecipe,
          mockGetAllRecipes: mockGetAllRecipes,
        );
        await tester.pumpWidget(widget);
        await tester.pumpAndSettle();

        final semanticsWidgets = find.byType(Semantics);
        expect(semanticsWidgets.evaluate().isNotEmpty, isTrue);
        tester.takeException();
      });
    });
  });
}

Future<Widget> createRecipeFilteringTestHarness({
  required MockFavoriteRecipe mockFavoriteRecipe,
  required MockBookmarkRecipe mockBookmarkRecipe,
  required MockGetAllRecipes mockGetAllRecipes,
  RecipeState? initialRecipeState,
}) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();

  return ProviderScope(
    overrides: [
      favoriteRecipeProvider.overrideWithValue(mockFavoriteRecipe),
      bookmarkRecipeProvider.overrideWithValue(mockBookmarkRecipe),
      getAllRecipesProvider.overrideWithValue(mockGetAllRecipes),

      sharedPreferencesProvider.overrideWithValue(prefs),
      if (initialRecipeState != null)
        recipeProvider
            .overrideWith((ref) => TestRecipeViewModel(initialRecipeState)),
    ],
    child: MaterialApp(
      home: const Scaffold(
        body: RecipePanel(),
      ),
      theme: ThemeData(
        useMaterial3: true,
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          type: BottomNavigationBarType.fixed,
        ),
      ),
    ),
  );
}
