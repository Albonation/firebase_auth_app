import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'authentication_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthService _authService = AuthService();
  final TextEditingController _newPasswordController = TextEditingController();

  bool _isUpdatingPassword = false;
  String? _message;

  @override
  void dispose() {
    _newPasswordController.dispose();
    super.dispose();
  }

  //validate new password by checking if empty and if it has at least 6 characters
  //then attempt to update the password using auth service and handle any errors that may occur
  Future<void> _changePassword() async {
    final newPassword = _newPasswordController.text.trim();

    if (newPassword.isEmpty) {
      setState(() {
        _message = 'Please enter a new password.';
      });
      return;
    }

    if (newPassword.length < 6) {
      setState(() {
        _message = 'New password must be at least 6 characters.';
      });
      return;
    }

    setState(() {
      _isUpdatingPassword = true;
      _message = null;
    });

    try {
      await _authService.changePassword(newPassword);
      _newPasswordController.clear();

      setState(() {
        _message = 'Password updated successfully.';
      });
    } on FirebaseAuthException catch (e) {
      setState(() {
        switch (e.code) {
          case 'no-user':
            _message = 'You must be signed in to change your password.';
            break;
          case 'requires-recent-login':
            _message =
            'Please sign out and sign in again before changing your password.';
            break;
          default:
            _message = e.message ?? 'Password update failed.';
        }
      });
    } catch (_) {
      setState(() {
        _message = 'Something went wrong while updating the password.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isUpdatingPassword = false;
        });
      }
    }
  }

  //sign out the user using auth service and navigate back to authentication screen
  //this method also removes all previous screens on the stack
  Future<void> _signOut() async {
    await _authService.signOut();

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const AuthenticationScreen()),
          (route) => false,
    );
  }

  //profile screen UI that shows signed in user's email
  //also includes a field to change the password and a button to sign out
  @override
  Widget build(BuildContext context) {
    final user = _authService.currentUser;
    final email = user?.email ?? 'No email found';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            onPressed: _signOut,
            icon: const Icon(Icons.logout),
            tooltip: 'Sign Out',
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Signed In User',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 16),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.email_outlined),
                      title: const Text('Email'),
                      subtitle: Text(email),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Change Password',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _newPasswordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'New Password',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (_message != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Text(
                          _message!,
                          style: TextStyle(
                            color: _message!.toLowerCase().contains('success')
                                ? Colors.green
                                : Colors.red,
                          ),
                        ),
                      ),
                    FilledButton(
                      onPressed: _isUpdatingPassword ? null : _changePassword,
                      child: _isUpdatingPassword
                          ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                          : const Text('Update Password'),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: _signOut,
                      icon: const Icon(Icons.logout),
                      label: const Text('Sign Out'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}