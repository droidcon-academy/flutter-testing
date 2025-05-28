import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:recipevault/presentation/views/dashboard/components/dashboard_panel.dart';
import 'package:recipevault/presentation/views/recipe/components/recipe_panel.dart';

class NavigationState {
  final int selectedIndex;

  const NavigationState({
    this.selectedIndex = 0,
  });

  NavigationState copyWith({
    int? selectedIndex,
  }) {
    return NavigationState(
      selectedIndex: selectedIndex ?? this.selectedIndex,
    );
  }
}

class NavigationViewModel extends StateNotifier<NavigationState> {
  NavigationViewModel() : super(const NavigationState());

  void setSelectedIndex(int index) {
    state = state.copyWith(selectedIndex: index);
  }
}

final navigationProvider = StateNotifierProvider<NavigationViewModel, NavigationState>((ref) {
  return NavigationViewModel();
});

final currentPageIndexProvider = StateProvider<int>((ref) => 0);

class SelectedPage {
  static List<Widget> get bodySelectedPage => [
    const RecipePanel(),
    const DashboardPanel(),
  ];

  static List<Widget> get bodySelectedPageSplitScreen => [
    const RecipePanel(),
    const DashboardPanel(),
  ];
}

class SelectedDashboardPage {
  static List<Widget> get bodySelectedDashboardPage => [
    const DashboardPanel(),
    const Center(child: Text('Dashboard Settings')),
  ];

  static List<Widget> get bodySelectedDashboardPageSplitScreen => [
    const DashboardPanel(),
    const Center(child: Text('Dashboard Settings')),
  ];
}