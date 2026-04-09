import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'profile_screen.dart';

class AuthenticationScreen extends StatefulWidget {
  const AuthenticationScreen({super.key});

  @override
  State<AuthenticationScreen> createState() => _AuthenticationScreenState();
}

class _AuthenticationScreenState extends State<AuthenticationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  final AuthService _authService = AuthService();

  bool _isLogin = true;
  bool _isLoading = false;
  String? _message;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  //validate email by checking if empty and if it matches a basic email pattern
  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email is required';
    }

    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Enter a valid email like test@gsu.com';
    }

    return null;
  }

  //validate password by checking if empty and if it has at least 6 characters
  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.trim().length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  //map FirebaseAuthException codes to helpful messages for the user
  String _helpfulAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return 'That email is already registered.';
      case 'invalid-email':
        return 'The email format is invalid.';
      case 'weak-password':
        return 'Choose a stronger password.';
      case 'user-not-found':
        return 'No account was found for that email.';
      case 'wrong-password':
        return 'Incorrect email or password.';
      case 'invalid-credential':
        return 'Incorrect email or password.';
      default:
        return e.message ?? 'Authentication failed.';
    }
  }

  //handle form submission for both login and registration, set loading state and error messages
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _message = null;
    });

    try {
      if (_isLogin) {
        await _authService.signIn(
          email: _emailController.text,
          password: _passwordController.text,
        );
      } else {
        await _authService.register(
          email: _emailController.text,
          password: _passwordController.text,
        );
      }

      if (!mounted) return;

      //go to profile screen but replace the current screen so user cannot go back to login
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const ProfileScreen()),
      );
    } on FirebaseAuthException catch (e) {
      setState(() {
        _message = _helpfulAuthError(e);
      });
    } catch (_) {
      setState(() {
        _message = 'Something went wrong. Please try again.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  //toggle between login and registration modes, reset form and clear messages
  void _toggleMode() {
    setState(() {
      _isLogin = !_isLogin;
      _message = null;
      _formKey.currentState?.reset();
      _passwordController.clear();
    });
  }

  //##TODO build the UI with a form for email and password
  //a submit button, and a toggle button to switch modes
}