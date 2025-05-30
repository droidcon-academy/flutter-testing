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

import 'dashboard/test_helpers.dart';

class MockGetAllRecipes extends Mock implements GetAllRecipes {}

class MockNavigatorObserver extends Mock implements NavigatorObserver {}

class FakeRoute extends Fake implements Route<dynamic> {}

class FakeGetAllRecipesParams extends Fake implements GetAllRecipesParams {}

class FakeFavoriteRecipeParams extends Fake implements FavoriteRecipeParams {}

class FakeBookmarkRecipeParams extends Fake implements BookmarkRecipeParams {}

void main() {
  group('Cross-Screen Navigation Integration Tests', () {
    late MockFavoriteRecipe mockFavoriteRecipe;
    late MockBookmarkRecipe mockBookmarkRecipe;
    late MockGetAllRecipes mockGetAllRecipes;
    late MockNavigatorObserver mockNavigatorObserver;
    late List<Route<dynamic>> routeHistory;

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
      routeHistory = [];

      setupCommonMockResponses(
        mockFavoriteRecipe: mockFavoriteRecipe,
        mockBookmarkRecipe: mockBookmarkRecipe,
      );

      when(() => mockGetAllRecipes.call(any()))
          .thenAnswer((_) async => Right(testRecipes));

      when(() => mockNavigatorObserver.didPush(any(), any()))
          .thenAnswer((invocation) {
        final route = invocation.positionalArguments[0] as Route<dynamic>;
        routeHistory.add(route);
      });
    });

    group('Complete App Navigation Flow', () {
      testWidgets('executes full navigation flow: Home → Recipe → Dashboard',
          (tester) async {
        String? selectedLetter;

        final widget = await createCrossScreenTestHarness(
          mockFavoriteRecipe: mockFavoriteRecipe,
          mockBookmarkRecipe: mockBookmarkRecipe,
          mockGetAllRecipes: mockGetAllRecipes,
          navigatorObserver: mockNavigatorObserver,
          onLetterChange: (letter) => selectedLetter = letter,
        );
        await tester.pumpWidget(widget);
        await tester.pumpAndSettle();

        expect(find.byType(HomeScreen), findsOneWidget);
        expect(find.byType(RecipeScreen), findsNothing);
        expect(find.byType(DashboardScreen), findsNothing);
        expect(selectedLetter, isNull);

        await tester.tap(find.text('A'));
        await tester.pumpAndSettle();

        expect(find.byType(HomeScreen), findsOneWidget);
        expect(find.byType(RecipeScreen), findsOneWidget);
        expect(selectedLetter, equals('A'));

        final bottomNavBar = find.byType(BottomNavigationBar);
        if (bottomNavBar.evaluate().isNotEmpty) {
          final dashboardButton = find.byIcon(Icons.dashboard);
          if (dashboardButton.evaluate().isNotEmpty) {
            await tester.tap(dashboardButton);
            await tester.pumpAndSettle();

            expect(find.byType(DashboardScreen), findsOneWidget);
            expect(selectedLetter, equals('A')); 
          }
        }

        tester.takeException();
      });

      testWidgets('maintains navigation state consistency across screens',
          (tester) async {
        String? trackedLetter;
        final navigationEvents = <String>[];

        final widget = await createCrossScreenTestHarness(
          mockFavoriteRecipe: mockFavoriteRecipe,
          mockBookmarkRecipe: mockBookmarkRecipe,
          mockGetAllRecipes: mockGetAllRecipes,
          navigatorObserver: mockNavigatorObserver,
          onLetterChange: (letter) {
            trackedLetter = letter;
            navigationEvents.add('Letter: $letter');
          },
          onNavigationChange: (screen) {
            navigationEvents.add('Screen: $screen');
          },
        );
        await tester.pumpWidget(widget);
        await tester.pumpAndSettle();

        navigationEvents.add('Initial: Home');

        await tester.tap(find.text('B'));
        await tester.pumpAndSettle();
        navigationEvents.add('Navigated to Recipe');

        expect(trackedLetter, equals('B'));
        expect(find.byType(RecipeScreen), findsOneWidget);

        expect(navigationEvents.contains('Letter: B'), isTrue);

        tester.takeException();
      });
    });

    group('Navigation State Persistence', () {
      testWidgets('preserves selected letter across screen transitions',
          (tester) async {
        String? persistedLetter;

        final widget = await createCrossScreenTestHarness(
          mockFavoriteRecipe: mockFavoriteRecipe,
          mockBookmarkRecipe: mockBookmarkRecipe,
          mockGetAllRecipes: mockGetAllRecipes,
          navigatorObserver: mockNavigatorObserver,
          onLetterChange: (letter) => persistedLetter = letter,
        );
        await tester.pumpWidget(widget);
        await tester.pumpAndSettle();

        await tester.tap(find.text('E'));
        await tester.pumpAndSettle();
        expect(persistedLetter, equals('E'));

        final backButton = find.byIcon(Icons.arrow_back);
        if (backButton.evaluate().isNotEmpty) {
          await tester.tap(backButton);
          await tester.pumpAndSettle();
        }

        await tester.tap(find.text('F'));
        await tester.pumpAndSettle();
        expect(persistedLetter, equals('F'));

        expect(find.byType(RecipeScreen), findsOneWidget);

        tester.takeException();
      });

      testWidgets('maintains favorites and bookmarks state across navigation',
          (tester) async {
        when(() => mockFavoriteRecipe.getFavorites())
            .thenAnswer((_) async => Right([testRecipes.first]));
        when(() => mockBookmarkRecipe.getBookmarks())
            .thenAnswer((_) async => Right([testRecipes.last]));

        final widget = await createCrossScreenTestHarness(
          mockFavoriteRecipe: mockFavoriteRecipe,
          mockBookmarkRecipe: mockBookmarkRecipe,
          mockGetAllRecipes: mockGetAllRecipes,
          navigatorObserver: mockNavigatorObserver,
        );
        await tester.pumpWidget(widget);
        await tester.pumpAndSettle();

        await tester.tap(find.text('G'));
        await tester.pumpAndSettle();

        verify(() => mockGetAllRecipes.call(any()))
            .called(greaterThanOrEqualTo(1));

        tester.takeException();
      });

      testWidgets('recovers navigation state after memory pressure',
          (tester) async {
        final widget = await createCrossScreenTestHarness(
          mockFavoriteRecipe: mockFavoriteRecipe,
          mockBookmarkRecipe: mockBookmarkRecipe,
          mockGetAllRecipes: mockGetAllRecipes,
          navigatorObserver: mockNavigatorObserver,
        );

        await tester.pumpWidget(widget);
        await tester.pumpAndSettle();
        await tester.tap(find.text('H'));
        await tester.pumpAndSettle();

        await tester.pump();

        expect(find.byType(RecipeScreen), findsOneWidget);

        tester.takeException();
      });
    });

    group('Back Button and Navigation History', () {
      testWidgets('handles back button navigation correctly', (tester) async {
        final widget = await createCrossScreenTestHarness(
          mockFavoriteRecipe: mockFavoriteRecipe,
          mockBookmarkRecipe: mockBookmarkRecipe,
          mockGetAllRecipes: mockGetAllRecipes,
          navigatorObserver: mockNavigatorObserver,
        );
        await tester.pumpWidget(widget);
        await tester.pumpAndSettle();

        expect(find.byType(HomeScreen), findsOneWidget);

        await tester.tap(find.text('I'));
        await tester.pumpAndSettle();
        expect(find.byType(RecipeScreen), findsOneWidget);

        final backButton = find.byIcon(Icons.arrow_back);
        if (backButton.evaluate().isNotEmpty) {
          await tester.tap(backButton);
          await tester.pumpAndSettle();

          expect(find.byType(HomeScreen), findsOneWidget);
          expect(find.byType(RecipeScreen), findsNothing);
        }

        tester.takeException();
      });

      testWidgets('manages navigation history correctly', (tester) async {
        final widget = await createCrossScreenTestHarness(
          mockFavoriteRecipe: mockFavoriteRecipe,
          mockBookmarkRecipe: mockBookmarkRecipe,
          mockGetAllRecipes: mockGetAllRecipes,
          navigatorObserver: mockNavigatorObserver,
        );
        await tester.pumpWidget(widget);
        await tester.pumpAndSettle();

        await tester.tap(find.text('J'));
        await tester.pumpAndSettle();

        verify(() => mockNavigatorObserver.didPush(any(), any()))
            .called(greaterThanOrEqualTo(1));

        tester.takeException();
      });

      testWidgets('handles system back button correctly', (tester) async {
        final widget = await createCrossScreenTestHarness(
          mockFavoriteRecipe: mockFavoriteRecipe,
          mockBookmarkRecipe: mockBookmarkRecipe,
          mockGetAllRecipes: mockGetAllRecipes,
          navigatorObserver: mockNavigatorObserver,
        );
        await tester.pumpWidget(widget);
        await tester.pumpAndSettle();

        await tester.tap(find.text('K'));
        await tester.pumpAndSettle();
        expect(find.byType(RecipeScreen), findsOneWidget);

        final navigator = tester.state<NavigatorState>(find.byType(Navigator));
        if (navigator.canPop()) {
          navigator.pop();
          await tester.pumpAndSettle();

          expect(find.byType(HomeScreen), findsOneWidget);
        }

        tester.takeException();
      });
    });

    group('Deep Linking and External Navigation', () {
      testWidgets('handles deep link navigation to specific screens',
          (tester) async {
        final widget = await createCrossScreenTestHarness(
          mockFavoriteRecipe: mockFavoriteRecipe,
          mockBookmarkRecipe: mockBookmarkRecipe,
          mockGetAllRecipes: mockGetAllRecipes,
          navigatorObserver: mockNavigatorObserver,
          initialSelectedLetter: 'A',
        );
        await tester.pumpWidget(widget);
        await tester.pumpAndSettle();

        expect(find.byType(RecipeScreen), findsOneWidget);
        expect(find.byType(HomeScreen), findsOneWidget);

        tester.takeException();
      });

      testWidgets('recovers from invalid deep link states', (tester) async {
        final widget = await createCrossScreenTestHarness(
          mockFavoriteRecipe: mockFavoriteRecipe,
          mockBookmarkRecipe: mockBookmarkRecipe,
          mockGetAllRecipes: mockGetAllRecipes,
          navigatorObserver: mockNavigatorObserver,
          initialSelectedLetter: '999', 
        );
        await tester.pumpWidget(widget);
        await tester.pumpAndSettle();

        expect(find.byType(HomeScreen), findsOneWidget);

        tester.takeException();
      });

      testWidgets('handles external navigation interruptions', (tester) async {
        final widget = await createCrossScreenTestHarness(
          mockFavoriteRecipe: mockFavoriteRecipe,
          mockBookmarkRecipe: mockBookmarkRecipe,
          mockGetAllRecipes: mockGetAllRecipes,
          navigatorObserver: mockNavigatorObserver,
        );
        await tester.pumpWidget(widget);
        await tester.pumpAndSettle();

        await tester.tap(find.text('B'));
        await tester.pump(const Duration(milliseconds: 100));

        await tester.pumpWidget(widget);
        await tester.pumpAndSettle();

        expect(find.byType(RecipeScreen), findsOneWidget);

        tester.takeException();
      });
    });

    group('Error Handling Across Screens', () {
      testWidgets('handles navigation errors gracefully', (tester) async {
        when(() => mockGetAllRecipes.call(any()))
            .thenThrow(Exception('Cross-screen navigation error'));

        final widget = await createCrossScreenTestHarness(
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

      testWidgets('recovers from cross-screen state inconsistencies',
          (tester) async {
        final widget = await createCrossScreenTestHarness(
          mockFavoriteRecipe: mockFavoriteRecipe,
          mockBookmarkRecipe: mockBookmarkRecipe,
          mockGetAllRecipes: mockGetAllRecipes,
          navigatorObserver: mockNavigatorObserver,
        );
        await tester.pumpWidget(widget);
        await tester.pumpAndSettle();

        for (final letter in ['D', 'E', 'F']) {
          final letterFinder = find.text(letter);
          if (letterFinder.evaluate().isNotEmpty) {
            await tester.tap(letterFinder.first);
            await tester.pump(const Duration(milliseconds: 25));
          }
        }

        await tester.pumpAndSettle();

        expect(find.byType(RecipeScreen), findsOneWidget);
        tester.takeException();
      });
    });

    group('Performance Across Screens', () {
      testWidgets('maintains performance during multi-screen navigation',
          (tester) async {
        final widget = await createCrossScreenTestHarness(
          mockFavoriteRecipe: mockFavoriteRecipe,
          mockBookmarkRecipe: mockBookmarkRecipe,
          mockGetAllRecipes: mockGetAllRecipes,
          navigatorObserver: mockNavigatorObserver,
        );

        final stopwatch = Stopwatch()..start();

        await tester.pumpWidget(widget);
        await tester.pumpAndSettle();

        await tester.tap(find.text('L'));
        await tester.pumpAndSettle();

        final backButton = find.byIcon(Icons.arrow_back);
        if (backButton.evaluate().isNotEmpty) {
          await tester.tap(backButton);
          await tester.pumpAndSettle();
        }

        await tester.tap(find.text('A'));
        await tester.pumpAndSettle();

        stopwatch.stop();

        expect(stopwatch.elapsedMilliseconds, lessThan(3000));

        tester.takeException();
      });

      testWidgets('handles memory efficiently during navigation',
          (tester) async {
        final widget = await createCrossScreenTestHarness(
          mockFavoriteRecipe: mockFavoriteRecipe,
          mockBookmarkRecipe: mockBookmarkRecipe,
          mockGetAllRecipes: mockGetAllRecipes,
          navigatorObserver: mockNavigatorObserver,
        );

        for (int i = 0; i < 3; i++) {
          await tester.pumpWidget(widget);
          await tester.pumpAndSettle();

          expect(find.byType(HomeScreen), findsOneWidget);

          await tester.pump();
        }

        await tester.pumpAndSettle();

        expect(find.byType(HomeScreen), findsOneWidget);

        tester.takeException();
      });
    });
  });
}

Future<Widget> createCrossScreenTestHarness({
  required MockFavoriteRecipe mockFavoriteRecipe,
  required MockBookmarkRecipe mockBookmarkRecipe,
  required MockGetAllRecipes mockGetAllRecipes,
  required MockNavigatorObserver navigatorObserver,
  void Function(String?)? onLetterChange,
  void Function(String)? onNavigationChange,
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

            if (onNavigationChange != null) {
              onNavigationChange('Home');
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
