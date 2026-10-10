import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../services/app_colors.dart';
import '../../services/recipe_service.dart';

class RecipeDetailsView extends StatefulWidget {
  const RecipeDetailsView({
    super.key,
    required this.title,
    required this.recipeId,
  });

  final String title;
  final String recipeId;

  @override
  State<RecipeDetailsView> createState() => _RecipeDetailsViewState();
}

class _RecipeDetailsViewState extends State<RecipeDetailsView> {
  dynamic recipe;

  bool isSaved = false;
  bool isLoading = true;
  bool isSaving = false;
  String? errorMessage;

  Set<String> pantryIngredients = {};
  bool isPantryLoading = true;
  bool pantryLoadFailed = false;

  @override
  void initState() {
    super.initState();
    _loadRecipe();
    _checkIfSaved();
    _loadPantryIngredients();
  }

  Future<void> _loadRecipe() async {
    try {
      final result = await RecipeService().getRecipeDetails(widget.recipeId);

      if (!mounted) return;

      setState(() {
        recipe = result;
        isLoading = false;
        errorMessage = result == null ? 'Recipe not found.' : null;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
        errorMessage = 'Unable to load this recipe. Please try again.';
      });
    }
  }

  Future<void> _loadPantryIngredients() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      if (!mounted) return;

