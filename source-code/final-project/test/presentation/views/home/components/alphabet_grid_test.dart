import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:recipevault/presentation/viewmodels/recipe_viewmodel.dart';
import 'package:recipevault/presentation/views/home/components/alphabet_grid.dart';
import 'package:recipevault/presentation/views/home/home_screen.dart';
import 'package:recipevault/presentation/widgets/alphabet/letter_item.dart';

class MockRecipeViewModel extends Mock implements RecipeViewModel {}

class AlphabetGridTestWrapper extends ConsumerWidget {
  const AlphabetGridTestWrapper({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const MaterialApp(
      home: AlphabetGrid(),
    );
  }
}

void main() {
  late MockRecipeViewModel mockRecipeVM;
  late RecipeState mockRecipeState;
  
  setUp(() {
    mockRecipeVM = MockRecipeViewModel();
    mockRecipeState = const RecipeState();
    
    when(() => mockRecipeVM.state).thenReturn(mockRecipeState);
    
    when(() => mockRecipeVM.setSelectedLetter(any())).thenAnswer((_) async {});
  });
  
  group('AlphabetGrid Tests', () {
    testWidgets('grid displays all 26 letters', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            selectedLetterProvider.overrideWithProvider(
              StateProvider<String?>((ref) => null),
            ),
            recipeProvider.overrideWith((ref) => mockRecipeVM),
          ],
          child: const AlphabetGridTestWrapper(),
        ),
      );
      
      expect(find.byType(GridView), findsOneWidget);
      
      final gridView = tester.widget<GridView>(find.byType(GridView));
      
      expect(gridView.semanticChildCount, 26, reason: 'GridView should have 26 items');
      final visibleLetterItems = find.byType(LetterItem);
      expect(visibleLetterItems, findsWidgets, reason: 'Should find visible LetterItem widgets');

      for (int i = 0; i < 5; i++) {
        final letter = String.fromCharCode(65 + i); 
        expect(find.text(letter), findsWidgets,
            reason: 'Letter $letter should be displayed');
      }
    });
    
    testWidgets('tapping a letter triggers interactions', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            selectedLetterProvider.overrideWithProvider(
              StateProvider<String?>((ref) => null),
            ),
            recipeProvider.overrideWith((ref) => mockRecipeVM),
          ],
          child: const AlphabetGridTestWrapper(),
        ),
      );

      final letterAText = find.text('A');
      expect(letterAText, findsWidgets, reason: 'Should find Text widget with letter A');

      final letterItemA = find.ancestor(
        of: find.text('A').first,  
        matching: find.byType(LetterItem),
      );
      expect(letterItemA, findsOneWidget, reason: 'Should find LetterItem containing letter A');
      
      await tester.tap(letterItemA);
      await tester.pump();

      verify(() => mockRecipeVM.setSelectedLetter('A')).called(1);
      expect(letterItemA, findsOneWidget);
    });
  });
}
