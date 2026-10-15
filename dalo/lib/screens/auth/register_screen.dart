import 'package:flutter/material.dart';

import '../../services/auth_service.dart'
    show AuthService, kAllowedEmailDomains;
import '../../core/widgets/common_widgets.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _obscurePass = true;
  bool _obscureConfirm = true;
  bool _loading = false;
  bool _success = false;
  String? _error;

  final _auth = AuthService();

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await _auth.signUp(
        email: _emailCtrl.text,
        password: _passCtrl.text,
        displayName: _nameCtrl.text,
      );
      if (mounted) setState(() => _success = true);
    } catch (e) {
      setState(() => _error = _friendlyError(e.toString()));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _friendlyError(String raw) {
    if (raw.contains('email-already-in-use')) {
      return 'An account with this email already exists.';
    }
    if (raw.contains('weak-password')) {
      return 'Password is too weak. Use at least 6 characters.';
    }
    if (raw.contains('allowed')) {
      // Domain restriction message
      return raw.replaceAll('Exception:', '').trim();
    }
    if (raw.contains('network')) {
      return 'Network error. Check your connection.';
    }
    return 'Registration failed. Please try again.';
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    if (_success) {
      return Scaffold(
        appBar: AppBar(title: const Text('Almost there')),
        body: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Check your email', style: tt.headlineLarge),
              const SizedBox(height: 16),
              Text(
                'We sent a verification link to ${_emailCtrl.text.trim()}. '
                'Open it to activate your account, then sign in.',
                style: tt.bodyMedium,
              ),
              const SizedBox(height: 32),
              PrimaryButton(
                label: 'Go to sign in',
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Create account')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Sign up', style: tt.headlineLarge),
                const SizedBox(height: 6),
                Text(
                  'Create a student account with your institution email.',
                  style: tt.bodySmall,
                ),
                if (kAllowedEmailDomains.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Only ${kAllowedEmailDomains.map((domain) => '@$domain').join(' or ')} addresses are accepted.',
                    style: tt.bodySmall?.copyWith(fontStyle: FontStyle.italic),
                  ),
                ],
                const SizedBox(height: 32),
                TextFormField(
                  controller: _nameCtrl,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(labelText: 'Full name'),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty)
                      return 'Enter your name.';
                    if (v.trim().length < 2) return 'Name is too short.';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  autocorrect: false,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(labelText: 'Email'),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty)
                      return 'Enter your email.';
                    if (!v.contains('@')) return 'Enter a valid email.';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passCtrl,
                  obscureText: _obscurePass,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    suffixIcon: IconButton(
                      icon: Icon(_obscurePass
                          ? Icons.visibility_off
                          : Icons.visibility),
                      onPressed: () =>
                          setState(() => _obscurePass = !_obscurePass),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Enter a password.';
                    if (v.length < 6)
                      return 'Password must be at least 6 characters.';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _confirmCtrl,
                  obscureText: _obscureConfirm,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _register(),
                  decoration: InputDecoration(
                    labelText: 'Confirm password',
                    suffixIcon: IconButton(
                      icon: Icon(_obscureConfirm
                          ? Icons.visibility_off
                          : Icons.visibility),
                      onPressed: () =>
                          setState(() => _obscureConfirm = !_obscureConfirm),
                    ),
                  ),
                  validator: (v) {
                    if (v != _passCtrl.text) return 'Passwords do not match.';
                    return null;
                  },
                ),
                if (_error != null) ...[
                  const SizedBox(height: 16),
                  ErrorBanner(message: _error!),
                ],
                const SizedBox(height: 28),
                PrimaryButton(
                  label: 'Create account',
                  onPressed: _register,
                  isLoading: _loading,
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Already have an account?', style: tt.bodySmall),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Sign in'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
