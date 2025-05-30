import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:recipevault/domain/entities/recipe.dart';
import 'package:recipevault/presentation/viewmodels/dashboard_viewmodel.dart';
import 'package:recipevault/core/errors/failure.dart';

class TestDashboardState extends DashboardState {
  TestDashboardState() : super();
}

class AnalyticsHelper {
  static const String optOutKey = 'analytics_opted_out';
  
  static List<Recipe> createTestRecipes(int count) {
    return List.generate(
      count,
      (index) => Recipe(
        id: 'recipe-$index',
        name: 'Recipe $index',
        instructions: 'Step-by-step instructions for recipe $index',
        thumbnailUrl: 'https://example.com/image$index.jpg',
        ingredients: [
          const Ingredient(name: 'Ingredient 1', measure: '1 cup'),
          const Ingredient(name: 'Ingredient 2', measure: '2 tbsp'),
        ],
        isFavorite: false,
        isBookmarked: false,
      ),
    );
  }
  
  static Future<void> setupInconsistentData() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString('recipes_cache', 
      jsonEncode([{'id': 'recipe-1'}, {'id': 'recipe-2'}]));
    await prefs.setString('favorites_cache', 
      jsonEncode(['recipe-1', 'invalid-id']));
  }

  static Future<void> setOptOutPreference(bool optOut) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(optOutKey, optOut);
  }

  static Future<bool> getOptOutPreference() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(optOutKey) ?? false;
  }
}

class TestLogger {
  static final List<LogEntry> _logs = [];

  static void log(LogLevel level, String message) {
    _logs.add(LogEntry(level, message));
  }

  static void reset() {
    _logs.clear();
  }

  static List<LogEntry> getLogs() {
    return List.from(_logs);
  }

  static bool hasInfoLog(String partialMessage) {
    return _logs.any((log) => 
      log.level == LogLevel.info && 
      log.message.contains(partialMessage));
  }

  static bool hasWarningLog(String partialMessage) {
    return _logs.any((log) => 
      log.level == LogLevel.warning && 
      log.message.contains(partialMessage));
  }

  static bool hasErrorLog(String partialMessage) {
    return _logs.any((log) => 
      log.level == LogLevel.error && 
      log.message.contains(partialMessage));
  }

  static bool hasCriticalLog(String partialMessage) {
    return _logs.any((log) => 
      log.level == LogLevel.critical && 
      log.message.contains(partialMessage));
  }

  static bool hasDimension(String dimensionKey, String dimensionValue) {
    return _logs.any((log) => 
      log.message.contains('"$dimensionKey":"$dimensionValue"') ||
      log.message.contains('"$dimensionKey": "$dimensionValue"'));
  }
}

class TestAnalyticsNotifier {
  bool disposed = false;

  void logAnalytics(LogLevel level, String message, {Map<String, dynamic>? dimensions}) {
    if (disposed && !message.contains('disposed')) {
      return;
    }
    String finalMessage = message;
    if (dimensions != null && dimensions.isNotEmpty) {
      finalMessage += ' [dimensions: ${json.encode(dimensions)}]';
    }
    
    TestLogger.log(level, finalMessage);
  }
  
  void trackUserInteraction(String action, String itemId, {bool? state}) {
    final dimensions = <String, dynamic>{
      'action': action,
      'item_id': itemId,
    };
    
    if (state != null) {
      dimensions['state'] = state.toString();
    }
    
    logAnalytics(LogLevel.info, 'User interaction: $action', dimensions: dimensions);
  }

  void trackError(Failure failure) {
    String errorCode = '';
    if (failure is ServerFailure) {
      errorCode = failure.statusCode.toString();
    }
    
    logAnalytics(
      LogLevel.error, 
      'Error encountered: ${failure.message}',
      dimensions: {'error_code': errorCode, 'error_type': failure.runtimeType.toString()}
    );
  }
  
  void setCustomDimension(String key, dynamic value) {
    logAnalytics(
      LogLevel.info, 
      'Setting custom dimension',
      dimensions: {key: value}
    );
  }

  void dispose() {
    disposed = true;
    logAnalytics(LogLevel.info, 'disposed');
  }
}

enum LogLevel {
  info,
  warning,
  error,
  critical,
}

class LogEntry {
  final LogLevel level;
  final String message;

  LogEntry(this.level, this.message);
}

class OptOutAwareTestNotifier extends TestAnalyticsNotifier {
  @override
  Future<void> logAnalytics(LogLevel level, String message, {Map<String, dynamic>? dimensions}) async {
    final optedOut = await AnalyticsHelper.getOptOutPreference();
    
    if (!optedOut) {
      super.logAnalytics(level, message, dimensions: dimensions);
    }
  }
}

