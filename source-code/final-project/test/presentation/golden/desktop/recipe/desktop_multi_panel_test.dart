import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:fpdart/fpdart.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:recipevault/core/themes/app_theme.dart';
import 'package:recipevault/domain/entities/recipe.dart';
import 'package:recipevault/domain/usecases/get_all_recipes.dart';
import 'package:recipevault/domain/usecases/favorite_recipe.dart';
import 'package:recipevault/domain/usecases/bookmark_recipe.dart';
import 'package:recipevault/presentation/viewmodels/recipe_viewmodel.dart';
import 'package:recipevault/presentation/viewmodels/dashboard_viewmodel.dart';
import 'package:recipevault/presentation/viewmodels/navigation_viewmodel.dart';
import 'package:recipevault/presentation/views/recipe/components/recipe_split_view.dart';
import 'package:recipevault/presentation/views/dashboard/components/dashboard_split_view.dart';
import 'package:recipevault/presentation/views/recipe/recipe_screen.dart';
import 'package:recipevault/presentation/views/dashboard/dashboard_screen.dart';
import 'package:recipevault/presentation/widgets/common/layout/responsive_layout_builder.dart';
import 'package:recipevault/data/datasources/local_datasource.dart';

const _mockRecipes = [
  Recipe(
    id: '1',
    name: 'Spaghetti Carbonara',
    ingredients: [
      Ingredient(name: 'spaghetti', measure: '400g'),
      Ingredient(name: 'eggs', measure: '3 large'),
    ],
    instructions: 'Cook pasta, mix with eggs and cheese.',
  ),
  Recipe(
    id: '2',
    name: 'Chicken Tikka Masala',
    ingredients: [
      Ingredient(name: 'chicken breast', measure: '500g'),
      Ingredient(name: 'tomatoes', measure: '400g'),
    ],
    instructions: 'Marinate chicken, cook with tomatoes.',
  ),
  Recipe(
    id: '3',
    name: 'Chocolate Cake',
    ingredients: [
      Ingredient(name: 'flour', measure: '2 cups'),
      Ingredient(name: 'chocolate', measure: '4 oz'),
    ],
    instructions: 'Mix and bake at 350°F for 30 minutes.',
  ),
];

final _mockFavoriteRecipes = [_mockRecipes[0], _mockRecipes[2]];
final _mockBookmarkRecipes = [_mockRecipes[1]];

class MockGetAllRecipes extends Mock implements GetAllRecipes {}

class MockFavoriteRecipe extends Mock implements FavoriteRecipe {}

class MockBookmarkRecipe extends Mock implements BookmarkRecipe {}

class FakeGetAllRecipesParams extends Fake implements GetAllRecipesParams {}

class FakeFavoriteRecipeParams extends Fake implements FavoriteRecipeParams {}

class FakeBookmarkRecipeParams extends Fake implements BookmarkRecipeParams {}

class TestRecipeViewModel extends RecipeViewModel {
  final RecipeState _fixedState;

  TestRecipeViewModel(
    this._fixedState,
    GetAllRecipes getAllRecipes,
    FavoriteRecipe favoriteRecipe,
    BookmarkRecipe bookmarkRecipe,
  ) : super(getAllRecipes, favoriteRecipe, bookmarkRecipe);

  @override
  RecipeState get state => _fixedState;

  @override
  Future<void> loadRecipes() async {}

  @override
  void setSelectedLetter(String? letter) {}
}

class TestDashboardViewModel extends DashboardViewModel {
  final DashboardState _fixedState;

  TestDashboardViewModel(
    this._fixedState,
    FavoriteRecipe favoriteRecipe,
    BookmarkRecipe bookmarkRecipe,
    RecipeState recipeState,
    Ref ref,
  ) : super(favoriteRecipe, bookmarkRecipe, recipeState, ref);

  @override
  DashboardState get state => _fixedState;

  @override
  Future<void> initializeData() async {}
}

