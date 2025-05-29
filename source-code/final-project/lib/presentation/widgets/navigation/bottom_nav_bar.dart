import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class NavBar extends ConsumerWidget {
  const NavBar({super.key, required this.selectedIndex, required this.onDestinationSelected});

  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return NavigationBar(
      indicatorColor: theme.colorScheme.secondaryContainer,
      backgroundColor: theme.colorScheme.surface,
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.menu_book),
          label: 'Recipe',
        ),
        NavigationDestination(
          icon: Icon(Icons.dashboard),
          label: 'Dashboard',
        ),
      ],
      selectedIndex: selectedIndex,
      onDestinationSelected: (index) {
        onDestinationSelected(index);
      },
    );
  }
}