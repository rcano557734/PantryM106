import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import 'services/notification_service.dart';
import 'firebase_options.dart';
import 'views/splash_view.dart';
import 'services/app_theme_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  await AppThemeController.instance.load();
  await NotificationService.instance.initialize();

  runApp(const PantryMatchApp());
}

class PantryMatchApp extends StatelessWidget {
  const PantryMatchApp({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: AppThemeController.instance,
      builder: (context, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppThemeController.lightTheme,
          darkTheme: AppThemeController.darkTheme,
          themeMode: AppThemeController.instance.mode,
          home: const SplashView(title: 'PantryMatch'),
        );
      },
    );
  }
}
