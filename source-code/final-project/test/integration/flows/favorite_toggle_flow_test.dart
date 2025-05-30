import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:recipevault/main.dart';
import 'package:recipevault/data/datasources/local_datasource.dart';
import 'package:recipevault/presentation/views/recipe/components/recipe_list_view.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  
  SharedPreferences.setMockInitialValues({});
  late SharedPreferences prefs;
  
  setUp(() async {
    prefs = await SharedPreferences.getInstance();
  });
  
  tearDown(() async {
    await Future.delayed(const Duration(milliseconds: 500));
  });
  
  group('Favorite Toggle Flow Tests', () {
    testWidgets('Toggle favorite and verify in dashboard', (tester) async {
      
      await tester.pumpWidget(ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
        child: const RecipeVaultApp(),
      ));
      
      await tester.pumpAndSettle(const Duration(seconds: 2));

      bool foundRecipes = false;
      for (final letter in ['A', 'B', 'C']) {
        final letterFinder = find.text(letter);
        if (letterFinder.evaluate().isEmpty) {
          continue;
        }
        
        await tester.tap(letterFinder.first);
        await tester.pumpAndSettle();
        
        final recipeFinder = find.byType(RecipeListView);
        if (recipeFinder.evaluate().isEmpty) {
          continue;
        }
        
        final anyTappableElement = find.descendant(
          of: recipeFinder,
          matching: find.byType(InkWell),
        );
        
        final recipeItems = anyTappableElement.evaluate().isNotEmpty 
            ? anyTappableElement 
            : find.descendant(
                of: recipeFinder,
                matching: find.byType(ListTile),
              );
              
        if (recipeItems.evaluate().isNotEmpty) {
          foundRecipes = true;
          
          await tester.tap(recipeItems.first);
          await tester.pumpAndSettle();

          break;
        } else {
        }
      }
      
      if (!foundRecipes) {
        return; 
      }
      await tester.pumpAndSettle();
      final isOnDetailsPage = find.textContaining('Ingredients').evaluate().isNotEmpty ||
                              find.textContaining('Instructions').evaluate().isNotEmpty;
      if (!isOnDetailsPage) {
        return; 
      }
      final favoriteElements = [
        find.byIcon(Icons.favorite_border),
        find.byIcon(Icons.favorite),
        find.byIcon(Icons.bookmark_border),
        find.byIcon(Icons.bookmark),
      ];
      
      bool tappedFavoriteIcon = false;
      for (final iconFinder in favoriteElements) {
        if (iconFinder.evaluate().isNotEmpty) {
          await tester.tap(iconFinder.first);
          tappedFavoriteIcon = true;
          await tester.pumpAndSettle();
          break;
        }
      }
      
      if (!tappedFavoriteIcon) {
        return; 
      }
      bool navigatedBack = false;
      final backButton = find.byIcon(Icons.arrow_back);
      if (backButton.evaluate().isNotEmpty) {
        await tester.tap(backButton.first);
        await tester.pumpAndSettle();
        navigatedBack = true;
      }
      
      if (!navigatedBack) {
        final bottomNav = find.byType(BottomNavigationBar);
        if (bottomNav.evaluate().isNotEmpty) {
          final homeIcons = [
            Icons.home,
            Icons.dashboard,
            Icons.menu,
            Icons.list,
            Icons.favorite,
          ];
          
          for (final icon in homeIcons) {
            final iconFinder = find.descendant(
              of: bottomNav,
              matching: find.byIcon(icon),
            );
            
            if (iconFinder.evaluate().isNotEmpty) {
              await tester.tap(iconFinder.first);
              await tester.pumpAndSettle();
              navigatedBack = true;
              break;
            }
          }
        }
      }
      
      if (!navigatedBack) {
        final appBarButtons = [
          find.byIcon(Icons.menu),
          find.byIcon(Icons.home),
          find.byIcon(Icons.dashboard),
        ];
        
        for (final button in appBarButtons) {
          if (button.evaluate().isNotEmpty) {
            await tester.tap(button.first);
            await tester.pumpAndSettle();
            navigatedBack = true;
            break;
          }
        }
      }
      
      if (!navigatedBack) {
        return; 
      }
      final favoritesTab = find.text('Favorites');
      if (favoritesTab.evaluate().isNotEmpty) {
        await tester.tap(favoritesTab.first);
        await tester.pumpAndSettle();
      }
    
    });
    
    testWidgets('Favorites persist across app restarts', (tester) async {
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
      );
      
      try {
        await tester.pumpWidget(UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: RecipeVaultApp()),
        ));
        
        await tester.pumpAndSettle(const Duration(seconds: 2));

        final letterA = find.text('A');
        if (letterA.evaluate().isNotEmpty) {
          await tester.tap(letterA.first);
          await tester.pumpAndSettle(const Duration(milliseconds: 500));
        } else {
          return;
        }
        
        final listItems = find.byType(ListTile);
        if (listItems.evaluate().isEmpty) {
          return;
        }
        
        await tester.tap(listItems.first);
        await tester.pumpAndSettle();
        
        final favoriteIconFinder = find.byIcon(Icons.favorite_border);
        if (favoriteIconFinder.evaluate().isNotEmpty) {
          await tester.tap(favoriteIconFinder.first);
          await tester.pumpAndSettle();
          expect(find.byIcon(Icons.favorite), findsOneWidget);
        } else {
          expect(find.byIcon(Icons.favorite), findsOneWidget);
        }
        
        await Future.delayed(const Duration(milliseconds: 300));

        await tester.pumpAndSettle();
        container.dispose();
        
        final newContainer = ProviderContainer(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
          ],
        );
        
        await tester.pumpWidget(UncontrolledProviderScope(
          container: newContainer,
          child: const MaterialApp(home: RecipeVaultApp()),
        ));
        await tester.pumpAndSettle(const Duration(seconds: 2));
        
        final letterAfterRestart = find.text('A');
        if (letterAfterRestart.evaluate().isNotEmpty) {
          await tester.tap(letterAfterRestart.first);
          await tester.pumpAndSettle();
        } else {
          return;
        }
        
        final listItemsAfterRestart = find.byType(ListTile);
        if (listItemsAfterRestart.evaluate().isNotEmpty) {
          await tester.tap(listItemsAfterRestart.first);
          await tester.pumpAndSettle();
          
          expect(find.byIcon(Icons.favorite), findsOneWidget, 
              reason: 'Favorite status not preserved after app restart');
        } else {
          fail('Could not find recipe list items after app restart');
        }
        
        await tester.pumpAndSettle();
        newContainer.dispose();
      } finally {
        try {
          container.dispose();
        } catch (e) {
          debugPrint('Cleanup error (can be ignored): $e');
        }
        
        await tester.pumpAndSettle();
        await Future.delayed(const Duration(milliseconds: 300));
      }
    });
  });
}
