import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'register_view.dart';
import 'main_view.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key, required this.title});

  final String title;

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  late final Future<void> _googleSignInInitialization;

  @override
  void initState() {
    super.initState();
    _googleSignInInitialization = GoogleSignIn.instance.initialize(
      serverClientId: '219036822002-eb96u8a4klcg76hcen7gbbuvq91v37pt.apps.googleusercontent.com',
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() async {
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
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
      debugPrint('Login failed: $e');
    }
  }

  Future<void> _signInWithGoogle() async {
    try {
      await _googleSignInInitialization;

      final googleUser = await GoogleSignIn.instance.authenticate();

      final googleAuth = googleUser.authentication;

      final idToken = googleAuth.idToken;

      if (idToken == null) {
        throw Exception(
          'Google ID token is missing. Check your Firebase configuration.',
        );
      }

      final credential = GoogleAuthProvider.credential(idToken: idToken);

      await FirebaseAuth.instance.signInWithCredential(credential);

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
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Google sign-in failed: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    var titleStyle = const TextStyle(
      fontWeight: FontWeight.w900,
      fontSize: 28,
      color: Color(0xFF3A3226),
    );

    var textStyle = const TextStyle(fontSize: 13, color: Color(0xFF8A7F6B));

    buildTextField(controller, isObscure, labelText) => TextField(
      controller: controller,
      obscureText: isObscure,
      decoration: InputDecoration(
        labelText: labelText,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE4D9C3)),
        ),
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
                          width: 210,
                        ),

                        Text(
                          'Welcome Back!',
                          style: titleStyle,
                          textAlign: TextAlign.center,
                        ),

                        Text(
                          'Log in to discover recipes from what you have.',
                          style: textStyle,
                          textAlign: TextAlign.center,
                        ),

                        const SizedBox(height: 10),

                        buildTextField(_emailController, false, 'Email'),

                        buildTextField(_passwordController, true, 'Password'),

                        Align(
                          alignment: Alignment.centerRight,
                          child: Text(
                            'Forgot Password?',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFFB5502E),
                            ),
                          ),
                        ),

                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _submit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFE8813A),
                              foregroundColor: Colors.white,
                              minimumSize: const Size(0, 48),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text('Log In'),
                          ),
                        ),

                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: _signInWithGoogle,
                            icon: const Text(
                              'G',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF4285F4),
                              ),
                            ),
                            label: const Text('Continue with Google'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF3A3226),
                              backgroundColor: Colors.white,
                              minimumSize: const Size(0, 48),
                              side: const BorderSide(color: Color(0xFFE4D9C3)),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Flexible(
                              child: Text(
                                "Don't have an account?",
                                style: textStyle,
                              ),
                            ),

                            TextButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const RegisterView(title: 'Register'),
                                  ),
                                );
                              },
                              child: const Text(
                                'Sign Up',
                                style: TextStyle(color: Color(0xFF639922)),
                              ),
                            ),
                          ],
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
