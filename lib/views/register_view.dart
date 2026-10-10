import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'main_view.dart';

class RegisterView extends StatefulWidget {
  const RegisterView({super.key, required this.title});

  final String title;

  @override
  State<RegisterView> createState() => _RegisterViewState();
}

class _RegisterViewState extends State<RegisterView> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _register() async {
    try {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text,
        password: _passwordController.text,
      );

      if (!mounted) {
        return;
      }

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const MainView(title: 'PantryMatch'),
        ),
      );
    } catch (e) {
      debugPrint('Registration failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    var textStyle = const TextStyle(
      fontWeight: FontWeight.w900,
      fontSize: 28,
      color: Color(0xFF3A3226),
    );

    buildTextField(controller, isObscure, labelText) => TextField(
      controller: controller,
      obscureText: isObscure,
      decoration: InputDecoration(
        labelText: labelText,
        border: const OutlineInputBorder(),
      ),
    );

    return Scaffold(
      backgroundColor: const Color(0xFFFBF6EC),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - 40,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 320),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      spacing: 15,
                      children: [
                        Image.asset(
                          'assets/images/pantrymatch_logo.png',
                          width: 200,
                        ),

                        Text(
                          'Create Account',
                          style: textStyle,
                          textAlign: TextAlign.center,
                        ),

                        buildTextField(_emailController, false, 'Email'),

                        buildTextField(_passwordController, true, 'Password'),

                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _register,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF639922),
                              foregroundColor: Colors.white,
                              minimumSize: const Size(0, 50),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text('Register'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
