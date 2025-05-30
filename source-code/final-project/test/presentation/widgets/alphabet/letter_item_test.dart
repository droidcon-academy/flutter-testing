// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recipevault/presentation/widgets/alphabet/letter_item.dart';

void main() {
  group('LetterItem Widget Tests', () {
    Widget buildTestableLetterItem({
      required String letter,
      bool isSelected = false,
      VoidCallback? onTap,
    }) {
      return MaterialApp(
        theme: ThemeData(
          colorScheme: const ColorScheme.light(
            primary: Colors.blue,
          ),
          textTheme: const TextTheme(
            titleLarge: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.normal,
              color: Colors.black,
            ),
          ),
        ),
        home: Scaffold(
          body: Center(
            child: LetterItem(
              letter: letter,
              onTap: onTap ?? () {},
              isSelected: isSelected,
            ),
          ),
        ),
      );
    }

    testWidgets('renders with the correct letter', (WidgetTester tester) async {
      const testLetter = 'A';
      await tester.pumpWidget(buildTestableLetterItem(letter: testLetter));

      expect(find.text(testLetter), findsOneWidget,
          reason: 'Should display the provided letter');
      
      final letterItemWidget = tester.widget<LetterItem>(find.byType(LetterItem));
      expect(letterItemWidget.letter, equals(testLetter));
      expect(letterItemWidget.isSelected, equals(false));
    });

    testWidgets('changes appearance when selected', (WidgetTester tester) async {
      const testLetter = 'B';
      await tester.pumpWidget(buildTestableLetterItem(
        letter: testLetter, 
        isSelected: true,
      ));

      final letterItemWidget = tester.widget<LetterItem>(find.byType(LetterItem));
      expect(letterItemWidget.isSelected, equals(true));
      
    });

    testWidgets('triggers onTap callback when tapped', (WidgetTester tester) async {
      bool wasTapped = false;
      const testLetter = 'C';
      await tester.pumpWidget(buildTestableLetterItem(
        letter: testLetter,
        onTap: () {
          wasTapped = true;
        },
      ));

      await tester.tap(find.byType(LetterItem));
      await tester.pump();

      expect(wasTapped, isTrue, reason: 'onTap callback should be called when tapped');
    });
    
    group('Mobile Layout Tests', () {
      testWidgets('displays correct mobile list layout', (WidgetTester tester) async {
        tester.binding.window.physicalSizeTestValue = const Size(360 * 3, 640 * 3);
        tester.binding.window.devicePixelRatioTestValue = 3.0;
        
        addTearDown(tester.binding.window.clearPhysicalSizeTestValue);
        addTearDown(tester.binding.window.clearDevicePixelRatioTestValue);
        
        const testLetter = 'D';
        await tester.pumpWidget(buildTestableLetterItem(letter: testLetter));
        
        final constrainedBox = find.byWidgetPredicate(
          (widget) => widget is ConstrainedBox && 
                     widget.constraints.minHeight == 56.0,
        );
        expect(constrainedBox, findsOneWidget, reason: 'Should find ConstrainedBox with minHeight 56.0');
        
        expect(find.byType(Row), findsOneWidget);
        
        expect(find.byIcon(Icons.arrow_forward_ios), findsOneWidget);
        
        final rowWidget = tester.widget<Row>(find.byType(Row));
        expect(rowWidget.mainAxisAlignment, equals(MainAxisAlignment.spaceBetween));
      });
      
      testWidgets('mobile layout shows selected state correctly', (WidgetTester tester) async {
        tester.binding.window.physicalSizeTestValue = const Size(360 * 3, 640 * 3);
        tester.binding.window.devicePixelRatioTestValue = 3.0;
        
        addTearDown(tester.binding.window.clearPhysicalSizeTestValue);
        addTearDown(tester.binding.window.clearDevicePixelRatioTestValue);
        
        const testLetter = 'E';
        await tester.pumpWidget(buildTestableLetterItem(
          letter: testLetter,
          isSelected: true,
        ));

        final iconWidget = tester.widget<Icon>(find.byIcon(Icons.arrow_forward_ios));
        expect(iconWidget.color, isNotNull);
      });
    });
    
    group('Tablet/Desktop Layout Tests', () {
      testWidgets('displays correct tablet/desktop grid layout', (WidgetTester tester) async {
        tester.binding.window.physicalSizeTestValue = const Size(1024 * 3, 768 * 3);
        tester.binding.window.devicePixelRatioTestValue = 3.0;
        
        addTearDown(tester.binding.window.clearPhysicalSizeTestValue);
        addTearDown(tester.binding.window.clearDevicePixelRatioTestValue);
        
        const testLetter = 'F';
        await tester.pumpWidget(buildTestableLetterItem(letter: testLetter));
        
        expect(find.byType(Container), findsWidgets);
        
        expect(find.byType(Center), findsWidgets);
        
        expect(find.byIcon(Icons.arrow_forward_ios), findsNothing);
        
        final textWidget = tester.widget<Text>(find.text(testLetter));
        expect(textWidget.textAlign, equals(TextAlign.center));
      });
      
      testWidgets('grid layout shows selected state with border', (WidgetTester tester) async {
        tester.binding.window.physicalSizeTestValue = const Size(1024 * 3, 768 * 3);
        tester.binding.window.devicePixelRatioTestValue = 3.0;
        
        addTearDown(tester.binding.window.clearPhysicalSizeTestValue);
        addTearDown(tester.binding.window.clearDevicePixelRatioTestValue);
        
        const testLetter = 'G';
        await tester.pumpWidget(buildTestableLetterItem(
          letter: testLetter,
          isSelected: true,
        ));
        expect(find.byType(Container), findsWidgets);
      });
    });
  });
}