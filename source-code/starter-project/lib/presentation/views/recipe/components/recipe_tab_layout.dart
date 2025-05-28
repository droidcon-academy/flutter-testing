import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:recipevault/core/utils/responsive_helper.dart';
import 'package:recipevault/domain/entities/recipe.dart';
import 'package:recipevault/presentation/viewmodels/navigation_viewmodel.dart';
import 'package:recipevault/presentation/views/home/home_screen.dart';
import 'package:recipevault/presentation/views/recipe/components/recipe_grid_view.dart';
import 'package:recipevault/presentation/views/recipe/components/recipe_list_view.dart';

class RecipeListTab extends ConsumerStatefulWidget {
  const RecipeListTab({
    super.key,
    this.onRecipeSelected,
  });

  final ValueChanged<Recipe>? onRecipeSelected;

  @override
  ConsumerState<RecipeListTab> createState() => _RecipeListTabState();
}

class _RecipeListTabState extends ConsumerState<RecipeListTab> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    final deviceType = ResponsiveHelper.deviceType;
    final selectedLetter = ref.watch(selectedLetterProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(selectedLetter != null ? 'Recipes Starting With Letter: ${selectedLetter.toUpperCase()}' : 'All Recipes'),
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
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.view_list), text: 'Recipe List'),
            Tab(icon: Icon(Icons.grid_view), text: 'Recipe Grid'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          RecipeListView(
            onRecipeSelected: widget.onRecipeSelected,
            storageKey: 'tabListView',
          ),
          RecipeGridView(
            onRecipeSelected: widget.onRecipeSelected,
            storageKey: 'tabGridView',
            deviceType: deviceType,
          ),
        ],
      ),
    );
  }
}
