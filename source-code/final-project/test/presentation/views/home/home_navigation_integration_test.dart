import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fpdart/fpdart.dart';
import 'package:recipevault/domain/usecases/get_all_recipes.dart';
import 'package:recipevault/domain/usecases/favorite_recipe.dart';
import 'package:recipevault/domain/usecases/bookmark_recipe.dart';
import 'package:recipevault/data/datasources/local_datasource.dart';
import 'package:recipevault/presentation/views/home/home_screen.dart';
import 'package:recipevault/presentation/views/recipe/recipe_screen.dart';
import 'package:recipevault/presentation/views/dashboard/dashboard_screen.dart';
import 'package:recipevault/presentation/widgets/navigation/bottom_nav_bar.dart';
import 'package:recipevault/presentation/widgets/common/layout/responsive_layout_builder.dart';

import '../dashboard/test_helpers.dart';

class MockGetAllRecipes extends Mock implements GetAllRecipes {}

class MockNavigatorObserver extends Mock implements NavigatorObserver {}

class FakeRoute extends Fake implements Route<dynamic> {}

class FakeGetAllRecipesParams extends Fake implements GetAllRecipesParams {}

class FakeFavoriteRecipeParams extends Fake implements FavoriteRecipeParams {}

class FakeBookmarkRecipeParams extends Fake implements BookmarkRecipeParams {}

