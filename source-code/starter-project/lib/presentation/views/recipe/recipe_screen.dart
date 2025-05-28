import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:recipevault/presentation/viewmodels/navigation_viewmodel.dart';
import 'package:recipevault/presentation/widgets/navigation/bottom_nav_bar.dart';
import 'package:recipevault/presentation/widgets/navigation/nav_rail.dart';
import '../../../core/constants/app_constants.dart';
import '../../viewmodels/recipe_viewmodel.dart';
import '../../widgets/common/layout/responsive_layout_builder.dart';

class RecipeScreen extends ConsumerStatefulWidget {
  const RecipeScreen({super.key});

  @override
  ConsumerState<RecipeScreen> createState() => _RecipeScreenState();
}

class _RecipeScreenState extends ConsumerState<RecipeScreen> {
  @override
  void initState() {
    super.initState();
    
    Future.microtask(() {
      // ref.read(recipeProvider.notifier).loadFavorites();
      // ref.read(recipeProvider.notifier).loadBookmarks();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(recipeProvider);

    final currentPageIndex = ref.watch(currentPageIndexProvider);

    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48.0, color: Colors.red),
            const SizedBox(height: Sizes.spacing),
            Text(
              state.error!,
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ResponsiveLayoutBuilder(
      mobile: 
      Scaffold(
        body: IndexedStack(
          index: currentPageIndex,
          children: SelectedPage.bodySelectedPage      
        ),
        bottomNavigationBar: NavBar(
          selectedIndex: currentPageIndex,
          onDestinationSelected: (index) {
            ref.read(currentPageIndexProvider.notifier).state = index;
          },
        ),
      ),
      tablet: Scaffold(
        body: IndexedStack(
          index: currentPageIndex,
          children: SelectedPage.bodySelectedPageSplitScreen      
        ),
        bottomNavigationBar: NavBar(
          selectedIndex: currentPageIndex,
          onDestinationSelected: (index) {
            ref.read(currentPageIndexProvider.notifier).state = index;
          },
        ),
      ),
      desktopWeb: Scaffold(
        body: Row(
          children: [
            SingleChildScrollView(
              child: Container(
                constraints: const BoxConstraints(
                  minHeight: Sizes.listPanelWidth,
                ),
                height: MediaQuery.of(context).size.height,
                child: NavRail(
                  selectedIndex: currentPageIndex,
                  onDestinationSelected: (index) {
                    ref.read(currentPageIndexProvider.notifier).state = index;
                  },
                )
              )
            ),
            const VerticalDivider(width: Sizes.verticalDividerWidth),
            Expanded(
              child: IndexedStack(
                index: currentPageIndex,
                children: SelectedPage.bodySelectedPageSplitScreen      
              ),
            ),
          ],
        )
      ),
    );
  }
}