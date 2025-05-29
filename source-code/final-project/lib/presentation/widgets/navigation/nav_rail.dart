import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../common/feedback/interaction_feedback.dart';


class NavRail extends ConsumerWidget {
  const NavRail({super.key, required this.selectedIndex, required this.onDestinationSelected});

  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return NavigationRail(
      useIndicator: true,
      indicatorColor: theme.colorScheme.secondaryContainer,
      backgroundColor: theme.colorScheme.surface.withOpacity(Sizes.navRailOpacity),
      leading: Padding(
        padding: const EdgeInsets.only(top: Sizes.navLeadingPadding),
        child: Icon(
          Icons.flutter_dash,
          size: Sizes.iconMedium,
          color: theme.colorScheme.primary,
        ),
      ),
      destinations: const [
        NavigationRailDestination(
          icon: Icon(Icons.menu_book),
          label: Text('Recipe'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.dashboard),
          label: Text('Dashboard'),
        ),
      ],
      selectedIndex: selectedIndex,
      onDestinationSelected: (index) {
        InteractionFeedback.selection();
        onDestinationSelected(index);
      },
    );
  }
}