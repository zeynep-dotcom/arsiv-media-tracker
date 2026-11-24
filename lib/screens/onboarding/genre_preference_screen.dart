import 'package:flutter/material.dart';

import 'package:arsiv_app/core/config/genre_map.dart';
import 'package:arsiv_app/core/theme/app_theme.dart';
import 'package:arsiv_app/screens/auth/auth_form.dart';
import 'package:arsiv_app/services/user_preferences.dart';

/// Kayıttan sonra açılan "Hangi türleri seversin?" ekranı (Ahmet).
/// GenreMap'teki türlerden en az [UserPreferences.minGenres] tanesi seçilince
/// "Devam" açılır; "Atla" seçim yapmadan geçer. Kaydetme işi AuthGate'te.
class GenrePreferenceScreen extends StatefulWidget {
  const GenrePreferenceScreen({
    super.key,
    required this.onSave,
    required this.onSkip,
    this.initial = const [],
  });

  /// Seçilen tür etiketleriyle çağrılır; hata fırlatırsa ekranda gösterilir.
  final Future<void> Function(List<String> genres) onSave;
  final VoidCallback onSkip;
  final List<String> initial;

  @override
  State<GenrePreferenceScreen> createState() => _GenrePreferenceScreenState();
}

class _GenrePreferenceScreenState extends State<GenrePreferenceScreen> {
  static const _saveError = 'Kaydedilemedi. Tekrar dene.';

  late final Set<String> _selected = widget.initial.toSet();
  bool _saving = false;
  String? _error;

  bool get _enough => _selected.length >= UserPreferences.minGenres;

  void _toggle(String genre) => setState(() {
    if (!_selected.remove(genre)) _selected.add(genre);
    _error = null;
  });

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.onSave(UserPreferences.cleanGenres(_selected));
    } catch (e) {
      debugPrint('[Tercihler] kaydedilemedi · $e');
      if (mounted) setState(() => _error = _saveError);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final count = _selected.length;
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        actions: [
          TextButton(
            onPressed: _saving ? null : widget.onSkip,
            child: const Text('Atla'),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          children: [
            const Text(
              'Hangi türleri seversin?',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            const Text(
              'En az ${UserPreferences.minGenres} tür seç; Keşfet\'teki '
              'öneriler bu türlerden başlasın.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 15),
            ),
            const SizedBox(height: 24),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final genre in GenreMap.all)
                  FilterChip(
                    label: Text(genre.label),
                    selected: _selected.contains(genre.label),
                    onSelected: _saving ? null : (_) => _toggle(genre.label),
                    selectedColor: AppColors.red,
                    checkmarkColor: Colors.white,
                    backgroundColor: AppColors.card,
                    side: BorderSide.none,
                    labelStyle: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              _enough
                  ? '$count tür seçildi'
                  : '$count / ${UserPreferences.minGenres} seçildi',
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _enough && !_saving ? _save : null,
              style: FilledButton.styleFrom(
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(48),
              ),
              child: _saving
                  ? const SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Devam'),
            ),
            ErrorText(_error),
          ],
        ),
      ),
    );
  }
}
