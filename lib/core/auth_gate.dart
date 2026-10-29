import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:arsiv_app/screens/auth/forgot_password_screen.dart';
import 'package:arsiv_app/screens/auth/login_screen.dart';
import 'package:arsiv_app/screens/auth/register_screen.dart';
import 'package:arsiv_app/screens/home_shell.dart';
import 'package:arsiv_app/screens/profile/profile_screen.dart';
import 'package:arsiv_app/services/auth_service.dart';
import 'package:arsiv_app/services/library_store.dart';

/// Uygulamanın girişi: oturum yoksa Giriş ekranı, varsa [home] açılır.
/// Giriş/kayıt/şifre ekranlarının callback'leri burada AuthService'e bağlanır;
/// oturum açılınca kütüphane users/{uid}/library ile eşitlenir.
class AuthGate extends StatefulWidget {
  const AuthGate({super.key, this.service, this.home = const HomeShell()});

  /// Testlerde sahte servis verilir; yoksa [AuthService.instance].
  final AuthService? service;
  final Widget home;

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  late final AuthService _auth = widget.service ?? AuthService.instance;
  late User? _user = _auth.currentUser;
  StreamSubscription<User?>? _subscription;

  @override
  void initState() {
    super.initState();
    _syncLibrary(_user);
    _subscription = _auth.authStateChanges.listen((user) {
      _syncLibrary(user);
      setState(() => _user = user);
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  void _syncLibrary(User? user) {
    final library = LibraryStore.instance;
    if (user == null) {
      library.stop();
    } else {
      library.start(user.uid, _auth.libraryOf(user.uid));
    }
  }

  void _openRegister(BuildContext context) {
    Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (routeContext) => RegisterScreen(
        onRegister: (name, email, password) async {
          await _auth.register(name, email, password);
          // Kayıt ekranını kapat; kapı artık ana ekranı gösterir.
          if (routeContext.mounted) {
            Navigator.of(routeContext).popUntil((route) => route.isFirst);
          }
        },
        onLoginTap: () => Navigator.of(routeContext).pop(),
      ),
    ));
  }

  void _openForgotPassword(BuildContext context) {
    Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) => ForgotPasswordScreen(onSendLink: _auth.sendPasswordReset),
    ));
  }

  @override
  Widget build(BuildContext context) {
    if (_user != null) return widget.home;
    return LoginScreen(
      onLogin: _auth.login,
      onRegisterTap: () => _openRegister(context),
      onForgotPasswordTap: () => _openForgotPassword(context),
    );
  }
}

/// Hesabım ekranını açar (Keşfet'teki avatar kullanır).
/// Çıkış yapılınca üstteki ekranlar kapanır, AuthGate girişi gösterir.
void openProfile(BuildContext context, {AuthService? service}) {
  final auth = service ?? AuthService.instance;
  final user = auth.currentUser;
  if (user == null) return;

  Navigator.of(context).push(MaterialPageRoute<void>(
    builder: (routeContext) => FutureBuilder<String>(
      future: auth.fetchPlan(),
      builder: (_, plan) => ProfileScreen(
        name: user.displayName ?? '',
        email: user.email ?? '',
        isPremium: plan.data == 'premium',
        onUpgrade: () => ScaffoldMessenger.of(routeContext).showSnackBar(
          const SnackBar(content: Text('Ödeme ekranı yakında.')),
        ),
        onLogout: () async {
          await auth.logout();
          if (routeContext.mounted) {
            Navigator.of(routeContext).popUntil((route) => route.isFirst);
          }
        },
      ),
    ),
  ));
}
