import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';
import 'package:recipevault/core/errors/failure.dart';
import 'package:recipevault/domain/entities/recipe.dart';
import 'package:recipevault/domain/usecases/favorite_recipe.dart';
import 'package:recipevault/domain/usecases/bookmark_recipe.dart';
import 'package:recipevault/presentation/viewmodels/dashboard_viewmodel.dart';
import 'package:recipevault/presentation/viewmodels/recipe_viewmodel.dart';

class MockFavoriteRecipe extends Mock implements FavoriteRecipe {}

class MockBookmarkRecipe extends Mock implements BookmarkRecipe {}

class MockRef extends Mock implements Ref {}

class MockProviderSubscription extends Mock
    implements ProviderSubscription<RecipeState> {}

class FakeRecipeStateProvider extends Fake
    implements ProviderListenable<RecipeState> {}

class TestFailure extends Failure {
  const TestFailure({required super.message});
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    registerFallbackValue(FakeRecipeStateProvider());
    registerFallbackValue((RecipeState? previous, RecipeState current) {});
  });

  late MockFavoriteRecipe mockFavoriteRecipe;
  late MockBookmarkRecipe mockBookmarkRecipe;
  late MockRef mockRef;
  late RecipeState recipeState;
  late DashboardViewModel viewModel;

  setUp(() {
    mockFavoriteRecipe = MockFavoriteRecipe();
    mockBookmarkRecipe = MockBookmarkRecipe();
    mockRef = MockRef();

    recipeState = const RecipeState(
      recipes: [],
      favoriteIds: {},
      bookmarkIds: {},
      isLoading: false,
    );

    final mockSubscription = MockProviderSubscription();
    when(() => mockRef.listen<RecipeState>(any(), any()))
        .thenReturn(mockSubscription);

    when(() => mockRef.read<RecipeState>(any())).thenReturn(recipeState);

    viewModel = DashboardViewModel.forTesting(
      favoriteRecipe: mockFavoriteRecipe,
      bookmarkRecipe: mockBookmarkRecipe,
      recipeState: recipeState,
      ref: mockRef,
    );
  });

  tearDown(() {
    viewModel.dispose();
  });

  group('DashboardViewModel Tests', () {
    test('initializeData sets loading state to true', () async {

      await viewModel.initializeData();

      expect(viewModel.state.isLoading, isTrue);
    });

    test('initializeData calls loadFavorites and getBookmarks', () async {
      var favoritesCalled = false;
      var bookmarksCalled = false;

      when(() => mockFavoriteRecipe.getFavorites()).thenAnswer((_) async {
        favoritesCalled = true;
        return const Right<Failure, List<Recipe>>([]);
      });

      when(() => mockBookmarkRecipe.getBookmarks()).thenAnswer((_) async {
        bookmarksCalled = true;
        return const Right<Failure, List<Recipe>>([]);
      });

      final future = viewModel.initializeData();

      await Future.delayed(const Duration(milliseconds: 50));

      expect(favoritesCalled, isTrue,
          reason: 'getFavorites should be called during initialization');
      expect(bookmarksCalled, isTrue,
          reason: 'getBookmarks should be called during initialization');

      await future;
    });

    test('initializeData sets error state when favorites loading fails',
        () async {
      when(() => mockFavoriteRecipe.getFavorites()).thenAnswer((_) async =>
              const Left<Failure, List<Recipe>>(
                  TestFailure(message: 'Test error')) 
          );
      when(() => mockBookmarkRecipe.getBookmarks()).thenAnswer((_) async =>
              const Right<Failure, List<Recipe>>([]) 
          );

      await viewModel.initializeData();

      verify(() => mockFavoriteRecipe.getFavorites())
          .called(greaterThanOrEqualTo(1));

      expect(
          viewModel.state.error != null, isTrue); 
    });

    test('initializeData handles partial success', () async {
      final testRecipes = [
        const Recipe(id: '1', name: 'Test Recipe 1', ingredients: []),
        const Recipe(id: '2', name: 'Test Recipe 2', ingredients: []),
      ];

      when(() => mockFavoriteRecipe.getFavorites()).thenAnswer((_) async =>
              Right<Failure, List<Recipe>>(
                  testRecipes)
          );

      when(() => mockBookmarkRecipe.getBookmarks()).thenAnswer((_) async =>
              const Left<Failure, List<Recipe>>(
                  TestFailure(message: 'Test error')) 
          );

      final future = viewModel.initializeData();

      await Future.delayed(const Duration(milliseconds: 50));
      verify(() => mockFavoriteRecipe.getFavorites())
          .called(greaterThanOrEqualTo(1));

      await future;
    });
  });
}
