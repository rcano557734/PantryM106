import 'package:flutter/material.dart';

import 'home/home_view.dart';
import 'pantry/pantry_view.dart';
import 'favorites/favorites_view.dart';
import '../services/app_colors.dart';
import 'profile/profile_view.dart';

class MainView extends StatefulWidget {
  const MainView({super.key, required this.title});

  final String title;

  @override
  State<MainView> createState() => _MainViewState();
}

class _MainViewState extends State<MainView> {
  int selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    var pages = [
      const HomeView(title: 'Home'),
      const PantryView(title: 'Pantry'),
      const FavoritesView(title: 'Favorites'),
      const ProfileView(title: 'Profile'),
    ];

    return Scaffold(
      body: pages[selectedIndex],

      bottomNavigationBar: BottomAppBar(
        elevation: 0,
        color: AppColors.background(context),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _navigationItem(Icons.home, 'Home', 0),

            _navigationItem(Icons.inventory_2_outlined, 'Pantry', 1),

            _navigationItem(Icons.favorite_border, 'Favorites', 2),

            _navigationItem(Icons.person_outline, 'Profile', 3),
          ],
        ),
      ),
    );
  }

  Widget _navigationItem(IconData icon, String label, int index) {
    final isSelected = selectedIndex == index;

    final activeColor = AppColors.greenAccent(context);
    final inactiveColor = AppColors.muted(context);
    final selectedBackground = AppColors.greenSoft(context);

    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            setState(() {
              selectedIndex = index;
            });
          },
          borderRadius: BorderRadius.circular(14),
          child: SizedBox(
            height: 64,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 5),
              decoration: BoxDecoration(
                color: isSelected ? selectedBackground : Colors.transparent,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    icon,
                    size: 21,
                    color: isSelected ? activeColor : inactiveColor,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.normal,
                      color: isSelected ? activeColor : inactiveColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
