// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:recipevault/presentation/viewmodels/recipe_viewmodel.dart';
import 'package:recipevault/presentation/views/home/components/alphabet_list.dart';
import 'package:recipevault/presentation/views/home/home_screen.dart';
import 'package:recipevault/presentation/widgets/alphabet/letter_item.dart';

class MockRecipeViewModel extends Mock implements RecipeViewModel {}

class AlphabetListTestWrapper extends ConsumerWidget {
  const AlphabetListTestWrapper({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const MaterialApp(
      home: AlphabetList(),
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
  
  group('AlphabetList Tests', () {
    testWidgets('list displays all 26 letters', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            selectedLetterProvider.overrideWithProvider(
              StateProvider<String?>((ref) => null),
            ),
            recipeProvider.overrideWith((ref) => mockRecipeVM),
          ],
          child: const AlphabetListTestWrapper(),
        ),
      );
      
      expect(find.byType(ListView), findsOneWidget);
      
      final listView = tester.widget<ListView>(find.byType(ListView));

      expect(listView.semanticChildCount, 26, reason: 'ListView should have 26 items');
      
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
          child: const AlphabetListTestWrapper(),
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
    
    testWidgets('list items have correct structure', (WidgetTester tester) async {
      tester.binding.window.physicalSizeTestValue = const Size(360 * 3, 640 * 3); 
      tester.binding.window.devicePixelRatioTestValue = 3.0;
      
      addTearDown(tester.binding.window.clearPhysicalSizeTestValue);
      addTearDown(tester.binding.window.clearDevicePixelRatioTestValue);
      
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            selectedLetterProvider.overrideWithProvider(
              StateProvider<String?>((ref) => null),
            ),
            recipeProvider.overrideWith((ref) => mockRecipeVM),
          ],
          child: const AlphabetListTestWrapper(),
        ),
      );

      final firstLetterItem = find.byType(LetterItem).first;
      expect(firstLetterItem, findsOneWidget);

      final letterItemWidget = tester.widget<LetterItem>(firstLetterItem);
      expect(letterItemWidget.letter, 'A');
      
      expect(find.descendant(
        of: firstLetterItem,
        matching: find.text('A'),
      ), findsOneWidget);
      
      expect(find.descendant(
        of: firstLetterItem,
        matching: find.byType(Row),
      ), findsOneWidget, reason: 'Should find Row widget in mobile list layout');
      
      expect(find.descendant(
        of: firstLetterItem,
        matching: find.byType(Icon),
      ), findsOneWidget, reason: 'Should find an Icon widget in the list item');
    });
  });
}