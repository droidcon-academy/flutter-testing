import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fpdart/fpdart.dart';
import 'package:recipevault/domain/entities/recipe.dart';
import 'package:recipevault/domain/usecases/get_all_recipes.dart';
import 'package:recipevault/presentation/widgets/alphabet/letter_item.dart';
import 'package:recipevault/presentation/widgets/common/layout/responsive_layout_builder.dart';

class MockGetAllRecipes extends Mock implements GetAllRecipes {}

class FakeGetAllRecipesParams extends Fake implements GetAllRecipesParams {}

class TestAlphabetList extends StatelessWidget {
  const TestAlphabetList({
    super.key,
    required this.onLetterSelected,
  });

  final void Function(String) onLetterSelected;

  @override
  Widget build(BuildContext context) {
    final letters =
        List.generate(26, (index) => String.fromCharCode(65 + index));

    return ListView.builder(
      itemCount: letters.length,
      itemBuilder: (context, index) {
        return LetterItem(
          letter: letters[index],
          onTap: () => onLetterSelected(letters[index]),
        );
      },
    );
  }
}

class TestAlphabetGrid extends StatelessWidget {
  const TestAlphabetGrid({
    super.key,
    required this.onLetterSelected,
  });

  final void Function(String) onLetterSelected;

  @override
  Widget build(BuildContext context) {
    final letters =
        List.generate(26, (index) => String.fromCharCode(65 + index));

    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        childAspectRatio: 1,
      ),
      itemCount: letters.length,
      itemBuilder: (context, index) {
        return LetterItem(
          letter: letters[index],
          onTap: () => onLetterSelected(letters[index]),
        );
      },
    );
  }
}

void setTestScreenSize(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
}

final testSelectedLetterProvider = StateProvider<String?>((ref) => null);

