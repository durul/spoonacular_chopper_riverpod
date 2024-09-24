import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:recipes/data/database/recipe_db.dart';
import 'package:recipes/data/provider/database_provider.dart';
import 'package:recipes/data/models/current_recipe_data.dart';
import 'package:recipes/data/models/ingredient.dart';
import 'package:recipes/data/repositories/db_repository.dart';
import 'package:recipes/global.dart';
import 'package:test/test.dart';

import 'db_repository_test.mocks.dart';

@GenerateNiceMocks([
  MockSpec<RecipeDatabase>(),
  MockSpec<RecipeDao>(),
  MockSpec<IngredientDao>(),
  MockSpec<Globals>(),
  MockSpec<DatabaseProvider>(),
])
void main() {
  late MockGlobals mockGlobals;
  late MockDatabaseProvider mockDatabaseProvider;
  late MockRecipeDatabase mockDb;
  late MockIngredientDao mockIngredientDao;
  late MockRecipeDao mockRecipeDao;

  setUp(() {
    mockGlobals = MockGlobals();
    mockDatabaseProvider = MockDatabaseProvider();
    mockDb = MockRecipeDatabase();
    mockIngredientDao = MockIngredientDao();
    mockRecipeDao = MockRecipeDao();

    // Setup the mock chain
    when(mockGlobals.databaseProvider).thenReturn(mockDatabaseProvider);
    when(mockDatabaseProvider.recipeDatabase).thenReturn(mockDb);
    when(mockDb.ingredientDao).thenReturn(mockIngredientDao);
    when(mockDb.recipeDao).thenReturn(mockRecipeDao);

    // Replace the global Globals instance with our mock
    Globals.instance = mockGlobals;
  });

  group('DBRepository', () {
    test('can instantiate', () async {
      // Arrange
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Act
      final dbRepositoryProvider =
          AsyncNotifierProvider<DBRepository, CurrentRecipeData>(
              DBRepository.new);
      final dbRepository = container.read(dbRepositoryProvider.notifier);

      // Wait for the build method to complete
      await container.read(dbRepositoryProvider.future);

      // Assert
      expect(dbRepository, isNotNull);
    });

    test('findIngredients', () async {
      // Arrange
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final dbRepositoryProvider =
          AsyncNotifierProvider<DBRepository, CurrentRecipeData>(
              DBRepository.new);
      final dbRepository = container.read(dbRepositoryProvider.notifier);

      // Wait for the build method to complete
      await container.read(dbRepositoryProvider.future);

      final randomIngredients = [
        const Ingredient(id: 1123, recipeId: 123, name: 'Pasta', amount: 1.0),
        const Ingredient(id: 1124, recipeId: 123, name: 'Garlic', amount: 1.0),
        const Ingredient(
            id: 1125, recipeId: 123, name: 'Breadcrumbs', amount: 5.0),
      ];

      when(mockIngredientDao.findAllIngredients()).thenAnswer((_) async {
        return randomIngredients
            .map((e) => DbIngredientData(
                id: e.id!,
                recipeId: e.recipeId!,
                name: e.name!,
                amount: e.amount!))
            .toList();
      });

      // Act
      final result = await dbRepository.findAllIngredients();

      // Assert
      verify(mockIngredientDao.findAllIngredients()).called(1);
      expect(result, equals(randomIngredients));
      expect(result, isNotNull);
      expect(result.length, 3);
    });
  });
}