void main() {
  group('Desktop Multi-Panel Golden Tests', () {
    late MockGetAllRecipes mockGetAllRecipes;
    late MockFavoriteRecipe mockFavoriteRecipe;
    late MockBookmarkRecipe mockBookmarkRecipe;

    setUpAll(() async {
      await loadAppFonts();

      registerFallbackValue(FakeGetAllRecipesParams());
      registerFallbackValue(FakeFavoriteRecipeParams());
      registerFallbackValue(FakeBookmarkRecipeParams());
    });

    setUp(() async {
      mockGetAllRecipes = MockGetAllRecipes();
      mockFavoriteRecipe = MockFavoriteRecipe();
      mockBookmarkRecipe = MockBookmarkRecipe();

      when(() => mockGetAllRecipes(any()))
          .thenAnswer((_) async => const Right(_mockRecipes));
      when(() => mockFavoriteRecipe.getFavorites())
          .thenAnswer((_) async => Right(_mockFavoriteRecipes));
      when(() => mockBookmarkRecipe.getBookmarks())
          .thenAnswer((_) async => Right(_mockBookmarkRecipes));
    });

    Future<Widget> createMultiPanelTestHarness({
      required Widget screen,
      RecipeState? initialRecipeState,
      DashboardState? initialDashboardState,
      ThemeData? theme,
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
            recipeProvider.overrideWith((ref) => TestRecipeViewModel(
                initialRecipeState,
                mockGetAllRecipes,
                mockFavoriteRecipe,
                mockBookmarkRecipe)),

          if (initialDashboardState != null)
            dashboardProvider.overrideWith((ref) => TestDashboardViewModel(
                initialDashboardState,
                mockFavoriteRecipe,
                mockBookmarkRecipe,
                initialRecipeState ?? const RecipeState(),
                ref)),
        ],
        child: MaterialApp(
          home: screen,
          theme: theme ?? AppTheme.lightTheme,
        ),
      );
    }

    Future<void> pumpDesktopMultiPanel(
      WidgetTester tester, {
      required Widget screen,
      required Size screenSize,
      RecipeState? recipeState,
      DashboardState? dashboardState,
      ThemeData? theme,
    }) async {
      tester.view.physicalSize = screenSize;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final widget = await createMultiPanelTestHarness(
        screen: screen,
        initialRecipeState: recipeState,
        initialDashboardState: dashboardState,
        theme: theme,
      );
      await tester.pumpWidget(widget);
      await tester.pumpAndSettle(const Duration(milliseconds: 500));
    }

    testGoldens('Desktop RecipeSplitView - List and Grid panels at 1400px',
        (tester) async {
      await pumpDesktopMultiPanel(
        tester,
        screen: const RecipeScreen(),
        screenSize: const Size(1400, 900), 
        recipeState: const RecipeState(
          isLoading: false,
          recipes: _mockRecipes,
        ),
      );

      expect(find.byType(RecipeScreen), findsOneWidget,
          reason: 'RecipeScreen should be displayed');
      expect(find.byType(ResponsiveLayoutBuilder), findsOneWidget,
          reason: 'RecipeScreen should use ResponsiveLayoutBuilder');

      expect(find.byType(RecipeSplitView), findsOneWidget,
          reason: 'Desktop layout should show RecipeSplitView');

      expect(find.byType(Row), findsWidgets,
          reason: 'RecipeSplitView should use Row layout for panels');
      expect(find.byType(VerticalDivider), findsAtLeastNWidgets(1),
          reason:
              'RecipeSplitView should include vertical divider between panels');

      await screenMatchesGolden(
          tester, 'desktop_multi_panel_recipe_split_view');
    });

    testGoldens(
        'Desktop DashboardSplitView - Favorites and Bookmarks panels at 1400px',
        (tester) async {
      await pumpDesktopMultiPanel(
        tester,
        screen: const DashboardScreen(),
        screenSize: const Size(1400, 900), 
        recipeState: const RecipeState(
          isLoading: false,
          recipes: _mockRecipes,
        ),
        dashboardState: DashboardState(
          isLoading: false,
          recipes: _mockRecipes,
          favoriteIds: {_mockFavoriteRecipes[0].id, _mockFavoriteRecipes[1].id},
          bookmarkIds: {_mockBookmarkRecipes[0].id},
        ),
      );

      expect(find.byType(DashboardScreen), findsOneWidget,
          reason: 'DashboardScreen should be displayed');
      expect(find.byType(ResponsiveLayoutBuilder), findsOneWidget,
          reason: 'DashboardScreen should use ResponsiveLayoutBuilder');

      expect(find.byType(DashboardSplitView), findsOneWidget,
          reason: 'Desktop layout should show DashboardSplitView');

      expect(find.byType(Row), findsWidgets,
          reason: 'DashboardSplitView should use Row layout for panels');
      expect(find.byType(VerticalDivider), findsAtLeastNWidgets(1),
          reason:
              'DashboardSplitView should include vertical divider between panels');

      await screenMatchesGolden(
          tester, 'desktop_multi_panel_dashboard_split_view');
    });

    testGoldens('Desktop RecipeSplitView - Dark theme at 1400px',
        (tester) async {
      await pumpDesktopMultiPanel(
        tester,
        screen: const RecipeScreen(),
        screenSize: const Size(1400, 900),
        theme: AppTheme.darkTheme,
        recipeState: const RecipeState(
          isLoading: false,
          recipes: _mockRecipes,
        ),
      );

      expect(find.byType(RecipeSplitView), findsOneWidget,
          reason: 'Dark theme should still show RecipeSplitView on desktop');

      await screenMatchesGolden(
          tester, 'desktop_multi_panel_recipe_dark_theme');
    });

    testGoldens('Desktop DashboardSplitView - Dark theme at 1400px',
        (tester) async {
      await pumpDesktopMultiPanel(
        tester,
        screen: const DashboardScreen(),
        screenSize: const Size(1400, 900),
        theme: AppTheme.darkTheme,
        recipeState: const RecipeState(
          isLoading: false,
          recipes: _mockRecipes,
        ),
        dashboardState: DashboardState(
          isLoading: false,
          recipes: _mockRecipes,
          favoriteIds: {_mockFavoriteRecipes[0].id},
          bookmarkIds: {_mockBookmarkRecipes[0].id},
        ),
      );

      expect(find.byType(DashboardSplitView), findsOneWidget,
          reason: 'Dark theme should still show DashboardSplitView on desktop');

      await screenMatchesGolden(
          tester, 'desktop_multi_panel_dashboard_dark_theme');
    });

    testGoldens('Desktop RecipeSplitView - Ultra-wide screen at 1920px',
        (tester) async {
      await pumpDesktopMultiPanel(
        tester,
        screen: const RecipeScreen(),
        screenSize: const Size(1920, 1080), 
        recipeState: const RecipeState(
          isLoading: false,
          recipes: _mockRecipes,
        ),
      );

      expect(find.byType(RecipeSplitView), findsOneWidget,
          reason: 'Ultra-wide desktop should still show RecipeSplitView');

      await screenMatchesGolden(
          tester, 'desktop_multi_panel_recipe_ultra_wide');
    });

    testGoldens('Desktop DashboardSplitView - Ultra-wide screen at 1920px',
        (tester) async {
      await pumpDesktopMultiPanel(
        tester,
        screen: const DashboardScreen(),
        screenSize: const Size(1920, 1080), 
        recipeState: const RecipeState(
          isLoading: false,
          recipes: _mockRecipes,
        ),
        dashboardState: DashboardState(
          isLoading: false,
          recipes: _mockRecipes,
          favoriteIds: {_mockFavoriteRecipes[0].id, _mockFavoriteRecipes[1].id},
          bookmarkIds: {_mockBookmarkRecipes[0].id},
        ),
      );

      expect(find.byType(DashboardSplitView), findsOneWidget,
          reason: 'Ultra-wide desktop should still show DashboardSplitView');

      await screenMatchesGolden(
          tester, 'desktop_multi_panel_dashboard_ultra_wide');
    });

    testGoldens('Responsive - Multi-panel disappears on tablet at 1024px',
        (tester) async {
      await pumpDesktopMultiPanel(
        tester,
        screen: const RecipeScreen(),
        screenSize: const Size(1024, 768),
        recipeState: const RecipeState(
          isLoading: false,
          recipes: _mockRecipes,
        ),
      );

      expect(find.byType(RecipeSplitView), findsOneWidget,
          reason: 'Tablet size should still show RecipeSplitView');

      await screenMatchesGolden(
          tester, 'desktop_multi_panel_tablet_responsive');
    });

    testGoldens(
        'Responsive - Multi-panel switches to single panel on mobile at 600px',
        (tester) async {
      await pumpDesktopMultiPanel(
        tester,
        screen: const RecipeScreen(),
        screenSize: const Size(600, 800),
        recipeState: const RecipeState(
          isLoading: false,
          recipes: _mockRecipes,
        ),
      );

      expect(find.byType(RecipeSplitView), findsNothing,
          reason: 'Mobile size should not show RecipeSplitView');

      await screenMatchesGolden(
          tester, 'desktop_multi_panel_mobile_responsive');
    });

    testGoldens('Desktop Multi-Panel - Loading states', (tester) async {
      await pumpDesktopMultiPanel(
        tester,
        screen: const DashboardScreen(),
        screenSize: const Size(1400, 900),
        recipeState: const RecipeState(
          isLoading: false,
          recipes: _mockRecipes,
        ),
        dashboardState: const DashboardState(
          isLoading: true,
          recipes: [],
          favoriteIds: {},
          bookmarkIds: {},
        ),
      );

      expect(find.byType(DashboardSplitView), findsOneWidget,
          reason: 'DashboardSplitView should show even during loading');

      await screenMatchesGolden(tester, 'desktop_multi_panel_loading_state');
    });

    tearDownAll(() async {
      
    });
  });
}
