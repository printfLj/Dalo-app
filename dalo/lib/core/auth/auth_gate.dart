import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../models/app_user.dart';
import '../../services/auth_service.dart';
import '../../screens/auth/login_screen.dart';
import '../../screens/student/student_home.dart';
import '../theme/dalo_theme.dart';
import '../widgets/dalo_brand_mark.dart';

/// Keeps auth state and profile loading separate so a profile read delay or
/// Firestore error can never silently send a signed-in user back to login.
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  late final AuthService _authService;
  late final Stream<User?> _authStream;

  @override
  void initState() {
    super.initState();
    _authService = AuthService();
    _authStream = _authService.authStateChanges;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: _authStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _SplashScreen();
        }
        if (snapshot.hasError) {
          return _SessionProblem(
            message:
                'Daló could not check your sign-in status. Check your connection and try again.',
            onSignOut: _authService.signOut,
          );
        }

        final user = snapshot.data;
        if (user == null) return const LoginScreen();
        if (!user.emailVerified) {
          return _SessionProblem(
            message:
                'Your student email is not verified yet. Sign out, verify your email, then sign in again.',
            onSignOut: _authService.signOut,
          );
        }

        return _UserProfileGate(user: user, authService: _authService);
      },
    );
  }
}

class _UserProfileGate extends StatelessWidget {
  final User user;
  final AuthService authService;

  const _UserProfileGate({required this.user, required this.authService});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AppUser?>(
      stream: authService.appUserStream(user.uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _SplashScreen();
        }
        if (snapshot.hasError) {
          return _SessionProblem(
            message:
                'You are signed in, but Daló could not load your profile. Check your connection and Firebase access, then sign out and try again.',
            onSignOut: authService.signOut,
          );
        }

        final appUser = snapshot.data;
        if (appUser == null) {
          return _SessionProblem(
            message:
                'You are signed in, but your Daló profile is missing. Sign out and register again, or ask the project owner to check the Firebase user record.',
            onSignOut: authService.signOut,
          );
        }

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
      backgroundColor: DaloPalette.canvas,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const DaloBrandMark(width: 220),
            const SizedBox(height: 24),
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: DaloPalette.accent,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SessionProblem extends StatelessWidget {
  final String message;
  final Future<void> Function() onSignOut;

  const _SessionProblem({required this.message, required this.onSignOut});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.cloud_off_outlined,
                  size: 48,
                  color: DaloPalette.accent,
                ),
                const SizedBox(height: 18),
                Text(
                  'Could not open your account',
                  style: Theme.of(context).textTheme.titleLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(message, textAlign: TextAlign.center),
                const SizedBox(height: 24),
                FilledButton.tonalIcon(
                  onPressed: onSignOut,
                  icon: const Icon(Icons.logout),
                  label: const Text('Sign out'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
