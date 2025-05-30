import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';

import 'package:recipevault/core/themes/app_theme.dart';
import 'package:recipevault/presentation/widgets/common/layout/responsive_layout_builder.dart';

void main() {
  group('ResponsiveLayoutBuilder Golden Tests - Real Component Usage', () {
    setUpAll(() async {
      await loadAppFonts();
    });

    Future<void> pumpResponsiveTest(
      WidgetTester tester, {
      required Size screenSize,
      ThemeData? theme,
    }) async {
      tester.view.physicalSize = screenSize;
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ResponsiveLayoutBuilder(
              mobile: Container(
                color: Colors.blue[100],
                child: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.phone_android, size: 48),
                      SizedBox(height: 16),
                      Text(
                        'Mobile Layout',
                        style: TextStyle(
                            fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Responsive: ≤ 600px width',
                        style: TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ),
              tablet: Container(
                color: Colors.green[100],
                child: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.tablet_android, size: 48),
                      SizedBox(height: 16),
                      Text(
                        'Tablet Layout',
                        style: TextStyle(
                            fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Responsive: 601px - 1024px width',
                        style: TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ),
              desktopWeb: Container(
                color: Colors.purple[100],
                child: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.desktop_windows, size: 48),
                      SizedBox(height: 16),
                      Text(
                        'Desktop Layout',
                        style: TextStyle(
                            fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Responsive: ≥ 1025px width',
                        style: TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          theme: theme ?? AppTheme.lightTheme,
        ),
      );

      await tester.pumpAndSettle();
    }

    group('ResponsiveLayoutBuilder Core Functionality', () {
      testGoldens('ResponsiveLayoutBuilder - Mobile device (375px)',
          (tester) async {
        await pumpResponsiveTest(
          tester,
          screenSize: const Size(375, 667), 
        );

        expect(find.byType(ResponsiveLayoutBuilder), findsOneWidget,
            reason: 'ResponsiveLayoutBuilder should be displayed');
        expect(find.text('Mobile Layout'), findsOneWidget,
            reason: 'Should show mobile layout at 375px width');

        await screenMatchesGolden(tester, 'responsive_layout_mobile_375');
      });

      testGoldens('ResponsiveLayoutBuilder - Tablet device (768px)',
          (tester) async {
        await pumpResponsiveTest(
          tester,
          screenSize: const Size(768, 1024), 
        );

        expect(find.byType(ResponsiveLayoutBuilder), findsOneWidget,
            reason: 'ResponsiveLayoutBuilder should be displayed');
        expect(find.text('Tablet Layout'), findsOneWidget,
            reason: 'Should show tablet layout at 768px width');

        await screenMatchesGolden(tester, 'responsive_layout_tablet_768');
      });

      testGoldens('ResponsiveLayoutBuilder - Desktop device (1200px)',
          (tester) async {
        await pumpResponsiveTest(
          tester,
          screenSize: const Size(1200, 800),
        );

        expect(find.byType(ResponsiveLayoutBuilder), findsOneWidget,
            reason: 'ResponsiveLayoutBuilder should be displayed');
        expect(find.text('Desktop Layout'), findsOneWidget,
            reason: 'Should show desktop layout at 1200px width');

        await screenMatchesGolden(tester, 'responsive_layout_desktop_1200');
      });
    });

    group('ResponsiveLayoutBuilder Breakpoint Testing', () {
      testGoldens('Responsive breakpoint - 600px boundary (mobile)',
          (tester) async {
        await pumpResponsiveTest(
          tester,
          screenSize: const Size(600, 800), 
        );

        expect(find.text('Mobile Layout'), findsOneWidget,
            reason: 'At 600px should show mobile layout');

        await screenMatchesGolden(
            tester, 'responsive_layout_boundary_600_mobile');
      });

      testGoldens('Responsive breakpoint - 601px boundary (tablet)',
          (tester) async {
        await pumpResponsiveTest(
          tester,
          screenSize: const Size(601, 800), 
        );

        expect(find.text('Tablet Layout'), findsOneWidget,
            reason: 'At 601px should show tablet layout');

        await screenMatchesGolden(
            tester, 'responsive_layout_boundary_601_tablet');
      });

      testGoldens('Responsive breakpoint - 1024px boundary (tablet)',
          (tester) async {
        await pumpResponsiveTest(
          tester,
          screenSize: const Size(1024, 768), 
        );

        expect(find.text('Tablet Layout'), findsOneWidget,
            reason: 'At 1024px should show tablet layout');

        await screenMatchesGolden(
            tester, 'responsive_layout_boundary_1024_tablet');
      });

      testGoldens('Responsive breakpoint - 1025px boundary (desktop)',
          (tester) async {
        await pumpResponsiveTest(
          tester,
          screenSize: const Size(1025, 768), 
        );

        expect(find.text('Desktop Layout'), findsOneWidget,
            reason: 'At 1025px should show desktop layout');

        await screenMatchesGolden(
            tester, 'responsive_layout_boundary_1025_desktop');
      });
    });

    group('ResponsiveLayoutBuilder with Dark Theme', () {
      testGoldens('ResponsiveLayoutBuilder - Dark theme mobile',
          (tester) async {
        await pumpResponsiveTest(
          tester,
          screenSize: const Size(375, 667),
          theme: AppTheme.darkTheme,
        );

        expect(find.byType(ResponsiveLayoutBuilder), findsOneWidget,
            reason: 'Should use ResponsiveLayoutBuilder in dark theme');
        expect(find.text('Mobile Layout'), findsOneWidget,
            reason: 'Dark theme mobile should show mobile layout');

        await screenMatchesGolden(tester, 'responsive_layout_dark_mobile');
      });

      testGoldens('ResponsiveLayoutBuilder - Dark theme desktop',
          (tester) async {
        await pumpResponsiveTest(
          tester,
          screenSize: const Size(1200, 800), 
          theme: AppTheme.darkTheme,
        );

        expect(find.byType(ResponsiveLayoutBuilder), findsOneWidget,
            reason: 'Should use ResponsiveLayoutBuilder in dark theme');
        expect(find.text('Desktop Layout'), findsOneWidget,
            reason: 'Dark theme desktop should show desktop layout');

        await screenMatchesGolden(tester, 'responsive_layout_dark_desktop');
      });
    });

    tearDownAll(() async {
    });
  });
}
