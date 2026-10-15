import 'package:flutter/material.dart';

import 'core/auth/auth_gate.dart';
import 'core/theme/dalo_theme.dart';

class DaloApp extends StatelessWidget {
  const DaloApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Daló',
      debugShowCheckedModeBanner: false,
      theme: DaloTheme.light,
      home: const AuthGate(),
    );
  }
}
