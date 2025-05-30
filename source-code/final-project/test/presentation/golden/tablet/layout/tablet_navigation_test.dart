import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:fpdart/fpdart.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:recipevault/core/themes/app_theme.dart';
import 'package:recipevault/core/utils/responsive_helper.dart';
import 'package:recipevault/domain/entities/recipe.dart';
import 'package:recipevault/domain/usecases/get_all_recipes.dart';
import 'package:recipevault/domain/usecases/favorite_recipe.dart';
import 'package:recipevault/domain/usecases/bookmark_recipe.dart';
import 'package:recipevault/presentation/viewmodels/recipe_viewmodel.dart';
import 'package:recipevault/presentation/viewmodels/navigation_viewmodel.dart';
import 'package:recipevault/presentation/widgets/navigation/nav_rail.dart';
import 'package:recipevault/presentation/widgets/navigation/bottom_nav_bar.dart';
import 'package:recipevault/presentation/widgets/common/layout/responsive_layout_builder.dart';
import 'package:recipevault/presentation/views/home/home_screen.dart';
import 'package:recipevault/presentation/views/dashboard/dashboard_screen.dart';
import 'package:recipevault/data/datasources/local_datasource.dart';

const _testRecipes = [
  Recipe(
    id: '1',
    name: 'Spaghetti Carbonara',
    ingredients: [
      Ingredient(name: 'Pasta', measure: '400g'),
      Ingredient(name: 'Eggs', measure: '3 large'),
    ],
    instructions: 'Cook pasta, mix with eggs and cheese.',
  ),
  Recipe(
    id: '2',
    name: 'Caesar Salad',
    ingredients: [
      Ingredient(name: 'Lettuce', measure: '2 heads'),
      Ingredient(name: 'Parmesan', measure: '50g'),
    ],
    instructions: 'Chop lettuce, add dressing and cheese.',
  ),
];

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
  Future<void> loadRecipes() async {
    
  }

  @override
  void setSelectedLetter(String? letter) {
   
  }
}

class TabletNavigationHarness extends ConsumerWidget {
  final int selectedIndex;
  final void Function(int) onDestinationSelected;

