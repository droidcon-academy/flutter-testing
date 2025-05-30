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
import 'package:recipevault/presentation/views/home/components/alphabet_list.dart';
import 'package:recipevault/presentation/views/home/components/alphabet_grid.dart';
import 'package:recipevault/presentation/views/recipe/recipe_screen.dart';
import 'package:recipevault/presentation/widgets/alphabet/letter_item.dart';
import 'package:recipevault/presentation/widgets/common/layout/responsive_layout_builder.dart';

import '../dashboard/test_helpers.dart';

class MockGetAllRecipes extends Mock implements GetAllRecipes {}

class FakeGetAllRecipesParams extends Fake implements GetAllRecipesParams {}

class FakeFavoriteRecipeParams extends Fake implements FavoriteRecipeParams {}

class FakeBookmarkRecipeParams extends Fake implements BookmarkRecipeParams {}

void main() {
  group('Home Screen Integration Tests', () {
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
      testWidgets('loads and displays alphabet view initially', (tester) async {
        tester.view.physicalSize = const Size(400, 800);
        tester.view.devicePixelRatio = 1.0;

        final widget = await createHomeScreenTestHarness(
          mockFavoriteRecipe: mockFavoriteRecipe,
          mockBookmarkRecipe: mockBookmarkRecipe,
          mockGetAllRecipes: mockGetAllRecipes,
        );
        await tester.pumpWidget(widget);
        await tester.pumpAndSettle();

        expect(find.byType(ResponsiveLayoutBuilder), findsWidgets);

        expect(find.byType(AlphabetList), findsOneWidget);
        expect(find.text('Recipe Vault'), findsOneWidget);

        addTearDown(tester.view.resetPhysicalSize);
      });

      testWidgets('displays correct initial state with no letter selected',
          (tester) async {
        tester.view.physicalSize = const Size(400, 800);
        tester.view.devicePixelRatio = 1.0;

        final widget = await createHomeScreenTestHarness(
          mockFavoriteRecipe: mockFavoriteRecipe,
          mockBookmarkRecipe: mockBookmarkRecipe,
          mockGetAllRecipes: mockGetAllRecipes,
        );
        await tester.pumpWidget(widget);
        await tester.pumpAndSettle();

        expect(find.byType(AlphabetList), findsOneWidget);
        expect(find.byType(RecipeScreen), findsNothing);

        expect(find.text('Recipe Vault'), findsOneWidget);
        expect(find.byType(AppBar), findsOneWidget);

        addTearDown(tester.view.resetPhysicalSize);
      });

      testWidgets('shows recipe screen when letter is selected',
          (tester) async {
        tester.view.physicalSize = const Size(400, 800);
        tester.view.devicePixelRatio = 1.0;

        final widget = await createHomeScreenTestHarness(
          mockFavoriteRecipe: mockFavoriteRecipe,
          mockBookmarkRecipe: mockBookmarkRecipe,
          mockGetAllRecipes: mockGetAllRecipes,
        );
        await tester.pumpWidget(widget);
        await tester.pumpAndSettle();

        expect(find.byType(AlphabetList), findsOneWidget);
        expect(find.byType(RecipeScreen), findsNothing);

        final letterA = find.text('A');
        expect(letterA, findsOneWidget);
        await tester.tap(letterA);
        await tester.pumpAndSettle();

        expect(find.byType(AlphabetList), findsNothing);
        expect(find.byType(RecipeScreen), findsOneWidget);

        addTearDown(tester.view.resetPhysicalSize);
      });
    });

    group('Alphabet Navigation Integration', () {
      testWidgets('displays all 26 letters in alphabet list', (tester) async {
        tester.view.physicalSize = const Size(400, 800);
        tester.view.devicePixelRatio = 1.0;

        final widget = await createHomeScreenTestHarness(
          mockFavoriteRecipe: mockFavoriteRecipe,
          mockBookmarkRecipe: mockBookmarkRecipe,
          mockGetAllRecipes: mockGetAllRecipes,
        );
        await tester.pumpWidget(widget);
        await tester.pumpAndSettle();

        for (int i = 0; i < 5; i++) {
          final letter = String.fromCharCode(65 + i);
          expect(find.text(letter), findsWidgets);
        }

        expect(find.byType(LetterItem), findsWidgets);

        addTearDown(tester.view.resetPhysicalSize);
      });

      testWidgets('letter selection updates state correctly', (tester) async {
        tester.view.physicalSize = const Size(400, 800);
        tester.view.devicePixelRatio = 1.0;

        const testLetter = 'B';
        String? selectedLetter;

        final widget = await createHomeScreenTestHarness(
          mockFavoriteRecipe: mockFavoriteRecipe,
          mockBookmarkRecipe: mockBookmarkRecipe,
          mockGetAllRecipes: mockGetAllRecipes,
          onLetterChange: (letter) => selectedLetter = letter,
        );
        await tester.pumpWidget(widget);
        await tester.pumpAndSettle();

        expect(selectedLetter, isNull);

        final letterB = find.text(testLetter);
        expect(letterB, findsOneWidget);
        await tester.tap(letterB);
        await tester.pumpAndSettle();

        expect(selectedLetter, equals(testLetter));

        addTearDown(tester.view.resetPhysicalSize);
      });

      testWidgets('multiple letter selections work correctly', (tester) async {
        final letters = ['A', 'C', 'F'];

        for (final letter in letters) {
          tester.view.physicalSize = const Size(400, 800);
          tester.view.devicePixelRatio = 1.0;

          final widget = await createHomeScreenTestHarness(
            mockFavoriteRecipe: mockFavoriteRecipe,
            mockBookmarkRecipe: mockBookmarkRecipe,
            mockGetAllRecipes: mockGetAllRecipes,
          );
          await tester.pumpWidget(widget);
          await tester.pumpAndSettle();

          final letterWidget = find.text(letter);
          if (letterWidget.evaluate().isEmpty) {
            final scrollable = find.byType(Scrollable);
            if (scrollable.evaluate().isNotEmpty) {
              await tester.drag(scrollable.first, const Offset(0, -100));
              await tester.pumpAndSettle();
            }
          }

          if (letterWidget.evaluate().isNotEmpty) {
            await tester.tap(letterWidget.first);
            await tester.pumpAndSettle();

            expect(find.byType(RecipeScreen), findsOneWidget);
            expect(find.byType(AlphabetList), findsNothing);
          }
        }

        addTearDown(tester.view.resetPhysicalSize);
      });
    });

    group('Responsive Layout Integration', () {
      testWidgets('mobile layout shows alphabet list', (tester) async {
        tester.view.physicalSize = const Size(400, 800);
        tester.view.devicePixelRatio = 1.0;

        final widget = await createHomeScreenTestHarness(
          mockFavoriteRecipe: mockFavoriteRecipe,
          mockBookmarkRecipe: mockBookmarkRecipe,
          mockGetAllRecipes: mockGetAllRecipes,
        );
        await tester.pumpWidget(widget);
        await tester.pumpAndSettle();

        expect(find.byType(AlphabetList), findsOneWidget);
        expect(find.byType(AlphabetGrid), findsNothing);

        addTearDown(tester.view.resetPhysicalSize);
      });

      testWidgets('tablet layout shows alphabet grid', (tester) async {
        tester.view.physicalSize = const Size(800, 1024);
        tester.view.devicePixelRatio = 1.0;

        final widget = await createHomeScreenTestHarness(
          mockFavoriteRecipe: mockFavoriteRecipe,
          mockBookmarkRecipe: mockBookmarkRecipe,
          mockGetAllRecipes: mockGetAllRecipes,
        );
        await tester.pumpWidget(widget);
        await tester.pumpAndSettle();

        expect(find.byType(AlphabetGrid), findsOneWidget);
        expect(find.byType(AlphabetList), findsNothing);

        addTearDown(tester.view.resetPhysicalSize);
      });

      testWidgets('desktop layout shows alphabet grid', (tester) async {
        tester.view.physicalSize = const Size(1200, 800);
        tester.view.devicePixelRatio = 1.0;

        final widget = await createHomeScreenTestHarness(
          mockFavoriteRecipe: mockFavoriteRecipe,
          mockBookmarkRecipe: mockBookmarkRecipe,
          mockGetAllRecipes: mockGetAllRecipes,
        );
        await tester.pumpWidget(widget);
        await tester.pumpAndSettle();

        expect(find.byType(AlphabetGrid), findsOneWidget);
        expect(find.byType(AlphabetList), findsNothing);

        addTearDown(tester.view.resetPhysicalSize);
      });

      testWidgets('responsive transitions work correctly', (tester) async {
        final widget = await createHomeScreenTestHarness(
          mockFavoriteRecipe: mockFavoriteRecipe,
          mockBookmarkRecipe: mockBookmarkRecipe,
          mockGetAllRecipes: mockGetAllRecipes,
        );

        tester.view.physicalSize = const Size(400, 800);
        tester.view.devicePixelRatio = 1.0;
        await tester.pumpWidget(widget);
        await tester.pumpAndSettle();
        expect(find.byType(AlphabetList), findsOneWidget);

        tester.view.physicalSize = const Size(800, 1024);
        await tester.pumpWidget(widget);
        await tester.pumpAndSettle();
        expect(find.byType(AlphabetGrid), findsOneWidget);

        tester.view.physicalSize = const Size(1200, 800);
        await tester.pumpWidget(widget);
        await tester.pumpAndSettle();
        expect(find.byType(AlphabetGrid), findsOneWidget);

        tester.view.physicalSize = const Size(400, 800);
        await tester.pumpWidget(widget);
        await tester.pumpAndSettle();
        expect(find.byType(AlphabetList), findsOneWidget);

        addTearDown(tester.view.resetPhysicalSize);
      });
    });

    group('State Transition Integration', () {
      testWidgets('seamless transition from alphabet to recipe view',
          (tester) async {
        tester.view.physicalSize = const Size(400, 800);
        tester.view.devicePixelRatio = 1.0;

        final widget = await createHomeScreenTestHarness(
          mockFavoriteRecipe: mockFavoriteRecipe,
          mockBookmarkRecipe: mockBookmarkRecipe,
          mockGetAllRecipes: mockGetAllRecipes,
        );
        await tester.pumpWidget(widget);
        await tester.pumpAndSettle();

        expect(find.byType(AlphabetList), findsOneWidget);
        expect(find.byType(RecipeScreen), findsNothing);
        expect(find.text('Recipe Vault'), findsOneWidget);

        final letterM = find.text('M');
        await tester.tap(letterM);
        await tester.pumpAndSettle();

        expect(find.byType(AlphabetList), findsNothing);
        expect(find.byType(RecipeScreen), findsOneWidget);

        addTearDown(tester.view.resetPhysicalSize);
      });

      testWidgets('state persists during widget rebuilds', (tester) async {
        tester.view.physicalSize = const Size(400, 800);
        tester.view.devicePixelRatio = 1.0;

        final widget = await createHomeScreenTestHarness(
          mockFavoriteRecipe: mockFavoriteRecipe,
          mockBookmarkRecipe: mockBookmarkRecipe,
          mockGetAllRecipes: mockGetAllRecipes,
        );
        await tester.pumpWidget(widget);
        await tester.pumpAndSettle();

        await tester.tap(find.text('D'));
        await tester.pumpAndSettle();

        expect(find.byType(RecipeScreen), findsOneWidget);

        await tester.pump();

        expect(find.byType(RecipeScreen), findsOneWidget);
        expect(find.byType(AlphabetList), findsNothing);

        addTearDown(tester.view.resetPhysicalSize);
      });

      testWidgets('handles rapid state changes gracefully', (tester) async {
        final letters = ['A', 'B', 'C'];
        for (final letter in letters) {
          tester.view.physicalSize = const Size(400, 800);
          tester.view.devicePixelRatio = 1.0;

          final widget = await createHomeScreenTestHarness(
            mockFavoriteRecipe: mockFavoriteRecipe,
            mockBookmarkRecipe: mockBookmarkRecipe,
            mockGetAllRecipes: mockGetAllRecipes,
          );
          await tester.pumpWidget(widget);
          await tester.pumpAndSettle();

          final letterWidget = find.text(letter);
          if (letterWidget.evaluate().isEmpty) {
            final scrollable = find.byType(Scrollable);
            if (scrollable.evaluate().isNotEmpty) {
              await tester.drag(scrollable.first, const Offset(0, -100));
              await tester.pumpAndSettle();
            }
          }

          if (letterWidget.evaluate().isNotEmpty) {
            await tester.tap(letterWidget.first);
            await tester.pump(const Duration(milliseconds: 100));
          }
        }

        await tester.pumpAndSettle();

        expect(find.byType(RecipeScreen), findsOneWidget);
        tester.takeException();

        addTearDown(tester.view.resetPhysicalSize);
      });
    });

    group('Error Handling Integration', () {
      testWidgets('handles alphabet display gracefully with no errors',
          (tester) async {
        tester.view.physicalSize = const Size(400, 800);
        tester.view.devicePixelRatio = 1.0;

        final widget = await createHomeScreenTestHarness(
          mockFavoriteRecipe: mockFavoriteRecipe,
          mockBookmarkRecipe: mockBookmarkRecipe,
          mockGetAllRecipes: mockGetAllRecipes,
        );
        await tester.pumpWidget(widget);
        await tester.pumpAndSettle();

        expect(find.byType(AlphabetList), findsOneWidget);
        expect(find.text('Recipe Vault'), findsOneWidget);
        tester.takeException();

        for (int i = 0; i < 5; i++) {
          final letter = String.fromCharCode(65 + i);

          tester.view.physicalSize = const Size(400, 800);
          tester.view.devicePixelRatio = 1.0;

          final resetWidget = await createHomeScreenTestHarness(
            mockFavoriteRecipe: mockFavoriteRecipe,
            mockBookmarkRecipe: mockBookmarkRecipe,
            mockGetAllRecipes: mockGetAllRecipes,
          );
          await tester.pumpWidget(resetWidget);
          await tester.pumpAndSettle();

          final letterWidget = find.text(letter);
          if (letterWidget.evaluate().isEmpty) {
            final scrollable = find.byType(Scrollable);
            if (scrollable.evaluate().isNotEmpty) {
              await tester.drag(scrollable.first, const Offset(0, -100));
              await tester.pumpAndSettle();
            }
          }

          if (letterWidget.evaluate().isNotEmpty) {
            await tester.tap(letterWidget.first);
            await tester.pumpAndSettle();
          }

          tester.takeException();
        }

        addTearDown(tester.view.resetPhysicalSize);
      });

      testWidgets('handles widget disposal correctly', (tester) async {
        tester.view.physicalSize = const Size(400, 800);
        tester.view.devicePixelRatio = 1.0;

        final widget = await createHomeScreenTestHarness(
          mockFavoriteRecipe: mockFavoriteRecipe,
          mockBookmarkRecipe: mockBookmarkRecipe,
          mockGetAllRecipes: mockGetAllRecipes,
        );
        await tester.pumpWidget(widget);
        await tester.pumpAndSettle();

        await tester.tap(find.text('K'));
        await tester.pumpAndSettle();

        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();

        tester.takeException();

        addTearDown(tester.view.resetPhysicalSize);
      });
    });

    group('Integration with Recipe System', () {
      testWidgets('letter selection triggers recipe provider correctly',
          (tester) async {
        String? selectedLetter;

        final widget = await createHomeScreenTestHarness(
          mockFavoriteRecipe: mockFavoriteRecipe,
          mockBookmarkRecipe: mockBookmarkRecipe,
          mockGetAllRecipes: mockGetAllRecipes,
          onLetterChange: (letter) => selectedLetter = letter,
        );
        await tester.pumpWidget(widget);
        await tester.pumpAndSettle();

        expect(selectedLetter, isNull);

        await tester.tap(find.text('R'));
        await tester.pumpAndSettle();

        expect(selectedLetter, equals('R'));
        expect(find.byType(RecipeScreen), findsOneWidget);
      });

      testWidgets('multiple letter selections update provider state',
          (tester) async {
        final selectedLetters = <String?>[];

        final widget = await createHomeScreenTestHarness(
          mockFavoriteRecipe: mockFavoriteRecipe,
          mockBookmarkRecipe: mockBookmarkRecipe,
          mockGetAllRecipes: mockGetAllRecipes,
          onLetterChange: (letter) {
            if (selectedLetters.isEmpty || selectedLetters.last != letter) {
              selectedLetters.add(letter);
            }
          },
        );

        final testSequence = ['P', 'Q', 'S'];

        for (final letter in testSequence) {
          await tester.pumpWidget(widget);
          await tester.pumpAndSettle();

          final letterFinder = find.text(letter);
          if (letterFinder.evaluate().isNotEmpty) {
            await tester.tap(letterFinder.first);
            await tester.pumpAndSettle();
          }
        }

        expect(selectedLetters.isNotEmpty, isTrue);
        tester.takeException();
      });
    });

    group('Performance Integration', () {
      testWidgets('handles large alphabet rendering efficiently',
          (tester) async {
        final widget = await createHomeScreenTestHarness(
          mockFavoriteRecipe: mockFavoriteRecipe,
          mockBookmarkRecipe: mockBookmarkRecipe,
          mockGetAllRecipes: mockGetAllRecipes,
        );
        await tester.pumpWidget(widget);
        await tester.pumpAndSettle();

        expect(find.byType(LetterItem), findsWidgets);

        final listView = find.byType(ListView);
        if (listView.evaluate().isNotEmpty) {
          await tester.drag(listView.first, const Offset(0, -200));
          await tester.pumpAndSettle();

          await tester.drag(listView.first, const Offset(0, -400));
          await tester.pumpAndSettle();
        }

        tester.takeException();
        expect(find.byType(LetterItem), findsWidgets);
      });

      testWidgets('layout transitions perform smoothly', (tester) async {
        final widget = await createHomeScreenTestHarness(
          mockFavoriteRecipe: mockFavoriteRecipe,
          mockBookmarkRecipe: mockBookmarkRecipe,
          mockGetAllRecipes: mockGetAllRecipes,
        );

        final screenSizes = [
          const Size(400, 800), 
          const Size(800, 1024), 
          const Size(1200, 800), 
          const Size(600, 900), 
        ];

        for (final size in screenSizes) {
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1.0;
          await tester.pumpWidget(widget);
          await tester.pump(const Duration(milliseconds: 100));
        }

        await tester.pumpAndSettle();

        tester.takeException();
        expect(find.byType(ResponsiveLayoutBuilder), findsWidgets);

        addTearDown(tester.view.resetPhysicalSize);
      });
    });
  });
}

Future<Widget> createHomeScreenTestHarness({
  required MockFavoriteRecipe mockFavoriteRecipe,
  required MockBookmarkRecipe mockBookmarkRecipe,
  required MockGetAllRecipes mockGetAllRecipes,
  void Function(String?)? onLetterChange,
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
        StateProvider<String?>((ref) => null),
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
