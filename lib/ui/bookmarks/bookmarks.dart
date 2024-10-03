import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:in_app_review/in_app_review.dart';

import '../../data/models/recipe.dart';
import '../../providers.dart';
import '../recipes/recipe_details.dart';
import 'in_app_alert_dialog.dart';

class Bookmarks extends ConsumerStatefulWidget {
  const Bookmarks({super.key});

  @override
  ConsumerState createState() => _BookmarkState();
}

class _BookmarkState extends ConsumerState<Bookmarks> {
  List<Recipe> recipes = [];
  late Stream<List<Recipe>> recipeStream;
  final InAppReview _inAppReview = InAppReview.instance;

  @override
  void initState() {
    super.initState();

    // This watches the repository for changes and updates the widget
    final repository = ref.read(repositoryProvider.notifier);
    recipeStream = repository.watchAllRecipes();
  }

  void _openAppStoreReview() async {
    if (await _inAppReview.isAvailable()) {
      // Open the store review page
      _inAppReview.openStoreListing(
        appStoreId: 'XXXXXX', // Replace with your app store ID
      );    } else {
      // If the store review is not available, I can prompt the user to rate your app on the app store.
      // For example, you can launch the Play Store or App Store URL based on the platform.
      // Here, we will show a dialog for demonstration purposes.
      _showRatingDialog();
    }
  }

  void _showRatingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return InAppAlertDialog();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return _buildBookmarks(context);
  }

  Widget _buildBookmarks(BuildContext context) {
    /// Delete Recipe
    void deleteRecipe(Recipe recipe) {
      ref.read(repositoryProvider.notifier).deleteRecipe(recipe);
    }

    return StreamBuilder<List<Recipe>>(
      stream: recipeStream,
      builder: (context, AsyncSnapshot<List<Recipe>> snapshot) {
        if (snapshot.connectionState == ConnectionState.active) {
          recipes = snapshot.data ?? [];
          if (recipes.length >= 5) {
            _openAppStoreReview();
          }
        }
        return SliverLayoutBuilder(
          builder: (BuildContext context, SliverConstraints constraints) {
            return SliverList.builder(
              itemCount: recipes.length,
              itemBuilder: (BuildContext context, int index) {
                final recipe = recipes[index];
                return SizedBox(
                  height: 100,
                  child: Slidable(
                    startActionPane: ActionPane(
                      motion: const DrawerMotion(),
                      extentRatio: 0.25,
                      children: [
                        SlidableAction(
                          label: 'Delete',
                          backgroundColor: Colors.transparent,
                          foregroundColor: Colors.black,
                          icon: Icons.delete,
                          onPressed: (context) {
                            deleteRecipe(recipe);
                          },
                        ),
                      ],
                    ),
                    endActionPane: ActionPane(
                      motion: const DrawerMotion(),
                      extentRatio: 0.25,
                      children: [
                        SlidableAction(
                          label: 'Delete',
                          backgroundColor: Colors.transparent,
                          foregroundColor: Colors.black,
                          icon: Icons.delete,
                          onPressed: (context) {
                            deleteRecipe(recipe);
                          },
                        ),
                      ],
                    ),
                    child: GestureDetector(
                      onTap: () {
                        /// Push to Recipe Details Page
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => RecipeDetails(
                              recipe: recipe.copyWith(bookmarked: true),
                            ),
                          ),
                        );
                      },
                      child: Card(
                        elevation: 1.0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                        color: Colors.white,
                        child: Align(
                          alignment: Alignment.center,
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: ListTile(
                              leading: CachedNetworkImage(
                                imageUrl: recipe.image ?? '',
                                height: 120,
                                width: 60,
                                fit: BoxFit.cover,
                              ),
                              title: Text(recipe.label ?? ''),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            );
          },
        );
        // TODO: Add else here
      },
    );
  }
}
