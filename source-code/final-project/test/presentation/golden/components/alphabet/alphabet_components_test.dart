import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:recipevault/core/themes/app_theme.dart';
import 'package:recipevault/domain/usecases/get_all_recipes.dart';
import 'package:recipevault/domain/usecases/favorite_recipe.dart';
import 'package:recipevault/domain/usecases/bookmark_recipe.dart';
import 'package:recipevault/presentation/viewmodels/recipe_viewmodel.dart';
import 'package:recipevault/presentation/views/home/components/alphabet_list.dart';
import 'package:recipevault/presentation/views/home/components/alphabet_grid.dart';
import 'package:recipevault/presentation/views/home/home_screen.dart';
import 'package:recipevault/presentation/widgets/alphabet/letter_item.dart';
import 'package:recipevault/presentation/widgets/common/layout/responsive_layout_builder.dart';

class MockRecipeViewModel extends Mock implements RecipeViewModel {}

class MockGetAllRecipes extends Mock implements GetAllRecipes {}

class MockFavoriteRecipe extends Mock implements FavoriteRecipe {}

class MockBookmarkRecipe extends Mock implements BookmarkRecipe {}

class FakeGetAllRecipesParams extends Fake implements GetAllRecipesParams {}

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

void main() {
  group('Alphabet Components Golden Tests', () {
    late MockRecipeViewModel mockRecipeViewModel;

    setUpAll(() async {
      await loadAppFonts();

      registerFallbackValue(FakeGetAllRecipesParams());
    });

    setUp(() async {
      mockRecipeViewModel = MockRecipeViewModel();

      when(() => mockRecipeViewModel.state).thenReturn(const RecipeState());
      when(() => mockRecipeViewModel.setSelectedLetter(any()))
          .thenAnswer((_) async {});
      when(() => mockRecipeViewModel.loadRecipes()).thenAnswer((_) async {});
    });

    Future<Widget> createAlphabetTestHarness({
      required Widget screen,
      String? selectedLetter,
      ThemeData? theme,
    }) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      return ProviderScope(
        overrides: [
          selectedLetterProvider.overrideWith((ref) => selectedLetter),
          recipeProvider.overrideWith((ref) => mockRecipeViewModel),
        ],
        child: MaterialApp(
          home: screen,
          theme: theme ?? AppTheme.lightTheme,
        ),
      );
    }

    Future<void> pumpAlphabetComponent(
      WidgetTester tester, {
      required Widget screen,
      required Size screenSize,
      String? selectedLetter,
      ThemeData? theme,
    }) async {
      tester.view.physicalSize = screenSize;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final widget = await createAlphabetTestHarness(
        screen: screen,
        selectedLetter: selectedLetter,
        theme: theme,
      );
      await tester.pumpWidget(widget);
      await tester.pumpAndSettle(const Duration(milliseconds: 500));
    }

    group('AlphabetList Mobile Layout', () {
      testGoldens('Mobile alphabet list - Normal state', (tester) async {
        await pumpAlphabetComponent(
          tester,
          screen: const AlphabetList(),
          screenSize: const Size(375, 667), 
        );

        expect(find.byType(AlphabetList), findsOneWidget,
            reason: 'AlphabetList should be displayed');
        expect(find.byType(ListView), findsOneWidget,
            reason: 'AlphabetList should use ListView');
        expect(find.byType(LetterItem), findsWidgets,
            reason: 'Should display LetterItem widgets');

        expect(find.byType(Row), findsWidgets,
            reason: 'Mobile LetterItem should use Row layout');
        expect(find.byIcon(Icons.arrow_forward_ios), findsWidgets,
            reason: 'Mobile LetterItem should show arrow icons');

        await screenMatchesGolden(tester, 'alphabet_mobile_list_normal');
      });

      testGoldens('Mobile alphabet list - Letter selected', (tester) async {
        await pumpAlphabetComponent(
          tester,
          screen: const AlphabetList(),
          screenSize: const Size(375, 667),
          selectedLetter: 'M', 
        );

        expect(find.byType(AlphabetList), findsOneWidget,
            reason: 'AlphabetList should be displayed with selected state');

        await screenMatchesGolden(tester, 'alphabet_mobile_list_selected');
      });

      testGoldens('Mobile alphabet list - Dark theme', (tester) async {
        await pumpAlphabetComponent(
          tester,
          screen: const AlphabetList(),
          screenSize: const Size(375, 667),
          theme: AppTheme.darkTheme,
        );

        expect(find.byType(AlphabetList), findsOneWidget,
            reason: 'AlphabetList should work with dark theme');

        await screenMatchesGolden(tester, 'alphabet_mobile_list_dark');
      });
    });

    group('AlphabetGrid Tablet/Desktop Layout', () {
      testGoldens('Tablet alphabet grid - Normal state', (tester) async {
        await pumpAlphabetComponent(
          tester,
          screen: const AlphabetGrid(),
          screenSize: const Size(800, 1024), 
        );

        expect(find.byType(AlphabetGrid), findsOneWidget,
            reason: 'AlphabetGrid should be displayed');
        expect(find.byType(GridView), findsOneWidget,
            reason: 'AlphabetGrid should use GridView');
        expect(find.byType(LetterItem), findsWidgets,
            reason: 'Should display LetterItem widgets');

        expect(find.byType(Container), findsWidgets,
            reason: 'Tablet LetterItem should use Container layout');
        expect(find.byIcon(Icons.arrow_forward_ios), findsNothing,
            reason: 'Tablet LetterItem should not show arrow icons');

        await screenMatchesGolden(tester, 'alphabet_tablet_grid_normal');
      });

      testGoldens('Tablet alphabet grid - Letter selected', (tester) async {
        await pumpAlphabetComponent(
          tester,
          screen: const AlphabetGrid(),
          screenSize: const Size(800, 1024),
          selectedLetter: 'R', 
        );

        expect(find.byType(AlphabetGrid), findsOneWidget,
            reason: 'AlphabetGrid should be displayed with selected state');

        await screenMatchesGolden(tester, 'alphabet_tablet_grid_selected');
      });

      testGoldens('Desktop alphabet grid - Ultra wide', (tester) async {
        await pumpAlphabetComponent(
          tester,
          screen: const AlphabetGrid(),
          screenSize: const Size(1920, 1080), 
        );

        expect(find.byType(AlphabetGrid), findsOneWidget,
            reason: 'AlphabetGrid should work on desktop');

        await screenMatchesGolden(tester, 'alphabet_desktop_grid_ultra_wide');
      });

      testGoldens('Desktop alphabet grid - Dark theme', (tester) async {
        await pumpAlphabetComponent(
          tester,
          screen: const AlphabetGrid(),
          screenSize: const Size(1400, 900),
          theme: AppTheme.darkTheme,
        );

        expect(find.byType(AlphabetGrid), findsOneWidget,
            reason: 'AlphabetGrid should work with dark theme');

        await screenMatchesGolden(tester, 'alphabet_desktop_grid_dark');
      });
    });

    group('Responsive Alphabet Behavior', () {
      testGoldens('HomeScreen responsive - Mobile shows AlphabetList',
          (tester) async {
        await pumpAlphabetComponent(
          tester,
          screen: const HomeScreen(),
          screenSize: const Size(375, 667), 
        );

        expect(find.byType(HomeScreen), findsOneWidget,
            reason: 'HomeScreen should be displayed');
        expect(find.byType(ResponsiveLayoutBuilder), findsWidgets,
            reason: 'HomeScreen should use ResponsiveLayoutBuilder');
        expect(find.byType(AlphabetList), findsOneWidget,
            reason: 'Mobile should show AlphabetList');
        expect(find.byType(AlphabetGrid), findsNothing,
            reason: 'Mobile should not show AlphabetGrid');

        await screenMatchesGolden(tester, 'alphabet_responsive_mobile');
      });

      testGoldens('HomeScreen responsive - Tablet shows AlphabetGrid',
          (tester) async {
        await pumpAlphabetComponent(
          tester,
          screen: const HomeScreen(),
          screenSize: const Size(800, 1024), 
        );

        expect(find.byType(HomeScreen), findsOneWidget,
            reason: 'HomeScreen should be displayed');
        expect(find.byType(ResponsiveLayoutBuilder), findsWidgets,
            reason: 'HomeScreen should use ResponsiveLayoutBuilder');
        expect(find.byType(AlphabetGrid), findsOneWidget,
            reason: 'Tablet should show AlphabetGrid');
        expect(find.byType(AlphabetList), findsNothing,
            reason: 'Tablet should not show AlphabetList');

        await screenMatchesGolden(tester, 'alphabet_responsive_tablet');
      });

      testGoldens('HomeScreen responsive - Desktop shows AlphabetGrid',
          (tester) async {
        await pumpAlphabetComponent(
          tester,
          screen: const HomeScreen(),
          screenSize: const Size(1400, 900), 
        );

        expect(find.byType(HomeScreen), findsOneWidget,
            reason: 'HomeScreen should be displayed');
        expect(find.byType(ResponsiveLayoutBuilder), findsWidgets,
            reason: 'HomeScreen should use ResponsiveLayoutBuilder');
        expect(find.byType(AlphabetGrid), findsOneWidget,
            reason: 'Desktop should show AlphabetGrid');
        expect(find.byType(AlphabetList), findsNothing,
            reason: 'Desktop should not show AlphabetList');

        await screenMatchesGolden(tester, 'alphabet_responsive_desktop');
      });

      testGoldens('Responsive breakpoint test - 600px mobile boundary',
          (tester) async {
        await pumpAlphabetComponent(
          tester,
          screen: const HomeScreen(),
          screenSize: const Size(600, 800), 
        );

        expect(find.byType(AlphabetList), findsOneWidget,
            reason: '600px should still show mobile AlphabetList');

        await screenMatchesGolden(
            tester, 'alphabet_responsive_mobile_boundary');
      });

      testGoldens('Responsive breakpoint test - 1024px tablet boundary',
          (tester) async {
        await pumpAlphabetComponent(
          tester,
          screen: const HomeScreen(),
          screenSize: const Size(1024, 768), 
        );

        expect(find.byType(AlphabetGrid), findsOneWidget,
            reason: '1024px should show tablet AlphabetGrid');

        await screenMatchesGolden(
            tester, 'alphabet_responsive_tablet_boundary');
      });
    });

    group('Alphabet Component States', () {
      testGoldens('AlphabetList with letter selection interaction',
          (tester) async {
        await pumpAlphabetComponent(
          tester,
          screen: const AlphabetList(),
          screenSize: const Size(375, 667),
          selectedLetter: 'G',
        );

        expect(find.byType(AlphabetList), findsOneWidget,
            reason: 'AlphabetList should handle letter selection');

        await screenMatchesGolden(tester, 'alphabet_list_letter_interaction');
      });

      testGoldens('AlphabetGrid with letter selection interaction',
          (tester) async {
        await pumpAlphabetComponent(
          tester,
          screen: const AlphabetGrid(),
          screenSize: const Size(800, 1024),
          selectedLetter: 'T', 
        );

        expect(find.byType(AlphabetGrid), findsOneWidget,
            reason: 'AlphabetGrid should handle letter selection');

        await screenMatchesGolden(tester, 'alphabet_grid_letter_interaction');
      });

      testGoldens('Alphabet component comparison - List vs Grid layouts',
          (tester) async {
        await pumpAlphabetComponent(
          tester,
          screen: const HomeScreen(),
          screenSize: const Size(1200, 800),
        );

        expect(find.byType(AlphabetGrid), findsOneWidget,
            reason: 'Desktop should show AlphabetGrid layout');

        await screenMatchesGolden(tester, 'alphabet_responsive_comparison');
      });
    });

    tearDownAll(() async {
    });
  });
}
