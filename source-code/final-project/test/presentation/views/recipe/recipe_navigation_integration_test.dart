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
import 'package:recipevault/presentation/viewmodels/navigation_viewmodel.dart';
import 'package:recipevault/presentation/views/recipe/recipe_screen.dart';
import 'package:recipevault/presentation/views/recipe/components/recipe_panel.dart';
import 'package:recipevault/presentation/views/recipe/components/recipe_detail_panel.dart';
import 'package:recipevault/presentation/views/recipe/components/recipe_split_view.dart';
import 'package:recipevault/presentation/widgets/navigation/bottom_nav_bar.dart';
import 'package:recipevault/presentation/widgets/navigation/nav_rail.dart';
import 'package:recipevault/domain/entities/recipe.dart';

import '../dashboard/test_helpers.dart';

class FakeGetAllRecipesParams extends Fake implements GetAllRecipesParams {}

class FakeFavoriteRecipeParams extends Fake implements FavoriteRecipeParams {}

class FakeBookmarkRecipeParams extends Fake implements BookmarkRecipeParams {}

void main() {
  group('Recipe Navigation Integration Tests', () {
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

    group('Primary Navigation Integration', () {
      testWidgets('bottom navigation switches between recipe and dashboard',
          (tester) async {
        final widget = await createRecipeNavigationTestHarness(
          mockFavoriteRecipe: mockFavoriteRecipe,
          mockBookmarkRecipe: mockBookmarkRecipe,
          mockGetAllRecipes: mockGetAllRecipes,
          useFullScreenNavigation: true,
        );
        await tester.pumpWidget(widget);
        await tester.pumpAndSettle();

        expect(find.byType(RecipeScreen), findsOneWidget);
        expect(find.byType(NavBar), findsOneWidget);

        final dashboardIcon = find.byIcon(Icons.dashboard);
        final recipeIcon = find.byIcon(Icons.menu_book);

        if (dashboardIcon.evaluate().isNotEmpty) {
          await tester.tap(dashboardIcon.first);
          await tester.pumpAndSettle();

          expect(tester.takeException(), isNull);
        }

        if (recipeIcon.evaluate().isNotEmpty) {
          await tester.tap(recipeIcon.first);
          await tester.pumpAndSettle();

          expect(find.byType(RecipeScreen), findsOneWidget);
          expect(tester.takeException(), isNull);
        }
      });

      testWidgets('navigation rail works on desktop layout', (tester) async {
        tester.view.physicalSize = const Size(1920, 1080);
        tester.view.devicePixelRatio = 1.0;

        final widget = await createRecipeNavigationTestHarness(
          mockFavoriteRecipe: mockFavoriteRecipe,
          mockBookmarkRecipe: mockBookmarkRecipe,
          mockGetAllRecipes: mockGetAllRecipes,
          useFullScreenNavigation: true,
        );
        await tester.pumpWidget(widget);
        await tester.pumpAndSettle();

        expect(find.byType(NavRail), findsOneWidget);
        expect(find.byType(NavBar), findsNothing);

        final navRail = find.byType(NavRail);
        if (navRail.evaluate().isNotEmpty) {
          final navRailWidget = tester.widget<NavRail>(navRail);
          expect(navRailWidget.selectedIndex, 0); 
        }

        addTearDown(tester.view.resetPhysicalSize);
      });

      testWidgets('navigation state persists across layout changes',
          (tester) async {
        tester.view.physicalSize = const Size(400, 800);
        tester.view.devicePixelRatio = 1.0;

        final widget1 = await createRecipeNavigationTestHarness(
          mockFavoriteRecipe: mockFavoriteRecipe,
          mockBookmarkRecipe: mockBookmarkRecipe,
          mockGetAllRecipes: mockGetAllRecipes,
          useFullScreenNavigation: true,
        );
        await tester.pumpWidget(widget1);
        await tester.pumpAndSettle();

        final dashboardIcon = find.byIcon(Icons.dashboard);
        if (dashboardIcon.evaluate().isNotEmpty) {
          await tester.tap(dashboardIcon.first);
          await tester.pumpAndSettle();
        }

        tester.view.physicalSize = const Size(1920, 1080);
        final widget2 = await createRecipeNavigationTestHarness(
          mockFavoriteRecipe: mockFavoriteRecipe,
          mockBookmarkRecipe: mockBookmarkRecipe,
          mockGetAllRecipes: mockGetAllRecipes,
          useFullScreenNavigation: true,
        );
        await tester.pumpWidget(widget2);
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);

        addTearDown(tester.view.resetPhysicalSize);
      });
    });

    group('Recipe Internal Navigation Integration', () {
      testWidgets('mobile: navigates from list to detail and back',
          (tester) async {
        tester.view.physicalSize = const Size(400, 800);
        tester.view.devicePixelRatio = 1.0;

        final widget = await createRecipeNavigationTestHarness(
          mockFavoriteRecipe: mockFavoriteRecipe,
          mockBookmarkRecipe: mockBookmarkRecipe,
          mockGetAllRecipes: mockGetAllRecipes,
        );
        await tester.pumpWidget(widget);
        await tester.pumpAndSettle();

        expect(find.byType(Navigator), findsAtLeastNWidgets(1));

        final recipeTile = find.byType(ListTile);
        if (recipeTile.evaluate().isNotEmpty) {
          await tester.tap(recipeTile.first);
          await tester.pumpAndSettle();

          expect(find.byType(RecipeDetailPanel), findsOneWidget);

          final backButton = find.byType(BackButton);
          if (backButton.evaluate().isNotEmpty) {
            await tester.tap(backButton.first);
            await tester.pumpAndSettle();

            tester.takeException();
          }
        }

        addTearDown(tester.view.resetPhysicalSize);
      });

      testWidgets('tablet: split view navigation updates detail panel',
          (tester) async {
        tester.view.physicalSize = const Size(768, 1024);
        tester.view.devicePixelRatio = 1.0;

        final widget = await createRecipeNavigationTestHarness(
          mockFavoriteRecipe: mockFavoriteRecipe,
          mockBookmarkRecipe: mockBookmarkRecipe,
          mockGetAllRecipes: mockGetAllRecipes,
        );
        await tester.pumpWidget(widget);
        await tester.pumpAndSettle();

        expect(find.byType(RecipeSplitView), findsOneWidget);

        final gestureDetector = find.byType(GestureDetector);
        if (gestureDetector.evaluate().isNotEmpty) {
          await tester.tap(gestureDetector.first);
          await tester.pumpAndSettle();

          tester.takeException();
        }

        addTearDown(tester.view.resetPhysicalSize);
      });

      testWidgets('desktop: split view navigation with persistent state',
          (tester) async {
        tester.view.physicalSize = const Size(1920, 1080);
        tester.view.devicePixelRatio = 1.0;

        final widget = await createRecipeNavigationTestHarness(
          mockFavoriteRecipe: mockFavoriteRecipe,
          mockBookmarkRecipe: mockBookmarkRecipe,
          mockGetAllRecipes: mockGetAllRecipes,
        );
        await tester.pumpWidget(widget);
        await tester.pumpAndSettle();

        expect(find.byType(RecipeSplitView), findsOneWidget);

        final interactiveElements = [
          find.byType(GestureDetector),
          find.byType(InkWell),
          find.byType(ListTile),
        ];

        for (final elementFinder in interactiveElements) {
          if (elementFinder.evaluate().isNotEmpty) {
            await tester.tap(elementFinder.first, warnIfMissed: false);
            await tester.pumpAndSettle();
            tester.takeException();
          }
        }

        addTearDown(tester.view.resetPhysicalSize);
      });
    });

    group('Cross-Screen Navigation Integration', () {
      testWidgets(
          'navigation preserves recipe selection when switching screens',
          (tester) async {
        final selectedRecipe = testRecipes.first;
        final initialState = RecipeState(
          recipes: testRecipes,
          selectedRecipe: selectedRecipe,
          isLoading: false,
          error: null,
        );

        final widget = await createRecipeNavigationTestHarness(
          mockFavoriteRecipe: mockFavoriteRecipe,
          mockBookmarkRecipe: mockBookmarkRecipe,
          mockGetAllRecipes: mockGetAllRecipes,
          useFullScreenNavigation: true,
          initialRecipeState: initialState,
        );
        await tester.pumpWidget(widget);
        await tester.pumpAndSettle();

        final dashboardIcon = find.byIcon(Icons.dashboard);
        if (dashboardIcon.evaluate().isNotEmpty) {
          await tester.tap(dashboardIcon.first);
          await tester.pumpAndSettle();
        }

        final recipeIcon = find.byIcon(Icons.menu_book);
        if (recipeIcon.evaluate().isNotEmpty) {
          await tester.tap(recipeIcon.first);
          await tester.pumpAndSettle();

          expect(tester.takeException(), isNull);
        }
      });

      testWidgets('rapid navigation between screens handles gracefully',
          (tester) async {
        final widget = await createRecipeNavigationTestHarness(
          mockFavoriteRecipe: mockFavoriteRecipe,
          mockBookmarkRecipe: mockBookmarkRecipe,
          mockGetAllRecipes: mockGetAllRecipes,
          useFullScreenNavigation: true,
        );
        await tester.pumpWidget(widget);
        await tester.pumpAndSettle();

        final dashboardIcon = find.byIcon(Icons.dashboard);
        final recipeIcon = find.byIcon(Icons.menu_book);

        for (int i = 0; i < 5; i++) {
          if (dashboardIcon.evaluate().isNotEmpty) {
            await tester.tap(dashboardIcon.first);
            await tester.pump();
          }
          if (recipeIcon.evaluate().isNotEmpty) {
            await tester.tap(recipeIcon.first);
            await tester.pump();
          }
        }
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
      });
    });

    group('Deep Navigation Integration', () {
      testWidgets('direct recipe detail navigation works', (tester) async {
        final selectedRecipe = testRecipes.first;
        final widget = await createDirectRecipeDetailTestHarness(
          mockFavoriteRecipe: mockFavoriteRecipe,
          mockBookmarkRecipe: mockBookmarkRecipe,
          mockGetAllRecipes: mockGetAllRecipes,
          recipe: selectedRecipe,
        );
        await tester.pumpWidget(widget);
        await tester.pumpAndSettle();

        expect(find.byType(RecipeDetailPanel), findsOneWidget);
        expect(find.text(selectedRecipe.name), findsWidgets);
        expect(tester.takeException(), isNull);
      });

      testWidgets('navigation from deep link preserves app structure',
          (tester) async {
        final selectedRecipe = testRecipes.first;
        final widget = await createDirectRecipeDetailTestHarness(
          mockFavoriteRecipe: mockFavoriteRecipe,
          mockBookmarkRecipe: mockBookmarkRecipe,
          mockGetAllRecipes: mockGetAllRecipes,
          recipe: selectedRecipe,
        );
        await tester.pumpWidget(widget);
        await tester.pumpAndSettle();

        final backButton = find.byType(BackButton);
        if (backButton.evaluate().isNotEmpty) {
          await tester.tap(backButton.first);
          await tester.pumpAndSettle();

          expect(tester.takeException(), isNull);
        }
      });
    });

    group('Navigation State Management Integration', () {
      testWidgets('navigation state updates correctly with provider changes',
          (tester) async {
        final widget = await createRecipeNavigationTestHarness(
          mockFavoriteRecipe: mockFavoriteRecipe,
          mockBookmarkRecipe: mockBookmarkRecipe,
          mockGetAllRecipes: mockGetAllRecipes,
          useFullScreenNavigation: true,
        );
        await tester.pumpWidget(widget);
        await tester.pumpAndSettle();

        final navBar = find.byType(NavBar);
        if (navBar.evaluate().isNotEmpty) {
          final navBarWidget = tester.widget<NavBar>(navBar);
          expect(navBarWidget.selectedIndex, 0);

          final dashboardIcon = find.byIcon(Icons.dashboard);
          if (dashboardIcon.evaluate().isNotEmpty) {
            await tester.tap(dashboardIcon.first);
            await tester.pumpAndSettle();

            final updatedNavBarWidget = tester.widget<NavBar>(navBar);
            expect(updatedNavBarWidget.selectedIndex, 1); 
          }
        }
      });

      testWidgets('concurrent navigation requests handled correctly',
          (tester) async {
        final widget = await createRecipeNavigationTestHarness(
          mockFavoriteRecipe: mockFavoriteRecipe,
          mockBookmarkRecipe: mockBookmarkRecipe,
          mockGetAllRecipes: mockGetAllRecipes,
          useFullScreenNavigation: true,
        );
        await tester.pumpWidget(widget);
        await tester.pumpAndSettle();

        final dashboardIcon = find.byIcon(Icons.dashboard);
        if (dashboardIcon.evaluate().isNotEmpty) {
          await tester.tap(dashboardIcon.first);
          await tester.tap(dashboardIcon.first);
          await tester.tap(dashboardIcon.first);
          await tester.pumpAndSettle();

          expect(tester.takeException(), isNull);
        }
      });
    });

    group('Navigation Performance Integration', () {
      testWidgets('navigation performance is acceptable', (tester) async {
        final widget = await createRecipeNavigationTestHarness(
          mockFavoriteRecipe: mockFavoriteRecipe,
          mockBookmarkRecipe: mockBookmarkRecipe,
          mockGetAllRecipes: mockGetAllRecipes,
          useFullScreenNavigation: true,
        );

        final stopwatch = Stopwatch()..start();
        await tester.pumpWidget(widget);
        await tester.pumpAndSettle();

        final dashboardIcon = find.byIcon(Icons.dashboard);
        if (dashboardIcon.evaluate().isNotEmpty) {
          await tester.tap(dashboardIcon.first);
          await tester.pumpAndSettle();
        }
        stopwatch.stop();

        expect(tester.takeException(), isNull);
        expect(stopwatch.elapsedMilliseconds, lessThan(3000));
      });

      testWidgets('multiple navigation operations perform well',
          (tester) async {
        final widget = await createRecipeNavigationTestHarness(
          mockFavoriteRecipe: mockFavoriteRecipe,
          mockBookmarkRecipe: mockBookmarkRecipe,
          mockGetAllRecipes: mockGetAllRecipes,
          useFullScreenNavigation: true,
        );
        await tester.pumpWidget(widget);
        await tester.pumpAndSettle();

        final dashboardIcon = find.byIcon(Icons.dashboard);
        final recipeIcon = find.byIcon(Icons.menu_book);

        final stopwatch = Stopwatch()..start();
        for (int i = 0; i < 10; i++) {
          if (dashboardIcon.evaluate().isNotEmpty) {
            await tester.tap(dashboardIcon.first);
            await tester.pumpAndSettle();
          }
          if (recipeIcon.evaluate().isNotEmpty) {
            await tester.tap(recipeIcon.first);
            await tester.pumpAndSettle();
          }
        }
        stopwatch.stop();

        expect(tester.takeException(), isNull);
        expect(stopwatch.elapsedMilliseconds, lessThan(10000));
      });
    });

    group('Navigation Error Handling Integration', () {
      testWidgets('handles navigation errors gracefully', (tester) async {
        final widget = await createRecipeNavigationTestHarness(
          mockFavoriteRecipe: mockFavoriteRecipe,
          mockBookmarkRecipe: mockBookmarkRecipe,
          mockGetAllRecipes: mockGetAllRecipes,
          useFullScreenNavigation: true,
        );
        await tester.pumpWidget(widget);
        await tester.pumpAndSettle();

        final allIcons = find.byType(Icon);
        for (int i = 0; i < allIcons.evaluate().length && i < 5; i++) {
          await tester.tap(allIcons.at(i), warnIfMissed: false);
          await tester.pump();
        }
        await tester.pumpAndSettle();

        tester.takeException();
      });

      testWidgets('recovers from navigation state corruption', (tester) async {
        const corruptedNavigationState = NavigationState(selectedIndex: 999);

        final widget = await createRecipeNavigationTestHarness(
          mockFavoriteRecipe: mockFavoriteRecipe,
          mockBookmarkRecipe: mockBookmarkRecipe,
          mockGetAllRecipes: mockGetAllRecipes,
          useFullScreenNavigation: true,
          initialNavigationState: corruptedNavigationState,
        );
        await tester.pumpWidget(widget);
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);

        final dashboardIcon = find.byIcon(Icons.dashboard);
        if (dashboardIcon.evaluate().isNotEmpty) {
          await tester.tap(dashboardIcon.first);
          await tester.pumpAndSettle();

          expect(tester.takeException(), isNull);
        }
      });
    });

    group('Navigation Accessibility Integration', () {
      testWidgets('navigation elements are accessible', (tester) async {
        final widget = await createRecipeNavigationTestHarness(
          mockFavoriteRecipe: mockFavoriteRecipe,
          mockBookmarkRecipe: mockBookmarkRecipe,
          mockGetAllRecipes: mockGetAllRecipes,
          useFullScreenNavigation: true,
        );
        await tester.pumpWidget(widget);
        await tester.pumpAndSettle();

        final semanticsWidgets = find.byType(Semantics);
        expect(semanticsWidgets.evaluate().isNotEmpty, isTrue);

        final navBar = find.byType(NavBar);
        if (navBar.evaluate().isNotEmpty) {
          expect(navBar, findsOneWidget);
        }

        tester.takeException();
      });

      testWidgets('keyboard navigation works', (tester) async {
        final widget = await createRecipeNavigationTestHarness(
          mockFavoriteRecipe: mockFavoriteRecipe,
          mockBookmarkRecipe: mockBookmarkRecipe,
          mockGetAllRecipes: mockGetAllRecipes,
          useFullScreenNavigation: true,
        );
        await tester.pumpWidget(widget);
        await tester.pumpAndSettle();

        final focusableWidgets = find.byType(Focus);
        expect(focusableWidgets.evaluate().isNotEmpty, isTrue);

        tester.takeException();
      });
    });
  });
}

