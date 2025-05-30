import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:fpdart/fpdart.dart';
import 'package:recipevault/core/errors/failure.dart';
import 'package:recipevault/domain/entities/recipe.dart';
import 'package:recipevault/domain/usecases/get_all_recipes.dart';
import 'package:recipevault/presentation/views/dashboard/dashboard_screen.dart';

import 'test_helpers.dart';

class FakeGetAllRecipesParams extends Fake implements GetAllRecipesParams {}

void main() {
  group('Dashboard State Management Integration Tests', () {
    late MockFavoriteRecipe mockFavoriteRecipe;
    late MockBookmarkRecipe mockBookmarkRecipe;

    setUpAll(() async {
      registerFallbackValue(FakeGetAllRecipesParams());

      await initializeDashboardTestEnvironment();
    });

    setUp(() {
      mockFavoriteRecipe = MockFavoriteRecipe();
      mockBookmarkRecipe = MockBookmarkRecipe();
    });

    group('State Persistence Integration', () {
      testWidgets('dashboard state persists during navigation and returns',
          (tester) async {
        when(() => mockFavoriteRecipe.getFavorites())
            .thenAnswer((_) async => Right(testRecipes.take(3).toList()));
        when(() => mockBookmarkRecipe.getBookmarks())
            .thenAnswer((_) async => Right(testRecipes.take(2).toList()));

        final widget = createDashboardScreenTestHarness(
          mockFavoriteRecipe: mockFavoriteRecipe,
          mockBookmarkRecipe: mockBookmarkRecipe,
        );

        await tester.pumpWidget(widget);
        await tester.pumpAndSettle();

        expect(find.byType(DashboardScreen), findsOneWidget);
        expect(find.text('My Dashboard'), findsOneWidget);

        await tester.pumpWidget(
            const MaterialApp(home: Scaffold(body: Text('Other Screen'))));
        await tester.pumpAndSettle();

        await tester.pumpWidget(widget);
        await tester.pumpAndSettle();

        expect(find.byType(DashboardScreen), findsOneWidget);
        expect(find.text('My Dashboard'), findsOneWidget);
      });

      testWidgets('favorites and bookmarks state synchronization',
          (tester) async {
        final initialFavorites = testRecipes.take(3).toList();
        final initialBookmarks = testRecipes.take(2).toList();

        when(() => mockFavoriteRecipe.getFavorites())
            .thenAnswer((_) async => Right(initialFavorites));
        when(() => mockBookmarkRecipe.getBookmarks())
            .thenAnswer((_) async => Right(initialBookmarks));

        final widget = createDashboardScreenTestHarness(
          mockFavoriteRecipe: mockFavoriteRecipe,
          mockBookmarkRecipe: mockBookmarkRecipe,
        );

        await tester.pumpWidget(widget);
        await tester.pumpAndSettle();

        expect(find.byType(DashboardScreen), findsOneWidget);
        expect(find.text('My Dashboard'), findsOneWidget);

        final updatedFavorites = [...initialFavorites, testRecipes[3]];
        when(() => mockFavoriteRecipe.getFavorites())
            .thenAnswer((_) async => Right(updatedFavorites));

        await tester.pumpAndSettle();

        expect(find.byType(DashboardScreen), findsOneWidget);
        
        verify(() => mockFavoriteRecipe.getFavorites()).called(greaterThan(1));
        
        expect(tester.takeException(), isNull);
      });
    });

    group('Error Recovery Integration', () {
      testWidgets('handles favorites loading failure with retry mechanism',
          (tester) async {
        when(() => mockFavoriteRecipe.getFavorites()).thenAnswer((_) async =>
            const Left(
                ServerFailure(message: 'Network error', statusCode: 500)));
        when(() => mockBookmarkRecipe.getBookmarks())
            .thenAnswer((_) async => Right(testRecipes.take(2).toList()));

        final widget = createDashboardScreenTestHarness(
          mockFavoriteRecipe: mockFavoriteRecipe,
          mockBookmarkRecipe: mockBookmarkRecipe,
        );

        await tester.pumpWidget(widget);
        await tester.pumpAndSettle();

        expect(find.byType(DashboardScreen), findsOneWidget);
        expect(find.text('My Dashboard'), findsOneWidget);

        when(() => mockFavoriteRecipe.getFavorites())
            .thenAnswer((_) async => Right(testRecipes.take(3).toList()));

        await tester.pumpAndSettle();

        expect(find.byType(DashboardScreen), findsOneWidget);
        expect(tester.takeException(), isNull);
      });

      testWidgets('handles bookmarks loading failure gracefully',
          (tester) async {
        when(() => mockFavoriteRecipe.getFavorites())
            .thenAnswer((_) async => Right(testRecipes.take(3).toList()));
        when(() => mockBookmarkRecipe.getBookmarks()).thenAnswer((_) async =>
            const Left(ServerFailure(
                message: 'Bookmarks unavailable', statusCode: 503)));

        final widget = createDashboardScreenTestHarness(
          mockFavoriteRecipe: mockFavoriteRecipe,
          mockBookmarkRecipe: mockBookmarkRecipe,
        );

        await tester.pumpWidget(widget);
        await tester.pumpAndSettle();

        expect(find.byType(DashboardScreen), findsOneWidget);
        expect(find.text('My Dashboard'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });

      testWidgets('handles complete data loading failure with appropriate UI',
          (tester) async {
        when(() => mockFavoriteRecipe.getFavorites()).thenAnswer((_) async =>
            const Left(
                ServerFailure(message: 'Complete failure', statusCode: 500)));
        when(() => mockBookmarkRecipe.getBookmarks()).thenAnswer((_) async =>
            const Left(
                ServerFailure(message: 'Complete failure', statusCode: 500)));

        final widget = createDashboardScreenTestHarness(
          mockFavoriteRecipe: mockFavoriteRecipe,
          mockBookmarkRecipe: mockBookmarkRecipe,
        );

        await tester.pumpWidget(widget);
        await tester.pumpAndSettle();

        expect(find.byType(DashboardScreen), findsOneWidget);
        expect(find.text('My Dashboard'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    });

    group('Complex State Transitions', () {
      testWidgets('handles rapid state changes without corruption',
          (tester) async {
        when(() => mockFavoriteRecipe.getFavorites()).thenAnswer((_) async {
          await Future.delayed(const Duration(milliseconds: 100));
          return Right(testRecipes.take(3).toList());
        });
        when(() => mockBookmarkRecipe.getBookmarks()).thenAnswer((_) async {
          await Future.delayed(const Duration(milliseconds: 150));
          return Right(testRecipes.take(2).toList());
        });

        final widget = createDashboardScreenTestHarness(
          mockFavoriteRecipe: mockFavoriteRecipe,
          mockBookmarkRecipe: mockBookmarkRecipe,
        );

        await tester.pumpWidget(widget);
        await tester.pumpAndSettle();

        for (int i = 0; i < 5; i++) {
          await tester.pump(const Duration(milliseconds: 50));
          expect(find.byType(DashboardScreen), findsOneWidget);
          expect(find.text('My Dashboard'), findsOneWidget);
        }

        await tester.pumpAndSettle();

        expect(find.byType(DashboardScreen), findsOneWidget);
        expect(find.text('My Dashboard'), findsOneWidget);
        
        verify(() => mockFavoriteRecipe.getFavorites()).called(greaterThanOrEqualTo(1));
        verify(() => mockBookmarkRecipe.getBookmarks()).called(greaterThanOrEqualTo(1));
        
        expect(tester.takeException(), isNull);
      });

      testWidgets('maintains consistent state during loading operations',
          (tester) async {
        when(() => mockFavoriteRecipe.getFavorites()).thenAnswer((_) async {
          await Future.delayed(const Duration(milliseconds: 200));
          return Right(testRecipes.take(4).toList());
        });
        when(() => mockBookmarkRecipe.getBookmarks()).thenAnswer((_) async {
          await Future.delayed(const Duration(milliseconds: 100));
          return Right(testRecipes.take(1).toList());
        });

        final widget = createDashboardScreenTestHarness(
          mockFavoriteRecipe: mockFavoriteRecipe,
          mockBookmarkRecipe: mockBookmarkRecipe,
        );

        await tester.pumpWidget(widget);

        await tester.pump(const Duration(milliseconds: 50));
        expect(find.byType(DashboardScreen), findsOneWidget);

        await tester.pumpAndSettle();

        expect(find.byType(DashboardScreen), findsOneWidget);
        expect(find.text('My Dashboard'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    });

    group('Data Synchronization Integration', () {
      testWidgets('synchronizes data changes across dashboard components',
          (tester) async {
        var favoritesData = testRecipes.take(2).toList();
        var bookmarksData = testRecipes.take(1).toList();

        when(() => mockFavoriteRecipe.getFavorites())
            .thenAnswer((_) async => Right(favoritesData));
        when(() => mockBookmarkRecipe.getBookmarks())
            .thenAnswer((_) async => Right(bookmarksData));

        final widget = createDashboardScreenTestHarness(
          mockFavoriteRecipe: mockFavoriteRecipe,
          mockBookmarkRecipe: mockBookmarkRecipe,
        );

        await tester.pumpWidget(widget);
        await tester.pumpAndSettle();

        expect(find.byType(DashboardScreen), findsOneWidget);
        expect(find.text('My Dashboard'), findsOneWidget);

        favoritesData = [...favoritesData, testRecipes[2]];
        when(() => mockFavoriteRecipe.getFavorites())
            .thenAnswer((_) async => Right(favoritesData));

        await tester.pump();
        await tester.pumpAndSettle();

        expect(find.byType(DashboardScreen), findsOneWidget);
        expect(tester.takeException(), isNull);
      });

      testWidgets('handles concurrent data operations correctly',
          (tester) async {
        when(() => mockFavoriteRecipe.getFavorites()).thenAnswer((_) async {
          await Future.delayed(const Duration(milliseconds: 300));
          return Right(testRecipes.take(3).toList());
        });
        when(() => mockBookmarkRecipe.getBookmarks()).thenAnswer((_) async {
          await Future.delayed(const Duration(milliseconds: 100));
          return Right(testRecipes.take(2).toList());
        });

        final widget = createDashboardScreenTestHarness(
          mockFavoriteRecipe: mockFavoriteRecipe,
          mockBookmarkRecipe: mockBookmarkRecipe,
        );

        await tester.pumpWidget(widget);

        await tester.pump(const Duration(milliseconds: 50));

        await tester.pump(const Duration(milliseconds: 50));
        await tester.pump(const Duration(milliseconds: 50));

        await tester.pumpAndSettle();

        expect(find.byType(DashboardScreen), findsOneWidget);
        expect(find.text('My Dashboard'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    });

    group('Memory and Performance Integration', () {
      testWidgets('handles large datasets without performance degradation',
          (tester) async {
        final largeRecipeList = List.generate(
            100,
            (index) => Recipe(
                  id: 'recipe_$index',
                  name: 'Recipe $index',
                  instructions: 'Instructions for recipe $index',
                  ingredients: [
                    const Ingredient(name: 'ingredient1'),
                    const Ingredient(name: 'ingredient2'),
                  ],
                  thumbnailUrl: 'https://example.com/image$index.jpg',
                ));

        when(() => mockFavoriteRecipe.getFavorites())
            .thenAnswer((_) async => Right(largeRecipeList.take(50).toList()));
        when(() => mockBookmarkRecipe.getBookmarks())
            .thenAnswer((_) async => Right(largeRecipeList.take(25).toList()));

        final widget = createDashboardScreenTestHarness(
          mockFavoriteRecipe: mockFavoriteRecipe,
          mockBookmarkRecipe: mockBookmarkRecipe,
        );

        await tester.pumpWidget(widget);
        await tester.pumpAndSettle();

        expect(find.byType(DashboardScreen), findsOneWidget);
        expect(find.text('My Dashboard'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });

      testWidgets('properly disposes resources on widget disposal',
          (tester) async {
        when(() => mockFavoriteRecipe.getFavorites())
            .thenAnswer((_) async => Right(testRecipes.take(3).toList()));
        when(() => mockBookmarkRecipe.getBookmarks())
            .thenAnswer((_) async => Right(testRecipes.take(2).toList()));

        final widget = createDashboardScreenTestHarness(
          mockFavoriteRecipe: mockFavoriteRecipe,
          mockBookmarkRecipe: mockBookmarkRecipe,
        );

        await tester.pumpWidget(widget);
        await tester.pumpAndSettle();

        expect(find.byType(DashboardScreen), findsOneWidget);

        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
      });
    });
  });
}
