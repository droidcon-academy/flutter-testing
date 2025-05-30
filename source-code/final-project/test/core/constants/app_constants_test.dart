import 'package:flutter_test/flutter_test.dart';
import 'package:recipevault/core/constants/app_constants.dart';

void main() {
  group('Sizes class constants', () {
    group('Recipe image dimensions', () {
      test('recipeImageHeight should have correct value', () {
        expect(Sizes.recipeImageHeight, equals(580.0));
      });

      test('recipeImagePreviewSize should have correct value', () {
        expect(Sizes.recipeImagePreviewSize, equals(120.0));
      });
    });

    group('Icon sizes', () {
      test('iconLarge should have correct value', () {
        expect(Sizes.iconLarge, equals(128.0));
      });

      test('iconMedium should have correct value', () {
        expect(Sizes.iconMedium, equals(38.0));
      });

      test('iconSmall should have correct value', () {
        expect(Sizes.iconSmall, equals(32.0));
      });
    });

    group('Layout dimensions', () {
      test('listPanelWidth should have correct value', () {
        expect(Sizes.listPanelWidth, equals(320.0));
      });

      test('gridItemSize should have correct value', () {
        expect(Sizes.gridItemSize, equals(180.0));
      });

      test('verticalDividerWidth should have correct value', () {
        expect(Sizes.verticalDividerWidth, equals(1.0));
      });
    });

    group('Spacing and padding', () {
      test('spacing should have correct value', () {
        expect(Sizes.spacing, equals(16.0));
      });

      test('smallSpacing should have correct value', () {
        expect(Sizes.smallSpacing, equals(8.0));
      });

      test('largeSpacing should have correct value', () {
        expect(Sizes.largeSpacing, equals(24.0));
      });

      test('spacing values should follow a logical pattern', () {
        expect(Sizes.smallSpacing, lessThan(Sizes.spacing));
        expect(Sizes.spacing, lessThan(Sizes.largeSpacing));
        expect(Sizes.largeSpacing, equals(Sizes.spacing * 1.5));
        expect(Sizes.smallSpacing, equals(Sizes.spacing / 2));
      });
    });

    group('Border radius', () {
      test('radiusSmall should have correct value', () {
        expect(Sizes.radiusSmall, equals(4.0));
      });

      test('radiusMedium should have correct value', () {
        expect(Sizes.radiusMedium, equals(8.0));
      });

      test('radiusLarge should have correct value', () {
        expect(Sizes.radiusLarge, equals(16.0));
      });

      test('radius values should follow a logical progression', () {
        expect(Sizes.radiusSmall, lessThan(Sizes.radiusMedium));
        expect(Sizes.radiusMedium, lessThan(Sizes.radiusLarge));
        expect(Sizes.radiusMedium, equals(Sizes.radiusSmall * 2));
        expect(Sizes.radiusLarge, equals(Sizes.radiusMedium * 2));
      });
    });

    group('Animation durations', () {
      test('animationDuration should have correct value', () {
        expect(Sizes.animationDuration, equals(const Duration(milliseconds: 300)));
      });

      test('longAnimationDuration should have correct value', () {
        expect(Sizes.longAnimationDuration, equals(const Duration(milliseconds: 500)));
      });

      test('animation durations should be consistent', () {
        expect(Sizes.animationDuration.inMilliseconds, 
               lessThan(Sizes.longAnimationDuration.inMilliseconds));
      });
    });

    group('Navigation UI constants', () {
      test('navIconMedium should have correct value', () {
        expect(Sizes.navIconMedium, equals(32.0));
      });

      test('navRailOpacity should have correct value', () {
        expect(Sizes.navRailOpacity, equals(0.2));
      });

      test('navLeadingPadding should have correct value', () {
        expect(Sizes.navLeadingPadding, equals(24.0));
      });
    });

    group('Dimensional consistency', () {
      test('icon sizes should be consistent', () {
        expect(Sizes.iconSmall, lessThan(Sizes.iconMedium));
        expect(Sizes.iconMedium, lessThan(Sizes.iconLarge));
      });

      test('nav icon size should relate to normal icon sizes', () {
        expect(Sizes.navIconMedium, equals(Sizes.iconSmall));
      });
    });
  });
}
