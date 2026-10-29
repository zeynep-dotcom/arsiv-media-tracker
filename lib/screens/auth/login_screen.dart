import 'package:flutter/material.dart';

import 'package:arsiv_app/core/theme/app_theme.dart';
import 'package:arsiv_app/screens/auth/auth_form.dart';

/// Giriş ekranı. Firebase'i bilmez; işi [onLogin] ile dışarıya bırakır
/// (AuthGate bağlar). Hata olursa [onLogin] fırlattığı mesaj gösterilir.
///
/// Geçici sade tasarım: Emir'in tasarımı gelince gövde değişecek,
/// constructor ve callback'ler aynı kalmalı.
class LoginScreen extends StatefulWidget {
  const LoginScreen({
    super.key,
    required this.onLogin,
    required this.onRegisterTap,
    required this.onForgotPasswordTap,
  });

  final Future<void> Function(String email, String password) onLogin;
  final VoidCallback onRegisterTap;
  final VoidCallback onForgotPasswordTap;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with AuthFormState {
  final _email = TextEditingController();
  final _password = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _submit() {
    if (_email.text.trim().isEmpty || _password.text.isEmpty) {
      showError('E-posta ve şifreni gir.');
      return;
    }
    run(() => widget.onLogin(_email.text, _password.text));
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      children: [
        const Text(
          'ARŞİV',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.red,
            fontSize: 40,
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 32),
        TextField(
          controller: _email,
          keyboardType: TextInputType.emailAddress,
          autofillHints: const [AutofillHints.email],
          decoration: const InputDecoration(labelText: 'E-posta'),
        ),
        const SizedBox(height: 12),
        PasswordField(
          controller: _password,
          label: 'Şifre',
          onSubmitted: (_) => _submit(),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: loading ? null : widget.onForgotPasswordTap,
            child: const Text('Şifremi unuttum'),
          ),
        ),
        SubmitButton(label: 'Giriş yap', loading: loading, onPressed: _submit),
        ErrorText(error),
        const SizedBox(height: 8),
        TextButton(
          onPressed: loading ? null : widget.onRegisterTap,
          child: const Text('Hesabın yok mu? Kayıt ol'),
        ),
      ],
    );
  }
}
