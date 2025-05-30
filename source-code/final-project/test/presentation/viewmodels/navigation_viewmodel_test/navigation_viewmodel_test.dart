import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recipevault/presentation/viewmodels/navigation_viewmodel.dart';

void main() {
  List<NavigationState> listenToStateChanges(ProviderContainer container) {
    final states = <NavigationState>[];
    container.listen<NavigationState>(
      navigationProvider,
      (_, state) => states.add(state),
      fireImmediately: true,
    );
    return states;
  }
  
  group('NavigationViewModel - Basic State Management', () {
    test('initial state has selectedIndex of 0', () {
      final viewModel = NavigationViewModel();
      expect(viewModel.state.selectedIndex, 0);
    });

    test('setSelectedIndex updates selectedIndex in state', () {
      final viewModel = NavigationViewModel();
      viewModel.setSelectedIndex(1);
      expect(viewModel.state.selectedIndex, 1);
    });

    test('state can be copied with new selectedIndex', () {
      const state = NavigationState(selectedIndex: 0);
      final newState = state.copyWith(selectedIndex: 1);
      expect(newState.selectedIndex, 1);
    });
  });
  
  group('NavigationViewModel - Provider Integration', () {
    test('navigationProvider emits state changes when index changes', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      
      final states = listenToStateChanges(container);
      
      expect(container.read(navigationProvider).selectedIndex, 0);
      
      container.read(navigationProvider.notifier).setSelectedIndex(1);
      
      expect(container.read(navigationProvider).selectedIndex, 1);
      
      expect(states.length, 2);
      expect(states[0].selectedIndex, 0); 
      expect(states[1].selectedIndex, 1); 
    });

    test('currentPageIndexProvider updates independently', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      
      expect(container.read(currentPageIndexProvider), 0);
      
      container.read(currentPageIndexProvider.notifier).state = 1;
      
      expect(container.read(currentPageIndexProvider), 1);
    });
  });

  group('NavigationViewModel - Page Transitions', () {
    testWidgets('IndexedStack changes active child when index changes', (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Consumer(builder: (context, ref, _) {
              final index = ref.watch(currentPageIndexProvider);
              return IndexedStack(
                index: index,
                children: const [
                  Text('Page 0'), 
                  Text('Page 1')
                ],
              );
            }),
          ),
        ),
      );
      
      expect(find.text('Page 0'), findsOneWidget);
      expect(find.text('Page 1'), findsNothing);
      
      container.read(currentPageIndexProvider.notifier).state = 1;
      
      await tester.pump();
      
      expect(find.text('Page 0'), findsNothing);
      expect(find.text('Page 1'), findsOneWidget);
    });
  });

  group('NavigationViewModel - Deep Linking Foundation', () {
    test('can initialize NavigationState with specific index', () {
      const initialState = NavigationState(selectedIndex: 1);
      expect(initialState.selectedIndex, 1);
      
      final viewModel = NavigationViewModel();
      viewModel.setSelectedIndex(initialState.selectedIndex);
      expect(viewModel.state.selectedIndex, 1);
    });
    
    test('index can be set to any value (no validation yet)', () {
      final viewModel = NavigationViewModel();
      const invalidIndex = 999; 
      
      viewModel.setSelectedIndex(invalidIndex);
      expect(viewModel.state.selectedIndex, invalidIndex);
    });
  });
  
  group('NavigationViewModel - Navigation Event Tracking', () {
    test('can track navigation state changes for analytics', () {
      final viewModel = NavigationViewModel();
      final stateChanges = <int>[];
      
      final removeListener = viewModel.addListener((state) {
        stateChanges.add(state.selectedIndex);
      });
      
      viewModel.setSelectedIndex(1);
      viewModel.setSelectedIndex(0);
      viewModel.setSelectedIndex(2);
      
      removeListener();
      
      expect(stateChanges, [0, 1, 0, 2]);
    });
    
    test('navigationProvider emits all state changes in order', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final states = listenToStateChanges(container);
      
      container.read(navigationProvider.notifier).setSelectedIndex(1);
      container.read(navigationProvider.notifier).setSelectedIndex(2);
      container.read(navigationProvider.notifier).setSelectedIndex(0);
      
      expect(states.length, 4);
      expect(states.map((s) => s.selectedIndex).toList(), [0, 1, 2, 0]);
    });
  });
}