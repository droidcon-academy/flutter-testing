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
import 'package:recipevault/presentation/views/recipe/recipe_screen.dart';
import 'package:recipevault/presentation/views/recipe/components/recipe_panel.dart';
import 'package:recipevault/presentation/widgets/navigation/bottom_nav_bar.dart';
import 'package:recipevault/presentation/widgets/navigation/nav_rail.dart';
import 'package:recipevault/presentation/widgets/common/layout/responsive_layout_builder.dart';

import '../dashboard/test_helpers.dart';

class FakeGetAllRecipesParams extends Fake implements GetAllRecipesParams {}

class FakeFavoriteRecipeParams extends Fake implements FavoriteRecipeParams {}

class FakeBookmarkRecipeParams extends Fake implements BookmarkRecipeParams {}

void main() {
  group('Recipe Screen Integration Tests', () {
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

    group('Main Screen Integration', () {
      testWidgets('recipe screen loads with proper structure and navigation',
          (tester) async {
        final widget = await createRecipeScreenTestHarness(
          mockFavoriteRecipe: mockFavoriteRecipe,
          mockBookmarkRecipe: mockBookmarkRecipe,
          mockGetAllRecipes: mockGetAllRecipes,
        );
        await tester.pumpWidget(widget);
        await tester.pumpAndSettle();

        expect(find.byType(RecipeScreen), findsOneWidget);
        expect(find.byType(ResponsiveLayoutBuilder), findsOneWidget);

        expect(find.byType(NavBar), findsOneWidget);
        expect(find.byType(IndexedStack), findsOneWidget);

        expect(find.byType(RecipePanel), findsOneWidget);

        expect(tester.takeException(), isNull);
      });

      testWidgets('navigation between recipe and dashboard pages works',
          (tester) async {
        final widget = await createRecipeScreenTestHarness(
          mockFavoriteRecipe: mockFavoriteRecipe,
          mockBookmarkRecipe: mockBookmarkRecipe,
          mockGetAllRecipes: mockGetAllRecipes,
        );
        await tester.pumpWidget(widget);
        await tester.pumpAndSettle();

        final navBar = find.byType(NavBar);
        expect(navBar, findsOneWidget);

        final NavBar navBarWidget = tester.widget(navBar);
        expect(navBarWidget.selectedIndex, 0);

        final dashboardIcon = find.byIcon(Icons.dashboard);
        expect(dashboardIcon, findsOneWidget);

        await tester.tap(dashboardIcon);
        await tester.pumpAndSettle();

        final NavBar updatedNavBarWidget = tester.widget(navBar);
        expect(updatedNavBarWidget.selectedIndex, 1);
      });

      testWidgets('page state persists during navigation', (tester) async {
        final widget = await createRecipeScreenTestHarness(
          mockFavoriteRecipe: mockFavoriteRecipe,
          mockBookmarkRecipe: mockBookmarkRecipe,
          mockGetAllRecipes: mockGetAllRecipes,
        );
        await tester.pumpWidget(widget);
        await tester.pumpAndSettle();

        final dashboardIcon = find.byIcon(Icons.dashboard);
        await tester.tap(dashboardIcon);
        await tester.pumpAndSettle();

        final recipeIcon = find.byIcon(Icons.menu_book);
        await tester.tap(recipeIcon);
        await tester.pumpAndSettle();

        expect(find.byType(RecipePanel), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    });

    group('Responsive Layout Integration', () {
      testWidgets('mobile layout shows bottom navigation', (tester) async {
        tester.view.physicalSize = const Size(400, 800);
        tester.view.devicePixelRatio = 1.0;

        final widget = await createRecipeScreenTestHarness(
          mockFavoriteRecipe: mockFavoriteRecipe,
          mockBookmarkRecipe: mockBookmarkRecipe,
          mockGetAllRecipes: mockGetAllRecipes,
        );
        await tester.pumpWidget(widget);
        await tester.pumpAndSettle();

        expect(find.byType(NavBar), findsOneWidget);
        expect(find.byType(NavRail), findsNothing);

        final scaffold = find.byType(Scaffold).first;
        final Scaffold scaffoldWidget = tester.widget(scaffold);
        expect(scaffoldWidget.bottomNavigationBar, isNotNull);

        addTearDown(tester.view.resetPhysicalSize);
      });

      testWidgets('tablet layout shows bottom navigation', (tester) async {
        tester.view.physicalSize = const Size(768, 1024);
        tester.view.devicePixelRatio = 1.0;

        final widget = await createRecipeScreenTestHarness(
          mockFavoriteRecipe: mockFavoriteRecipe,
          mockBookmarkRecipe: mockBookmarkRecipe,
          mockGetAllRecipes: mockGetAllRecipes,
        );
        await tester.pumpWidget(widget);
        await tester.pumpAndSettle();

        expect(find.byType(NavBar), findsOneWidget);
        expect(find.byType(NavRail), findsNothing);

        addTearDown(tester.view.resetPhysicalSize);
      });

      testWidgets('desktop layout shows navigation rail', (tester) async {
        tester.view.physicalSize = const Size(1200, 800);
        tester.view.devicePixelRatio = 1.0;

        final widget = await createRecipeScreenTestHarness(
          mockFavoriteRecipe: mockFavoriteRecipe,
          mockBookmarkRecipe: mockBookmarkRecipe,
          mockGetAllRecipes: mockGetAllRecipes,
        );
        await tester.pumpWidget(widget);
        await tester.pumpAndSettle();

        expect(find.byType(NavRail), findsOneWidget);
        expect(find.byType(NavBar), findsNothing);

        expect(find.byType(Row), findsWidgets);
        expect(find.byType(VerticalDivider), findsAtLeastNWidgets(1));

        addTearDown(tester.view.resetPhysicalSize);
      });

      testWidgets('layout adapts when window is resized', (tester) async {
        tester.view.physicalSize = const Size(400, 800);
        tester.view.devicePixelRatio = 1.0;

        final widget1 = await createRecipeScreenTestHarness(
          mockFavoriteRecipe: mockFavoriteRecipe,
          mockBookmarkRecipe: mockBookmarkRecipe,
          mockGetAllRecipes: mockGetAllRecipes,
        );
        await tester.pumpWidget(widget1);
        await tester.pumpAndSettle();

        expect(find.byType(NavBar), findsOneWidget);
        expect(find.byType(NavRail), findsNothing);

        tester.view.physicalSize = const Size(1200, 800);
        final widget2 = await createRecipeScreenTestHarness(
          mockFavoriteRecipe: mockFavoriteRecipe,
          mockBookmarkRecipe: mockBookmarkRecipe,
          mockGetAllRecipes: mockGetAllRecipes,
        );
        await tester.pumpWidget(widget2);
        await tester.pumpAndSettle();

        expect(find.byType(NavRail), findsOneWidget);
        expect(find.byType(NavBar), findsNothing);

        addTearDown(tester.view.resetPhysicalSize);
      });
    });

    group('State Management Integration', () {
      testWidgets('loading state shows progress indicator', (tester) async {
        const loadingState = RecipeState(isLoading: true);

        final widget = await createRecipeScreenTestHarness(
          mockFavoriteRecipe: mockFavoriteRecipe,
          mockBookmarkRecipe: mockBookmarkRecipe,
          mockGetAllRecipes: mockGetAllRecipes,
          initialRecipeState: loadingState,
        );
        await tester.pumpWidget(widget);
        await tester.pump();

        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        expect(find.byType(RecipePanel), findsNothing);
      });

      testWidgets('error state shows error message and retry functionality',
          (tester) async {
        const errorMessage = 'Failed to load recipes';
        const errorState = RecipeState(
          error: errorMessage,
          isLoading: false,
        );

        final widget = await createRecipeScreenTestHarness(
          mockFavoriteRecipe: mockFavoriteRecipe,
          mockBookmarkRecipe: mockBookmarkRecipe,
          mockGetAllRecipes: mockGetAllRecipes,
          initialRecipeState: errorState,
        );
        await tester.pumpWidget(widget);
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.error_outline), findsOneWidget);
        expect(find.text(errorMessage), findsOneWidget);
        expect(find.byType(RecipePanel), findsNothing);
      });

      testWidgets('successful state shows recipe content', (tester) async {
        final successState = RecipeState(
          recipes: testRecipes,
          isLoading: false,
          error: null,
        );

        final widget = await createRecipeScreenTestHarness(
          mockFavoriteRecipe: mockFavoriteRecipe,
          mockBookmarkRecipe: mockBookmarkRecipe,
          mockGetAllRecipes: mockGetAllRecipes,
          initialRecipeState: successState,
        );
        await tester.pumpWidget(widget);
        await tester.pumpAndSettle();

        expect(find.byType(RecipePanel), findsOneWidget);
        expect(find.byType(CircularProgressIndicator), findsNothing);
        expect(find.byIcon(Icons.error_outline), findsNothing);
      });

      testWidgets('navigation state integration works properly',
          (tester) async {
        final widget = await createRecipeScreenTestHarness(
          mockFavoriteRecipe: mockFavoriteRecipe,
          mockBookmarkRecipe: mockBookmarkRecipe,
          mockGetAllRecipes: mockGetAllRecipes,
        );
        await tester.pumpWidget(widget);
        await tester.pumpAndSettle();

        final dashboardIcon = find.byIcon(Icons.dashboard);
        expect(dashboardIcon, findsOneWidget);

        await tester.tap(dashboardIcon);
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);

        final recipeIcon = find.byIcon(Icons.menu_book);
        expect(recipeIcon, findsOneWidget);
        await tester.tap(recipeIcon);
        await tester.pumpAndSettle();

        expect(find.byType(RecipeScreen), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    });

    group('Error Handling Integration', () {
      testWidgets('gracefully handles provider errors', (tester) async {
        const errorState = RecipeState(
          error: 'Network error',
          isLoading: false,
        );

        final widget = await createRecipeScreenTestHarness(
          mockFavoriteRecipe: mockFavoriteRecipe,
          mockBookmarkRecipe: mockBookmarkRecipe,
          mockGetAllRecipes: mockGetAllRecipes,
          initialRecipeState: errorState,
        );
        await tester.pumpWidget(widget);
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.byType(RecipeScreen), findsOneWidget);
        expect(find.byIcon(Icons.error_outline), findsOneWidget);
        expect(find.text('Network error'), findsOneWidget);
      });

      testWidgets('handles navigation errors gracefully', (tester) async {
        final widget = await createRecipeScreenTestHarness(
          mockFavoriteRecipe: mockFavoriteRecipe,
          mockBookmarkRecipe: mockBookmarkRecipe,
          mockGetAllRecipes: mockGetAllRecipes,
        );
        await tester.pumpWidget(widget);
        await tester.pumpAndSettle();

        final dashboardIcon = find.byIcon(Icons.dashboard);
        final recipeIcon = find.byIcon(Icons.menu_book);

        await tester.tap(dashboardIcon);
        await tester.pump();
        await tester.tap(recipeIcon);
        await tester.pump();
        await tester.tap(dashboardIcon);
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.byType(RecipeScreen), findsOneWidget);
      });
    });
  });
}

Future<Widget> createRecipeScreenTestHarness({
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
      home: const RecipeScreen(),
      theme: ThemeData(
        useMaterial3: true,
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          type: BottomNavigationBarType.fixed,
        ),
      ),
    ),
  );
}
