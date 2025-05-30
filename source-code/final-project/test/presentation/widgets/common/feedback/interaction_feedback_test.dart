import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recipevault/presentation/widgets/common/feedback/interaction_feedback.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  
  group('InteractionFeedback', () {
    
    test('light() should call HapticFeedback.lightImpact', () async {
      final List<MethodCall> log = <MethodCall>[];
      
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (MethodCall methodCall) async {
          log.add(methodCall);
          return null;
        }
      );
      
      InteractionFeedback.light();
      
      expect(log, hasLength(1));
      expect(log.first.method, 'HapticFeedback.vibrate');
      expect(log.first.arguments, 'HapticFeedbackType.lightImpact');
    });
    
    test('medium() should call HapticFeedback.mediumImpact', () async {
      final List<MethodCall> log = <MethodCall>[];
      
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (MethodCall methodCall) async {
          log.add(methodCall);
          return null;
        }
      );
      
      InteractionFeedback.medium();
      
      expect(log, hasLength(1));
      expect(log.first.method, 'HapticFeedback.vibrate');
      expect(log.first.arguments, 'HapticFeedbackType.mediumImpact');
    });
    
    test('heavy() should call HapticFeedback.heavyImpact', () async {
      final List<MethodCall> log = <MethodCall>[];
      
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (MethodCall methodCall) async {
          log.add(methodCall);
          return null;
        }
      );
      
      InteractionFeedback.heavy();
      
      expect(log, hasLength(1));
      expect(log.first.method, 'HapticFeedback.vibrate');
      expect(log.first.arguments, 'HapticFeedbackType.heavyImpact');
    });
    
    test('selection() should call HapticFeedback.selectionClick', () async {
      final List<MethodCall> log = <MethodCall>[];
      
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (MethodCall methodCall) async {
          log.add(methodCall);
          return null;
        }
      );
      
      InteractionFeedback.selection();
      
      expect(log, hasLength(1));
      expect(log.first.method, 'HapticFeedback.vibrate');
      expect(log.first.arguments, 'HapticFeedbackType.selectionClick');
    });
    
    test('vibrate() should call HapticFeedback.vibrate', () async {
      final List<MethodCall> log = <MethodCall>[];
      
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (MethodCall methodCall) async {
          log.add(methodCall);
          return null;
        }
      );
      
      InteractionFeedback.vibrate();
      
      expect(log, hasLength(1));
      expect(log.first.method, 'HapticFeedback.vibrate');
      expect(log.first.arguments, null);
    });
  });
}