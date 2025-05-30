// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recipevault/core/utils/responsive_helper.dart';

void main() {
  group('ResponsiveHelper Device Type Detection', () {
    testWidgets('should detect mobile device correctly', (WidgetTester tester) async {
      tester.binding.window.physicalSizeTestValue = const Size(360 * 3, 640 * 3); 
      tester.binding.window.devicePixelRatioTestValue = 3.0;
      addTearDown(tester.binding.window.clearPhysicalSizeTestValue);
      addTearDown(tester.binding.window.clearDevicePixelRatioTestValue);

      expect(ResponsiveHelper.deviceType, equals(ResponsiveSizes.mobile));
      expect(ResponsiveHelper.isMobile, isTrue);
      expect(ResponsiveHelper.isTablet, isFalse);
      expect(ResponsiveHelper.isDesktop, isFalse);
    });

    testWidgets('should detect tablet device correctly', (WidgetTester tester) async {
      tester.binding.window.physicalSizeTestValue = const Size(800 * 2, 1200 * 2); 
      tester.binding.window.devicePixelRatioTestValue = 2.0;
      addTearDown(tester.binding.window.clearPhysicalSizeTestValue);
      addTearDown(tester.binding.window.clearDevicePixelRatioTestValue);

      expect(ResponsiveHelper.deviceType, equals(ResponsiveSizes.tablet));
      expect(ResponsiveHelper.isMobile, isFalse);
      expect(ResponsiveHelper.isTablet, isTrue);
      expect(ResponsiveHelper.isDesktop, isFalse);
    });

    testWidgets('should detect desktop device correctly', (WidgetTester tester) async {
      tester.binding.window.physicalSizeTestValue = const Size(1920 * 1, 1080 * 1); 
      tester.binding.window.devicePixelRatioTestValue = 1.0;
      addTearDown(tester.binding.window.clearPhysicalSizeTestValue);
      addTearDown(tester.binding.window.clearDevicePixelRatioTestValue);
      
      expect(ResponsiveHelper.deviceType, equals(ResponsiveSizes.desktopWeb));
      expect(ResponsiveHelper.isMobile, isFalse);
      expect(ResponsiveHelper.isTablet, isFalse);
      expect(ResponsiveHelper.isDesktop, isTrue);
    });
  });

  group('ResponsiveHelper Window Metrics Handling', () {
    testWidgets('should provide appropriate screen padding based on device size', (WidgetTester tester) async {
      tester.binding.window.physicalSizeTestValue = const Size(360 * 3, 640 * 3);
      tester.binding.window.devicePixelRatioTestValue = 3.0;
      expect(ResponsiveHelper.screenPadding, equals(const EdgeInsets.all(8.0)));

      tester.binding.window.physicalSizeTestValue = const Size(800 * 2, 1200 * 2);
      tester.binding.window.devicePixelRatioTestValue = 2.0;
      expect(ResponsiveHelper.screenPadding, equals(const EdgeInsets.all(16.0)));

      tester.binding.window.physicalSizeTestValue = const Size(1920 * 1, 1080 * 1);
      tester.binding.window.devicePixelRatioTestValue = 1.0;
      expect(ResponsiveHelper.screenPadding, equals(const EdgeInsets.all(24.0)));
      
      addTearDown(tester.binding.window.clearPhysicalSizeTestValue);
      addTearDown(tester.binding.window.clearDevicePixelRatioTestValue);
    });

    testWidgets('should provide appropriate alphabet grid columns based on device size', (WidgetTester tester) async {
      tester.binding.window.physicalSizeTestValue = const Size(360 * 3, 640 * 3);
      tester.binding.window.devicePixelRatioTestValue = 3.0;
      expect(ResponsiveHelper.alphabetGridColumns, equals(3));

      tester.binding.window.physicalSizeTestValue = const Size(800 * 2, 1200 * 2);
      tester.binding.window.devicePixelRatioTestValue = 2.0;
      expect(ResponsiveHelper.alphabetGridColumns, equals(4));

      tester.binding.window.physicalSizeTestValue = const Size(1920 * 1, 1080 * 1);
      tester.binding.window.devicePixelRatioTestValue = 1.0;
      expect(ResponsiveHelper.alphabetGridColumns, equals(6));
      
      addTearDown(tester.binding.window.clearPhysicalSizeTestValue);
      addTearDown(tester.binding.window.clearDevicePixelRatioTestValue);
    });
  });

  group('ResponsiveHelper Orientation Changes', () {
    testWidgets('should calculate recipe grid columns correctly for portrait orientation', (WidgetTester tester) async {
      tester.binding.window.physicalSizeTestValue = const Size(1080, 1920);
      tester.binding.window.devicePixelRatioTestValue = 3.0;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(builder: (context) {
            expect(MediaQuery.of(context).orientation, equals(Orientation.portrait));
            expect(ResponsiveHelper.recipeGridColumns(context), equals(2));
            return const Placeholder();
          }),
        ),
      );
      
      addTearDown(tester.binding.window.clearPhysicalSizeTestValue);
      addTearDown(tester.binding.window.clearDevicePixelRatioTestValue);
    });
    
    testWidgets('should calculate recipe grid columns correctly for landscape orientation', (WidgetTester tester) async {
      tester.binding.window.physicalSizeTestValue = const Size(1920, 1080);
      tester.binding.window.devicePixelRatioTestValue = 3.0;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(builder: (context) {
            expect(MediaQuery.of(context).orientation, equals(Orientation.landscape));
            expect(ResponsiveHelper.recipeGridColumns(context), equals(3));
            return const Placeholder();
          }),
        ),
      );
      
      addTearDown(tester.binding.window.clearPhysicalSizeTestValue);
      addTearDown(tester.binding.window.clearDevicePixelRatioTestValue);
    });
    
    testWidgets('should calculate recipe grid columns correctly for tablet portrait and landscape', (WidgetTester tester) async {
      tester.binding.window.physicalSizeTestValue = const Size(1400, 2000); 
      tester.binding.window.devicePixelRatioTestValue = 2.0;
      
      expect(1400 / 2.0 > 600 && 1400 / 2.0 <= 1024, isTrue, 
          reason: 'Logical pixel width should be in tablet range (601-1024)');
      
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(builder: (context) {
            expect(MediaQuery.of(context).orientation, equals(Orientation.portrait));
            expect(ResponsiveHelper.deviceType, equals(ResponsiveSizes.tablet));
            expect(ResponsiveHelper.recipeGridColumns(context), equals(2));
            return const Placeholder();
          }),
        ),
      );
      
      tester.binding.window.physicalSizeTestValue = const Size(2000, 1400);
      addTearDown(tester.binding.window.clearPhysicalSizeTestValue);
      
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(builder: (context) {
            expect(MediaQuery.of(context).orientation, equals(Orientation.landscape));
            expect(ResponsiveHelper.deviceType, equals(ResponsiveSizes.tablet));
            expect(ResponsiveHelper.recipeGridColumns(context), equals(3));
            return const Placeholder();
          }),
        ),
      );
      
      addTearDown(tester.binding.window.clearDevicePixelRatioTestValue);
    });
  });
}
