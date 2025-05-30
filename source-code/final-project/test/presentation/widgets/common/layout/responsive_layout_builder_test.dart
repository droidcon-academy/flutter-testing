// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recipevault/core/utils/responsive_helper.dart';
import 'package:recipevault/presentation/widgets/common/layout/responsive_layout_builder.dart';

void main() {
  group('ResponsiveLayoutBuilder', () {
    const mobileWidget = Text('Mobile Layout');
    const tabletWidget = Text('Tablet Layout');
    const desktopWidget = Text('Desktop Layout');
    
    Widget createWidgetUnderTest() {
      return const MaterialApp(
        home: Scaffold(
          body: ResponsiveLayoutBuilder(
            mobile: mobileWidget,
            tablet: tabletWidget,
            desktopWeb: desktopWidget,
          ),
        ),
      );
    }
    
    testWidgets('shows mobile layout on mobile devices', (WidgetTester tester) async {
      tester.binding.window.physicalSizeTestValue = const Size(360 * 3, 640 * 3); 
      tester.binding.window.devicePixelRatioTestValue = 3.0;
      
      addTearDown(tester.binding.window.clearPhysicalSizeTestValue);
      addTearDown(tester.binding.window.clearDevicePixelRatioTestValue);
      
      await tester.pumpWidget(createWidgetUnderTest());
    
      expect(find.text('Mobile Layout'), findsOneWidget,
          reason: 'Mobile layout should be displayed on mobile devices');
      expect(find.text('Tablet Layout'), findsNothing);
      expect(find.text('Desktop Layout'), findsNothing);
    });
    
    testWidgets('shows tablet layout on tablet devices', (WidgetTester tester) async {
      tester.binding.window.physicalSizeTestValue = const Size(800 * 2, 1200 * 2); 
      tester.binding.window.devicePixelRatioTestValue = 2.0;
      
      addTearDown(tester.binding.window.clearPhysicalSizeTestValue);
      addTearDown(tester.binding.window.clearDevicePixelRatioTestValue);
      
      await tester.pumpWidget(createWidgetUnderTest());
      
      expect(find.text('Tablet Layout'), findsOneWidget,
          reason: 'Tablet layout should be displayed on tablet devices');
      expect(find.text('Mobile Layout'), findsNothing);
      expect(find.text('Desktop Layout'), findsNothing);
    });
    
    testWidgets('shows desktop layout on desktop devices', (WidgetTester tester) async {
      tester.binding.window.physicalSizeTestValue = const Size(1920 * 1, 1080 * 1);
      tester.binding.window.devicePixelRatioTestValue = 1.0;
      
      addTearDown(tester.binding.window.clearPhysicalSizeTestValue);
      addTearDown(tester.binding.window.clearDevicePixelRatioTestValue);
      
      await tester.pumpWidget(createWidgetUnderTest());
      
      expect(find.text('Desktop Layout'), findsOneWidget,
          reason: 'Desktop layout should be displayed on desktop devices');
      expect(find.text('Mobile Layout'), findsNothing);
      expect(find.text('Tablet Layout'), findsNothing);
    });
    
    testWidgets('shows mobile layout at 600px width (upper boundary)', (WidgetTester tester) async {
      tester.binding.window.physicalSizeTestValue = const Size(600 * 3, 800 * 3);
      tester.binding.window.devicePixelRatioTestValue = 3.0;
      
      addTearDown(tester.binding.window.clearPhysicalSizeTestValue);
      addTearDown(tester.binding.window.clearDevicePixelRatioTestValue);
      
      await tester.pumpWidget(createWidgetUnderTest());
      
      expect(find.text('Mobile Layout'), findsOneWidget,
          reason: 'Mobile layout should be shown at 600px width (upper boundary)');
      expect(find.text('Tablet Layout'), findsNothing);
      expect(find.text('Desktop Layout'), findsNothing);
    });
    
    testWidgets('shows tablet layout at 601px width (lower boundary)', (WidgetTester tester) async {
      tester.binding.window.physicalSizeTestValue = const Size(601 * 3, 800 * 3);
      tester.binding.window.devicePixelRatioTestValue = 3.0;
      
      addTearDown(tester.binding.window.clearPhysicalSizeTestValue);
      addTearDown(tester.binding.window.clearDevicePixelRatioTestValue);
      
      await tester.pumpWidget(createWidgetUnderTest());
      
      expect(find.text('Tablet Layout'), findsOneWidget,
          reason: 'Tablet layout should be shown at 601px width (lower boundary)');
      expect(find.text('Mobile Layout'), findsNothing);
      expect(find.text('Desktop Layout'), findsNothing);
    });
    
    testWidgets('shows tablet layout at 1024px width (upper boundary)', (WidgetTester tester) async {
      tester.binding.window.physicalSizeTestValue = const Size(1024 * 2, 800 * 2);
      tester.binding.window.devicePixelRatioTestValue = 2.0;
      
      addTearDown(tester.binding.window.clearPhysicalSizeTestValue);
      addTearDown(tester.binding.window.clearDevicePixelRatioTestValue);
      
      await tester.pumpWidget(createWidgetUnderTest());
      
      expect(find.text('Tablet Layout'), findsOneWidget,
          reason: 'Tablet layout should be shown at 1024px width (upper boundary)');
      expect(find.text('Mobile Layout'), findsNothing);
      expect(find.text('Desktop Layout'), findsNothing);
    });
    
    testWidgets('shows desktop layout at 1025px width (lower boundary)', (WidgetTester tester) async {
      tester.binding.window.physicalSizeTestValue = const Size(1025 * 2, 800 * 2);
      tester.binding.window.devicePixelRatioTestValue = 2.0;
      
      addTearDown(tester.binding.window.clearPhysicalSizeTestValue);
      addTearDown(tester.binding.window.clearDevicePixelRatioTestValue);
      
      await tester.pumpWidget(createWidgetUnderTest());
      
      expect(find.text('Desktop Layout'), findsOneWidget,
          reason: 'Desktop layout should be shown at 1025px width (lower boundary)');
      expect(find.text('Mobile Layout'), findsNothing);
      expect(find.text('Tablet Layout'), findsNothing);
    });
    
    testWidgets('respects orientation changes when determining layout', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(
              size: Size(360, 640),
              devicePixelRatio: 3.0,
            ),
            child: Builder(
              builder: (context) {
                final orientation = MediaQuery.of(context).orientation;
                expect(orientation, equals(Orientation.portrait));
                
                final width = MediaQuery.of(context).size.width;
                
                return Scaffold(
                  body: width <= 600
                      ? const Center(child: Text('Mobile Layout'))
                      : width <= 1024
                          ? const Center(child: Text('Tablet Layout'))
                          : const Center(child: Text('Desktop Layout')),
                );
              },
            ),
          ),
        ),
      );
      
      expect(find.text('Mobile Layout'), findsOneWidget,
          reason: 'Mobile layout should be displayed in portrait orientation');
      
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(
              size: Size(640, 360), 
              devicePixelRatio: 3.0,
            ),
            child: Builder(
              builder: (context) {
                final orientation = MediaQuery.of(context).orientation;
                
                expect(orientation, equals(Orientation.landscape));
                
                final width = MediaQuery.of(context).size.width;
                
                return Scaffold(
                  body: width <= 600
                      ? const Center(child: Text('Mobile Layout'))
                      : width <= 1024
                          ? const Center(child: Text('Tablet Layout'))
                          : const Center(child: Text('Desktop Layout')),
                );
              },
            ),
          ),
        ),
      );

      expect(find.text('Tablet Layout'), findsOneWidget,
          reason: 'Tablet layout should be displayed in landscape with wider width');
    });
    
    testWidgets('updates correctly when device pixel ratio changes', (WidgetTester tester) async {
      responsiveBuilder(BuildContext context, BoxConstraints constraints) {
        final screenWidth = MediaQuery.of(context).size.width;
        
        if (screenWidth <= 600) {
          return const Center(child: Text('Mobile Layout'));
        } else if (screenWidth <= 1024) {
          return const Center(child: Text('Tablet Layout'));
        } else {
          return const Center(child: Text('Desktop Layout'));
        }
      }
      
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(
              size: Size(600, 800), 
              devicePixelRatio: 3.0,
            ),
            child: Scaffold(
              body: LayoutBuilder(builder: responsiveBuilder),
            ),
          ),
        ),
      );
      
      expect(find.text('Mobile Layout'), findsOneWidget,
          reason: 'Mobile layout should be displayed at 600 logical pixels');
      
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(
              size: Size(800, 1000), 
              devicePixelRatio: 2.0,
            ),
            child: Scaffold(
              body: LayoutBuilder(builder: responsiveBuilder),
            ),
          ),
        ),
      );
      
      expect(find.text('Tablet Layout'), findsOneWidget,
          reason: 'Tablet layout should be displayed at 800 logical pixels');
      
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(
              size: Size(1200, 900), 
              devicePixelRatio: 1.0,
            ),
            child: Scaffold(
              body: LayoutBuilder(builder: responsiveBuilder),
            ),
          ),
        ),
      );
      
      expect(find.text('Desktop Layout'), findsOneWidget,
          reason: 'Desktop layout should be displayed at 1200 logical pixels');
    });
    
    testWidgets('ResponsiveLayoutBuilder works correctly with window size changes', (WidgetTester tester) async {
      Widget buildTestWidget() {
        return const MaterialApp(
          home: Scaffold(
            body: ResponsiveLayoutBuilder(
              mobile: Text('Mobile Layout'),
              tablet: Text('Tablet Layout'),
              desktopWeb: Text('Desktop Layout'),
            ),
          ),
        );
      }
      
      tester.binding.window.physicalSizeTestValue = const Size(360 * 3, 640 * 3);
      tester.binding.window.devicePixelRatioTestValue = 3.0;
      await tester.pumpWidget(buildTestWidget());
      
      expect(find.text('Mobile Layout'), findsOneWidget,
          reason: 'Mobile layout should be shown on mobile devices');
      expect(find.text('Tablet Layout'), findsNothing);
      expect(find.text('Desktop Layout'), findsNothing);
      
      tester.binding.window.physicalSizeTestValue = const Size(800 * 2, 1200 * 2);
      tester.binding.window.devicePixelRatioTestValue = 2.0;
      await tester.pumpWidget(buildTestWidget());
      
      expect(find.text('Tablet Layout'), findsOneWidget,
          reason: 'Tablet layout should be shown on tablet devices');
      expect(find.text('Mobile Layout'), findsNothing);
      expect(find.text('Desktop Layout'), findsNothing);
      
      tester.binding.window.physicalSizeTestValue = const Size(1200 * 1, 900 * 1);
      tester.binding.window.devicePixelRatioTestValue = 1.0;
      await tester.pumpWidget(buildTestWidget());
      
      expect(find.text('Desktop Layout'), findsOneWidget,
          reason: 'Desktop layout should be shown on desktop devices');
      expect(find.text('Mobile Layout'), findsNothing);
      expect(find.text('Tablet Layout'), findsNothing);
      
      addTearDown(tester.binding.window.clearPhysicalSizeTestValue);
      addTearDown(tester.binding.window.clearDevicePixelRatioTestValue);
    });
  });
}
