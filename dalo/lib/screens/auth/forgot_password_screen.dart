import 'package:flutter/material.dart';

import '../../services/auth_service.dart';
import '../../core/widgets/common_widgets.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  bool _loading = false;
  bool _sent = false;
  String? _error;

  final _auth = AuthService();

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _loading = true; _error = null; });
    try {
      await _auth.sendPasswordReset(_emailCtrl.text);
      if (mounted) setState(() => _sent = true);
    } catch (e) {
      setState(() => _error = 'Could not send reset email. Check the address and try again.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Reset password')),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
        child: _sent
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Email sent', style: tt.headlineLarge),
                  const SizedBox(height: 12),
                  Text(
                    'Check your inbox for a password reset link.',
                    style: tt.bodyMedium,
                  ),
                  const SizedBox(height: 24),
                  SecondaryButton(
                    label: 'Back to sign in',
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              )
            : Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Forgot your password?', style: tt.headlineLarge),
                    const SizedBox(height: 8),
                    Text(
                      'Enter your email and we\'ll send a reset link.',
                      style: tt.bodySmall,
                    ),
                    const SizedBox(height: 32),
                    TextFormField(
                      controller: _emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      autocorrect: false,
                      decoration: const InputDecoration(labelText: 'Email'),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Enter your email.';
                        if (!v.contains('@')) return 'Enter a valid email.';
                        return null;
                      },
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 16),
                      ErrorBanner(message: _error!),
                    ],
                    const SizedBox(height: 24),
                    PrimaryButton(
                      label: 'Send reset email',
                      onPressed: _submit,
                      isLoading: _loading,
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
