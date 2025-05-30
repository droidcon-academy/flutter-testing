import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recipevault/presentation/widgets/overlays/heart_overlay.dart';

void main() {
  group('HeartOverlay Widget Tests', () {
    testWidgets('does not display when isVisible is false', (WidgetTester tester) async {
     
      await tester.pumpWidget(
        const MaterialApp(
          home: Stack(
            children: [
              HeartOverlay(
                isVisible: false,
                position: Offset(100, 100),
              ),
            ],
          ),
        ),
      );
      
      expect(find.byType(HeartOverlay), findsOneWidget,
          reason: 'HeartOverlay widget should exist in the widget tree');
      expect(find.byIcon(Icons.favorite), findsNothing,
          reason: 'Heart icon should not be visible when isVisible is false');
    });
    
    testWidgets('displays heart icon when isVisible is true', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Stack(
            children: [
              HeartOverlay(
                isVisible: true,
                position: Offset(100, 100),
              ),
            ],
          ),
        ),
      );
      
      await tester.pump();
      
      expect(find.byIcon(Icons.favorite), findsOneWidget,
          reason: 'Heart icon should be visible when isVisible is true');
    });
    
    testWidgets('uses the correct position', (WidgetTester tester) async {
      const testPosition = Offset(150, 200);
      
      await tester.pumpWidget(
        const MaterialApp(
          home: Stack(
            children: [
              HeartOverlay(
                isVisible: true,
                position: testPosition,
              ),
            ],
          ),
        ),
      );

      await tester.pump();
      
      final positionedWidget = tester.widget<Positioned>(
          find.ancestor(of: find.byIcon(Icons.favorite), matching: find.byType(Positioned)));
      
      expect(positionedWidget.left, testPosition.dx,
          reason: 'Heart overlay should be positioned at the correct X coordinate');
      expect(positionedWidget.top, testPosition.dy,
          reason: 'Heart overlay should be positioned at the correct Y coordinate');
    });
    
    testWidgets('applies custom color correctly', (WidgetTester tester) async {
      const testColor = Colors.blue;
      
      await tester.pumpWidget(
        const MaterialApp(
          home: Stack(
            children: [
              HeartOverlay(
                isVisible: true,
                position: Offset(100, 100),
                color: testColor,
              ),
            ],
          ),
        ),
      );
      
      await tester.pump();
      final iconWidget = tester.widget<Icon>(find.byType(Icon));
      
      expect(iconWidget.color, testColor,
          reason: 'Heart icon should use the custom color provided');
    });
    
    testWidgets('applies custom size correctly', (WidgetTester tester) async {
      const testSize = 100.0;
      
      await tester.pumpWidget(
        const MaterialApp(
          home: Stack(
            children: [
              HeartOverlay(
                isVisible: true,
                position: Offset(100, 100),
                size: testSize,
              ),
            ],
          ),
        ),
      );
      
      await tester.pump();
      
      final iconWidget = tester.widget<Icon>(find.byType(Icon));
      
      expect(iconWidget.size, testSize,
          reason: 'Heart icon should use the custom size provided');
    });
    
    testWidgets('animation starts when isVisible changes from false to true', 
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: HeartOverlayTestHarness(),
        ),
      );

      expect(find.byIcon(Icons.favorite), findsNothing,
          reason: 'Heart icon should not be visible initially');
      
      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();
      
      expect(find.byIcon(Icons.favorite), findsOneWidget,
          reason: 'Heart icon should become visible after toggling');
      
      expect(find.byType(Opacity), findsOneWidget,
          reason: 'Opacity widget should exist for the fade animation');
      
      final opacityWidget1 = tester.widget<Opacity>(find.byType(Opacity));
      final initialOpacity = opacityWidget1.opacity;
      
      await tester.pump(const Duration(milliseconds: 200));
      
      final opacityWidget2 = tester.widget<Opacity>(find.byType(Opacity));
      final laterOpacity = opacityWidget2.opacity;
      
      expect(initialOpacity != laterOpacity, isTrue,
          reason: 'Opacity should change during animation, proving animation is in progress');
      
      expect(find.byType(Transform), findsWidgets,
          reason: 'Transform widgets should exist for scale and translation animations');
    });
  });
}

class HeartOverlayTestHarness extends StatefulWidget {
  const HeartOverlayTestHarness({super.key});

  @override
  State<HeartOverlayTestHarness> createState() => _HeartOverlayTestHarnessState();
}

class _HeartOverlayTestHarnessState extends State<HeartOverlayTestHarness> {
  bool _isVisible = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Center(
            child: ElevatedButton(
              onPressed: () {
                setState(() {
                  _isVisible = true;
                });
              },
              child: const Text('Show Heart'),
            ),
          ),
          HeartOverlay(
            isVisible: _isVisible,
            position: const Offset(200, 200),
          ),
        ],
      ),
    );
  }
}