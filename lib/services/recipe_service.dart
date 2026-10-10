import 'dart:convert';

import 'package:http/http.dart' as http;

class RecipeService {
  Future<List<dynamic>> filterRecipesByCategory(String category) async {
    final url = Uri.parse(
      'https://www.themealdb.com/api/json/v1/1/filter.php'
      '?c=${Uri.encodeComponent(category)}',
    );

    final response = await http.get(url);

    if (response.statusCode != 200) {
      throw Exception('Could not load $category recipes.');
    }

    final data = jsonDecode(response.body);

    if (data['meals'] == null) {
      return [];
    }

    return List<dynamic>.from(data['meals']);
  }

  Future<List<dynamic>> searchRecipes(String query) async {
    var url = Uri.parse(
      'https://www.themealdb.com/api/json/v1/1/search.php?s=$query',
    );

    var response = await http.get(url);

    if (response.statusCode == 200) {
      var data = jsonDecode(response.body);

      if (data['meals'] == null) {
        return [];
      }

      return data['meals'];
    }

    return [];
  }

  Future<List<dynamic>> filterRecipes(String ingredient) async {
    var url = Uri.parse(
      'https://www.themealdb.com/api/json/v1/1/filter.php?i=${Uri.encodeComponent(ingredient.toLowerCase())}',
    );

    var response = await http.get(url);

    if (response.statusCode == 200) {
      var data = jsonDecode(response.body);

      if (data['meals'] == null) {
        return [];
      }

      return data['meals'];
    }

    return [];
  }

  Future<List<dynamic>> searchByIngredients(List<String> ingredients) async {
    var selected = ingredients
        .map((item) => item.trim().toLowerCase())
        .where((item) => item.isNotEmpty)
        .toSet()
        .toList();

    if (selected.isEmpty) {
      return [];
    }

    // Search for each selected ingredient.
    var filteredLists = await Future.wait(
      selected.map((ingredient) => filterRecipes(ingredient)),
    );

    // Combine results and remove duplicate recipe IDs.
    var candidates = <String, dynamic>{};

    for (var list in filteredLists) {
      for (var candidate in list.take(12)) {
        var id = candidate['idMeal']?.toString();

        if (id != null) {
          candidates.putIfAbsent(id, () => candidate);
        }
      }
    }

    // Fetch recipe details concurrently.
    var details = await Future.wait(
      candidates.values.map((candidate) async {
        try {
          return await getRecipeDetails(candidate['idMeal'].toString());
        } catch (_) {
          return null;
        }
      }),
    );

    var matches = <Map<String, dynamic>>[];

    for (var recipe in details) {
      if (recipe == null) {
        continue;
      }

      var recipeIngredients = <String>{};

      for (var i = 1; i <= 20; i++) {
        var ingredient = recipe['strIngredient$i']
            ?.toString()
            .trim()
            .toLowerCase();

        if (ingredient != null && ingredient.isNotEmpty) {
          recipeIngredients.add(ingredient);
        }
      }

      // Count how many selected ingredients each recipe contains.
      var matchedIngredients = selected
          .where((ingredient) => recipeIngredients.contains(ingredient))
          .toList();

      if (matchedIngredients.isNotEmpty) {
        var recipeData = Map<String, dynamic>.from(recipe);

        recipeData['_matchCount'] = matchedIngredients.length;
        recipeData['_matchedIngredients'] = matchedIngredients;

        matches.add({'recipe': recipeData, 'score': matchedIngredients.length});
      }
    }

    // Put the recipes with the most matching ingredients first.
    matches.sort((a, b) => (b['score'] as int).compareTo(a['score'] as int));

    return [for (var match in matches) match['recipe']];
  }

  Future<dynamic> getRecipeDetails(String id) async {
    var url = Uri.parse(
      'https://www.themealdb.com/api/json/v1/1/lookup.php?i=$id',
    );

    var response = await http.get(url);

    if (response.statusCode == 200) {
      var data = jsonDecode(response.body);

      if (data['meals'] == null) {
        return null;
      }

      return data['meals'][0];
    }

    return null;
  }
}
