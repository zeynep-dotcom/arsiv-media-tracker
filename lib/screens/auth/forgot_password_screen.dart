import 'package:flutter/material.dart';

import 'package:arsiv_app/core/theme/app_theme.dart';
import 'package:arsiv_app/screens/auth/auth_form.dart';

/// Şifre sıfırlama ekranı. Bağlantıyı [onSendLink] gönderir (AuthGate
/// bağlar); gönderilince "E-postanı kontrol et" durumuna geçer.
///
/// Geçici sade tasarım: Emir'in tasarımı gelince gövde değişecek,
/// constructor ve callback aynı kalmalı.
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key, required this.onSendLink});

  final Future<void> Function(String email) onSendLink;

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen>
    with AuthFormState {
  final _email = TextEditingController();
  bool _sent = false;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_email.text.trim().isEmpty) {
      showError('E-posta adresini gir.');
      return;
    }
    final ok = await run(() => widget.onSendLink(_email.text));
    if (ok && mounted) setState(() => _sent = true);
  }

  @override
  Widget build(BuildContext context) {
    if (_sent) {
      return AuthScaffold(
        title: 'Şifremi unuttum',
        children: [
          const Icon(Icons.mark_email_read_outlined,
              size: 64, color: AppColors.green),
          const SizedBox(height: 16),
          const Text(
            'E-postanı kontrol et',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            '${_email.text.trim()} adresine şifre sıfırlama bağlantısı '
            'gönderdik.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 24),
          SubmitButton(
            label: 'Girişe dön',
            loading: false,
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      );
    }

    return AuthScaffold(
      title: 'Şifremi unuttum',
      children: [
        const Text(
          'Hesabının e-posta adresini gir; şifreni sıfırlaman için bir '
          'bağlantı gönderelim.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _email,
          keyboardType: TextInputType.emailAddress,
          autofillHints: const [AutofillHints.email],
          onSubmitted: (_) => _submit(),
          decoration: const InputDecoration(labelText: 'E-posta'),
        ),
        const SizedBox(height: 16),
        SubmitButton(
          label: 'Bağlantı gönder',
          loading: loading,
          onPressed: _submit,
        ),
        ErrorText(error),
      ],
    );
  }
}
