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
    if (!_formKey.currentState!.validate()) {
      debugPrint('[AUTH] Form validation failed');
      return;
    }

    setState(() {
      _isLoading = true;
      _message = null;
    });

    debugPrint(
      '[AUTH] Attempting to ${_isLogin ? 'sign in' : 'register'} with email: ${_emailController.text}',
    );

    try {
      if (_isLogin) {
        await _authService.signIn(
          email: _emailController.text,
          password: _passwordController.text,
        );
        debugPrint('[AUTH] Sign in successful for email: ${_emailController.text}');
      } else {
        await _authService.register(
          email: _emailController.text,
          password: _passwordController.text,
        );
        debugPrint(
          '[AUTH] Registration successful for email: ${_emailController.text}',
        );
      }

      if (!mounted) return;

      //go to profile screen but replace the current screen so user cannot go back to login
      debugPrint('[AUTH] Navigating to ProfileScreen via pushReplacement');
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
      debugPrint(
        '[AUTH] Authentication process completed for email: ${_emailController.text}',
      );
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

    debugPrint('[AUTH] Auth mode switched to ${_isLogin ? 'Sign In' : 'Register'}');
  }

  //UI with a form for email and password
  //a submit button, and a toggle button to switch modes
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isLogin ? 'Sign In' : 'Register')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      Text(
                        _isLogin ? 'Sign In' : 'Create Account',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _emailController,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.emailAddress,
                        validator: _validateEmail,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _passwordController,
                        decoration: const InputDecoration(
                          labelText: 'Password',
                          border: OutlineInputBorder(),
                        ),
                        obscureText: true,
                        validator: _validatePassword,
                      ),
                      const SizedBox(height: 16),
                      if (_message != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Text(
                            _message!,
                            style: const TextStyle(color: Colors.red),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: _isLoading ? null : _submit,
                          child: _isLoading
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(_isLogin ? 'Sign In' : 'Register'),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: _isLoading ? null : _toggleMode,
                        child: Text(
                          _isLogin
                              ? 'Need an account? Register'
                              : 'Already have an account? Sign In',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
