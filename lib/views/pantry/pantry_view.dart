import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../services/app_colors.dart';

class PantryView extends StatefulWidget {
  const PantryView({super.key, required this.title});

  final String title;

  @override
  State<PantryView> createState() => _PantryViewState();
}

class _PantryViewState extends State<PantryView> {
  List<String> ingredients = [];
  List<String> ingredientIds = [];

  bool _isLoading = true;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _loadPantry();
  }

  Future<void> _loadPantry() async {
    if (mounted && !_isLoading) {
      setState(() {
        _isLoading = true;
        _loadError = null;
      });
    }

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      if (!mounted) return;

      setState(() {
        ingredients = [];
        ingredientIds = [];
        _isLoading = false;
      });
      return;
    }

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('pantry')
          .get();

      if (!mounted) return;

      setState(() {
        ingredients = [
          for (final document in snapshot.docs) document['name'].toString(),
        ];

        ingredientIds = [for (final document in snapshot.docs) document.id];

        _isLoading = false;
        _loadError = null;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _loadError = 'Could not load your pantry. Please try again.';
      });
    }
  }

  Future<void> _removeIngredient(int index) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null ||
        index < 0 ||
        index >= ingredients.length ||
        index >= ingredientIds.length) {
      return;
    }

    final ingredientName = ingredients[index];
    final ingredientId = ingredientIds[index];

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('pantry')
          .doc(ingredientId)
          .delete();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$ingredientName removed from your pantry.')),
      );

      await _loadPantry();
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not remove ingredient. Please try again.'),
        ),
      );
    }
  }

  Future<void> _addIngredient() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return _AddIngredientSheet(
          existingIngredients: List<String>.from(ingredients),
          onSave: (name) async {
            final user = FirebaseAuth.instance.currentUser;

            if (user == null) {
              throw Exception('Please log in again.');
            }

            await FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .collection('pantry')
                .add({'name': name});
          },
        );
      },
    );

    if (!mounted) {
      return;
    }

    _loadPantry();
  }

  @override
  @override
  Widget build(BuildContext context) {
    final headingStyle = TextStyle(
      fontWeight: FontWeight.w700,
      fontSize: 22,
      letterSpacing: -0.3,
      color: AppColors.muted(context),
    );

    final subtitleStyle = TextStyle(
      fontSize: 13,
      height: 1.4,
      color: AppColors.muted(context),
    );

    final statusText = _isLoading
        ? 'Loading ingredients...'
        : _loadError != null
        ? 'Pantry unavailable'
        : '${ingredients.length} ingredients saved';

    return Scaffold(
      backgroundColor: AppColors.background(context),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('My pantry', style: headingStyle),
                        SizedBox(height: 5),
                        Text(
                          'Keep track of what you have at home.',
                          style: subtitleStyle,
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: const Color(0xFFDCEBCB),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.kitchen_rounded,
                      color: Color(0xFF3B6D11),
                      size: 27,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 22),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF416C32), Color(0xFF769849)],
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
                            'YOUR PANTRY',
                            style: TextStyle(
                              fontSize: 10,
                              letterSpacing: 1.2,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFFDCEBCB),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            statusText,
                            style: const TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 5),
                          const Text(
                            'Make the most of what you already have.',
                            style: TextStyle(
                              fontSize: 12,
                              height: 1.4,
                              color: Color(0xFFF5F1E5),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: const Color(0x33FFFFFF),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: const Icon(
                        Icons.inventory_2_outlined,
                        color: Colors.white,
                        size: 27,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 26),

              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Your ingredients',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF3A3226),
                      ),
                    ),
                  ),
                  if (!_isLoading && _loadError == null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 11,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDCEBCB),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${ingredients.length}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF3B6D11),
                        ),
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 14),

              if (_isLoading)
                Container(
                  width: double.infinity,
                  height: 170,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFFE4D9C3)),
                  ),
                  child: const Center(
                    child: CircularProgressIndicator(color: Color(0xFF3B6D11)),
                  ),
                )
              else if (_loadError != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFFE4D9C3)),
                  ),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.cloud_off_outlined,
                        color: Color(0xFFB95D20),
                        size: 36,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        _loadError!,
                        textAlign: TextAlign.center,
                        style: subtitleStyle,
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: _loadPantry,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Try again'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF3B6D11),
                        ),
                      ),
                    ],
                  ),
                )
              else if (ingredients.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 22,
                    vertical: 30,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFFE4D9C3)),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.kitchen_outlined,
                        size: 45,
                        color: Color(0xFF8A7F6B),
                      ),
                      SizedBox(height: 12),
                      Text(
                        'Your pantry is empty',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF3A3226),
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        'Add ingredients you already have at home '
                        'to start discovering recipes.',
                        textAlign: TextAlign.center,
                        style: subtitleStyle,
                      ),
                    ],
                  ),
                )
              else
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFFE4D9C3)),
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
                    runSpacing: 10,
                    children: [
                      for (var i = 0; i < ingredients.length; i++)
                        _ingredient(ingredients[i], i),
                    ],
                  ),
                ),

              const SizedBox(height: 22),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _addIngredient,
                  icon: const Icon(Icons.add_rounded),
                  label: const Text(
                    'Add ingredient',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE8813A),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
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

  Future<void> _confirmRemoveIngredient(int index) async {
    if (index < 0 || index >= ingredients.length) return;

    final name = ingredients[index];

    final shouldRemove = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFFFBF6EC),
        title: const Text(
          'Remove ingredient?',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: Color(0xFF3A3226),
          ),
        ),
        content: Text(
          'Remove $name from your pantry?',
          style: const TextStyle(color: Color(0xFF8A7F6B)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE8813A),
              foregroundColor: Colors.white,
            ),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (!mounted || shouldRemove != true) return;

    await _removeIngredient(index);
  }

  Widget _ingredient(String name, int index) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 5, 5, 5),
      decoration: BoxDecoration(
        color: AppColors.greenSoft(context),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border(context)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.eco_outlined,
            size: 15,
            color: AppColors.greenAccent(context),
          ),
          const SizedBox(width: 6),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 160),
            child: Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.orangeAccent(context),
              ),
            ),
          ),
          const SizedBox(width: 3),
          IconButton(
            onPressed: () => _confirmRemoveIngredient(index),
            tooltip: 'Remove $name',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
            visualDensity: VisualDensity.compact,
            icon: Icon(
              Icons.close_rounded,
              size: 16,
              color: AppColors.muted(context),
            ),
          ),
        ],
      ),
    );
  }
}

