import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import '../../../../core/utils/responsive_helper.dart';


class ResponsiveLayoutBuilder extends StatelessWidget {
  const ResponsiveLayoutBuilder({
    super.key,
    required this.mobile,
    required this.tablet,
    required this.desktopWeb,
  });

  final Widget mobile;
  final Widget tablet;
  final Widget desktopWeb;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (
        BuildContext context,
        BoxConstraints constraints,
      ) {
        return switch (ResponsiveSizes.whichDevice()) {
          ResponsiveSizes.mobile => mobile,
          ResponsiveSizes.tablet => tablet,
          _ => desktopWeb
        };
      },
    );
  }
}
