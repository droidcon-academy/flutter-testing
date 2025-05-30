// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:recipevault/main.dart';
import 'package:recipevault/data/datasources/local_datasource.dart';
import 'package:recipevault/presentation/views/recipe/recipe_screen.dart';
import 'package:recipevault/presentation/views/recipe/components/recipe_list_view.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  
  SharedPreferences.setMockInitialValues({});
  late SharedPreferences prefs;
  
  setUp(() async {
    prefs = await SharedPreferences.getInstance();
  });
  
  group('Recipe Browsing Flow Tests', () {
    testWidgets('Complete alphabet selection to recipe detail flow', (tester) async {
      await tester.pumpWidget(ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
        child: const RecipeVaultApp(),
      ));
      await tester.pumpAndSettle(); 
      
      await tester.tap(find.text('A').first);
      await tester.pumpAndSettle();
      
      expect(find.byType(RecipeScreen), findsOneWidget);
      
      await tester.tap(find.textContaining('A').first);
      await tester.pumpAndSettle();
      
      expect(find.textContaining('Ingredients'), findsOneWidget);
      
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();
      
      expect(find.byType(RecipeListView), findsOneWidget);
    });
    
    testWidgets('Recipe browsing on different device sizes', (tester) async {
      await _testBasicUIOnDeviceSize(tester, const Size(375, 812), prefs); 
      await _testBasicUIOnDeviceSize(tester, const Size(812, 375), prefs); 
      await _testBasicUIOnDeviceSize(tester, const Size(834, 1194), prefs); 
    });
  });
}

Future<void> _testBasicUIOnDeviceSize(WidgetTester tester, Size size, SharedPreferences prefs) async {
  tester.binding.window.physicalSizeTestValue = Size(
    size.width * tester.binding.window.devicePixelRatio,
    size.height * tester.binding.window.devicePixelRatio,
  );
  tester.binding.window.devicePixelRatioTestValue = 1.0;
  
  addTearDown(() {
    tester.binding.window.clearPhysicalSizeTestValue();
    tester.binding.window.clearDevicePixelRatioTestValue();
  });
  
  await tester.pumpWidget(ProviderScope(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
    ],
    child: const RecipeVaultApp(),
  ));
  
  await tester.pumpAndSettle(const Duration(seconds: 1));
  
  expect(find.byType(Scaffold), findsWidgets);
  
  final screenSize = Size(
    tester.binding.window.physicalSize.width / tester.binding.window.devicePixelRatio,
    tester.binding.window.physicalSize.height / tester.binding.window.devicePixelRatio
  );

  expect(find.byType(Text), findsWidgets);
  expect(find.byType(Material), findsWidgets);
  
  final alphabetLetters = ['A', 'B', 'C', 'D', 'E'];
  bool foundAnyLetter = false;
  
  for (final letter in alphabetLetters) {
    if (find.text(letter).evaluate().isNotEmpty) {
      foundAnyLetter = true;
      break;
    }
  }
  
  if (!foundAnyLetter) {
    debugPrint('No alphabet letters found on screen size ${screenSize.width}x${screenSize.height}');
  } else {
    debugPrint('Found alphabet letters on screen size ${screenSize.width}x${screenSize.height}');
  }
}