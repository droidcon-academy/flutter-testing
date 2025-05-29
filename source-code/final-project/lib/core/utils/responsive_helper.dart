import 'package:flutter/material.dart';
import '../constants/app_constants.dart';

enum ResponsiveSizes {
  mobile,
  tablet,
  desktopWeb;

  static ResponsiveSizes whichDevice() {
    final view = WidgetsBinding.instance.platformDispatcher.views.first;
    final physicalSizeWidth = view.physicalSize.width;
    final devicePixelRatio = view.devicePixelRatio;
    final widthInLogicalPixels = physicalSizeWidth / devicePixelRatio;

    return switch (widthInLogicalPixels) {
      <= 600.0 => ResponsiveSizes.mobile,
      >= 601.0 && <= 1024.0 => ResponsiveSizes.tablet,
      _ => ResponsiveSizes.desktopWeb
    };
  }
}

class ResponsiveHelper {
  static bool get isMobile => ResponsiveSizes.whichDevice() == ResponsiveSizes.mobile;
  static bool get isTablet => ResponsiveSizes.whichDevice() == ResponsiveSizes.tablet;
  static bool get isDesktop =>  ResponsiveSizes.whichDevice() == ResponsiveSizes.desktopWeb;

  static ResponsiveSizes get deviceType => ResponsiveSizes.whichDevice();

  static int recipeGridColumns(BuildContext context) {
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;
    final isSplitView = deviceType != ResponsiveSizes.mobile;
    
    final crossAxisCount = switch (deviceType) {
      ResponsiveSizes.mobile => isLandscape ? 3 : 2,
      ResponsiveSizes.tablet => isLandscape ? (isSplitView ? 3 : 4) : (isSplitView ? 2 : 3),
      ResponsiveSizes.desktopWeb => isLandscape ? (isSplitView ? 4 : 5) : (isSplitView ? 3 : 4),
    };
    return crossAxisCount;
  }

  static int get alphabetGridColumns {
    if (isDesktop) return 6;
    if (isTablet) return 4;
    return 3;
  }

  static EdgeInsets get screenPadding {
    if (isDesktop) {
      return const EdgeInsets.all(Sizes.largeSpacing);
    }
    if (isTablet) {
      return const EdgeInsets.all(Sizes.spacing);
    }
    if (isMobile) {
      return const EdgeInsets.all(Sizes.smallSpacing);
    }
    return const EdgeInsets.symmetric(
      horizontal: Sizes.smallSpacing,
      vertical: Sizes.spacing,
    );
  }
}