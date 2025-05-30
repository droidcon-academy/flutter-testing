import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:recipevault/main.dart';
import 'package:recipevault/data/datasources/local_datasource.dart';
import 'package:recipevault/presentation/widgets/recipe/grid/recipe_grid_card.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  
  SharedPreferences.setMockInitialValues({});
  late SharedPreferences prefs;
  
  setUp(() async {
    prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  });

  group('Memory Usage Tests', () {
    testWidgets('Monitor object counts during recipe browsing', (tester) async {

      await tester.pumpWidget(ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
        child: const RecipeVaultApp(),
      ));
      await tester.pumpAndSettle();
      
      final initialWidgetCount = tester.allWidgets.length;
      final loadedRecipes = <String>{};
      for (final letter in ['A', 'B']) {
        final letterText = find.text(letter);
        if (letterText.evaluate().isNotEmpty) {
          await tester.tap(letterText);
          await tester.pumpAndSettle(const Duration(seconds: 1));
        } else {
          continue;
        }
        
        final recipeCards = find.byType(RecipeGridCard);
        if (recipeCards.evaluate().isNotEmpty) {
          await tester.tap(recipeCards.first);
          await tester.pumpAndSettle();
          
          final recipeTitles = find.byType(Text)
              .evaluate()
              .map((e) => (e.widget as Text).data)
              .whereType<String>()
              .where((text) => text.length > 3) 
              .toList();
              
          if (recipeTitles.isNotEmpty) {
            loadedRecipes.add(recipeTitles.first);
          }
          
          final backButton = find.byIcon(Icons.arrow_back);
          if (backButton.evaluate().isNotEmpty) {
            await tester.tap(backButton);
            await tester.pumpAndSettle();
          } else {
            final backAction = find.byWidgetPredicate((widget) => 
              widget is IconButton && (widget.icon is Icon && 
              (widget.icon as Icon).icon == Icons.arrow_back));
              
            if (backAction.evaluate().isNotEmpty) {
              await tester.tap(backAction);
              await tester.pumpAndSettle();
            } else {
              debugPrint('No back button found, cannot navigate back');
            }
          }
        }
      }
      
      await tester.pumpAndSettle(const Duration(seconds: 1));
      final midWidgetCount = tester.allWidgets.length;
      debugPrint('Widget count after recipe browsing: $midWidgetCount');
      
      final homeButton = find.text('Recipe');
      if (homeButton.evaluate().isNotEmpty) {
        await tester.tap(homeButton);
        await tester.pumpAndSettle();
        
        final favoriteButtons = find.byIcon(Icons.favorite_border);
        if (favoriteButtons.evaluate().isNotEmpty) {
          
          await tester.tap(favoriteButtons.first);
          await tester.pumpAndSettle();
        }
      }
      
      await tester.pumpAndSettle(const Duration(seconds: 1));
      final finalWidgetCount = tester.allWidgets.length;
      
      expect(finalWidgetCount, lessThan(initialWidgetCount * 1.5), 
          reason: 'Widget count should not grow excessively');

      await triggerGarbageCollection(tester);
      
      await tester.pumpAndSettle();
      final postGCWidgetCount = tester.allWidgets.length;
      debugPrint('Widget count after GC: $postGCWidgetCount');
    });

    testWidgets('Check for memory leaks during navigation cycles', (tester) async {
      await tester.pumpWidget(ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
        child: const RecipeVaultApp(),
      ));
      await tester.pumpAndSettle();
      
      final initialWidgetCount = tester.allWidgets.length;
      for (int i = 0; i < 3; i++) {
        final dashboardTab = find.text('Dashboard');
        if (dashboardTab.evaluate().isNotEmpty) {
          await tester.tap(dashboardTab);
          await tester.pumpAndSettle();
        }
        
        final recipeTab = find.text('Recipe');
        if (recipeTab.evaluate().isNotEmpty) {
          await tester.tap(recipeTab);
          await tester.pumpAndSettle();
        }
      }
      
      final finalWidgetCount = tester.allWidgets.length;
      debugPrint('Final widget count after navigation cycles: $finalWidgetCount');

      expect((finalWidgetCount - initialWidgetCount).abs(), lessThan(30),
          reason: 'Widget count should be stable after navigation cycles');
    });
  });
}

Future<void> triggerGarbageCollection(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pumpWidget(const MaterialApp(home: SizedBox()));
  
  await Future.delayed(const Duration(milliseconds: 500));
  await tester.pump();
}
