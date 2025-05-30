import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:recipevault/main.dart';
import 'package:recipevault/data/datasources/local_datasource.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  
  SharedPreferences.setMockInitialValues({});
  late SharedPreferences prefs;
  
  setUp(() async {
    prefs = await SharedPreferences.getInstance();
  });
  
  group('Loading Performance Tests', () {
    testWidgets('Measure initial app loading time', (tester) async {
      final stopwatch = Stopwatch()..start();
      
      await tester.pumpWidget(ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
        child: const RecipeVaultApp(),
      ));
      
      await tester.pump();
      final firstFrameTime = stopwatch.elapsedMilliseconds;
      
      await tester.pumpAndSettle();
      final fullLoadTime = stopwatch.elapsedMilliseconds;
      stopwatch.stop();

      debugPrint('First frame time: ${firstFrameTime}ms');
      debugPrint('Full initialization time: ${fullLoadTime}ms');
      
      expect(fullLoadTime, lessThan(5000), reason: 'Initial app loading took too long');
    });
    
    
    testWidgets('Measure recipe detail loading time', (tester) async {
      await tester.pumpWidget(ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
        child: const RecipeVaultApp(),
      ));
      await tester.pumpAndSettle();
      
      final letterFinder = find.text('A');
      if (letterFinder.evaluate().isEmpty) {
        fail('Could not find letter A for performance testing');
      }
      
      await tester.tap(letterFinder.first);
      await tester.pumpAndSettle();
      
      final recipeItems = find.byType(ListTile);
      if (recipeItems.evaluate().isEmpty) {
        fail('No recipes found for performance testing');
      }
      
      final stopwatch = Stopwatch()..start();
      
      await tester.tap(recipeItems.first);
      await tester.pump(); 
      
      final timeToFirstResponse = stopwatch.elapsedMilliseconds;
      
      await tester.pumpAndSettle();
      final fullLoadTime = stopwatch.elapsedMilliseconds;
      stopwatch.stop();
      
      final detailsLoaded = find.byType(Card).evaluate().isNotEmpty || 
                           find.byType(Image).evaluate().isNotEmpty;
      
      expect(detailsLoaded, isTrue, reason: 'Recipe details did not load properly');
      debugPrint('Time to first response: ${timeToFirstResponse}ms');
      
      expect(fullLoadTime, lessThan(3000), reason: 'Recipe detail loading took too long');
    });
    
    testWidgets('Measure image loading performance (with caching)', (tester) async {
      await tester.pumpWidget(ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
        child: const RecipeVaultApp(),
      ));
      await tester.pumpAndSettle();
      
      final letterFinder = find.text('A');
      if (letterFinder.evaluate().isEmpty) {
        fail('Could not find letter A for performance testing');
      }
      
      await tester.tap(letterFinder.first);
      await tester.pumpAndSettle();
      
      final recipeItems = find.byType(ListTile);
      if (recipeItems.evaluate().isEmpty) {
        fail('No recipes found for performance testing');
      }
      
      final firstLoadStopwatch = Stopwatch()..start();
      await tester.tap(recipeItems.first);
      await tester.pump(); 
      
      final firstLoadTimeToFirstResponse = firstLoadStopwatch.elapsedMilliseconds;
      debugPrint('Time to first response: ${firstLoadTimeToFirstResponse}ms');
      
      await tester.pumpAndSettle();
      final firstLoadFullTime = firstLoadStopwatch.elapsedMilliseconds;
      firstLoadStopwatch.stop();
      
      final imageWidgets = find.byType(Image);
      if (imageWidgets.evaluate().isEmpty) {
        debugPrint('Warning: No images found for performance testing');
      } else {
        debugPrint('Found ${imageWidgets.evaluate().length} images');
      }
      
      expect(firstLoadFullTime, lessThan(5000), reason: 'Initial image loading took too long');
      
      final backButton = find.byIcon(Icons.arrow_back);
      if (backButton.evaluate().isNotEmpty) {
        await tester.tap(backButton.first);
        await tester.pumpAndSettle();
      } else {
        return;
      }
      
      final secondLoadStopwatch = Stopwatch()..start();
      if (recipeItems.evaluate().isNotEmpty) {
        await tester.tap(recipeItems.first);
        await tester.pump(); 
        
        final secondLoadTimeToFirstResponse = secondLoadStopwatch.elapsedMilliseconds;
        debugPrint('Time to first response: ${secondLoadTimeToFirstResponse}ms');
        
        await tester.pumpAndSettle();
        final secondLoadFullTime = secondLoadStopwatch.elapsedMilliseconds;
        secondLoadStopwatch.stop();
        
        expect(secondLoadFullTime, lessThan(2000), reason: 'Cached image loading took too long');
      } else {
        debugPrint('Warning: Could not find recipe items for cached test');
      }
    });
  });
}

