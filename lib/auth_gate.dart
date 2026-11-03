import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'backend_config.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!supabaseConfigured) {
      return BackendSetupScreen(child: child);
    }

    final client = Supabase.instance.client;
    return StreamBuilder<AuthState>(
      stream: client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        if (client.auth.currentSession != null || snapshot.data?.session != null) {
          return child;
        }
        return const SignInScreen();
      },
    );
  }
}

class BackendSetupScreen extends StatelessWidget {
  const BackendSetupScreen({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.cloud_outlined, size: 52),
                const SizedBox(height: 16),
                Text('Connect AccessWay Cloud', style: Theme.of(context).textTheme.headlineSmall, textAlign: TextAlign.center),
                const SizedBox(height: 10),
                const Text(
                  'Supabase is not configured yet. You can continue using the local demo, or add the project URL and publishable key to GitHub Actions to enable real accounts and cloud reports.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: () => Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (_) => child),
                  ),
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Continue in demo mode'),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});
  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final formKey = GlobalKey<FormState>();
  final name = TextEditingController();
  final email = TextEditingController();
  final password = TextEditingController();
  bool creatingAccount = false;
  bool busy = false;
  String? notice;

  @override
  void dispose() {
    name.dispose();
    email.dispose();
    password.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    if (!formKey.currentState!.validate()) return;
    setState(() { busy = true; notice = null; });
    try {
      final auth = Supabase.instance.client.auth;
      if (creatingAccount) {
        final response = await auth.signUp(
          email: email.text.trim(),
          password: password.text,
          data: {'display_name': name.text.trim()},
        );
        if (response.session == null && mounted) {
          setState(() => notice = 'Account created. Check your email to confirm, then sign in.');
        }
      } else {
        await auth.signInWithPassword(
          email: email.text.trim(),
          password: password.text,
        );
      }
    } on AuthException catch (e) {
      if (mounted) setState(() => notice = e.message);
    } catch (_) {
      if (mounted) setState(() => notice = 'Could not connect. Check your internet and Supabase project settings.');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: Form(
              key: formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const CircleAvatar(radius: 34, child: Icon(Icons.accessible_forward, size: 36)),
                  const SizedBox(height: 18),
                  Text('AccessWay AI', textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  const Text('Accessibility without boundaries', textAlign: TextAlign.center),
                  const SizedBox(height: 28),
                  Text(creatingAccount ? 'Create your account' : 'Welcome back', style: Theme.of(context).textTheme.titleLarge),
                  if (creatingAccount) ...[
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: name,
                      decoration: const InputDecoration(labelText: 'Full name', prefixIcon: Icon(Icons.person_outline)),
                      validator: (v) => v == null || v.trim().length < 2 ? 'Enter your name' : null,
                    ),
                  ],
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: email,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(labelText: 'Email address', prefixIcon: Icon(Icons.email_outlined)),
                    validator: (v) => v == null || !v.contains('@') ? 'Enter a valid email' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: password,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'Password', prefixIcon: Icon(Icons.lock_outline)),
                    validator: (v) => v == null || v.length < 8 ? 'Use at least 8 characters' : null,
                  ),
                  if (notice != null) ...[
                    const SizedBox(height: 12),
                    Text(notice!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                  ],
                  const SizedBox(height: 18),
                  FilledButton(
                    onPressed: busy ? null : submit,
                    child: Text(busy ? 'Please wait…' : creatingAccount ? 'Create account' : 'Sign in'),
                  ),
                  TextButton(
                    onPressed: busy ? null : () => setState(() { creatingAccount = !creatingAccount; notice = null; }),
                    child: Text(creatingAccount ? 'Already have an account? Sign in' : 'New to AccessWay? Create an account'),
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
