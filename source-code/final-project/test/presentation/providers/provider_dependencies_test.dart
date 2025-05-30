import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:recipevault/core/errors/failure.dart';
import 'package:recipevault/data/repositories/recipe_repository_impl.dart';
import 'package:recipevault/domain/entities/recipe.dart';
import 'package:recipevault/domain/repositories/recipe_repository.dart';
import 'package:recipevault/domain/usecases/get_all_recipes.dart';
import 'package:recipevault/domain/usecases/favorite_recipe.dart';
import 'package:recipevault/domain/usecases/bookmark_recipe.dart';
import 'package:recipevault/presentation/viewmodels/recipe_viewmodel.dart';

class MockRecipeRepository extends Mock implements RecipeRepository {}

class MockGetAllRecipes extends Mock implements GetAllRecipes {}

class MockFavoriteRecipe extends Mock implements FavoriteRecipe {}

class MockBookmarkRecipe extends Mock implements BookmarkRecipe {}

class Listener<T> extends Mock {
  void call(T? previous, T next);
}

class FakeGetAllRecipesParams extends Fake implements GetAllRecipesParams {}

class FakeRecipeState extends Fake implements RecipeState {}

void main() {
  setUpAll(() {
    registerFallbackValue(const GetAllRecipesParams(letter: 'A'));
    registerFallbackValue(FakeRecipeState());
  });
  
  group('Provider Chain Dependencies Tests', () {
    late MockRecipeRepository mockRepository;
    late MockGetAllRecipes mockGetAllRecipes;
    late MockFavoriteRecipe mockFavoriteRecipe;
    late MockBookmarkRecipe mockBookmarkRecipe;

    setUp(() {
      mockRepository = MockRecipeRepository();
      mockGetAllRecipes = MockGetAllRecipes();
      mockFavoriteRecipe = MockFavoriteRecipe();
      mockBookmarkRecipe = MockBookmarkRecipe();
    });

    test('changes in repository update dependent usecase providers', () async {
      const testRecipe = Recipe(id: 'new-recipe', name: 'New Recipe', ingredients: []);
      
      final container = ProviderContainer(
        overrides: [
          recipeRepositoryProvider.overrideWithValue(mockRepository),
        ],
      );
      
      when(() => mockRepository.getRecipesByLetter(any()))
          .thenAnswer((_) async => const Right([testRecipe]));
      
      when(() => mockRepository.getFavorites())
          .thenAnswer((_) async => const Right([]));
      when(() => mockRepository.getBookmarks())
          .thenAnswer((_) async => const Right([]));
      
      final getAllRecipes = container.read(getAllRecipesProvider);
      
      final result = await getAllRecipes(const GetAllRecipesParams(letter: 'A'));
      
      verify(() => mockRepository.getRecipesByLetter('A')).called(1);
      
      expect(result, isA<Right<Failure, List<Recipe>>>());
      expect(
        result.fold(
          (l) => null,
          (r) => r.first.id,
        ),
        equals('new-recipe'),
      );
    });

    test('usecase provider updates propagate to viewmodel providers', () async {
      when(() => mockGetAllRecipes(any()))
          .thenAnswer((_) async => const Right([Recipe(id: '1', name: 'Test', ingredients: [])]));
      
      when(() => mockFavoriteRecipe.getFavorites())
          .thenAnswer((_) async => const Right([]));
      when(() => mockBookmarkRecipe.getBookmarks())
          .thenAnswer((_) async => const Right([]));

      final container = ProviderContainer(
        overrides: [
          getAllRecipesProvider.overrideWithValue(mockGetAllRecipes),
          favoriteRecipeProvider.overrideWithValue(mockFavoriteRecipe),
          bookmarkRecipeProvider.overrideWithValue(mockBookmarkRecipe),
        ],
      );

      final listener = Listener<RecipeState>();
      container.listen<RecipeState>(
        recipeProvider,
        (previous, next) {
          listener(previous, next);
        },
        fireImmediately: true,
      );
      
      reset(listener);
      
      when(() => mockGetAllRecipes(any()))
          .thenAnswer((_) async => const Right([
                Recipe(id: '1', name: 'Test', ingredients: []),
                Recipe(id: '2', name: 'New Recipe', ingredients: []),
              ]));
      
      await container.read(recipeProvider.notifier).loadRecipes();
      
      verify(() => listener(any(), any())).called(greaterThan(0));

      expect(container.read(recipeProvider).recipes.length, equals(2));
      expect(
        container.read(recipeProvider).recipes.map((r) => r.id).toList(),
        containsAll(['1', '2']),
      );
    });
    
    test('changes propagate through the entire provider chain', () async {
      final mockRepo = MockRecipeRepository();
      
      final initialRecipes = [const Recipe(id: '1', name: 'Initial Recipe', ingredients: [])];

      when(() => mockRepo.getRecipesByLetter(any()))
          .thenAnswer((_) async => Right(initialRecipes));
      when(() => mockRepo.getFavorites())
          .thenAnswer((_) async => const Right([]));
      when(() => mockRepo.getBookmarks())
          .thenAnswer((_) async => const Right([]));

      final container = ProviderContainer(
        overrides: [
          recipeRepositoryProvider.overrideWithValue(mockRepo),
        ],
      );
      
      await container.read(recipeProvider.notifier).loadRecipes();
      
      expect(container.read(filteredRecipesProvider).length, equals(1));
      expect(container.read(filteredRecipesProvider)[0].id, equals('1'));
      
      final updatedRecipes = [
        const Recipe(id: '1', name: 'Initial Recipe', ingredients: []),
        const Recipe(id: '2', name: 'New Recipe', ingredients: []),
      ];
      
      when(() => mockRepo.getRecipesByLetter(any()))
          .thenAnswer((_) async => Right(updatedRecipes));
      
      await container.read(recipeProvider.notifier).loadRecipes();
      
      await container.pump();
      expect(container.read(filteredRecipesProvider).length, equals(2));
      
      final recipeIds = container.read(filteredRecipesProvider).map((r) => r.id).toList();
      expect(recipeIds, containsAll(['1', '2']));
      
    
      container.dispose();
    });
  });
}
