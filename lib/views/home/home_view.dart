import 'package:flutter/material.dart';

import '../../services/recipe_service.dart';
import 'recipe_details_view.dart';
import '../../services/app_colors.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'ingredient_view.dart';
import 'recipe_results_view.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key, required this.title});
  final String title;

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  final TextEditingController _searchController = TextEditingController();

  String get _firstName {
    final name = FirebaseAuth.instance.currentUser?.displayName?.trim();

    if (name == null || name.isEmpty) {
      return 'there';
    }

    return name.split(RegExp(r'\s+')).first;
  }

  Future<void> _searchRecipes() async {
    final query = _searchController.text.trim();

    if (query.isEmpty) return;

    final user = FirebaseAuth.instance.currentUser;

    // Save the search history without preventing the search if saving fails.
    if (user != null) {
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('search_history')
            .add({
              'type': 'recipe',
              'query': query,
              'ingredients': [query],
              'createdAt': FieldValue.serverTimestamp(),
            });
      } catch (_) {
        // Continue to the recipe search if history saving fails.
      }
    }

    if (!mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            RecipeResultsView(title: 'Recipe Results', query: query),
      ),
    );
  }

  String? _recommendationKey;
  Future<List<dynamic>>? _recommendationsFuture;

  Future<List<dynamic>> _getRecommendations(List<String> ingredients) {
    // Use up to three pantry ingredients to keep loading manageable.
    var selected = ingredients
        .map((item) => item.trim().toLowerCase())
        .where((item) => item.isNotEmpty)
        .toSet()
        .take(3)
        .toList();

    var key = selected.join('|');

    if (_recommendationKey != key) {
      _recommendationKey = key;

      _recommendationsFuture = selected.isEmpty
          ? Future.value(<dynamic>[])
          : RecipeService()
                .searchByIngredients(selected)
                .then((results) => results.take(6).toList());
    }

    return _recommendationsFuture!;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final headingStyle = TextStyle(
      fontWeight: FontWeight.w700,
      fontSize: 18,
      letterSpacing: -0.3,
      color: AppColors.text(context),
    );

    final smallStyle = TextStyle(
      fontSize: 13,
      height: 1.4,
      color: AppColors.muted(context),
    );

    return Scaffold(
      backgroundColor: AppColors.background(context),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),

              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Hi, $_firstName', style: headingStyle),
                        const SizedBox(height: 4),
                        Text(
                          'Ready to cook something good?',
                          style: smallStyle,
                        ),
                      ],
                    ),
                  ),

                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.greenSoft(context),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.restaurant_menu,
                      color: AppColors.greenAccent(context),
                      size: 23,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 18),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: AppColors.isDark(context)
                        ? const [Color(0xFF263B2A), Color(0xFF354B36)]
                        : const [Color(0xFF416C32), Color(0xFF769849)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x1A3A3226),
                      blurRadius: 12,
                      offset: Offset(0, 5),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'YOUR PANTRY, YOUR NEXT MEAL',
                            style: TextStyle(
                              fontSize: 10,
                              letterSpacing: 1,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFFDCEBCB),
                            ),
                          ),

                          const SizedBox(height: 9),

                          const Text(
                            'Cook something delicious.',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),

                          const SizedBox(height: 7),

                          const Text(
                            'Discover recipes using what you already have.',
                            style: TextStyle(
                              fontSize: 12,
                              height: 1.4,
                              color: Color(0xFFF5F1E5),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 10),

                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: const Color(0x33FFFFFF),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: const Icon(
                        Icons.soup_kitchen,
                        size: 29,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              TextField(
                controller: _searchController,
                textInputAction: TextInputAction.search,
                onSubmitted: (_) => _searchRecipes(),
                decoration: InputDecoration(
                  hintText: 'Search recipes...',
                  prefixIcon: const Icon(
                    Icons.search,
                    color: Color(0xFFA99C82),
                  ),
                  suffixIcon: IconButton(
                    onPressed: _searchRecipes,
                    tooltip: 'Search recipes',
                    icon: Icon(
                      Icons.search_rounded,
                      color: AppColors.greenAccent(context),
                    ),
                  ),
                  filled: true,
                  fillColor: AppColors.surface(context),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColors.border(context)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColors.border(context)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: AppColors.greenAccent(context),
                      width: 1.5,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 18),

              Text("What's in your pantry?", style: headingStyle),

              const SizedBox(height: 12),

              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .doc(FirebaseAuth.instance.currentUser!.uid)
                    .collection('pantry')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const CircularProgressIndicator();
                  }

                  var ingredients = snapshot.data!.docs;

                  if (ingredients.isEmpty) {
                    return Text(
                      'No ingredients saved yet.',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.muted(context),
                      ),
                    );
                  }

                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.surface(context),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border(context)),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x0D3A3226),
                          blurRadius: 8,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final document in ingredients.take(6))
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 11,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.greenSoft(context),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.eco_outlined,
                                  size: 14,
                                  color: AppColors.greenAccent(context),
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  document['name']?.toString() ?? 'Ingredient',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.greenAccent(context),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        if (ingredients.length > 6)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 11,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.orangeSoft(context),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '+${ingredients.length - 6} more',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.orangeAccent(context),
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 14),

              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          IngredientView(title: 'Ingredients'),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE8813A),
                  foregroundColor: Colors.white,
                  fixedSize: const Size(double.infinity, 45),
                  minimumSize: const Size(double.infinity, 45),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Find Recipes'),
              ),

              const SizedBox(height: 20),

              Text('Popular categories', style: headingStyle),

              const SizedBox(height: 8),

              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _category('Chicken'),
                  _category('Beef'),
                  _category('Seafood'),
                  _category('Pasta'),
                  _category('Vegetarian'),
                ],
              ),

              const SizedBox(height: 18),

              Text('Recommended for you', style: headingStyle),

              const SizedBox(height: 4),

              Text('Ideas using ingredients in your pantry', style: smallStyle),

              const SizedBox(height: 12),

              StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: FirebaseAuth.instance.currentUser == null
                    ? null
                    : FirebaseFirestore.instance
                          .collection('users')
                          .doc(FirebaseAuth.instance.currentUser!.uid)
                          .collection('pantry')
                          .snapshots(),
                builder: (context, pantrySnapshot) {
                  if (pantrySnapshot.hasError) {
                    return const Text('Unable to load pantry ingredients.');
                  }

                  if (!pantrySnapshot.hasData) {
                    return const SizedBox(
                      height: 90,
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }

                  var ingredients = pantrySnapshot.data!.docs
                      .map((doc) => doc.data()['name']?.toString() ?? '')
                      .where((name) => name.trim().isNotEmpty)
                      .toList();

                  if (ingredients.isEmpty) {
                    return const Text(
                      'Add ingredients to your pantry to get recipe ideas.',
                      style: TextStyle(fontSize: 12, color: Color(0xFF8A7F6B)),
                    );
                  }

                  return FutureBuilder<List<dynamic>>(
                    future: _getRecommendations(ingredients),
                    builder: (context, recipeSnapshot) {
                      if (recipeSnapshot.hasError) {
                        return const Text('Unable to load recommendations.');
                      }

                      if (!recipeSnapshot.hasData) {
                        return const SizedBox(
                          height: 180,
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }

                      var recipes = recipeSnapshot.data!;

                      if (recipes.isEmpty) {
                        return const Text(
                          'No matching recipes found yet. Try adding more ingredients.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF8A7F6B),
                          ),
                        );
                      }

                      return SizedBox(
                        height: 220,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: recipes.length,
                          separatorBuilder: (context, index) =>
                              const SizedBox(width: 12),
                          itemBuilder: (context, index) {
                            return _recommendationCard(context, recipes[index]);
                          },
                        ),
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _category(String name) {
    return Material(
      color: AppColors.surface(context),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  RecipeResultsView(title: '$name Recipes', category: name),
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.border(context)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.restaurant_menu,
                size: 14,
                color: AppColors.greenAccent(context),
              ),
              const SizedBox(width: 6),
              Text(
                name,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.text(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _recommendationCard(BuildContext context, dynamic recipe) {
    final name = recipe['strMeal']?.toString() ?? 'Recipe';
    final image = recipe['strMealThumb']?.toString();
    final id = recipe['idMeal']?.toString();
    final matches = recipe['_matchCount'] ?? 0;

    return SizedBox(
      width: 185,
      child: Material(
        color: AppColors.surface(context),
        elevation: 2,
        shadowColor: AppColors.isDark(context)
            ? const Color(0x40000000)
            : const Color(0x183A3226),
        borderRadius: BorderRadius.circular(18),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: id == null
              ? null
              : () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => RecipeDetailsView(
                        title: 'Recipe Details',
                        recipeId: id,
                      ),
                    ),
                  );
                },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 122,
                width: double.infinity,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (image == null || image.isEmpty)
                      ColoredBox(
                        color: AppColors.surfaceAlt(context),
                        child: Icon(
                          Icons.restaurant_rounded,
                          size: 42,
                          color: AppColors.orangeAccent(context),
                        ),
                      )
                    else
                      Image.network(
                        image,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return ColoredBox(
                            color: AppColors.surfaceAlt(context),
                            child: Icon(
                              Icons.restaurant_rounded,
                              size: 42,
                              color: AppColors.orangeAccent(context),
                            ),
                          );
                        },
                      ),
                    Positioned(
                      left: 9,
                      bottom: 9,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.surface(context),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.inventory_2_outlined,
                              size: 13,
                              color: AppColors.greenAccent(context),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              '$matches matches',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: AppColors.greenAccent(context),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.3,
                          fontWeight: FontWeight.w700,
                          color: AppColors.text(context),
                        ),
                      ),
                      const Spacer(),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'View recipe',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppColors.orangeAccent(context),
                              ),
                            ),
                          ),
                          Icon(
                            Icons.arrow_forward_rounded,
                            size: 14,
                            color: AppColors.orangeAccent(context),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