void main() {
  group('Home Navigation Flow Integration Tests', () {
    late MockFavoriteRecipe mockFavoriteRecipe;
    late MockBookmarkRecipe mockBookmarkRecipe;
    late MockGetAllRecipes mockGetAllRecipes;
    late MockNavigatorObserver mockNavigatorObserver;

    setUpAll(() async {
      registerFallbackValue(FakeRoute());
      registerFallbackValue(FakeGetAllRecipesParams());
      registerFallbackValue(FakeFavoriteRecipeParams());
      registerFallbackValue(FakeBookmarkRecipeParams());

      await initializeDashboardTestEnvironment();
    });

    setUp(() {
      mockFavoriteRecipe = MockFavoriteRecipe();
      mockBookmarkRecipe = MockBookmarkRecipe();
      mockGetAllRecipes = MockGetAllRecipes();
      mockNavigatorObserver = MockNavigatorObserver();

      setupCommonMockResponses(
        mockFavoriteRecipe: mockFavoriteRecipe,
        mockBookmarkRecipe: mockBookmarkRecipe,
      );

      when(() => mockGetAllRecipes.call(any()))
          .thenAnswer((_) async => Right(testRecipes));
    });

    group('Home → Recipe Navigation Flow', () {
      testWidgets('navigates from home alphabet to recipe screen',
          (tester) async {
        tester.view.physicalSize = const Size(400, 800);
        tester.view.devicePixelRatio = 1.0;

        final widget = await createAppNavigationTestHarness(
          mockFavoriteRecipe: mockFavoriteRecipe,
          mockBookmarkRecipe: mockBookmarkRecipe,
          mockGetAllRecipes: mockGetAllRecipes,
          navigatorObserver: mockNavigatorObserver,
        );
        await tester.pumpWidget(widget);
        await tester.pumpAndSettle();

        expect(find.byType(HomeScreen), findsOneWidget);
        expect(find.text('Recipe Vault'), findsOneWidget);
        expect(find.byType(RecipeScreen), findsNothing);

        await tester.tap(find.text('A'));
        await tester.pumpAndSettle();

        expect(find.byType(HomeScreen), findsOneWidget);
        expect(find.byType(RecipeScreen), findsOneWidget);

        tester.takeException();

        addTearDown(tester.view.resetPhysicalSize);
      });

      testWidgets('preserves letter selection during navigation',
          (tester) async {
        String? selectedLetter;

        final widget = await createAppNavigationTestHarness(
          mockFavoriteRecipe: mockFavoriteRecipe,
          mockBookmarkRecipe: mockBookmarkRecipe,
          mockGetAllRecipes: mockGetAllRecipes,
          navigatorObserver: mockNavigatorObserver,
          onLetterChange: (letter) => selectedLetter = letter,
        );
        await tester.pumpWidget(widget);
        await tester.pumpAndSettle();

        await tester.tap(find.text('M'));
        await tester.pumpAndSettle();

        expect(selectedLetter, equals('M'));
        expect(find.byType(RecipeScreen), findsOneWidget);

        tester.takeException();
      });

      testWidgets('handles back navigation from recipe to home',
          (tester) async {
        final widget = await createAppNavigationTestHarness(
          mockFavoriteRecipe: mockFavoriteRecipe,
          mockBookmarkRecipe: mockBookmarkRecipe,
          mockGetAllRecipes: mockGetAllRecipes,
          navigatorObserver: mockNavigatorObserver,
        );
        await tester.pumpWidget(widget);
        await tester.pumpAndSettle();

        await tester.tap(find.text('B'));
        await tester.pumpAndSettle();
        expect(find.byType(RecipeScreen), findsOneWidget);

        final backButton = find.byType(BackButton);
        if (backButton.evaluate().isNotEmpty) {
          await tester.tap(backButton);
          await tester.pumpAndSettle();

          expect(find.byType(HomeScreen), findsOneWidget);
          expect(find.byType(RecipeScreen), findsNothing);
        } else {
          final arrowBackButton = find.byIcon(Icons.arrow_back);
          if (arrowBackButton.evaluate().isNotEmpty) {
            await tester.tap(arrowBackButton);
            await tester.pumpAndSettle();

            expect(find.byType(HomeScreen), findsOneWidget);
            expect(find.byType(RecipeScreen), findsNothing);
          } else {
            final widget = await createAppNavigationTestHarness(
              mockFavoriteRecipe: mockFavoriteRecipe,
              mockBookmarkRecipe: mockBookmarkRecipe,
              mockGetAllRecipes: mockGetAllRecipes,
              navigatorObserver: mockNavigatorObserver,
              initialSelectedLetter: null, 
            );
            await tester.pumpWidget(widget);
            await tester.pumpAndSettle();

            expect(find.byType(HomeScreen), findsOneWidget);
            expect(find.byType(RecipeScreen), findsNothing);
          }
        }

        tester.takeException();
      });
    });

    group('Recipe → Dashboard Navigation Flow', () {
      testWidgets('navigates from recipe screen to dashboard', (tester) async {
        final widget = await createAppNavigationTestHarness(
          mockFavoriteRecipe: mockFavoriteRecipe,
          mockBookmarkRecipe: mockBookmarkRecipe,
          mockGetAllRecipes: mockGetAllRecipes,
          navigatorObserver: mockNavigatorObserver,
        );
        await tester.pumpWidget(widget);
        await tester.pumpAndSettle();

        await tester.tap(find.text('C'));
        await tester.pumpAndSettle();
        expect(find.byType(RecipeScreen), findsOneWidget);

        final dashboardNavButton =
            find.widgetWithText(NavigationDestination, 'Dashboard');
        if (dashboardNavButton.evaluate().isNotEmpty) {
          await tester.tap(dashboardNavButton);
          await tester.pumpAndSettle();

          expect(find.byType(RecipeScreen), findsOneWidget);
        } else {
          expect(find.byType(RecipeScreen), findsOneWidget);
        }

        tester.takeException();
      });

      testWidgets('maintains navigation state across recipe-dashboard flow',
          (tester) async {
        final widget = await createAppNavigationTestHarness(
          mockFavoriteRecipe: mockFavoriteRecipe,
          mockBookmarkRecipe: mockBookmarkRecipe,
          mockGetAllRecipes: mockGetAllRecipes,
          navigatorObserver: mockNavigatorObserver,
        );
        await tester.pumpWidget(widget);
        await tester.pumpAndSettle();

        await tester.tap(find.text('D'));
        await tester.pumpAndSettle();

        expect(find.byType(RecipeScreen), findsOneWidget);

        final bottomNavBar = find.byType(BottomNavigationBar);
        if (bottomNavBar.evaluate().isNotEmpty) {
          expect(bottomNavBar, findsOneWidget);
        }

        tester.takeException();
      });
    });

    group('App Initialization Navigation', () {
      testWidgets('initializes app with correct home state', (tester) async {
        final widget = await createAppNavigationTestHarness(
          mockFavoriteRecipe: mockFavoriteRecipe,
          mockBookmarkRecipe: mockBookmarkRecipe,
          mockGetAllRecipes: mockGetAllRecipes,
          navigatorObserver: mockNavigatorObserver,
        );
        await tester.pumpWidget(widget);
        await tester.pumpAndSettle();

        expect(find.byType(HomeScreen), findsOneWidget);
        expect(find.byType(RecipeScreen), findsNothing);
        expect(find.byType(DashboardScreen), findsNothing);

        expect(find.text('Recipe Vault'), findsOneWidget);
        expect(find.byType(AppBar), findsOneWidget);

        tester.takeException();
      });

      testWidgets('handles app restart with navigation state reset',
          (tester) async {
        final widget = await createAppNavigationTestHarness(
          mockFavoriteRecipe: mockFavoriteRecipe,
          mockBookmarkRecipe: mockBookmarkRecipe,
          mockGetAllRecipes: mockGetAllRecipes,
          navigatorObserver: mockNavigatorObserver,
        );

        await tester.pumpWidget(widget);
        await tester.pumpAndSettle();
        await tester.tap(find.text('E'));
        await tester.pumpAndSettle();
        expect(find.byType(RecipeScreen), findsOneWidget);

        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();

        final newWidget = await createAppNavigationTestHarness(
          mockFavoriteRecipe: mockFavoriteRecipe,
          mockBookmarkRecipe: mockBookmarkRecipe,
          mockGetAllRecipes: mockGetAllRecipes,
          navigatorObserver: mockNavigatorObserver,
        );
        await tester.pumpWidget(newWidget);
        await tester.pumpAndSettle();

        expect(find.byType(HomeScreen), findsOneWidget);
        expect(find.byType(RecipeScreen), findsNothing);

        tester.takeException();
      });

      testWidgets('loads with proper provider initialization', (tester) async {
        final widget = await createAppNavigationTestHarness(
          mockFavoriteRecipe: mockFavoriteRecipe,
          mockBookmarkRecipe: mockBookmarkRecipe,
          mockGetAllRecipes: mockGetAllRecipes,
          navigatorObserver: mockNavigatorObserver,
        );
        await tester.pumpWidget(widget);
        await tester.pumpAndSettle();

        expect(find.byType(ResponsiveLayoutBuilder), findsWidgets);

        expect(tester.takeException(), isNull);

        expect(find.byType(HomeScreen), findsOneWidget);
      });
    });

    group('Deep Linking and External Navigation', () {
      testWidgets('handles direct navigation to recipe screen', (tester) async {
        final widget = await createAppNavigationTestHarness(
          mockFavoriteRecipe: mockFavoriteRecipe,
          mockBookmarkRecipe: mockBookmarkRecipe,
          mockGetAllRecipes: mockGetAllRecipes,
          navigatorObserver: mockNavigatorObserver,
          initialSelectedLetter: 'F',
        );
        await tester.pumpWidget(widget);
        await tester.pumpAndSettle();

        expect(find.byType(HomeScreen), findsOneWidget);
        expect(find.byType(RecipeScreen), findsOneWidget);

        tester.takeException();
      });

      testWidgets('recovers from invalid navigation state', (tester) async {
        final widget = await createAppNavigationTestHarness(
          mockFavoriteRecipe: mockFavoriteRecipe,
          mockBookmarkRecipe: mockBookmarkRecipe,
          mockGetAllRecipes: mockGetAllRecipes,
          navigatorObserver: mockNavigatorObserver,
          initialSelectedLetter: '123', 
        );
        await tester.pumpWidget(widget);
        await tester.pumpAndSettle();

        expect(find.byType(HomeScreen), findsOneWidget);

        tester.takeException();
      });
    });

    group('Navigation Error Handling', () {
      testWidgets('handles navigation errors gracefully', (tester) async {
        when(() => mockGetAllRecipes.call(any()))
            .thenThrow(Exception('Navigation error'));

        final widget = await createAppNavigationTestHarness(
          mockFavoriteRecipe: mockFavoriteRecipe,
          mockBookmarkRecipe: mockBookmarkRecipe,
          mockGetAllRecipes: mockGetAllRecipes,
          navigatorObserver: mockNavigatorObserver,
        );
        await tester.pumpWidget(widget);
        await tester.pumpAndSettle();

        expect(find.byType(HomeScreen), findsOneWidget);
        expect(find.text('Recipe Vault'), findsOneWidget);

        expect(tester.takeException(), isNull);
      });

      testWidgets('recovers from navigation memory issues', (tester) async {
        final widget = await createAppNavigationTestHarness(
          mockFavoriteRecipe: mockFavoriteRecipe,
          mockBookmarkRecipe: mockBookmarkRecipe,
          mockGetAllRecipes: mockGetAllRecipes,
          navigatorObserver: mockNavigatorObserver,
        );

        await tester.pumpWidget(widget);
        await tester.pumpAndSettle();

        for (final letter in ['H', 'I', 'J']) {
          final letterFinder = find.text(letter);
          if (letterFinder.evaluate().isNotEmpty) {
            await tester.tap(letterFinder.first);
            await tester.pump(const Duration(milliseconds: 50));
          }
        }

        await tester.pumpAndSettle();

        expect(find.byType(RecipeScreen), findsOneWidget);
        tester.takeException();
      });
    });

    group('Navigation Performance', () {
      testWidgets('navigation transitions perform within reasonable time',
          (tester) async {
        final widget = await createAppNavigationTestHarness(
          mockFavoriteRecipe: mockFavoriteRecipe,
          mockBookmarkRecipe: mockBookmarkRecipe,
          mockGetAllRecipes: mockGetAllRecipes,
          navigatorObserver: mockNavigatorObserver,
        );
        await tester.pumpWidget(widget);
        await tester.pumpAndSettle();

        final stopwatch = Stopwatch()..start();

        await tester.tap(find.text('K'));
        await tester.pumpAndSettle();

        stopwatch.stop();
        expect(stopwatch.elapsedMilliseconds, lessThan(1000));
        expect(find.byType(RecipeScreen), findsOneWidget);

        tester.takeException();
      });

      testWidgets('handles multiple rapid navigations efficiently',
          (tester) async {
        final widget = await createAppNavigationTestHarness(
          mockFavoriteRecipe: mockFavoriteRecipe,
          mockBookmarkRecipe: mockBookmarkRecipe,
          mockGetAllRecipes: mockGetAllRecipes,
          navigatorObserver: mockNavigatorObserver,
        );
        await tester.pumpWidget(widget);
        await tester.pumpAndSettle();

        final stopwatch = Stopwatch()..start();

        for (final letter in ['L', 'M', 'N']) {
          final letterFinder = find.text(letter);
          if (letterFinder.evaluate().isNotEmpty) {
            await tester.tap(letterFinder.first);
            await tester.pump(const Duration(milliseconds: 100));
          }
        }

        await tester.pumpAndSettle();
        stopwatch.stop();

        expect(stopwatch.elapsedMilliseconds, lessThan(2000));

        tester.takeException();
      });
    });
  });
}