class _AddIngredientSheet extends StatefulWidget {
  const _AddIngredientSheet({
    required this.existingIngredients,
    required this.onSave,
  });

  final List<String> existingIngredients;
  final Future<void> Function(String name) onSave;

  @override
  State<_AddIngredientSheet> createState() => _AddIngredientSheetState();
}

class _AddIngredientSheetState extends State<_AddIngredientSheet> {
  final TextEditingController _controller = TextEditingController();

  bool _isSaving = false;
  String? _errorMessage;

  final List<String> _suggestions = [
    'Chicken',
    'Beef',
    'Egg',
    'Garlic',
    'Tomato',
    'Onion',
    'Potato',
    'Rice',
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _controller.text.trim();

    if (name.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter an ingredient.';
      });
      return;
    }

    final alreadyExists = widget.existingIngredients.any(
      (item) => item.trim().toLowerCase() == name.toLowerCase(),
    );

    if (alreadyExists) {
      setState(() {
        _errorMessage = 'This ingredient is already in your pantry.';
      });
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      await widget.onSave(name);

      if (!mounted) {
        return;
      }

      // Closing this sheet disposes its controller through dispose().
      Navigator.of(context).pop();
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isSaving = false;
        _errorMessage = 'Could not save. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.background(context),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFC9BFA8),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              Text(
                'Add ingredients',
                style: TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.w700,
                  color: AppColors.text(context),
                ),
              ),

              const SizedBox(height: 5),

              const Text(
                'What ingredients do you have?',
                style: TextStyle(fontSize: 13, color: Color(0xFF8A7F6B)),
              ),

              const SizedBox(height: 18),

              TextField(
                controller: _controller,
                autofocus: true,
                enabled: !_isSaving,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  hintText: 'Enter an ingredient',
                  prefixIcon: Icon(
                    Icons.kitchen_outlined,
                    color: AppColors.muted(context),
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

              if (_errorMessage != null) ...[
                const SizedBox(height: 8),
                Text(
                  _errorMessage!,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFFB5502E),
                  ),
                ),
              ],

              const SizedBox(height: 18),

              Text(
                'Quick add',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.text(context),
                ),
              ),

              const SizedBox(height: 10),

              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (var name in _suggestions)
                    ActionChip(
                      label: Text(name),
                      backgroundColor: AppColors.surface(context),
                      side: BorderSide(color: AppColors.border(context)),
                      onPressed: _isSaving
                          ? null
                          : () {
                              setState(() {
                                _controller.text = name;
                                _controller.selection = TextSelection.collapsed(
                                  offset: name.length,
                                );
                                _errorMessage = null;
                              });
                            },
                    ),
                ],
              ),

              const SizedBox(height: 22),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isSaving
                          ? null
                          : () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 48),
                        foregroundColor: const Color(0xFF8A7F6B),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isSaving ? null : _submit,
                      icon: _isSaving
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.add),
                      label: Text(_isSaving ? 'Saving...' : 'Add'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE8813A),
                        foregroundColor: Colors.white,
                        minimumSize: const Size(0, 48),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
