import 'package:flutter/material.dart';

import '../../services/app_colors.dart';
import '../../services/recipe_service.dart';
import 'recipe_details_view.dart';

class RecipeResultsView extends StatefulWidget {
  const RecipeResultsView({
    super.key,
    required this.title,
    this.query,
    this.initialRecipes,
    this.category,
  });

  final String title;
  final String? query;
  final List<dynamic>? initialRecipes;
  final String? category;

  @override
  State<RecipeResultsView> createState() => _RecipeResultsViewState();
}

class _RecipeResultsViewState extends State<RecipeResultsView> {
  List<dynamic> recipes = [];
  bool isLoading = false;
  String errorMessage = '';

  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();

    _searchController.text = widget.query ?? '';

    if (widget.initialRecipes != null) {
      recipes = widget.initialRecipes!;
    } else if (widget.category != null) {
      _loadCategory(widget.category!);
    } else {
      _loadRecipes(widget.query ?? 'chicken');
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCategory(String category) async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      final results = await RecipeService().filterRecipesByCategory(category);

      if (!mounted) return;

      setState(() {
        recipes = results;
        isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
        errorMessage = 'Unable to load $category recipes.';
      });
    }
  }

  Future<void> _loadRecipes(String query) async {
    if (query.trim().isEmpty) return;

    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      final results = await RecipeService().searchRecipes(query.trim());

      if (!mounted) return;

      setState(() {
        recipes = results;
        isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
        errorMessage = 'Unable to load recipes.';
      });
    }
  }

  void _searchRecipes() {
    final query = _searchController.text.trim();

    if (query.isNotEmpty) {
      _loadRecipes(query);
    }
  }

  @override
  Widget build(BuildContext context) {
    final headingStyle = TextStyle(
      fontSize: 22,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.3,
      color: AppColors.text(context),
    );

    final mutedStyle = TextStyle(
      fontSize: 13,
      height: 1.4,
      color: AppColors.muted(context),
    );

    final subtitle = widget.category != null
        ? 'Explore ${widget.category} dishes'
        : widget.query != null && widget.query!.trim().isNotEmpty
        ? 'Results for "${widget.query}"'
        : 'Discover your next meal.';

    return Scaffold(
      backgroundColor: AppColors.background(context),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.title, style: headingStyle),
                        const SizedBox(height: 5),
                        Text(subtitle, style: mutedStyle),
                      ],
                    ),
                  ),
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: AppColors.greenSoft(context),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Icon(
                      Icons.restaurant_menu_rounded,
                      color: AppColors.greenAccent(context),
                      size: 24,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 22),

              TextField(
                controller: _searchController,
                textInputAction: TextInputAction.search,
                onSubmitted: (_) => _searchRecipes(),
                style: TextStyle(color: AppColors.text(context)),
                decoration: InputDecoration(
                  hintText: 'Search recipes by name...',
                  hintStyle: TextStyle(
                    fontSize: 13,
                    color: AppColors.muted(context),
                  ),
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    color: AppColors.muted(context),
                  ),
                  suffixIcon: IconButton(
                    onPressed: _searchRecipes,
                    tooltip: 'Search recipes',
                    icon: Icon(
                      Icons.arrow_forward_rounded,
                      color: AppColors.greenAccent(context),
                    ),
                  ),
                  filled: true,
                  fillColor: AppColors.surface(context),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 15,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide(color: AppColors.border(context)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide(color: AppColors.border(context)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide(
                      color: AppColors.greenAccent(context),
                      width: 1.5,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 22),

              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Find something delicious',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.text(context),
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 11,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.greenSoft(context),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      isLoading
                          ? 'Searching...'
                          : errorMessage.isNotEmpty
                          ? 'Unavailable'
                          : '${recipes.length} found',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.greenAccent(context),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              Expanded(
                child: isLoading
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircularProgressIndicator(
                              color: AppColors.primaryGreen,
                            ),
                            const SizedBox(height: 14),
                            Text(
                              'Finding recipes for you...',
                              style: mutedStyle,
                            ),
                          ],
                        ),
                      )
                    : errorMessage.isNotEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.cloud_off_outlined,
                              size: 45,
                              color: AppColors.orangeAccent(context),
                            ),
                            const SizedBox(height: 14),
                            Text(
                              errorMessage,
                              textAlign: TextAlign.center,
                              style: mutedStyle,
                            ),
                            const SizedBox(height: 14),
                            ElevatedButton.icon(
                              onPressed: () {
                                if (widget.category != null &&
                                    _searchController.text.trim().isEmpty) {
                                  _loadCategory(widget.category!);
                                } else {
                                  final query = _searchController.text.trim();
                                  _loadRecipes(
                                    query.isNotEmpty
                                        ? query
                                        : widget.query ?? 'chicken',
                                  );
                                }
                              },
                              icon: const Icon(Icons.refresh_rounded),
                              label: const Text('Try again'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primaryOrange,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      )
                    : recipes.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.menu_book_outlined,
                                size: 54,
                                color: AppColors.muted(context),
                              ),
                              const SizedBox(height: 14),
                              Text(
                                'No recipes found',
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.text(context),
                                ),
                              ),
                              const SizedBox(height: 7),
                              Text(
                                'Try another recipe name or search term.',
                                textAlign: TextAlign.center,
                                style: mutedStyle,
                              ),
                            ],
                          ),
                        ),
                      )
                    : GridView.builder(
                        padding: const EdgeInsets.only(bottom: 12),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 14,
                              childAspectRatio: 0.74,
                            ),
                        itemCount: recipes.length,
                        itemBuilder: (context, index) {
                          final recipe = recipes[index];

                          return _recipeCard(
                            context,
                            recipe['idMeal']?.toString(),
                            recipe['strMeal']?.toString(),
                            recipe['strMealThumb']?.toString(),
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
    String? id,
    String? name,
    String? image,
  ) {
    final recipeName = name == null || name.trim().isEmpty
        ? 'Recipe'
        : name.trim();

    return Material(
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
              width: double.infinity,
              height: 118,
              child: image == null || image.trim().isEmpty
                  ? ColoredBox(
                      color: AppColors.surfaceAlt(context),
                      child: Icon(
                        Icons.restaurant_rounded,
                        size: 42,
                        color: AppColors.orangeAccent(context),
                      ),
                    )
                  : Image.network(
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
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(11, 11, 11, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      recipeName,
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
                          size: 15,
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
    );
  }
}