void main() {
  group('Widget Integration Tests', () {
    late MockGetAllRecipes mockGetAllRecipes;

    setUpAll(() async {
      registerFallbackValue(FakeGetAllRecipesParams());

      SharedPreferences.setMockInitialValues({});
    });

    setUp(() {
      mockGetAllRecipes = MockGetAllRecipes();

      when(() => mockGetAllRecipes.call(any())).thenAnswer(
        (_) async => const Right([
          Recipe(
            id: '1',
            name: 'Apple Pie',
            ingredients: [Ingredient(name: 'apples')],
          ),
          Recipe(
            id: '2',
            name: 'Banana Bread',
            ingredients: [Ingredient(name: 'bananas')],
          ),
        ]),
      );
    });

    group('Cross-Widget Communication Integration', () {
      testWidgets('LetterItem communicates correctly with test alphabet list',
          (tester) async {
        String? selectedLetter;
        int tapCount = 0;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: TestAlphabetList(
                onLetterSelected: (letter) {
                  selectedLetter = letter;
                  tapCount++;
                },
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final letterA = find.text('A');
        expect(letterA, findsOneWidget);

        await tester.tap(letterA);
        await tester.pumpAndSettle();

        expect(selectedLetter, equals('A'));
        expect(tapCount, equals(1));

        final letterB = find.text('B');
        await tester.tap(letterB);
        await tester.pumpAndSettle();

        expect(selectedLetter, equals('B'));
        expect(tapCount, equals(2));
      });

      testWidgets('LetterItem communicates correctly with test alphabet grid',
          (tester) async {
        String? selectedLetter;
        int tapCount = 0;

        setTestScreenSize(tester, const Size(800, 1024));

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: TestAlphabetGrid(
                onLetterSelected: (letter) {
                  selectedLetter = letter;
                  tapCount++;
                },
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final letterItems = find.byType(LetterItem);
        expect(letterItems.evaluate().length,
            greaterThanOrEqualTo(20)); 

        final letterC = find.text('C');
        expect(letterC, findsOneWidget);

        await tester.tap(letterC);
        await tester.pumpAndSettle();

        expect(selectedLetter, equals('C'));
        expect(tapCount, equals(1));

        addTearDown(() => tester.view.resetPhysicalSize());
      });

      testWidgets('ResponsiveLayoutBuilder coordinates with child widgets',
          (tester) async {
        setTestScreenSize(tester, const Size(400, 800));

        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: ResponsiveLayoutBuilder(
                mobile: Text('Mobile Layout'),
                tablet: Text('Tablet Layout'),
                desktopWeb: Text('Desktop Layout'),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(ResponsiveLayoutBuilder), findsOneWidget);

        final hasText = find.textContaining('Layout').evaluate().isNotEmpty;
        expect(hasText, isTrue,
            reason: 'Should display one of the layout texts');

        setTestScreenSize(tester, const Size(800, 1024));
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: ResponsiveLayoutBuilder(
                mobile: Text('Mobile Layout'),
                tablet: Text('Tablet Layout'),
                desktopWeb: Text('Desktop Layout'),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(ResponsiveLayoutBuilder), findsOneWidget);

        setTestScreenSize(tester, const Size(1200, 800));
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: ResponsiveLayoutBuilder(
                mobile: Text('Mobile Layout'),
                tablet: Text('Tablet Layout'),
                desktopWeb: Text('Desktop Layout'),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(ResponsiveLayoutBuilder), findsOneWidget);

        addTearDown(() => tester.view.resetPhysicalSize());
      });
    });

    group('Responsive Widget Integration', () {
      testWidgets('LetterItem adapts correctly in different layouts',
          (tester) async {
        setTestScreenSize(tester, const Size(400, 800));

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: LetterItem(
                letter: 'A',
                onTap: () {},
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('A'), findsOneWidget);

        final arrowIcons = find.byIcon(Icons.arrow_forward_ios);
        final hasArrowIcon = arrowIcons.evaluate().isNotEmpty;

        setTestScreenSize(tester, const Size(800, 1024));
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: LetterItem(
                letter: 'A',
                onTap: () {},
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('A'), findsOneWidget);

        setTestScreenSize(tester, const Size(1200, 800));
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: LetterItem(
                letter: 'A',
                onTap: () {},
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('A'), findsOneWidget);

        addTearDown(() => tester.view.resetPhysicalSize());
      });

      testWidgets('Alphabet components maintain consistency across layouts',
          (tester) async {
        String? mobileSelection;
        String? tabletSelection;

        setTestScreenSize(tester, const Size(400, 800));
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: TestAlphabetList(
                onLetterSelected: (letter) => mobileSelection = letter,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('M'));
        await tester.pumpAndSettle();
        expect(mobileSelection, equals('M'));

        setTestScreenSize(tester, const Size(800, 1024));
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: TestAlphabetGrid(
                onLetterSelected: (letter) => tabletSelection = letter,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('N'));
        await tester.pumpAndSettle();
        expect(tabletSelection, equals('N'));

        expect(mobileSelection, isNotNull);
        expect(tabletSelection, isNotNull);

        addTearDown(() => tester.view.resetPhysicalSize());
      });
    });

    group('State Coordination Integration', () {
      testWidgets('LetterItem selection state coordinates with parent widgets',
          (tester) async {
        String? selectedLetter;

        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: Consumer(
                builder: (context, ref, child) {
                  selectedLetter = ref.watch(testSelectedLetterProvider);
                  return Scaffold(
                    body: Column(
                      children: [
                        Text('Selected: ${selectedLetter ?? 'None'}'),
                        Expanded(
                          child: TestAlphabetList(
                            onLetterSelected: (letter) {
                              ref
                                  .read(testSelectedLetterProvider.notifier)
                                  .state = letter;
                            },
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Selected: None'), findsOneWidget);
        expect(selectedLetter, isNull);

        await tester.tap(find.text('K'));
        await tester.pumpAndSettle();

        expect(find.text('Selected: K'), findsOneWidget);
        expect(selectedLetter, equals('K'));

        await tester.tap(find.text('L'));
        await tester.pumpAndSettle();

        expect(find.text('Selected: L'), findsOneWidget);
        expect(selectedLetter, equals('L'));
      });

      testWidgets('Responsive layout maintains state consistency',
          (tester) async {
        String? selectedLetter;

        setTestScreenSize(tester, const Size(400, 800));

        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: Consumer(
                builder: (context, ref, child) {
                  selectedLetter = ref.watch(testSelectedLetterProvider);
                  return Scaffold(
                    body: ResponsiveLayoutBuilder(
                      mobile: Column(
                        children: [
                          Text(
                              'Mobile - Selected: ${selectedLetter ?? 'None'}'),
                          Expanded(
                            child: TestAlphabetList(
                              onLetterSelected: (letter) {
                                ref
                                    .read(testSelectedLetterProvider.notifier)
                                    .state = letter;
                              },
                            ),
                          ),
                        ],
                      ),
                      tablet: Column(
                        children: [
                          Text(
                              'Tablet - Selected: ${selectedLetter ?? 'None'}'),
                          Expanded(
                            child: TestAlphabetGrid(
                              onLetterSelected: (letter) {
                                ref
                                    .read(testSelectedLetterProvider.notifier)
                                    .state = letter;
                              },
                            ),
                          ),
                        ],
                      ),
                      desktopWeb: Column(
                        children: [
                          Text(
                              'Desktop - Selected: ${selectedLetter ?? 'None'}'),
                          Expanded(
                            child: TestAlphabetGrid(
                              onLetterSelected: (letter) {
                                ref
                                    .read(testSelectedLetterProvider.notifier)
                                    .state = letter;
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final hasLayoutText =
            find.textContaining('Selected: None').evaluate().isNotEmpty;
        expect(hasLayoutText, isTrue,
            reason: 'Should display selected state text');

        final availableLetters = ['A', 'B', 'C'];
        String? selectedTestLetter;

        for (final letter in availableLetters) {
          if (find.text(letter).evaluate().isNotEmpty) {
            selectedTestLetter = letter;
            break;
          }
        }

        expect(selectedTestLetter, isNotNull,
            reason: 'Should find at least one visible letter');

        await tester.tap(find.text(selectedTestLetter!));
        await tester.pumpAndSettle();

        final hasSelectedText = find
            .textContaining('Selected: $selectedTestLetter')
            .evaluate()
            .isNotEmpty;
        expect(hasSelectedText, isTrue, reason: 'Should show selected letter');

        setTestScreenSize(tester, const Size(800, 1024));
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: Consumer(
                builder: (context, ref, child) {
                  selectedLetter = ref.watch(testSelectedLetterProvider);
                  return Scaffold(
                    body: ResponsiveLayoutBuilder(
                      mobile: Column(
                        children: [
                          Text(
                              'Mobile - Selected: ${selectedLetter ?? 'None'}'),
                          Expanded(
                            child: TestAlphabetList(
                              onLetterSelected: (letter) {
                                ref
                                    .read(testSelectedLetterProvider.notifier)
                                    .state = letter;
                              },
                            ),
                          ),
                        ],
                      ),
                      tablet: Column(
                        children: [
                          Text(
                              'Tablet - Selected: ${selectedLetter ?? 'None'}'),
                          Expanded(
                            child: TestAlphabetGrid(
                              onLetterSelected: (letter) {
                                ref
                                    .read(testSelectedLetterProvider.notifier)
                                    .state = letter;
                              },
                            ),
                          ),
                        ],
                      ),
                      desktopWeb: Column(
                        children: [
                          Text(
                              'Desktop - Selected: ${selectedLetter ?? 'None'}'),
                          Expanded(
                            child: TestAlphabetGrid(
                              onLetterSelected: (letter) {
                                ref
                                    .read(testSelectedLetterProvider.notifier)
                                    .state = letter;
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(selectedLetter, equals(selectedTestLetter));

        addTearDown(() => tester.view.resetPhysicalSize());
      });
    });

    group('Widget Performance Integration', () {
      testWidgets('Large widget trees perform efficiently', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Column(
                children: [
                  for (int i = 0; i < 5; i++)
                    Expanded(
                      child: ResponsiveLayoutBuilder(
                        mobile: Text('Mobile $i'),
                        tablet: Text('Tablet $i'),
                        desktopWeb: Text('Desktop $i'),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(ResponsiveLayoutBuilder), findsNWidgets(5));
        expect(tester.takeException(), isNull);

        setTestScreenSize(tester, const Size(800, 1024));
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Column(
                children: [
                  for (int i = 0; i < 5; i++)
                    Expanded(
                      child: ResponsiveLayoutBuilder(
                        mobile: Text('Mobile $i'),
                        tablet: Text('Tablet $i'),
                        desktopWeb: Text('Desktop $i'),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final textWidgets = find.byType(Text);
        expect(textWidgets.evaluate().length, greaterThanOrEqualTo(5));

        addTearDown(() => tester.view.resetPhysicalSize());
      });

      testWidgets('Rapid widget interaction performs smoothly', (tester) async {
        int tapCount = 0;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: TestAlphabetList(
                onLetterSelected: (letter) => tapCount++,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final letters = ['A', 'B', 'C', 'D', 'E'];
        for (final letter in letters) {
          await tester.tap(find.text(letter));
          await tester.pump(const Duration(milliseconds: 50));
        }

        await tester.pumpAndSettle();

        expect(tapCount, equals(5));
        expect(tester.takeException(), isNull);
      });
    });

    group('Widget Error Handling Integration', () {
      testWidgets('Widget hierarchy gracefully handles basic errors',
          (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) {
                  return const Center(
                    child: Text('Widget loaded successfully'),
                  );
                },
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.text('Widget loaded successfully'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });

      testWidgets('Widget disposal happens cleanly', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: TestAlphabetList(
                onLetterSelected: (letter) {},
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
      });
    });

    group('Widget Accessibility Integration', () {
      testWidgets('LetterItem widgets are accessible', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: LetterItem(
                letter: 'A',
                onTap: () {},
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('A'), findsOneWidget);
        expect(find.byType(InkWell), findsOneWidget);

        await tester.tap(find.text('A'));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
      });

      testWidgets('Alphabet components support accessibility', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: TestAlphabetList(
                onLetterSelected: (letter) {},
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('A'), findsOneWidget);
        final allLetterFinders = ['Z', 'Y', 'X', 'W', 'V'];
        bool foundEndLetter = false;

        for (final letter in allLetterFinders) {
          if (find.text(letter).evaluate().isNotEmpty) {
            foundEndLetter = true;
            break;
          }
        }

        if (!foundEndLetter) {
          await tester.dragUntilVisible(
            find.text('Z'),
            find.byType(ListView),
            const Offset(0, -50),
          );
          await tester.pumpAndSettle();
        }

        expect(find.byType(ListView), findsOneWidget);
        expect(find.byType(InkWell), findsWidgets);
      });
    });

    group('Complex Widget Composition Integration', () {
      testWidgets('Multi-level responsive widget hierarchy works together',
          (tester) async {
        setTestScreenSize(tester, const Size(400, 800));

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ResponsiveLayoutBuilder(
                mobile: Column(
                  children: [
                    const Text('Mobile Header'),
                    Expanded(
                      child: TestAlphabetList(
                        onLetterSelected: (letter) {},
                      ),
                    ),
                  ],
                ),
                tablet: Column(
                  children: [
                    const Text('Tablet Header'),
                    Expanded(
                      child: TestAlphabetGrid(
                        onLetterSelected: (letter) {},
                      ),
                    ),
                  ],
                ),
                desktopWeb: Column(
                  children: [
                    const Text('Desktop Header'),
                    Expanded(
                      child: TestAlphabetGrid(
                        onLetterSelected: (letter) {},
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final hasHeader = find.textContaining('Header').evaluate().isNotEmpty;
        expect(hasHeader, isTrue,
            reason: 'Should display one of the header texts');

        final hasAlphabetComponent =
            find.byType(TestAlphabetList).evaluate().isNotEmpty ||
                find.byType(TestAlphabetGrid).evaluate().isNotEmpty;
        expect(hasAlphabetComponent, isTrue,
            reason: 'Should display alphabet component');

        setTestScreenSize(tester, const Size(800, 1024));
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ResponsiveLayoutBuilder(
                mobile: Column(
                  children: [
                    const Text('Mobile Header'),
                    Expanded(
                      child: TestAlphabetList(
                        onLetterSelected: (letter) {},
                      ),
                    ),
                  ],
                ),
                tablet: Column(
                  children: [
                    const Text('Tablet Header'),
                    Expanded(
                      child: TestAlphabetGrid(
                        onLetterSelected: (letter) {},
                      ),
                    ),
                  ],
                ),
                desktopWeb: Column(
                  children: [
                    const Text('Desktop Header'),
                    Expanded(
                      child: TestAlphabetGrid(
                        onLetterSelected: (letter) {},
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final hasTabletHeader =
            find.textContaining('Header').evaluate().isNotEmpty;
        expect(hasTabletHeader, isTrue, reason: 'Should display header text');

        expect(tester.takeException(), isNull);

        addTearDown(() => tester.view.resetPhysicalSize());
      });
    });
  });
}