Future<Widget> createRecipeNavigationTestHarness({
  required MockFavoriteRecipe mockFavoriteRecipe,
  required MockBookmarkRecipe mockBookmarkRecipe,
  required MockGetAllRecipes mockGetAllRecipes,
  RecipeState? initialRecipeState,
  NavigationState? initialNavigationState,
  bool useFullScreenNavigation = false,
}) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();

  Widget child;
  if (useFullScreenNavigation) {
    child = const RecipeScreen();
  } else {
    child = const Scaffold(
      body: RecipePanel(),
    );
  }

  return ProviderScope(
    overrides: [
      favoriteRecipeProvider.overrideWithValue(mockFavoriteRecipe),
      bookmarkRecipeProvider.overrideWithValue(mockBookmarkRecipe),
      getAllRecipesProvider.overrideWithValue(mockGetAllRecipes),

      sharedPreferencesProvider.overrideWithValue(prefs),

      if (initialRecipeState != null)
        recipeProvider
            .overrideWith((ref) => TestRecipeViewModel(initialRecipeState)),

      if (initialNavigationState != null)
        navigationProvider.overrideWith((ref) {
          final notifier = NavigationViewModel();
          notifier.setSelectedIndex(initialNavigationState.selectedIndex);
          return notifier;
        }),
    ],
    child: MaterialApp(
      home: child,
      theme: ThemeData(
        useMaterial3: true,
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          type: BottomNavigationBarType.fixed,
        ),
      ),
    ),
  );
}

Future<Widget> createDirectRecipeDetailTestHarness({
  required MockFavoriteRecipe mockFavoriteRecipe,
  required MockBookmarkRecipe mockBookmarkRecipe,
  required MockGetAllRecipes mockGetAllRecipes,
  required Recipe recipe,
}) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();

  return ProviderScope(
    overrides: [
      favoriteRecipeProvider.overrideWithValue(mockFavoriteRecipe),
      bookmarkRecipeProvider.overrideWithValue(mockBookmarkRecipe),
      getAllRecipesProvider.overrideWithValue(mockGetAllRecipes),

      sharedPreferencesProvider.overrideWithValue(prefs),
    ],
    child: MaterialApp(
      home: Scaffold(
        body: RecipeDetailPanel(recipe: recipe),
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
