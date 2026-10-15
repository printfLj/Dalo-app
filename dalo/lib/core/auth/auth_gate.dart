import 'package:flutter/material.dart';

import '../../models/app_user.dart';
import '../../services/auth_service.dart';
import '../../screens/auth/login_screen.dart';
import '../../screens/student/student_home.dart';

/// Watches the auth + user-role stream and routes to the correct home screen.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();
    return StreamBuilder<AppUser?>(
      stream: authService.currentAppUserStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _SplashScreen();
        }

        final appUser = snapshot.data;
        if (appUser == null) {
          return const LoginScreen();
        }

        // Every account can browse, join, and host events. Facilitator tools
        // remain available from the shared home for facilitator accounts.
        return StudentHome(appUser: appUser);
      },
    );
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Daló',
              style: Theme.of(context).textTheme.displayMedium,
            ),
            const SizedBox(height: 24),
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Color(0xFF111111),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
