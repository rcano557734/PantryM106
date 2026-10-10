import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../services/app_colors.dart';
import '../home/recipe_details_view.dart';

class FavoritesView extends StatelessWidget {
  const FavoritesView({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: AppColors.background(context),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Your favorites',
                          style: TextStyle(
                            fontSize: 23,
                            fontWeight: FontWeight.w700,
                            color: AppColors.text(context),
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          'Your go-to meals, all in one place.',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.muted(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.orangeSoft(context),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      Icons.favorite_rounded,
                      color: AppColors.orangeAccent(context),
                      size: 25,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 22),

              Expanded(
                child: user == null
                    ? Center(
                        child: Text(
                          'Please log in to view your favorites.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppColors.muted(context)),
                        ),
                      )
                    : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                        stream: FirebaseFirestore.instance
                            .collection('users')
                            .doc(user.uid)
                            .collection('favorites')
                            .snapshots(),
                        builder: (context, snapshot) {
                          if (snapshot.hasError) {
                            return Center(
                              child: Text(
                                'Could not load favorites. Please try again.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: AppColors.muted(context),
                                ),
                              ),
                            );
                          }

                          if (!snapshot.hasData) {
                            return Center(
                              child: CircularProgressIndicator(
                                color: AppColors.primaryOrange,
                              ),
                            );
                          }

                          final documents = snapshot.data!.docs;

                          if (documents.isEmpty) {
                            return Center(
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  color: AppColors.surface(context),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: AppColors.border(context),
                                  ),
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(22),
                                      decoration: BoxDecoration(
                                        color: AppColors.orangeSoft(context),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        Icons.favorite_border_rounded,
                                        size: 42,
                                        color: AppColors.orangeAccent(context),
                                      ),
                                    ),
                                    const SizedBox(height: 18),
                                    Text(
                                      'No favorites yet',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.text(context),
                                      ),
                                    ),
                                    const SizedBox(height: 7),
                                    Text(
                                      'Explore recipes and save the ones\n'
                                      'you would love to cook again.',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 13,
                                        height: 1.5,
                                        color: AppColors.muted(context),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${documents.length} saved '
                                '${documents.length == 1 ? 'recipe' : 'recipes'}',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.greenAccent(context),
                                ),
                              ),

                              const SizedBox(height: 12),

                              Expanded(
                                child: GridView.builder(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  gridDelegate:
                                      const SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: 2,
                                        crossAxisSpacing: 12,
                                        mainAxisSpacing: 14,
                                        childAspectRatio: 0.70,
                                      ),
                                  itemCount: documents.length,
                                  itemBuilder: (context, index) {
                                    final document = documents[index];

                                    return _recipeCard(
                                      context,
                                      user.uid,
                                      document.id,
                                      document.data(),
                                    );
                                  },
                                ),
                              ),
                            ],
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _recipeCard(
    BuildContext context,
    String userId,
    String documentId,
    Map<String, dynamic> data,
  ) {
    final name = data['name']?.toString() ?? 'Recipe';
    final imageUrl = data['image']?.toString() ?? '';
    final category = data['category']?.toString() ?? 'Recipe';

    return Material(
      color: AppColors.surface(context),
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          final recipeId = data['recipeId']?.toString();

          if (recipeId == null || recipeId.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'This older favorite has no recipe ID. '
                  'Find and save the recipe again.',
                ),
              ),
            );
            return;
          }

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => RecipeDetailsView(
                title: 'Recipe Details',
                recipeId: recipeId,
              ),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (imageUrl.isNotEmpty)
                    Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, progress) {
                        if (progress == null) {
                          return child;
                        }

                        return ColoredBox(
                          color: AppColors.surfaceAlt(context),
                          child: Center(
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.primaryOrange,
                            ),
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return _imagePlaceholder(context);
                      },
                    )
                  else
                    _imagePlaceholder(context),

                  Positioned(
                    top: 8,
                    right: 8,
                    child: Material(
                      color: AppColors.surface(context),
                      shape: const CircleBorder(),
                      child: IconButton(
                        tooltip: 'Remove favorite',
                        visualDensity: VisualDensity.compact,
                        onPressed: () =>
                            _removeFavorite(context, userId, documentId),
                        icon: Icon(
                          Icons.favorite_rounded,
                          color: AppColors.orangeAccent(context),
                          size: 19,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(11, 11, 11, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      height: 1.25,
                      color: AppColors.text(context),
                    ),
                  ),

                  const SizedBox(height: 8),

                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.greenSoft(context),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      category,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: AppColors.greenAccent(context),
                      ),
                    ),
                  ),

                  const SizedBox(height: 7),

                  Row(
                    children: [
                      Icon(
                        Icons.open_in_new_rounded,
                        size: 12,
                        color: AppColors.muted(context),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'View recipe',
                        style: TextStyle(
                          fontSize: 10,
                          color: AppColors.muted(context),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _imagePlaceholder(BuildContext context) {
    return ColoredBox(
      color: AppColors.surfaceAlt(context),
      child: Center(
        child: Icon(
          Icons.restaurant_rounded,
          size: 38,
          color: AppColors.orangeAccent(context),
        ),
      ),
    );
  }

  Future<void> _removeFavorite(
    BuildContext context,
    String userId,
    String documentId,
  ) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('favorites')
          .doc(documentId)
          .delete();
    } catch (_) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not remove favorite. Please try again.'),
        ),
      );
    }
  }
}
