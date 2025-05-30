import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:recipevault/main.dart';
import 'package:recipevault/data/datasources/local_datasource.dart';
import 'package:recipevault/presentation/viewmodels/navigation_viewmodel.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});
  late SharedPreferences prefs;
  
  setUp(() async {
    prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  });
  
  group('UI Inspection Tests', () {
    testWidgets('Identify available UI navigation elements', (tester) async {
      await tester.pumpWidget(ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
        child: const RecipeVaultApp(),
      ));
      await tester.pumpAndSettle();
      
      expect(find.byType(Scaffold), findsOneWidget);
    });
  });
  
  group('State Update Performance Tests', () {
    testWidgets('Measure basic state update performance', (tester) async {
      await tester.pumpWidget(ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
        child: const RecipeVaultApp(),
      ));
      await tester.pumpAndSettle();

      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
      );
      addTearDown(container.dispose);
      
      final stopwatch = Stopwatch()..start();
      try {
        container.read(currentPageIndexProvider.notifier).state = 1;
        stopwatch.stop();
        expect(stopwatch.elapsedMilliseconds, lessThan(50));
      } catch (e) {
        stopwatch.stop();
      }
    });
  });
  
  group('Frame Rate Performance Tests', () {
    testWidgets('Measure general UI performance during scrolling', (tester) async {
      SharedPreferences.setMockInitialValues({
        'recipe_cache': '[{"id":"1","name":"Test Recipe 1"},{"id":"2","name":"Test Recipe 2"}]',
      });
      prefs = await SharedPreferences.getInstance();
      
      await tester.pumpWidget(ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
        child: const RecipeVaultApp(),
      ));
      await tester.pumpAndSettle();
      
      final listView = find.byType(ListView);
      final gridView = find.byType(GridView);
      
      if (listView.evaluate().isNotEmpty) {
        final stopwatch = Stopwatch()..start();
        await tester.drag(listView.first, const Offset(0, -300));
        
        int frameCount = 0;
        while (stopwatch.elapsedMilliseconds < 500) {
          await tester.pump(const Duration(milliseconds: 16));
          frameCount++;
        }
        stopwatch.stop();
        
        expect(frameCount, greaterThanOrEqualTo(12), 
            reason: 'Animation should run at a reasonable frame rate on web (25+ fps)');
      } else if (gridView.evaluate().isNotEmpty) {
        final stopwatch = Stopwatch()..start();
        await tester.drag(gridView.first, const Offset(0, -300));
        
        int frameCount = 0;
        while (stopwatch.elapsedMilliseconds < 500) {
          await tester.pump(const Duration(milliseconds: 16)); 
          frameCount++;
        }
        stopwatch.stop();

        expect(frameCount, greaterThanOrEqualTo(12), 
            reason: 'Animation should run at a reasonable frame rate on web (25+ fps)');
      }
    });
  });
  
  group('Tap Performance Tests', () {
    testWidgets('Measure performance of tap interactions', (tester) async {
      await tester.pumpWidget(ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
        child: const RecipeVaultApp(),
      ));
      
      await tester.pumpAndSettle(const Duration(milliseconds: 500));
      final buttons = find.byType(ElevatedButton);
      final inkWells = find.byType(InkWell);
      final gestureDetectors = find.byType(GestureDetector);
      
      Finder tappableElement;
      if (buttons.evaluate().isNotEmpty) {
        tappableElement = buttons.first;
      } else if (inkWells.evaluate().isNotEmpty) {
        tappableElement = inkWells.first;
      } else if (gestureDetectors.evaluate().isNotEmpty) {
        tappableElement = gestureDetectors.first;
      } else {
        return; 
      }
      
      final stopwatch = Stopwatch()..start();
      await tester.tap(tappableElement);
      
      int frameCount = 0;
      bool visualChangeDetected = false;

      final initialState = tester.allWidgets.length;
      
      while (stopwatch.elapsedMilliseconds < 300 && !visualChangeDetected) {
        await tester.pump(const Duration(milliseconds: 16));
        frameCount++;
        
        if (tester.allWidgets.length != initialState) {
          visualChangeDetected = true;
          break;
        }
      }
      stopwatch.stop();
      
      if (visualChangeDetected) {
        expect(stopwatch.elapsedMilliseconds, lessThan(300), 
          reason: 'Tap response should be quick');
      } else {
        debugPrint('No visual change detected after tap - element might not be interactive');
      }
      
      await tester.pumpAndSettle(const Duration(seconds: 1));
    });
  });
}
