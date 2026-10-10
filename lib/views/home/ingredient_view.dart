import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../services/recipe_service.dart';
import 'recipe_results_view.dart';

class IngredientView extends StatefulWidget {
  const IngredientView({
    super.key,
    required this.title,
    this.initialIngredients,
  });

  final String title;
  final List<String>? initialIngredients;

  @override
  State<IngredientView> createState() => _IngredientViewState();
}

class _IngredientViewState extends State<IngredientView> {
  final TextEditingController _ingredientController = TextEditingController();

  List<String> selectedIngredients = [];

  bool isLoading = false;

  @override
  void initState() {
    super.initState();

    if (widget.initialIngredients != null) {
      selectedIngredients = List.from(widget.initialIngredients!);
    } else {
      _loadPantry();
    }
  }

  @override
  void dispose() {
    _ingredientController.dispose();
    super.dispose();
  }

  void _loadPantry() async {
    var user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      var snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('pantry')
          .get();

      setState(() {
        selectedIngredients = [
          for (var document in snapshot.docs) document['name'].toString(),
        ];
      });
    }
  }

  void _addIngredient() {
    if (_ingredientController.text.isNotEmpty) {
      setState(() {
        selectedIngredients.add(_ingredientController.text);
        _ingredientController.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    var headingStyle = const TextStyle(
      fontWeight: FontWeight.w500,
      fontSize: 17,
      color: Color(0xFF3A3226),
    );

    var smallStyle = const TextStyle(fontSize: 13, color: Color(0xFF8A7F6B));

    return Scaffold(
      backgroundColor: const Color(0xFFFBF6EC),

      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 25),

            Text('Choose ingredients', style: headingStyle),

            Text('What ingredients do you have?', style: smallStyle),

            const SizedBox(height: 18),

            TextField(
              controller: _ingredientController,
              decoration: InputDecoration(
                labelText: 'Search ingredient',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                suffixIcon: IconButton(
                  onPressed: _addIngredient,
                  icon: const Icon(Icons.add),
                ),
              ),
            ),

            const SizedBox(height: 20),

            Text('Selected ingredients', style: smallStyle),

            const SizedBox(height: 8),

            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (var ingredient in selectedIngredients)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDCEBCB),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          ingredient,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF3B6D11),
                          ),
                        ),

                        const SizedBox(width: 5),

                        GestureDetector(
                          onTap: () {
                            setState(() {
                              selectedIngredients.remove(ingredient);
                            });
                          },
                          child: const Icon(
                            Icons.close,
                            size: 14,
                            color: Color(0xFF3B6D11),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 22),

            Text('Suggested ingredients', style: smallStyle),

            const SizedBox(height: 8),

            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _ingredientButton('Onion'),
                _ingredientButton('Garlic'),
                _ingredientButton('Cheese'),
                _ingredientButton('Potato'),
                _ingredientButton('Carrot'),
                _ingredientButton('Rice'),
              ],
            ),

            const Spacer(),

            SizedBox(
              width: double.infinity,
              height: 45,
              child: ElevatedButton(
                onPressed: isLoading
                    ? null
                    : () async {
                        if (selectedIngredients.isEmpty) {
                          return;
                        }

                        setState(() {
                          isLoading = true;
                        });

                        var service = RecipeService();

                        var results = await service.searchByIngredients(
                          selectedIngredients,
                        );

                        if (!mounted) {
                          return;
                        }

                        var user = FirebaseAuth.instance.currentUser;

                        if (user != null) {
                          await FirebaseFirestore.instance
                              .collection('users')
                              .doc(user.uid)
                              .collection('search_history')
                              .add({
                                'type': 'ingredients',
                                'ingredients': selectedIngredients,
                                'createdAt': FieldValue.serverTimestamp(),
                              });
                        }

                        if (!context.mounted) {
                          return;
                        }

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => RecipeResultsView(
                              title: 'Recipe Results',
                              initialRecipes: results,
                            ),
                          ),
                        );

                        setState(() {
                          isLoading = false;
                        });
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE8813A),
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: const Color(0xFFD9B08A),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Find Recipes'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _ingredientButton(String name) {
    return GestureDetector(
      onTap: () {
        setState(() {
          if (!selectedIngredients.contains(name)) {
            selectedIngredients.add(name);
          }
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE4D9C3)),
        ),
        child: Text(
          name,
          style: const TextStyle(fontSize: 12, color: Color(0xFF3A3226)),
        ),
      ),
    );
  }
}
