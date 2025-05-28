import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:recipevault/presentation/viewmodels/navigation_viewmodel.dart';
import '../../../core/constants/app_constants.dart';

import '../../viewmodels/dashboard_viewmodel.dart';
import '../../widgets/common/layout/responsive_layout_builder.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    
    Future.microtask(() {
      ref.read(dashboardProvider.notifier).initializeData();
    });
  }


  @override
  Widget build(BuildContext context) {
    final dashboardState = ref.watch(dashboardProvider);
    
    _showPartialDataNotificationIfNeeded(context, dashboardState);
    
    final currentPageIndex = ref.watch(currentPageIndexProvider);
    
    if (dashboardState.isLoading && !dashboardState.isPartiallyLoaded) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: Sizes.spacing),
              Text('Loading recipes and favorites...'),
            ],
          ),
        ),
      );
    }
    
    if (dashboardState.error != null && dashboardState.recipes.isEmpty) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48.0, color: Colors.red),
              const SizedBox(height: Sizes.spacing),
              Text('Failed to load recipes: ${dashboardState.error}'),
              const SizedBox(height: Sizes.spacing),
              ElevatedButton(
                onPressed: () => ref.read(dashboardProvider.notifier).initializeData(),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }
    
    if (dashboardState.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    
    if (dashboardState.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48.0, color: Colors.red),
            const SizedBox(height: Sizes.spacing),
            Text(
              dashboardState.error!,
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: Sizes.spacing),
            ElevatedButton(
              onPressed: () => ref.read(dashboardProvider.notifier).initializeData(),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }
    
    return ResponsiveLayoutBuilder(
      mobile: Scaffold(
        body: IndexedStack(
          index: currentPageIndex,
          children: SelectedDashboardPage.bodySelectedDashboardPage,
        ),
      ),
      
      tablet: Scaffold(
        body: IndexedStack(
          index: currentPageIndex,
          children: SelectedDashboardPage.bodySelectedDashboardPageSplitScreen,
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
              ),
            ),
            const VerticalDivider(width: Sizes.verticalDividerWidth),
            
            Expanded(
              child: IndexedStack(
                index: currentPageIndex,
                children: SelectedDashboardPage.bodySelectedDashboardPageSplitScreen,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  void _showPartialDataNotificationIfNeeded(BuildContext context, DashboardState state) {
    if (state.isPartiallyLoaded && state.error != null && state.recipes.isNotEmpty) {
      Future.microtask(() {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Some data couldn\'t be loaded. Pull to refresh.'),
            action: SnackBarAction(
              label: 'Retry',
              onPressed: () => ref.read(dashboardProvider.notifier).initializeData(),
            ),
            duration: const Duration(seconds: 5),
          ),
        );
      });
    }
  }
}