import 'package:flutter/material.dart';

import 'package:arsiv_app/core/theme/app_theme.dart';
import 'package:arsiv_app/services/auth_service.dart';

/// Giriş, Kayıt ve Şifremi unuttum ekranlarının ortak durumu:
/// istek sürerken [loading], başarısız olursa Türkçe [error].
mixin AuthFormState<T extends StatefulWidget> on State<T> {
  bool loading = false;
  String? error;

  void showError(String message) => setState(() => error = message);

  /// [action] sürerken butonu kilitler; [AuthException] mesajını gösterir.
  /// Başarılıysa true döner.
  Future<bool> run(Future<void> Function() action) async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      await action();
      return true;
    } on AuthException catch (e) {
      if (mounted) setState(() => error = e.message);
    } catch (e) {
      debugPrint('[Auth] beklenmeyen hata · $e');
      if (mounted) setState(() => error = AuthService.messageFor('unknown'));
    } finally {
      if (mounted) setState(() => loading = false);
    }
    return false;
  }
}

class AuthScaffold extends StatelessWidget {
  const AuthScaffold({super.key, this.title, required this.children});

  final String? title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: title == null ? null : AppBar(title: Text(title!)),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: children,
            ),
          ),
        ),
      ),
    );
  }
}

/// Göster/gizle ikonlu şifre alanı.
class PasswordField extends StatefulWidget {
  const PasswordField({
    super.key,
    required this.controller,
    required this.label,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final String label;
  final ValueChanged<String>? onSubmitted;

  @override
  State<PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<PasswordField> {
  bool _hidden = true;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: widget.controller,
      obscureText: _hidden,
      onSubmitted: widget.onSubmitted,
      decoration: InputDecoration(
        labelText: widget.label,
        suffixIcon: IconButton(
          tooltip: _hidden ? 'Şifreyi göster' : 'Şifreyi gizle',
          icon: Icon(_hidden ? Icons.visibility : Icons.visibility_off),
          onPressed: () => setState(() => _hidden = !_hidden),
        ),
      ),
    );
  }
}

/// Yüklenirken dönen gösterge çıkaran ana buton.
class SubmitButton extends StatelessWidget {
  const SubmitButton({
    super.key,
    required this.label,
    required this.loading,
    required this.onPressed,
  });

  final String label;
  final bool loading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: loading ? null : onPressed,
      style: FilledButton.styleFrom(
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(48),
      ),
      child: loading
          ? const SizedBox.square(
              dimension: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Text(label),
    );
  }
}

class ErrorText extends StatelessWidget {
  const ErrorText(this.error, {super.key});

  final String? error;

  @override
  Widget build(BuildContext context) {
    if (error == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Text(
        error!,
        textAlign: TextAlign.center,
        style: const TextStyle(color: AppColors.red),
      ),
    );
  }
}
