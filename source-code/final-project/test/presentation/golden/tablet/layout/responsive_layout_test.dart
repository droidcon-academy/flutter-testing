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
import 'package:recipevault/presentation/widgets/common/layout/responsive_layout_builder.dart';
import 'package:recipevault/presentation/views/dashboard/dashboard_screen.dart';
import 'package:recipevault/presentation/views/home/home_screen.dart';
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

void main() {
  group('Tablet ResponsiveLayoutBuilder Golden Tests - Real Component Tests',
      () {
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

    Future<Widget> createResponsiveLayoutTestHarness({
      RecipeState? recipeState,
      ThemeData? theme,
      Widget? testContent,
    }) async {
      final prefs = await SharedPreferences.getInstance();

      return ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          getAllRecipesProvider.overrideWithValue(mockGetAllRecipes),
          favoriteRecipeProvider.overrideWithValue(mockFavoriteRecipe),
          bookmarkRecipeProvider.overrideWithValue(mockBookmarkRecipe),
          currentPageIndexProvider.overrideWith((ref) => 0), 

          if (recipeState != null)
            recipeProvider.overrideWith((ref) => TestRecipeViewModel(
                recipeState,
                mockGetAllRecipes,
                mockFavoriteRecipe,
                mockBookmarkRecipe)),
        ],
        child: MaterialApp(
          theme: theme ?? AppTheme.lightTheme,
          home: testContent ??
              ResponsiveLayoutBuilder(
                mobile: Container(
                  color: Colors.blue[50],
                  child: const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.phone_android, size: 64, color: Colors.blue),
                        SizedBox(height: 16),
                        Text(
                          'Mobile Layout',
                          style: TextStyle(
                              fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                        Text('≤ 600px width'),
                      ],
                    ),
                  ),
                ),
                tablet: Container(
                  color: Colors.green[50],
                  child: const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.tablet, size: 64, color: Colors.green),
                        SizedBox(height: 16),
                        Text(
                          'Tablet Layout',
                          style: TextStyle(
                              fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                        Text('601px - 1024px width'),
                      ],
                    ),
                  ),
                ),
                desktopWeb: Container(
                  color: Colors.purple[50],
                  child: const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.desktop_windows,
                            size: 64, color: Colors.purple),
                        SizedBox(height: 16),
                        Text(
                          'Desktop Layout',
                          style: TextStyle(
                              fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                        Text('≥ 1025px width'),
                      ],
                    ),
                  ),
                ),
              ),
        ),
      );
    }

    Future<void> pumpResponsiveLayoutTest(
      WidgetTester tester, {
      required Size screenSize,
      RecipeState? recipeState,
      ThemeData? theme,
      Widget? testContent,
    }) async {
      tester.view.physicalSize = screenSize;
      tester.view.devicePixelRatio = 1.0;

      final widget = await createResponsiveLayoutTestHarness(
        recipeState: recipeState,
        theme: theme,
        testContent: testContent,
      );

      await tester.pumpWidget(widget);
      await tester.pumpAndSettle(const Duration(milliseconds: 500));
    }

    testGoldens('ResponsiveLayoutBuilder - Tablet landscape layout',
        (tester) async {
      expect(ResponsiveHelper.isTablet, isTrue,
          reason: 'Should detect tablet screen size for this test');

      await pumpResponsiveLayoutTest(
        tester,
        screenSize: const Size(1024, 768),
      );

      expect(find.byType(ResponsiveLayoutBuilder), findsOneWidget,
          reason: 'ResponsiveLayoutBuilder should be displayed');
      expect(find.text('Tablet Layout'), findsOneWidget,
          reason: 'Should display tablet layout at 1024px width');
      expect(find.byIcon(Icons.tablet), findsOneWidget,
          reason: 'Should show tablet icon');

      await screenMatchesGolden(tester, 'responsive_layout_tablet_landscape');
    });

    testGoldens('ResponsiveLayoutBuilder - Tablet portrait layout',
        (tester) async {
      await pumpResponsiveLayoutTest(
        tester,
        screenSize: const Size(768, 1024), 
      );

      expect(find.byType(ResponsiveLayoutBuilder), findsOneWidget,
          reason: 'ResponsiveLayoutBuilder should be displayed');
      expect(find.text('Tablet Layout'), findsOneWidget,
          reason: 'Should display tablet layout at 768px width');

      await screenMatchesGolden(tester, 'responsive_layout_tablet_portrait');
    });

    testGoldens(
        'ResponsiveLayoutBuilder - Responsive breakpoint 600px (mobile)',
        (tester) async {
      await pumpResponsiveLayoutTest(
        tester,
        screenSize: const Size(600, 800),
      );

      expect(find.byType(ResponsiveLayoutBuilder), findsOneWidget,
          reason: 'ResponsiveLayoutBuilder should be displayed');
      expect(find.text('Mobile Layout'), findsOneWidget,
          reason: 'At 600px should show mobile layout');
      expect(find.byIcon(Icons.phone_android), findsOneWidget,
          reason: 'Should show mobile icon at boundary');

      await screenMatchesGolden(
          tester, 'responsive_layout_breakpoint_600_mobile');
    });

    testGoldens(
        'ResponsiveLayoutBuilder - Responsive breakpoint 601px (tablet)',
        (tester) async {
      await pumpResponsiveLayoutTest(
        tester,
        screenSize: const Size(601, 800),
      );

      expect(find.byType(ResponsiveLayoutBuilder), findsOneWidget,
          reason: 'ResponsiveLayoutBuilder should be displayed');
      expect(find.text('Tablet Layout'), findsOneWidget,
          reason: 'At 601px should show tablet layout');

      await screenMatchesGolden(
          tester, 'responsive_layout_breakpoint_601_tablet');
    });

    testGoldens('ResponsiveLayoutBuilder - Desktop breakpoint 1025px',
        (tester) async {
      await pumpResponsiveLayoutTest(
        tester,
        screenSize: const Size(1025, 768), 
      );

      expect(find.byType(ResponsiveLayoutBuilder), findsOneWidget,
          reason: 'ResponsiveLayoutBuilder should be displayed');
      expect(find.text('Desktop Layout'), findsOneWidget,
          reason: 'At 1025px should show desktop layout');
      expect(find.byIcon(Icons.desktop_windows), findsOneWidget,
          reason: 'Should show desktop icon');

      await screenMatchesGolden(
          tester, 'responsive_layout_breakpoint_1025_desktop');
    });

    testGoldens('ResponsiveLayoutBuilder - Dark theme responsive layout',
        (tester) async {
      await pumpResponsiveLayoutTest(
        tester,
        screenSize: const Size(768, 1024), 
        theme: AppTheme.darkTheme,
      );

      expect(find.byType(ResponsiveLayoutBuilder), findsOneWidget,
          reason: 'ResponsiveLayoutBuilder should work with dark theme');
      expect(find.text('Tablet Layout'), findsOneWidget,
          reason: 'Should display tablet layout in dark theme');

      await screenMatchesGolden(tester, 'responsive_layout_dark_theme');
    });

    testGoldens('ResponsiveLayoutBuilder - Real DashboardScreen context',
        (tester) async {
      await pumpResponsiveLayoutTest(
        tester,
        screenSize: const Size(1024, 768), 
        testContent: const DashboardScreen(),
        recipeState: const RecipeState(
          isLoading: false,
          recipes: _testRecipes,
        ),
      );

      expect(find.byType(DashboardScreen), findsOneWidget,
          reason: 'DashboardScreen should be displayed');
      expect(find.byType(ResponsiveLayoutBuilder), findsWidgets,
          reason:
              'DashboardScreen should use multiple ResponsiveLayoutBuilder widgets');

      await screenMatchesGolden(tester, 'responsive_layout_dashboard_context');
    });

    testGoldens('ResponsiveLayoutBuilder - Real HomeScreen context',
        (tester) async {
      await pumpResponsiveLayoutTest(
        tester,
        screenSize: const Size(768, 1024), 
        testContent: const HomeScreen(),
        recipeState: const RecipeState(
          isLoading: false,
          recipes: _testRecipes,
        ),
      );

      expect(find.byType(HomeScreen), findsOneWidget,
          reason: 'HomeScreen should be displayed');
      expect(find.byType(ResponsiveLayoutBuilder), findsWidgets,
          reason:
              'HomeScreen should use multiple ResponsiveLayoutBuilder widgets');

      await screenMatchesGolden(tester, 'responsive_layout_home_context');
    });

    testGoldens('ResponsiveHelper - Grid columns responsive behavior',
        (tester) async {
      await pumpResponsiveLayoutTest(
        tester,
        screenSize: const Size(1200, 800), 
        testContent: Builder(builder: (context) {
          final gridColumns = ResponsiveHelper.recipeGridColumns(context);
          final deviceType = ResponsiveHelper.deviceType;
          final isLandscape =
              MediaQuery.of(context).orientation == Orientation.landscape;

          return Scaffold(
            body: Container(
              color: Colors.orange[50],
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.grid_view, size: 64, color: Colors.orange),
                    const SizedBox(height: 16),
                    Text(
                      'ResponsiveHelper Grid',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 8),
                    Text('Device: ${deviceType.name}'),
                    Text(
                        'Orientation: ${isLandscape ? "Landscape" : "Portrait"}'),
                    Text('Grid Columns: $gridColumns'),
                    const SizedBox(height: 16),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: GridView.builder(
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: gridColumns,
                            childAspectRatio: 1.2,
                            crossAxisSpacing: 8,
                            mainAxisSpacing: 8,
                          ),
                          itemCount: 6,
                          itemBuilder: (context, index) {
                            return Container(
                              decoration: BoxDecoration(
                                color: Colors.orange[100],
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.orange[300]!),
                              ),
                              child: Center(
                                child: Text('Item ${index + 1}'),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      );

      expect(find.text('ResponsiveHelper Grid'), findsOneWidget,
          reason: 'Should display ResponsiveHelper grid demo');
      expect(find.byType(GridView), findsOneWidget,
          reason: 'Should show responsive grid layout');

      await screenMatchesGolden(tester, 'responsive_helper_grid_columns');
    });

    tearDownAll(() async {
      
    });
  });
}