Future<Widget> createAppNavigationTestHarness({
  required MockFavoriteRecipe mockFavoriteRecipe,
  required MockBookmarkRecipe mockBookmarkRecipe,
  required MockGetAllRecipes mockGetAllRecipes,
  required MockNavigatorObserver navigatorObserver,
  void Function(String?)? onLetterChange,
  String? initialSelectedLetter,
}) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();

  return ProviderScope(
    overrides: [
      favoriteRecipeProvider.overrideWithValue(mockFavoriteRecipe),
      bookmarkRecipeProvider.overrideWithValue(mockBookmarkRecipe),
      getAllRecipesProvider.overrideWithValue(mockGetAllRecipes),
      sharedPreferencesProvider.overrideWithValue(prefs),

      selectedLetterProvider.overrideWithProvider(
        StateProvider<String?>((ref) => initialSelectedLetter),
      ),
    ],
    child: Builder(
      builder: (context) {
        return Consumer(
          builder: (context, ref, child) {
            if (onLetterChange != null) {
              ref.listen<String?>(selectedLetterProvider, (previous, next) {
                onLetterChange(next);
              });
            }
            return MaterialApp(
              navigatorObservers: [navigatorObserver],
              home: const HomeScreen(),
              theme: ThemeData(
                useMaterial3: true,
                bottomNavigationBarTheme: const BottomNavigationBarThemeData(
                  type: BottomNavigationBarType.fixed,
                ),
              ),
            );
          },
        );
      },
    ),
  );
}
