import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:recipevault/core/constants/app_constants.dart';
import 'package:recipevault/core/utils/responsive_helper.dart';
import 'package:recipevault/domain/entities/recipe.dart';
import 'package:recipevault/presentation/viewmodels/navigation_viewmodel.dart';
import 'package:recipevault/presentation/views/home/home_screen.dart';
import 'package:recipevault/presentation/views/recipe/components/recipe_grid_view.dart';
import 'package:recipevault/presentation/views/recipe/components/recipe_list_view.dart';

class RecipeSplitView extends ConsumerStatefulWidget {
  const RecipeSplitView({
    super.key,
    this.onRecipeSelected,
  });

  final ValueChanged<Recipe>? onRecipeSelected;

  @override
  ConsumerState<RecipeSplitView> createState() => _RecipeSplitViewState();
}

class _RecipeSplitViewState extends ConsumerState<RecipeSplitView> {
  final ScrollController _listScrollController = ScrollController();
  final ScrollController _gridScrollController = ScrollController();

  @override
  void dispose() {
    _listScrollController.dispose();
    _gridScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final deviceType = ResponsiveSizes.whichDevice();
    final selectedLetter = ref.watch(selectedLetterProvider);
    
    return Scaffold(
      appBar: deviceType == ResponsiveSizes.mobile
          ? null
          : PreferredSize(
              preferredSize: const Size.fromHeight(kToolbarHeight * 0.8),
              child: AppBar(
                title: Text(
                  selectedLetter != null ? 'Recipes Starting With Letter: ${selectedLetter.toUpperCase()}' : 'All Recipes',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                centerTitle: true,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () {
                    ref.read(selectedLetterProvider.notifier).state = null;
                    
                    if (Navigator.of(context).canPop()) {
                      Navigator.of(context).pop();
                    } else {
                      ref.read(navigationProvider.notifier).setSelectedIndex(0);
                    }
                  },
                ),
              ),
            ),
      body: Row(
        children: [
          SizedBox(
            width: Sizes.listPanelWidth,
            child: RecipeListView(
              onRecipeSelected: widget.onRecipeSelected,
              scrollController: _listScrollController,
              storageKey: 'splitViewListView',
            ),
          ),

          const VerticalDivider(width: Sizes.verticalDividerWidth),
          
          Expanded(
            child: RecipeGridView(
              onRecipeSelected: widget.onRecipeSelected,
              scrollController: _gridScrollController,
              storageKey: 'splitViewGridView',
              deviceType: deviceType,
            ),
          ),
        ],
      ),
    );
  }
}
