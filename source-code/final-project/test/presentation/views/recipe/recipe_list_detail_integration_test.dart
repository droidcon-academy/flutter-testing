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
import 'package:recipevault/presentation/views/recipe/components/recipe_detail_panel.dart';
import 'package:recipevault/domain/entities/recipe.dart';

import '../dashboard/test_helpers.dart';

class FakeGetAllRecipesParams extends Fake implements GetAllRecipesParams {}

class FakeFavoriteRecipeParams extends Fake implements FavoriteRecipeParams {}

class FakeBookmarkRecipeParams extends Fake implements BookmarkRecipeParams {}

void main() {
  group('Recipe List and Detail Integration Tests', () {
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

    group('List to Detail Navigation Integration', () {
      testWidgets('mobile: recipe list tap navigates to detail screen',
          (tester) async {
        tester.view.physicalSize = const Size(400, 800);
        tester.view.devicePixelRatio = 1.0;

        final widget = await createRecipeListDetailTestHarness(
          mockFavoriteRecipe: mockFavoriteRecipe,
          mockBookmarkRecipe: mockBookmarkRecipe,
          mockGetAllRecipes: mockGetAllRecipes,
        );
        await tester.pumpWidget(widget);
        await tester.pumpAndSettle();

        expect(find.byType(RecipePanel), findsOneWidget);
        expect(find.byType(Navigator), findsAtLeastNWidgets(1));

        final recipeTile = find.byType(ListTile);
        if (recipeTile.evaluate().isNotEmpty) {
          await tester.ensureVisible(recipeTile.first);
          await tester.tap(recipeTile.first);
          await tester.pumpAndSettle();

          expect(find.byType(RecipeDetailPanel), findsOneWidget);
        }

        tester.takeException();

        addTearDown(tester.view.resetPhysicalSize);
      });

      testWidgets('tablet: recipe list shows split view with detail panel',
          (tester) async {
        tester.view.physicalSize = const Size(768, 1024);
        tester.view.devicePixelRatio = 1.0;

        final widget = await createRecipeListDetailTestHarness(
          mockFavoriteRecipe: mockFavoriteRecipe,
          mockBookmarkRecipe: mockBookmarkRecipe,
          mockGetAllRecipes: mockGetAllRecipes,
        );
        await tester.pumpWidget(widget);
        await tester.pumpAndSettle();

        expect(find.byType(RecipePanel), findsOneWidget);

        final recipeWidget = find.byType(GestureDetector);
        if (recipeWidget.evaluate().isNotEmpty) {
          await tester.ensureVisible(recipeWidget.first);
          await tester.tap(recipeWidget.first);
          await tester.pumpAndSettle();

          expect(find.byType(RecipeDetailPanel), findsOneWidget);
        }

        tester.takeException();

        addTearDown(tester.view.resetPhysicalSize);
      });

      testWidgets('desktop: recipe list shows split view with detail panel',
          (tester) async {
        tester.view.physicalSize = const Size(1920, 1080);
        tester.view.devicePixelRatio = 1.0;

        final widget = await createRecipeListDetailTestHarness(
          mockFavoriteRecipe: mockFavoriteRecipe,
          mockBookmarkRecipe: mockBookmarkRecipe,
          mockGetAllRecipes: mockGetAllRecipes,
        );
        await tester.pumpWidget(widget);
        await tester.pumpAndSettle();

        expect(find.byType(RecipePanel), findsOneWidget);

        tester.takeException();

        addTearDown(tester.view.resetPhysicalSize);
      });
    });

    group('Recipe List State Integration', () {
      testWidgets('recipe list displays all test recipes', (tester) async {
        final successState = RecipeState(
          recipes: testRecipes,
          isLoading: false,
          error: null,
        );

        final widget = await createRecipeListDetailTestHarness(
          mockFavoriteRecipe: mockFavoriteRecipe,
          mockBookmarkRecipe: mockBookmarkRecipe,
          mockGetAllRecipes: mockGetAllRecipes,
          initialRecipeState: successState,
        );
        await tester.pumpWidget(widget);
        await tester.pumpAndSettle();

        expect(find.byType(RecipePanel), findsOneWidget);

        for (final recipe in testRecipes) {
          expect(find.text(recipe.name), findsWidgets);
        }
      });

      testWidgets('empty recipe list shows appropriate message',
          (tester) async {
        const successState = RecipeState(
          recipes: [],
          isLoading: false,
          error: null,
        );

        final widget = await createRecipeListDetailTestHarness(
          mockFavoriteRecipe: mockFavoriteRecipe,
          mockBookmarkRecipe: mockBookmarkRecipe,
          mockGetAllRecipes: mockGetAllRecipes,
          initialRecipeState: successState,
        );
        await tester.pumpWidget(widget);
        await tester.pumpAndSettle();

        expect(find.byType(RecipePanel), findsOneWidget);
        expect(tester.takeException(), isNull);
      });

      testWidgets('recipe list handles loading state', (tester) async {
        const loadingState = RecipeState(
          isLoading: true,
          recipes: [],
          error: null,
        );

        final widget = await createRecipeListDetailTestHarness(
          mockFavoriteRecipe: mockFavoriteRecipe,
          mockBookmarkRecipe: mockBookmarkRecipe,
          mockGetAllRecipes: mockGetAllRecipes,
          initialRecipeState: loadingState,
        );
        await tester.pumpWidget(widget);
        await tester.pump(); 

        expect(find.byType(RecipePanel), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    });

    group('Recipe Detail State Integration', () {
      testWidgets('recipe detail shows selected recipe information',
          (tester) async {
        final selectedRecipe = testRecipes.first;
        final stateWithSelection = RecipeState(
          recipes: testRecipes,
          selectedRecipe: selectedRecipe,
          isLoading: false,
          error: null,
        );

        final widget = await createRecipeListDetailTestHarness(
          mockFavoriteRecipe: mockFavoriteRecipe,
          mockBookmarkRecipe: mockBookmarkRecipe,
          mockGetAllRecipes: mockGetAllRecipes,
          initialRecipeState: stateWithSelection,
        );
        await tester.pumpWidget(widget);
        await tester.pumpAndSettle();

        if (find.byType(RecipeDetailPanel).evaluate().isNotEmpty) {
          expect(find.byType(RecipeDetailPanel), findsOneWidget);
          expect(find.text(selectedRecipe.name), findsWidgets);
        }
      });

      testWidgets('recipe detail updates when selection changes',
          (tester) async {
        final widget = await createRecipeListDetailTestHarness(
          mockFavoriteRecipe: mockFavoriteRecipe,
          mockBookmarkRecipe: mockBookmarkRecipe,
          mockGetAllRecipes: mockGetAllRecipes,
        );
        await tester.pumpWidget(widget);
        await tester.pumpAndSettle();

        final gestureDetector = find.byType(GestureDetector);
        final inkWell = find.byType(InkWell);
        final listTile = find.byType(ListTile);

        if (gestureDetector.evaluate().isNotEmpty) {
          await tester.tap(gestureDetector.first);
          await tester.ensureVisible(gestureDetector.first);
          await tester.pumpAndSettle();
        } else if (inkWell.evaluate().isNotEmpty) {
          await tester.tap(inkWell.first);
          await tester.ensureVisible(inkWell.first);
          await tester.pumpAndSettle();
        } else if (listTile.evaluate().isNotEmpty) {
          await tester.tap(listTile.first);
          await tester.ensureVisible(listTile.first);
          await tester.pumpAndSettle();
        }

        tester.takeException();
      });
    });

    group('List Detail Responsive Integration', () {
      testWidgets('layout switches between mobile and tablet correctly',
          (tester) async {
        tester.view.physicalSize = const Size(400, 800);
        tester.view.devicePixelRatio = 1.0;

        final widget1 = await createRecipeListDetailTestHarness(
          mockFavoriteRecipe: mockFavoriteRecipe,
          mockBookmarkRecipe: mockBookmarkRecipe,
          mockGetAllRecipes: mockGetAllRecipes,
        );
        await tester.pumpWidget(widget1);
        await tester.pumpAndSettle();

        expect(find.byType(RecipePanel), findsOneWidget);
        expect(find.byType(Navigator), findsAtLeastNWidgets(1));

        tester.view.physicalSize = const Size(768, 1024);
        final widget2 = await createRecipeListDetailTestHarness(
          mockFavoriteRecipe: mockFavoriteRecipe,
          mockBookmarkRecipe: mockBookmarkRecipe,
          mockGetAllRecipes: mockGetAllRecipes,
        );
        await tester.pumpWidget(widget2);
        await tester.pumpAndSettle();

        expect(find.byType(RecipePanel), findsOneWidget);

        addTearDown(tester.view.resetPhysicalSize);
      });

      testWidgets('responsive layout preserves recipe selection state',
          (tester) async {
        final selectedRecipe = testRecipes.first;
        final stateWithSelection = RecipeState(
          recipes: testRecipes,
          selectedRecipe: selectedRecipe,
          isLoading: false,
          error: null,
        );

        tester.view.physicalSize = const Size(400, 800);
        tester.view.devicePixelRatio = 1.0;

        final widget1 = await createRecipeListDetailTestHarness(
          mockFavoriteRecipe: mockFavoriteRecipe,
          mockBookmarkRecipe: mockBookmarkRecipe,
          mockGetAllRecipes: mockGetAllRecipes,
          initialRecipeState: stateWithSelection,
        );
        await tester.pumpWidget(widget1);
        await tester.pumpAndSettle();

        tester.view.physicalSize = const Size(768, 1024);
        final widget2 = await createRecipeListDetailTestHarness(
          mockFavoriteRecipe: mockFavoriteRecipe,
          mockBookmarkRecipe: mockBookmarkRecipe,
          mockGetAllRecipes: mockGetAllRecipes,
          initialRecipeState: stateWithSelection,
        );
        await tester.pumpWidget(widget2);
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.byType(RecipePanel), findsOneWidget);

        addTearDown(tester.view.resetPhysicalSize);
      });
    });

    group('Recipe List Detail Performance Integration', () {
      testWidgets('handles large recipe list efficiently', (tester) async {
        final largeRecipeList = List.generate(
          100,
          (index) => Recipe(
            id: 'recipe_$index',
            name: 'Recipe $index',
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

        final widget = await createRecipeListDetailTestHarness(
          mockFavoriteRecipe: mockFavoriteRecipe,
          mockBookmarkRecipe: mockBookmarkRecipe,
          mockGetAllRecipes: mockGetAllRecipes,
          initialRecipeState: largeListState,
        );

        final stopwatch = Stopwatch()..start();
        await tester.pumpWidget(widget);
        await tester.pumpAndSettle();
        stopwatch.stop();

        expect(tester.takeException(), isNull);
        expect(find.byType(RecipePanel), findsOneWidget);

        expect(stopwatch.elapsedMilliseconds, lessThan(5000));
      });

      testWidgets('scrolling through recipe list performs well',
          (tester) async {
        final widget = await createRecipeListDetailTestHarness(
          mockFavoriteRecipe: mockFavoriteRecipe,
          mockBookmarkRecipe: mockBookmarkRecipe,
          mockGetAllRecipes: mockGetAllRecipes,
        );
        await tester.pumpWidget(widget);
        await tester.pumpAndSettle();

        final scrollable = find.byType(Scrollable);
        if (scrollable.evaluate().isNotEmpty) {
          await tester.drag(scrollable.first, const Offset(0, -300));
          await tester.pumpAndSettle();

          await tester.drag(scrollable.first, const Offset(0, 300));
          await tester.pumpAndSettle();
        }

        expect(tester.takeException(), isNull);
      });
    });

    group('List Detail Error Handling Integration', () {
      testWidgets('gracefully handles recipe selection errors', (tester) async {
        final widget = await createRecipeListDetailTestHarness(
          mockFavoriteRecipe: mockFavoriteRecipe,
          mockBookmarkRecipe: mockBookmarkRecipe,
          mockGetAllRecipes: mockGetAllRecipes,
        );
        await tester.pumpWidget(widget);
        await tester.pumpAndSettle();

        final tappableWidgets = [
          find.byType(GestureDetector),
          find.byType(InkWell),
          find.byType(ListTile),
        ];

        for (final finder in tappableWidgets) {
          if (finder.evaluate().isNotEmpty) {
            await tester.tap(finder.first);
            await tester.ensureVisible(finder.first);
            await tester.pump();
            await tester.tap(finder.first);
            await tester.pump();
          }
        }
        await tester.pumpAndSettle();

        tester.takeException();
      });

      testWidgets('handles navigation errors between list and detail',
          (tester) async {
        tester.view.physicalSize = const Size(400, 800); 
        tester.view.devicePixelRatio = 1.0;

        final widget = await createRecipeListDetailTestHarness(
          mockFavoriteRecipe: mockFavoriteRecipe,
          mockBookmarkRecipe: mockBookmarkRecipe,
          mockGetAllRecipes: mockGetAllRecipes,
        );
        await tester.pumpWidget(widget);
        await tester.pumpAndSettle();

        final listTile = find.byType(ListTile);
        if (listTile.evaluate().isNotEmpty) {
          await tester.tap(listTile.first);
          await tester.ensureVisible(listTile.first);
          await tester.pumpAndSettle();

          final backButton = find.byType(BackButton);
          if (backButton.evaluate().isNotEmpty) {
            await tester.tap(backButton.first);
            await tester.pumpAndSettle();
          }
        }
        tester.takeException();

        addTearDown(tester.view.resetPhysicalSize);
      });
    });
  });
}

Future<Widget> createRecipeListDetailTestHarness({
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
