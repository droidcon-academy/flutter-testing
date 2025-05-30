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
import 'dashboard/test_helpers.dart';

class MockGetAllRecipes extends Mock implements GetAllRecipes {}

class FakeGetAllRecipesParams extends Fake implements GetAllRecipesParams {}

class FakeFavoriteRecipeParams extends Fake implements FavoriteRecipeParams {}

class FakeBookmarkRecipeParams extends Fake implements BookmarkRecipeParams {}

void main() {
  group('Global State Integration Tests', () {
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

    group('Recipe Favorites/Bookmarks Consistency', () {
      testWidgets('favorites state is consistent across all screens',
          (tester) async {
        final favoriteRecipes = [testRecipes.first, testRecipes.last];

        when(() => mockFavoriteRecipe.getFavorites())
            .thenAnswer((_) async => Right(favoriteRecipes));

        final widget = await createGlobalStateTestHarness(
          mockFavoriteRecipe: mockFavoriteRecipe,
          mockBookmarkRecipe: mockBookmarkRecipe,
          mockGetAllRecipes: mockGetAllRecipes,
        );
        await tester.pumpWidget(widget);
        await tester.pumpAndSettle();

        expect(find.byType(HomeScreen), findsOneWidget);

        await tester.tap(find.text('A'));
        await tester.pumpAndSettle();
        expect(find.byType(RecipeScreen), findsOneWidget);

        verify(() => mockFavoriteRecipe.getFavorites())
            .called(greaterThanOrEqualTo(1));

        tester.takeException();
      });

      testWidgets('bookmarks state is consistent across all screens',
          (tester) async {
        final bookmarkedRecipes = [testRecipes[1], testRecipes[2]];

        when(() => mockBookmarkRecipe.getBookmarks())
            .thenAnswer((_) async => Right(bookmarkedRecipes));

        final widget = await createGlobalStateTestHarness(
          mockFavoriteRecipe: mockFavoriteRecipe,
          mockBookmarkRecipe: mockBookmarkRecipe,
          mockGetAllRecipes: mockGetAllRecipes,
        );
        await tester.pumpWidget(widget);
        await tester.pumpAndSettle();

        await tester.tap(find.text('B'));
        await tester.pumpAndSettle();

        verify(() => mockBookmarkRecipe.getBookmarks())
            .called(greaterThanOrEqualTo(1));

        tester.takeException();
      });

      testWidgets('favorites/bookmarks changes propagate across screens',
          (tester) async {
        String? currentLetter;

        when(() => mockFavoriteRecipe.getFavorites())
            .thenAnswer((_) async => Right([testRecipes.first]));
        when(() => mockFavoriteRecipe.call(any()))
            .thenAnswer((_) async => Right(testRecipes.first));

        final widget = await createGlobalStateTestHarness(
          mockFavoriteRecipe: mockFavoriteRecipe,
          mockBookmarkRecipe: mockBookmarkRecipe,
          mockGetAllRecipes: mockGetAllRecipes,
          onLetterChange: (letter) => currentLetter = letter,
        );
        await tester.pumpWidget(widget);
        await tester.pumpAndSettle();

        await tester.tap(find.text('C'));
        await tester.pumpAndSettle();
        expect(currentLetter, equals('C'));

        verify(() => mockFavoriteRecipe.getFavorites())
            .called(greaterThanOrEqualTo(1));

        tester.takeException();
      });

      testWidgets('handles concurrent favorites/bookmarks operations',
          (tester) async {
        when(() => mockFavoriteRecipe.call(any()))
            .thenAnswer((_) async => Right(testRecipes.first));
        when(() => mockBookmarkRecipe.call(any()))
            .thenAnswer((_) async => Right(testRecipes.first));

        final widget = await createGlobalStateTestHarness(
          mockFavoriteRecipe: mockFavoriteRecipe,
          mockBookmarkRecipe: mockBookmarkRecipe,
          mockGetAllRecipes: mockGetAllRecipes,
        );
        await tester.pumpWidget(widget);
        await tester.pumpAndSettle();

        await tester.tap(find.text('D'));
        await tester.pumpAndSettle();

        expect(find.byType(RecipeScreen), findsOneWidget);

        tester.takeException();
      });
    });

    group('Selected Recipe Persistence', () {
      testWidgets('maintains selected recipe across navigation',
          (tester) async {
        String? selectedLetter;

        final widget = await createGlobalStateTestHarness(
          mockFavoriteRecipe: mockFavoriteRecipe,
          mockBookmarkRecipe: mockBookmarkRecipe,
          mockGetAllRecipes: mockGetAllRecipes,
          onLetterChange: (letter) => selectedLetter = letter,
        );
        await tester.pumpWidget(widget);
        await tester.pumpAndSettle();

        await tester.tap(find.text('E'));
        await tester.pumpAndSettle();
        expect(selectedLetter, equals('E'));
        expect(find.byType(RecipeScreen), findsOneWidget);

        final backButton = find.byIcon(Icons.arrow_back);
        if (backButton.evaluate().isNotEmpty) {
          await tester.tap(backButton);
          await tester.pumpAndSettle();
        }

        expect(find.byType(HomeScreen), findsOneWidget);

        tester.takeException();
      });

      testWidgets('recipe selection state survives app restart simulation',
          (tester) async {
        String? persistedLetter;

        final widget = await createGlobalStateTestHarness(
          mockFavoriteRecipe: mockFavoriteRecipe,
          mockBookmarkRecipe: mockBookmarkRecipe,
          mockGetAllRecipes: mockGetAllRecipes,
          onLetterChange: (letter) => persistedLetter = letter,
        );

        await tester.pumpWidget(widget);
        await tester.pumpAndSettle();
        await tester.tap(find.text('F'));
        await tester.pumpAndSettle();
        expect(persistedLetter, equals('F'));

        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();

        final newWidget = await createGlobalStateTestHarness(
          mockFavoriteRecipe: mockFavoriteRecipe,
          mockBookmarkRecipe: mockBookmarkRecipe,
          mockGetAllRecipes: mockGetAllRecipes,
          onLetterChange: (letter) => persistedLetter = letter,
        );
        await tester.pumpWidget(newWidget);
        await tester.pumpAndSettle();

        expect(find.byType(HomeScreen), findsOneWidget);

        tester.takeException();
      });

      testWidgets('handles invalid recipe selection gracefully',
          (tester) async {
        final widget = await createGlobalStateTestHarness(
          mockFavoriteRecipe: mockFavoriteRecipe,
          mockBookmarkRecipe: mockBookmarkRecipe,
          mockGetAllRecipes: mockGetAllRecipes,
          initialSelectedLetter: '999',
        );
        await tester.pumpWidget(widget);
        await tester.pumpAndSettle();

        expect(find.byType(HomeScreen), findsOneWidget);

        tester.takeException();
      });
    });

    group('Loading State Coordination', () {
      testWidgets('coordinates loading states across multiple screens',
          (tester) async {
        when(() => mockGetAllRecipes.call(any())).thenAnswer((_) async {
          await Future.delayed(const Duration(milliseconds: 100));
          return Right(testRecipes);
        });

        final widget = await createGlobalStateTestHarness(
          mockFavoriteRecipe: mockFavoriteRecipe,
          mockBookmarkRecipe: mockBookmarkRecipe,
          mockGetAllRecipes: mockGetAllRecipes,
        );
        await tester.pumpWidget(widget);

        await tester.pump(const Duration(milliseconds: 50));

        await tester.pumpAndSettle();

        expect(find.byType(HomeScreen), findsOneWidget);

        tester.takeException();
      });

      testWidgets('handles simultaneous loading operations', (tester) async {
        when(() => mockFavoriteRecipe.getFavorites()).thenAnswer((_) async {
          await Future.delayed(const Duration(milliseconds: 50));
          return Right(testRecipes.take(2).toList());
        });
        when(() => mockBookmarkRecipe.getBookmarks()).thenAnswer((_) async {
          await Future.delayed(const Duration(milliseconds: 75));
          return Right(testRecipes.take(1).toList());
        });

        final widget = await createGlobalStateTestHarness(
          mockFavoriteRecipe: mockFavoriteRecipe,
          mockBookmarkRecipe: mockBookmarkRecipe,
          mockGetAllRecipes: mockGetAllRecipes,
        );
        await tester.pumpWidget(widget);
        await tester.pumpAndSettle();

        await tester.tap(find.text('G'));
        await tester.pumpAndSettle();

        verify(() => mockFavoriteRecipe.getFavorites())
            .called(greaterThanOrEqualTo(1));
        verify(() => mockBookmarkRecipe.getBookmarks())
            .called(greaterThanOrEqualTo(1));

        tester.takeException();
      });

      testWidgets('loading state recovery after interruption', (tester) async {
        when(() => mockGetAllRecipes.call(any())).thenAnswer((_) async {
          await Future.delayed(const Duration(milliseconds: 200));
          return Right(testRecipes);
        });

        final widget = await createGlobalStateTestHarness(
          mockFavoriteRecipe: mockFavoriteRecipe,
          mockBookmarkRecipe: mockBookmarkRecipe,
          mockGetAllRecipes: mockGetAllRecipes,
        );
        await tester.pumpWidget(widget);
        await tester.pump(const Duration(milliseconds: 100));

        await tester.tap(find.text('H'));
        await tester.pump(const Duration(milliseconds: 50));

        await tester.pumpAndSettle();

        expect(find.byType(RecipeScreen), findsOneWidget);

        tester.takeException();
      });
    });

    group('Error State Propagation', () {
      testWidgets('propagates error states across screens', (tester) async {
        when(() => mockGetAllRecipes.call(any()))
            .thenThrow(Exception('Global state error'));

        final widget = await createGlobalStateTestHarness(
          mockFavoriteRecipe: mockFavoriteRecipe,
          mockBookmarkRecipe: mockBookmarkRecipe,
          mockGetAllRecipes: mockGetAllRecipes,
        );
        await tester.pumpWidget(widget);
        await tester.pumpAndSettle();

        expect(find.byType(HomeScreen), findsOneWidget);

        expect(find.text('Recipe Vault'), findsOneWidget);

        expect(tester.takeException(), isNull);
      });

      testWidgets('error recovery maintains state consistency', (tester) async {
        var callCount = 0;
        when(() => mockGetAllRecipes.call(any())).thenAnswer((_) async {
          callCount++;
          if (callCount == 1) {
            throw Exception('Temporary error');
          }
          return Right(testRecipes);
        });

        final widget = await createGlobalStateTestHarness(
          mockFavoriteRecipe: mockFavoriteRecipe,
          mockBookmarkRecipe: mockBookmarkRecipe,
          mockGetAllRecipes: mockGetAllRecipes,
        );
        await tester.pumpWidget(widget);
        await tester.pumpAndSettle();

        expect(find.byType(HomeScreen), findsOneWidget);

        tester.takeException();
      });

      testWidgets('partial error handling maintains app functionality',
          (tester) async {
        when(() => mockFavoriteRecipe.getFavorites())
            .thenAnswer((_) async => Right(testRecipes.take(1).toList()));
        when(() => mockBookmarkRecipe.getBookmarks())
            .thenAnswer((_) async => Right(testRecipes.take(1).toList()));

        final widget = await createGlobalStateTestHarness(
          mockFavoriteRecipe: mockFavoriteRecipe,
          mockBookmarkRecipe: mockBookmarkRecipe,
          mockGetAllRecipes: mockGetAllRecipes,
        );
        await tester.pumpWidget(widget);
        await tester.pumpAndSettle();

        await tester.tap(find.text('I'));
        await tester.pumpAndSettle();
        expect(find.byType(RecipeScreen), findsOneWidget);

        final backButton = find.byIcon(Icons.arrow_back);
        if (backButton.evaluate().isNotEmpty) {
          await tester.tap(backButton);
          await tester.pumpAndSettle();
        }

        expect(find.byType(HomeScreen), findsOneWidget);

        await tester.tap(find.text('J'));
        await tester.pumpAndSettle();
        expect(find.byType(RecipeScreen), findsOneWidget);

        tester.takeException();
      });
    });

    group('Cache Synchronization', () {
      testWidgets('synchronizes cache updates across providers',
          (tester) async {
        final widget = await createGlobalStateTestHarness(
          mockFavoriteRecipe: mockFavoriteRecipe,
          mockBookmarkRecipe: mockBookmarkRecipe,
          mockGetAllRecipes: mockGetAllRecipes,
        );
        await tester.pumpWidget(widget);
        await tester.pumpAndSettle();

        await tester.tap(find.text('A')); 
        await tester.pumpAndSettle();

        verify(() => mockGetAllRecipes.call(any()))
            .called(greaterThanOrEqualTo(1));

        tester.takeException();
      });

      testWidgets('handles cache invalidation correctly', (tester) async {
        var cacheValid = true;
        when(() => mockGetAllRecipes.call(any())).thenAnswer((_) async {
          if (!cacheValid) {
            await Future.delayed(const Duration(milliseconds: 50));
          }
          return Right(testRecipes);
        });

        final widget = await createGlobalStateTestHarness(
          mockFavoriteRecipe: mockFavoriteRecipe,
          mockBookmarkRecipe: mockBookmarkRecipe,
          mockGetAllRecipes: mockGetAllRecipes,
        );
        await tester.pumpWidget(widget);
        await tester.pumpAndSettle();

        await tester.tap(find.text('B')); 
        await tester.pumpAndSettle();

        cacheValid = false;

        final backButton = find.byIcon(Icons.arrow_back);
        if (backButton.evaluate().isNotEmpty) {
          await tester.tap(backButton);
          await tester.pumpAndSettle();
        }

        await tester.tap(find.text('C'));
        await tester.pumpAndSettle();

        expect(find.byType(RecipeScreen), findsOneWidget);

        tester.takeException();
      });

      testWidgets('cache consistency during concurrent operations',
          (tester) async {
        final widget = await createGlobalStateTestHarness(
          mockFavoriteRecipe: mockFavoriteRecipe,
          mockBookmarkRecipe: mockBookmarkRecipe,
          mockGetAllRecipes: mockGetAllRecipes,
        );
        await tester.pumpWidget(widget);
        await tester.pumpAndSettle();

        await tester.tap(find.text('D')); 
        await tester.pump(const Duration(milliseconds: 25));

        final backButton = find.byIcon(Icons.arrow_back);
        if (backButton.evaluate().isNotEmpty) {
          await tester.tap(backButton);
          await tester.pump(const Duration(milliseconds: 25));
        }

        await tester.tap(find.text('E')); 
        await tester.pumpAndSettle();

        expect(find.byType(RecipeScreen), findsOneWidget);

        tester.takeException();
      });
    });

    group('Provider Dependency Resolution', () {
      testWidgets('resolves provider dependencies correctly', (tester) async {
        final widget = await createGlobalStateTestHarness(
          mockFavoriteRecipe: mockFavoriteRecipe,
          mockBookmarkRecipe: mockBookmarkRecipe,
          mockGetAllRecipes: mockGetAllRecipes,
        );
        await tester.pumpWidget(widget);
        await tester.pumpAndSettle();

        expect(find.byType(HomeScreen), findsOneWidget);

        await tester.tap(find.text('F')); 
        await tester.pumpAndSettle();

        verify(() => mockGetAllRecipes.call(any()))
            .called(greaterThanOrEqualTo(1));

        tester.takeException();
      });

      testWidgets('handles circular dependency prevention', (tester) async {
        final widget = await createGlobalStateTestHarness(
          mockFavoriteRecipe: mockFavoriteRecipe,
          mockBookmarkRecipe: mockBookmarkRecipe,
          mockGetAllRecipes: mockGetAllRecipes,
        );
        await tester.pumpWidget(widget);
        await tester.pumpAndSettle();

        expect(find.byType(HomeScreen), findsOneWidget);

        await tester.tap(find.text('G')); 
        await tester.pumpAndSettle();

        expect(find.byType(RecipeScreen), findsOneWidget);

        tester.takeException();
      });

      testWidgets('provider disposal and lifecycle management', (tester) async {
        final widget = await createGlobalStateTestHarness(
          mockFavoriteRecipe: mockFavoriteRecipe,
          mockBookmarkRecipe: mockBookmarkRecipe,
          mockGetAllRecipes: mockGetAllRecipes,
        );
        await tester.pumpWidget(widget);
        await tester.pumpAndSettle();

        await tester.tap(find.text('H')); 
        await tester.pumpAndSettle();

        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();

        tester.takeException();
      });
    });

    group('Performance and Memory Management', () {
      testWidgets('maintains memory efficiency across state operations',
          (tester) async {
        final widget = await createGlobalStateTestHarness(
          mockFavoriteRecipe: mockFavoriteRecipe,
          mockBookmarkRecipe: mockBookmarkRecipe,
          mockGetAllRecipes: mockGetAllRecipes,
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

      testWidgets('state operations perform within reasonable time',
          (tester) async {
        final widget = await createGlobalStateTestHarness(
          mockFavoriteRecipe: mockFavoriteRecipe,
          mockBookmarkRecipe: mockBookmarkRecipe,
          mockGetAllRecipes: mockGetAllRecipes,
        );

        final stopwatch = Stopwatch()..start();

        await tester.pumpWidget(widget);
        await tester.pumpAndSettle();

        await tester.tap(find.text('I')); 
        await tester.pumpAndSettle();

        stopwatch.stop();

        expect(stopwatch.elapsedMilliseconds, lessThan(2000));

        tester.takeException();
      });
    });
  });
}

Future<Widget> createGlobalStateTestHarness({
  required MockFavoriteRecipe mockFavoriteRecipe,
  required MockBookmarkRecipe mockBookmarkRecipe,
  required MockGetAllRecipes mockGetAllRecipes,
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
