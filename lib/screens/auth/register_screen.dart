import 'package:flutter/material.dart';

import 'package:arsiv_app/screens/auth/auth_form.dart';

/// Kayıt ekranı. Hesabı [onRegister] açar (AuthGate bağlar).
///
/// Geçici sade tasarım: Emir'in tasarımı gelince gövde değişecek,
/// constructor ve callback'ler aynı kalmalı.
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({
    super.key,
    required this.onRegister,
    required this.onLoginTap,
  });

  final Future<void> Function(String name, String email, String password)
      onRegister;
  final VoidCallback onLoginTap;

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> with AuthFormState {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _passwordAgain = TextEditingController();
  bool _acceptedTerms = false;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _passwordAgain.dispose();
    super.dispose();
  }

  void _submit() {
    if (_name.text.trim().isEmpty ||
        _email.text.trim().isEmpty ||
        _password.text.isEmpty) {
      showError('Ad, e-posta ve şifre alanlarını doldur.');
    } else if (_password.text != _passwordAgain.text) {
      showError('Şifreler aynı değil.');
    } else if (!_acceptedTerms) {
      showError('Devam etmek için kullanım koşullarını kabul et.');
    } else {
      run(() => widget.onRegister(_name.text, _email.text, _password.text));
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      title: 'Kayıt ol',
      children: [
        TextField(
          controller: _name,
          textCapitalization: TextCapitalization.words,
          autofillHints: const [AutofillHints.name],
          decoration: const InputDecoration(labelText: 'Ad'),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _email,
          keyboardType: TextInputType.emailAddress,
          autofillHints: const [AutofillHints.email],
          decoration: const InputDecoration(labelText: 'E-posta'),
        ),
        const SizedBox(height: 12),
        PasswordField(controller: _password, label: 'Şifre'),
        const SizedBox(height: 12),
        PasswordField(controller: _passwordAgain, label: 'Şifre tekrar'),
        CheckboxListTile(
          value: _acceptedTerms,
          onChanged: (v) => setState(() => _acceptedTerms = v ?? false),
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
          title: const Text('Kullanım koşullarını kabul ediyorum'),
        ),
        SubmitButton(label: 'Kayıt ol', loading: loading, onPressed: _submit),
        ErrorText(error),
        const SizedBox(height: 8),
        TextButton(
          onPressed: loading ? null : widget.onLoginTap,
          child: const Text('Zaten hesabın var mı? Giriş yap'),
        ),
      ],
    );
  }
}
