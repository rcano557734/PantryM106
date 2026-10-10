import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'login_view.dart';
import 'main_view.dart';

class SplashView extends StatefulWidget {
  const SplashView({super.key, required this.title});

  final String title;

  @override
  State<SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends State<SplashView> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();

    _timer = Timer(const Duration(seconds: 3), _checkLogin);
  }

  Future<void> _checkLogin() async {
    // Wait for Firebase to provide the initial authentication state.
    final user = await FirebaseAuth.instance.authStateChanges().first;

    if (!mounted) {
      return;
    }

    final Widget destination = user != null
        ? const MainView(title: 'PantryMatch')
        : const LoginView(title: 'Login');

    Navigator.of(context)
        .pushReplacement(MaterialPageRoute(builder: (context) => destination));
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBF6EC),
      body: Center(
        child: Image.asset('assets/images/pantrymatch_logo.png', width: 300),
      ),
    );
  }
}
