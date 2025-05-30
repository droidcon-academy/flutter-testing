import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:recipevault/main.dart';
import 'package:recipevault/core/themes/app_theme.dart';
import 'package:recipevault/data/datasources/local_datasource.dart';
import 'package:recipevault/presentation/views/home/home_screen.dart';

void main() {
  group('RecipeVaultApp Mobile Golden Tests', () {
    late SharedPreferences mockPrefs;

    setUpAll(() async {
      await loadAppFonts();
    });

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      mockPrefs = await SharedPreferences.getInstance();
    });

    testGoldens('RecipeVaultApp displays correctly in light theme',
        (tester) async {
      final widget = ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(mockPrefs),
        ],
        child: const RecipeVaultApp(),
      );

      await tester.pumpWidgetBuilder(
        widget,
        surfaceSize: const Size(375, 812), 
      );
      await tester.pumpAndSettle();

      await screenMatchesGolden(tester, 'main_app_light_mobile');
    });

    testGoldens('RecipeVaultApp displays correctly in dark theme',
        (tester) async {
      final widget = ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(mockPrefs),
        ],
        child: MaterialApp(
          title: 'Recipe Vault',
          theme: AppTheme.darkTheme,
          themeMode: ThemeMode.dark,
          home: const HomeScreen(),
        ),
      );

      await tester.pumpWidgetBuilder(
        widget,
        surfaceSize: const Size(375, 812),
      );
      await tester.pumpAndSettle();

      await screenMatchesGolden(tester, 'main_app_dark_mobile');
    });

    testGoldens('RecipeVaultApp system theme mode respects platform brightness',
        (tester) async {
      final widget = ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(mockPrefs),
        ],
        child: const RecipeVaultApp(),
      );

      await tester.pumpWidgetBuilder(
        widget,
        surfaceSize: const Size(375, 812),
        wrapper: materialAppWrapper(
          platform: TargetPlatform.iOS,
          theme: AppTheme.lightTheme,
        ),
      );
      await tester.pumpAndSettle();

      await screenMatchesGolden(tester, 'main_app_system_light_mobile');
    });

    testGoldens('RecipeVaultApp shows correct app title and structure',
        (tester) async {
      final widget = ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(mockPrefs),
        ],
        child: const RecipeVaultApp(),
      );

      await tester.pumpWidgetBuilder(
        widget,
        surfaceSize: const Size(375, 812),
      );
      await tester.pumpAndSettle();

      expect(find.byType(RecipeVaultApp), findsOneWidget);

      await screenMatchesGolden(tester, 'main_app_structure_mobile');
    });
  });
}
