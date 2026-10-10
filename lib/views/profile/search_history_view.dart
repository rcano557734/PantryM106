import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../services/app_colors.dart';
import '../home/ingredient_view.dart';
import '../home/recipe_results_view.dart';

class SearchHistoryView extends StatelessWidget {
  const SearchHistoryView({super.key, required this.title});

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
                          title,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: AppColors.text(context),
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          'Your cooking searches, all in one place.',
                          style: TextStyle(
                            fontSize: 12,
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
                      Icons.history_rounded,
                      color: AppColors.orangeAccent(context),
                      size: 27,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 22),

              Expanded(
                child: user == null
                    ? Center(
                        child: Text(
                          'Please log in to view your history.',
                          style: TextStyle(color: AppColors.muted(context)),
                        ),
                      )
                    : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                        stream: FirebaseFirestore.instance
                            .collection('users')
                            .doc(user.uid)
                            .collection('search_history')
                            .snapshots(),
                        builder: (context, snapshot) {
                          if (snapshot.hasError) {
                            return Center(
                              child: Text(
                                'Could not load search history. Please try again.',
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

                          final documents = [...snapshot.data!.docs];

                          // Newest searches first. Older records without
                          // timestamps remain visible at the bottom.
                          documents.sort((a, b) {
                            final aTime = a.data()['createdAt'];
                            final bTime = b.data()['createdAt'];

                            final aMillis = aTime is Timestamp
                                ? aTime.millisecondsSinceEpoch
                                : 0;

                            final bMillis = bTime is Timestamp
                                ? bTime.millisecondsSinceEpoch
                                : 0;

                            return bMillis.compareTo(aMillis);
                          });

                          if (documents.isEmpty) {
                            return _emptyState(context);
                          }

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      'RECENT SEARCHES',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 1.2,
                                        color: AppColors.muted(context),
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.greenSoft(context),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      '${documents.length} '
                                      '${documents.length == 1 ? 'search' : 'searches'}',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.greenAccent(context),
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 12),

                              Expanded(
                                child: ListView.separated(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  itemCount: documents.length,
                                  separatorBuilder: (_, _) =>
                                      const SizedBox(height: 10),
                                  itemBuilder: (context, index) {
                                    final document = documents[index];
                                    final data = document.data();

                                    final rawIngredients = data['ingredients'];

                                    final ingredients = rawIngredients is List
                                        ? rawIngredients
                                              .map((item) => item.toString())
                                              .toList()
                                        : <String>[];

                                    final type = data['type']?.toString();

                                    // Support older entries that have no type.
                                    final isRecipeSearch =
                                        type == 'recipe' ||
                                        (type == null &&
                                            ingredients.length == 1);

                                    final label = isRecipeSearch
                                        ? (data['query']?.toString() ??
                                              ingredients.join(' + '))
                                        : ingredients.join(' + ');

                                    return _historyCard(
                                      context: context,
                                      userId: user.uid,
                                      documentId: document.id,
                                      label: label.isEmpty
                                          ? 'Recipe search'
                                          : label,
                                      timestamp: data['createdAt'],
                                      isRecipeSearch: isRecipeSearch,
                                      data: data,
                                      ingredients: ingredients,
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

  Widget _historyCard({
    required BuildContext context,
    required String userId,
    required String documentId,
    required String label,
    required dynamic timestamp,
    required bool isRecipeSearch,
    required Map<String, dynamic> data,
    required List<String> ingredients,
  }) {
    final accent = isRecipeSearch
        ? AppColors.orangeAccent(context)
        : AppColors.greenAccent(context);

    final iconBackground = isRecipeSearch
        ? AppColors.orangeSoft(context)
        : AppColors.greenSoft(context);

    return Material(
      color: AppColors.surface(context),
      borderRadius: BorderRadius.circular(17),
      child: InkWell(
        onTap: () => _repeatSearch(context, data, ingredients),
        borderRadius: BorderRadius.circular(17),
        child: Container(
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(17),
            border: Border.all(color: AppColors.border(context)),
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: iconBackground,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  isRecipeSearch
                      ? Icons.search_rounded
                      : Icons.kitchen_outlined,
                  color: accent,
                  size: 24,
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.3,
                        fontWeight: FontWeight.w700,
                        color: AppColors.text(context),
                      ),
                    ),

                    const SizedBox(height: 6),

                    Row(
                      children: [
                        Icon(
                          isRecipeSearch
                              ? Icons.restaurant_menu
                              : Icons.checklist_rounded,
                          size: 13,
                          color: accent,
                        ),
                        const SizedBox(width: 5),
                        Flexible(
                          child: Text(
                            isRecipeSearch
                                ? 'Recipe search'
                                : 'Ingredient search',
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.muted(context),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 5),

                    Text(
                      _formatTime(timestamp),
                      style: TextStyle(
                        fontSize: 10,
                        color: AppColors.muted(context),
                      ),
                    ),
                  ],
                ),
              ),

              IconButton(
                tooltip: 'Delete search',
                onPressed: () => _confirmDelete(context, userId, documentId),
                icon: Icon(
                  Icons.delete_outline_rounded,
                  color: AppColors.orangeAccent(context),
                  size: 21,
                ),
              ),

              Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: AppColors.muted(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _emptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(23),
            decoration: BoxDecoration(
              color: AppColors.orangeSoft(context),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.manage_search_rounded,
              size: 42,
              color: AppColors.orangeAccent(context),
            ),
          ),

          const SizedBox(height: 17),

          Text(
            'No searches yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.text(context),
            ),
          ),

          const SizedBox(height: 7),

          Text(
            'Find a recipe or choose ingredients to get started.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: AppColors.muted(context)),
          ),
        ],
      ),
    );
  }

  void _repeatSearch(
    BuildContext context,
    Map<String, dynamic> data,
    List<String> ingredients,
  ) {
    if (ingredients.isEmpty) return;

    final type = data['type']?.toString();

    final isRecipeSearch =
        type == 'recipe' || (type == null && ingredients.length == 1);

    if (isRecipeSearch) {
      final query = data['query']?.toString() ?? ingredients.first;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              RecipeResultsView(title: 'Recipe Results', query: query),
        ),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => IngredientView(
            title: 'Ingredients',
            initialIngredients: ingredients,
          ),
        ),
      );
    }
  }

  Future<void> _confirmDelete(
    BuildContext context,
    String userId,
    String documentId,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.surface(dialogContext),
          title: Text(
            'Delete search?',
            style: TextStyle(color: AppColors.text(dialogContext)),
          ),
          content: Text(
            'This search will be removed from your history.',
            style: TextStyle(color: AppColors.muted(dialogContext)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryOrange,
                foregroundColor: Colors.white,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !context.mounted) return;

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('search_history')
          .doc(documentId)
          .delete();
    } catch (_) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not delete the search. Please try again.'),
        ),
      );
    }
  }

  String _formatTime(dynamic value) {
    if (value is! Timestamp) {
      return 'Previous search';
    }

    final date = value.toDate();
    final difference = DateTime.now().difference(date);

    if (difference.isNegative || difference.inMinutes < 1) {
      return 'Just now';
    }

    if (difference.inHours < 1) {
      return '${difference.inMinutes} min ago';
    }

    if (difference.inDays < 1) {
      return '${difference.inHours} hr ago';
    }

    if (difference.inDays == 1) {
      return 'Yesterday';
    }

    return '${date.day}/${date.month}/${date.year}';
  }
}