  const TabletNavigationHarness({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ResponsiveLayoutBuilder(
      mobile: Scaffold(
        appBar: AppBar(title: const Text('Mobile Navigation')),
        body: const Center(child: Text('Mobile Content')),
        bottomNavigationBar: NavBar(
          selectedIndex: selectedIndex,
          onDestinationSelected: onDestinationSelected,
        ),
      ),
      tablet: Scaffold(
        appBar: AppBar(title: const Text('Tablet Navigation')),
        body: const Center(child: Text('Tablet Content')),
        bottomNavigationBar: NavBar(
          selectedIndex: selectedIndex,
          onDestinationSelected: onDestinationSelected,
        ),
      ),
      desktopWeb: Scaffold(
        appBar: AppBar(title: const Text('Desktop Navigation')),
        body: Row(
          children: [
            NavRail(
              selectedIndex: selectedIndex,
              onDestinationSelected: onDestinationSelected,
            ),
            const VerticalDivider(width: 1),
            const Expanded(child: Center(child: Text('Desktop Content'))),
          ],
        ),
      ),
    );
  }
}

void main() {
  group('Tablet Navigation Golden Tests - Real Component Tests', () {
    late SharedPreferences mockSharedPreferences;
    late MockGetAllRecipes mockGetAllRecipes;
    late MockFavoriteRecipe mockFavoriteRecipe;
    late MockBookmarkRecipe mockBookmarkRecipe;

    setUpAll(() async {
      SharedPreferences.setMockInitialValues({});
      await loadAppFonts();

      registerFallbackValue(FakeGetAllRecipesParams());
      registerFallbackValue(FakeFavoriteRecipeParams());
      registerFallbackValue(FakeBookmarkRecipeParams());
    });

    setUp(() async {
      mockSharedPreferences = await SharedPreferences.getInstance();
      mockGetAllRecipes = MockGetAllRecipes();
      mockFavoriteRecipe = MockFavoriteRecipe();
      mockBookmarkRecipe = MockBookmarkRecipe();

      when(() => mockGetAllRecipes(any()))
          .thenAnswer((_) async => const Right(_testRecipes));
      when(() => mockFavoriteRecipe.getFavorites())
          .thenAnswer((_) async => const Right([]));
      when(() => mockBookmarkRecipe.getBookmarks())
          .thenAnswer((_) async => const Right([]));
    });

    Future<Widget> createTabletNavigationTestHarness({
      RecipeState? recipeState,
      ThemeData? theme,
      int selectedIndex = 0,
      Widget? customContent,
    }) async {
      final prefs = await SharedPreferences.getInstance();

      return ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          getAllRecipesProvider.overrideWithValue(mockGetAllRecipes),
          favoriteRecipeProvider.overrideWithValue(mockFavoriteRecipe),
          bookmarkRecipeProvider.overrideWithValue(mockBookmarkRecipe),
          currentPageIndexProvider.overrideWith((ref) => selectedIndex),
          if (recipeState != null)
            recipeProvider.overrideWith((ref) => TestRecipeViewModel(
                recipeState,
                mockGetAllRecipes,
                mockFavoriteRecipe,
                mockBookmarkRecipe)),
        ],
        child: MaterialApp(
          theme: theme ?? AppTheme.lightTheme,
          home: customContent ??
              TabletNavigationHarness(
                selectedIndex: selectedIndex,
                onDestinationSelected: (index) {},
              ),
        ),
      );
    }

    Future<void> pumpTabletNavigationTest(
      WidgetTester tester, {
      required Size screenSize,
      RecipeState? recipeState,
      ThemeData? theme,
      int selectedIndex = 0,
      Widget? customContent,
    }) async {
      tester.view.physicalSize = screenSize;
      tester.view.devicePixelRatio = 1.0;

      final widget = await createTabletNavigationTestHarness(
        recipeState: recipeState,
        theme: theme,
        selectedIndex: selectedIndex,
        customContent: customContent,
      );

      await tester.pumpWidget(widget);
      await tester.pumpAndSettle(const Duration(milliseconds: 500));
    }

    testGoldens('ResponsiveNavigation - Tablet landscape with NavBar',
        (tester) async {
      expect(ResponsiveHelper.isTablet, isTrue,
          reason: 'Should detect tablet screen size for this test');

      await pumpTabletNavigationTest(
        tester,
        screenSize: const Size(1024, 768), 
        selectedIndex: 0,
      );

      expect(find.byType(ResponsiveLayoutBuilder), findsOneWidget,
          reason: 'Should use ResponsiveLayoutBuilder for navigation');
      expect(find.byType(NavBar), findsOneWidget,
          reason: 'Tablet should show bottom navigation bar');
      expect(find.byType(NavRail), findsNothing,
          reason: 'Tablet should not show navigation rail');

      final navBar = tester.widget<NavBar>(find.byType(NavBar));
      expect(navBar.selectedIndex, equals(0),
          reason: 'Recipe tab should be selected');

      await screenMatchesGolden(tester, 'tablet_navigation_landscape_navbar');
    });

    testGoldens('ResponsiveNavigation - Tablet portrait with NavBar',
        (tester) async {
      await pumpTabletNavigationTest(
        tester,
        screenSize: const Size(768, 1024), 
        selectedIndex: 1, 
      );

      expect(find.byType(ResponsiveLayoutBuilder), findsOneWidget,
          reason: 'Should use ResponsiveLayoutBuilder for navigation');
      expect(find.byType(NavBar), findsOneWidget,
          reason: 'Tablet portrait should show bottom navigation bar');
      expect(find.byType(NavRail), findsNothing,
          reason: 'Tablet portrait should not show navigation rail');

      final navBar = tester.widget<NavBar>(find.byType(NavBar));
      expect(navBar.selectedIndex, equals(1),
          reason: 'Dashboard tab should be selected');

      await screenMatchesGolden(tester, 'tablet_navigation_portrait_navbar');
    });

    testGoldens('ResponsiveNavigation - Desktop boundary with NavRail',
        (tester) async {
      await pumpTabletNavigationTest(
        tester,
        screenSize: const Size(1025, 768), 
        selectedIndex: 0,
      );

      expect(find.byType(ResponsiveLayoutBuilder), findsOneWidget,
          reason: 'Should use ResponsiveLayoutBuilder for navigation');
      expect(find.byType(NavRail), findsOneWidget,
          reason: 'At 1025px should show navigation rail (desktop layout)');
      expect(find.byType(NavBar), findsNothing,
          reason: 'At 1025px should not show bottom navigation');

      expect(find.byType(Row), findsWidgets,
          reason: 'Desktop layout should use Row for NavRail');
      expect(find.byType(VerticalDivider), findsOneWidget,
          reason: 'Should show vertical divider with NavRail');

      await screenMatchesGolden(
          tester, 'tablet_navigation_desktop_boundary_navrail');
    });

    testGoldens('ResponsiveNavigation - Dark theme with NavBar',
        (tester) async {
      await pumpTabletNavigationTest(
        tester,
        screenSize: const Size(768, 1024), 
        theme: AppTheme.darkTheme,
        selectedIndex: 1,
      );

      expect(find.byType(ResponsiveLayoutBuilder), findsOneWidget,
          reason: 'Should use ResponsiveLayoutBuilder in dark theme');
      expect(find.byType(NavBar), findsOneWidget,
          reason: 'Dark theme should show bottom navigation on tablet');

      await screenMatchesGolden(tester, 'tablet_navigation_dark_theme');
    });

    testGoldens('ResponsiveNavigation - Real HomeScreen context',
        (tester) async {
      await pumpTabletNavigationTest(
        tester,
        screenSize: const Size(768, 1024), 
        customContent: const HomeScreen(),
        recipeState: const RecipeState(
          isLoading: false,
          recipes: _testRecipes,
        ),
      );

      expect(find.byType(HomeScreen), findsOneWidget,
          reason: 'HomeScreen should be displayed');
      expect(find.byType(ResponsiveLayoutBuilder), findsWidgets,
          reason: 'HomeScreen should use ResponsiveLayoutBuilder');

      await screenMatchesGolden(tester, 'tablet_navigation_homescreen_context');
    });

    testGoldens('ResponsiveNavigation - Real DashboardScreen context',
        (tester) async {
      await pumpTabletNavigationTest(
        tester,
        screenSize: const Size(1024, 768),
        customContent: const DashboardScreen(),
        recipeState: const RecipeState(
          isLoading: false,
          recipes: _testRecipes,
        ),
      );

      expect(find.byType(DashboardScreen), findsOneWidget,
          reason: 'DashboardScreen should be displayed');
      expect(find.byType(ResponsiveLayoutBuilder), findsWidgets,
          reason: 'DashboardScreen should use ResponsiveLayoutBuilder');

      await screenMatchesGolden(tester, 'tablet_navigation_dashboard_context');
    });

    testGoldens('ResponsiveNavigation - Mobile boundary behavior',
        (tester) async {
      await pumpTabletNavigationTest(
        tester,
        screenSize: const Size(600, 800),
        selectedIndex: 0,
      );

      expect(find.byType(ResponsiveLayoutBuilder), findsOneWidget,
          reason: 'Should use ResponsiveLayoutBuilder at mobile boundary');
      expect(find.byType(NavBar), findsOneWidget,
          reason: 'At 600px should show mobile navigation (NavBar)');
      expect(find.byType(NavRail), findsNothing,
          reason: 'At 600px should not show navigation rail');

      await screenMatchesGolden(tester, 'tablet_navigation_mobile_boundary');
    });

    testGoldens('ResponsiveNavigation - Selected state variations',
        (tester) async {
      await pumpTabletNavigationTest(
        tester,
        screenSize: const Size(768, 1024), 
        selectedIndex: 1, 
      );

      expect(find.byType(NavBar), findsOneWidget,
          reason: 'Should show NavBar on tablet');

      final navBar = tester.widget<NavBar>(find.byType(NavBar));
      expect(navBar.selectedIndex, equals(1),
          reason: 'Dashboard should be selected (index 1)');

      await screenMatchesGolden(tester, 'tablet_navigation_selection_states');
    });

    tearDownAll(() async {
      
    });
  });
}