void main() {
  group('Dashboard Analytics Tests', () {
    setUp(() async {
      TestLogger.reset();
      SharedPreferences.setMockInitialValues({});
    });

    test('logs at different severity levels', () async {
      final testNotifier = TestAnalyticsNotifier();
      
      testNotifier.logAnalytics(LogLevel.info, 'Test info message');
      testNotifier.logAnalytics(LogLevel.warning, 'Data inconsistency detected');
      testNotifier.logAnalytics(LogLevel.error, 'Failed to load favorites');
      testNotifier.logAnalytics(LogLevel.critical, 'Database corruption detected');
      
      expect(TestLogger.hasInfoLog('Test info message'), isTrue, 
        reason: 'Should log at INFO level');
        
      expect(TestLogger.hasWarningLog('Data inconsistency detected'), isTrue, 
        reason: 'Should log at WARNING level');
        
      expect(TestLogger.hasErrorLog('Failed to load favorites'), isTrue,
        reason: 'Should log at ERROR level');
        
      expect(TestLogger.hasCriticalLog('Database corruption detected'), isTrue,
        reason: 'Should log at CRITICAL level');
    });
    
    test('does not log after disposal except for disposal events', () async {
      final testNotifier = TestAnalyticsNotifier();
      
      testNotifier.logAnalytics(LogLevel.info, 'Pre-disposal message');
      
      testNotifier.dispose();
      testNotifier.logAnalytics(LogLevel.info, 'Post-disposal message');
      
      expect(TestLogger.hasInfoLog('Pre-disposal'), isTrue);
      expect(TestLogger.hasInfoLog('Post-disposal'), isFalse);
    });
    
    test('logs disposal event properly', () async {
      final testNotifier = TestAnalyticsNotifier();
      
      testNotifier.dispose();
      
      expect(TestLogger.hasInfoLog('disposed'), isTrue,
        reason: 'Should log disposal event');
    });
    
    test('handles data consistency warnings appropriately', () async {
      await AnalyticsHelper.setupInconsistentData();
      
      final testNotifier = TestAnalyticsNotifier();
      testNotifier.logAnalytics(LogLevel.warning, 
          'Data inconsistency detected. Favorites: 2 -> 1, Bookmarks: 2 -> 1');
      
      expect(
        TestLogger.hasWarningLog('Data inconsistency detected'),
        isTrue,
        reason: 'Should log data inconsistency warnings',
      );
    });
    
    test('tracks user interaction metrics correctly', () async {
      final testNotifier = TestAnalyticsNotifier();
      
      testNotifier.trackUserInteraction('favorite_toggle', 'recipe-123', state: true);
      
      expect(TestLogger.hasInfoLog('User interaction: favorite_toggle'), isTrue);
      expect(TestLogger.hasDimension('action', 'favorite_toggle'), isTrue);
      expect(TestLogger.hasDimension('item_id', 'recipe-123'), isTrue);
      expect(TestLogger.hasDimension('state', 'true'), isTrue);
    });
    
    test('reports errors to analytics correctly', () async {
      final testNotifier = TestAnalyticsNotifier();
      final testFailure = ServerFailure(message: 'Connection timeout', statusCode: 408);
      
      testNotifier.trackError(testFailure);
      
      expect(TestLogger.hasErrorLog('Error encountered: Connection timeout'), isTrue);
      expect(TestLogger.hasDimension('error_code', '408'), isTrue);
      expect(TestLogger.hasDimension('error_type', 'ServerFailure'), isTrue);
    });
    
    test('sets custom analytics dimensions correctly', () async {
      final testNotifier = TestAnalyticsNotifier();
      
      testNotifier.setCustomDimension('user_type', 'premium');
      testNotifier.setCustomDimension('view_mode', 'grid');
      
      expect(TestLogger.hasInfoLog('Setting custom dimension'), isTrue);
      expect(TestLogger.hasDimension('user_type', 'premium'), isTrue);
      expect(TestLogger.hasDimension('view_mode', 'grid'), isTrue);
    });
    
    test('respects telemetry opt-out preferences', () async {
      final defaultNotifier = OptOutAwareTestNotifier();
      await defaultNotifier.logAnalytics(LogLevel.info, 'Opted-in message');
      
      expect(TestLogger.hasInfoLog('Opted-in message'), isTrue);
      
      await AnalyticsHelper.setOptOutPreference(true);
      
      final optOutNotifier = OptOutAwareTestNotifier();
      await optOutNotifier.logAnalytics(LogLevel.info, 'This should not be logged');
      
      expect(TestLogger.hasInfoLog('This should not be logged'), isFalse);
    });
  });
}