      setState(() {
        isPantryLoading = false;
        pantryLoadFailed = true;
      });
      return;
    }

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('pantry')
          .get();

      final savedIngredients = snapshot.docs
          .map(
            (doc) => _normalizeIngredient(doc.data()['name']?.toString() ?? ''),
          )
          .where((name) => name.isNotEmpty)
          .toSet();

      if (!mounted) return;

      setState(() {
        pantryIngredients = savedIngredients;
        isPantryLoading = false;
        pantryLoadFailed = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        isPantryLoading = false;
        pantryLoadFailed = true;
      });
    }
  }

  String _normalizeIngredient(String ingredient) {
    var value = ingredient
        .toLowerCase()
        .trim()
        .replaceAll(RegExp(r'[^a-z0-9\s]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ');

    const prefixes = [
      'fresh ',
      'chopped ',
      'minced ',
      'diced ',
      'sliced ',
      'crushed ',
      'grated ',
      'peeled ',
      'ground ',
      'boneless ',
      'skinless ',
    ];

    var changed = true;

    while (changed) {
      changed = false;

      for (final prefix in prefixes) {
        if (value.startsWith(prefix)) {
          value = value.substring(prefix.length).trim();
          changed = true;
        }
      }
    }

    if (value.endsWith('ies') && value.length > 4) {
      value = '${value.substring(0, value.length - 3)}y';
    } else if (value.endsWith('oes') && value.length > 4) {
      value = value.substring(0, value.length - 2);
    } else if (value.endsWith('s') &&
        !value.endsWith('ss') &&
        !{'asparagus', 'molasses'}.contains(value)) {
      value = value.substring(0, value.length - 1);
    }

    return value.trim();
  }

  bool _isInPantry(String ingredient) {
    return pantryIngredients.contains(_normalizeIngredient(ingredient));
  }

  Future<void> _checkIfSaved() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) return;

    try {
      final favorite = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('favorites')
          .doc(widget.recipeId)
          .get();

      if (!mounted) return;

      setState(() {
        isSaved = favorite.exists;
      });
    } catch (e) {
      debugPrint('Could not check favorite status: $e');
    }
  }

  Future<void> _saveRecipe() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to save recipes.')),
      );
      return;
    }

    if (recipe == null || isSaving) return;

    setState(() {
      isSaving = true;
    });

    try {
      final favorite = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('favorites')
          .doc(widget.recipeId);

      if (isSaved) {
        await favorite.delete();
      } else {
        await favorite.set({
          'recipeId': widget.recipeId,
          'name': recipe['strMeal'],
          'image': recipe['strMealThumb'],
          'category': recipe['strCategory'],
          'area': recipe['strArea'],
        });
      }

      if (!mounted) return;

      setState(() {
        isSaved = !isSaved;
        isSaving = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isSaved
                ? 'Recipe added to your favorites.'
                : 'Recipe removed from your favorites.',
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;

      setState(() {
        isSaving = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not update favorites. Please try again.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        backgroundColor: AppColors.background(context),
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primaryOrange),
        ),
      );
    }

    if (errorMessage != null || recipe == null) {
      return Scaffold(
        backgroundColor: AppColors.background(context),
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.restaurant_outlined,
                    size: 52,
                    color: AppColors.orangeAccent(context),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Recipe unavailable',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppColors.text(context),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    errorMessage ?? 'We could not find this recipe.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.5,
                      color: AppColors.muted(context),
                    ),
                  ),
                  const SizedBox(height: 18),
                  ElevatedButton.icon(
                    onPressed: _loadRecipe,
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Try again'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryOrange,
                      foregroundColor: Colors.white,
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    child: const Text('Go back'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    final name = recipe['strMeal']?.toString() ?? 'Recipe';
    final image = recipe['strMealThumb']?.toString();
    final category = recipe['strCategory']?.toString() ?? '';
    final area = recipe['strArea']?.toString() ?? '';

    return Scaffold(
      backgroundColor: AppColors.background(context),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 26),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: SizedBox(
                  width: double.infinity,
                  height: 235,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (image == null || image.trim().isEmpty)
                        _imagePlaceholder()
                      else
                        Image.network(
                          image,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return _imagePlaceholder();
                          },
                        ),
                      Positioned(
                        top: 12,
                        left: 12,
                        child: Material(
                          color: AppColors.surface(context),
                          shape: const CircleBorder(),
                          child: IconButton(
                            onPressed: () => Navigator.of(context).maybePop(),
                            tooltip: 'Go back',
                            icon: Icon(
                              Icons.arrow_back_rounded,
                              color: AppColors.text(context),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              Text(
                name,
                style: TextStyle(
                  fontSize: 25,
                  height: 1.2,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                  color: AppColors.text(context),
                ),
              ),

              const SizedBox(height: 13),

              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (category.trim().isNotEmpty)
                    _infoChip(Icons.restaurant_menu_rounded, category),
                  if (area.trim().isNotEmpty)
                    _infoChip(Icons.public_rounded, area, orange: true),
                ],
              ),

              const SizedBox(height: 26),

              _sectionHeading('Ingredients', Icons.shopping_basket_outlined),

              const SizedBox(height: 5),

              Text(
                'Everything you need for this recipe',
                style: TextStyle(fontSize: 13, color: AppColors.muted(context)),
              ),

              const SizedBox(height: 13),

              _buildIngredients(),

              const SizedBox(height: 26),

              _sectionHeading('Cooking instructions', Icons.menu_book_outlined),

              const SizedBox(height: 5),

              Text(
                'Follow the steps to prepare your meal.',
                style: TextStyle(fontSize: 13, color: AppColors.muted(context)),
              ),

              const SizedBox(height: 14),

              _buildInstructions(),

              const SizedBox(height: 26),

              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton.icon(
                  onPressed: isSaving ? null : _saveRecipe,
                  icon: isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Icon(
                          isSaved
                              ? Icons.favorite_rounded
                              : Icons.favorite_border_rounded,
                        ),
                  label: Text(
                    isSaving
                        ? 'Updating favorites...'
                        : isSaved
                        ? 'Saved to Favorites'
                        : 'Save to Favorites',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isSaved
                        ? AppColors.primaryGreen
                        : AppColors.primaryOrange,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: AppColors.muted(context),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _imagePlaceholder() {
    return ColoredBox(
      color: AppColors.surfaceAlt(context),
      child: Center(
        child: Icon(
          Icons.restaurant_rounded,
          size: 52,
          color: AppColors.orangeAccent(context),
        ),
      ),
    );
  }

  Widget _sectionHeading(String label, IconData icon) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.text(context),
            ),
          ),
        ),
        Icon(icon, color: AppColors.greenAccent(context), size: 21),
      ],
    );
  }

  Widget _infoChip(IconData icon, String label, {bool orange = false}) {
    final background = orange
        ? AppColors.orangeSoft(context)
        : AppColors.greenSoft(context);

    final foreground = orange
        ? AppColors.orangeAccent(context)
        : AppColors.greenAccent(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: foreground),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: foreground,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIngredients() {
    final items = <Widget>[];
    final ingredientNames = <String>[];

    for (var i = 1; i <= 20; i++) {
      final ingredient = recipe['strIngredient$i']?.toString().trim() ?? '';
      final measure = recipe['strMeasure$i']?.toString().trim() ?? '';

      if (ingredient.isNotEmpty) {
        ingredientNames.add(ingredient);
        items.add(_ingredient(ingredient, measure));
      }
    }

    final matchedCount = ingredientNames.where(_isInPantry).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (isPantryLoading)
          _pantryMatchBanner(
            'Checking your pantry...',
            Icons.hourglass_empty_rounded,
            AppColors.surfaceAlt(context),
            AppColors.muted(context),
          )
        else if (pantryLoadFailed)
          _pantryMatchBanner(
            'Pantry availability could not be checked.',
            Icons.info_outline_rounded,
            AppColors.surfaceAlt(context),
            AppColors.muted(context),
          )
        else
          _pantryMatchBanner(
            '$matchedCount of ${ingredientNames.length} ingredients are in your pantry',
            Icons.inventory_2_outlined,
            AppColors.greenSoft(context),
            AppColors.greenAccent(context),
          ),

        const SizedBox(height: 12),

        if (items.isEmpty)
          Text(
            'No ingredient information is available.',
            style: TextStyle(fontSize: 13, color: AppColors.muted(context)),
          )
        else
          ...items,
      ],
    );
  }

  Widget _pantryMatchBanner(
    String message,
    IconData icon,
    Color background,
    Color foreground,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, color: foreground, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: foreground,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _ingredient(String name, String measure) {
    final inPantry = _isInPantry(name);

    final status = isPantryLoading
        ? 'Checking...'
        : pantryLoadFailed
        ? 'Not checked'
        : inPantry
        ? 'In pantry'
        : 'Not in pantry';

    final statusColor = isPantryLoading || pantryLoadFailed
        ? AppColors.muted(context)
        : inPantry
        ? AppColors.greenAccent(context)
        : AppColors.orangeAccent(context);

    final statusBackground = isPantryLoading || pantryLoadFailed
        ? AppColors.surfaceAlt(context)
        : inPantry
        ? AppColors.greenSoft(context)
        : AppColors.orangeSoft(context);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                inPantry && !isPantryLoading && !pantryLoadFailed
                    ? Icons.check_circle_rounded
                    : Icons.circle_outlined,
                size: 19,
                color: inPantry && !isPantryLoading && !pantryLoadFailed
                    ? AppColors.greenAccent(context)
                    : AppColors.muted(context),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  name,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.text(context),
                  ),
                ),
              ),
              if (measure.trim().isNotEmpty)
                Flexible(
                  child: Text(
                    measure,
                    textAlign: TextAlign.end,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.muted(context),
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 9),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
            decoration: BoxDecoration(
              color: statusBackground,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              status,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: statusColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstructions() {
    final rawInstructions = recipe['strInstructions']?.toString().trim() ?? '';

    final steps = rawInstructions
        .split(RegExp(r'\r?\n+'))
        .map((step) => step.trim())
        .where((step) => step.isNotEmpty)
        .toList();

    if (steps.isEmpty) {
      return Text(
        'No cooking instructions are available for this recipe.',
        style: TextStyle(
          fontSize: 13,
          height: 1.6,
          color: AppColors.muted(context),
        ),
      );
    }

    return Column(
      children: [
        for (var i = 0; i < steps.length; i++)
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surface(context),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: AppColors.border(context)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 30,
                  height: 30,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.greenSoft(context),
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '${i + 1}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.greenAccent(context),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    steps[i],
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.6,
                      color: AppColors.text(context),
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
