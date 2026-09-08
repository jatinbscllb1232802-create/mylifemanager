import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../navigation/post_auth.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  static const routeName = '/login';

  @override
  Widget build(BuildContext context) {
    final authProvider = context.read<AuthProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Sign in')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'MyLifeManager',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              'Sign in to sync tasks across your devices.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: () async {
                try {
                  await authProvider.signInWithGoogle();
                  if (!context.mounted) return;
                  await navigateAfterAuthenticated(context);
                } catch (e) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Google sign-in failed: $e')),
                  );
                }
              },
              icon: const Icon(Icons.login),
              label: const Text('Continue with Google'),
            ),
          ],
        ),
      ),
    );
  }
}