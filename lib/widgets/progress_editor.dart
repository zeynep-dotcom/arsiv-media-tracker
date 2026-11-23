import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:arsiv_app/core/theme/app_theme.dart';
import 'package:arsiv_app/models/content_item.dart';
import 'package:arsiv_app/models/progress_format.dart';

/// Detay ekranındaki ilerleme bölümü (Ece · Hafta 4).
///
/// Uzunluk biliniyorsa birimle çalışır ("140 / 350 sayfa", "12 / 40 saat",
/// "35 / 148 dk"); bilinmiyorsa yüzde gösterir. Değere dokununca sayı elle
/// girilebilir.
///
/// Sürüklerken yalnızca ekrandaki değer değişir; parmak kalkınca
/// [onChanged] bir kez çağrılır, böylece Firestore'a her adımda değil tek
/// seferde yazılır.
class ProgressEditor extends StatefulWidget {
  const ProgressEditor({
    super.key,
    required this.item,
    required this.progress,
    required this.onChanged,
  });

  final ContentItem item;

  /// 0-1 arası kayıtlı ilerleme.
  final double progress;
  final ValueChanged<double> onChanged;

  @override
  State<ProgressEditor> createState() => _ProgressEditorState();
}

class _ProgressEditorState extends State<ProgressEditor> {
  double? _dragValue;

  /// Kaydırıcı adımları: birim biliniyorsa her sayfa/saat/dakika bir adım
  /// (çok uzunsa serbest), bilinmiyorsa %5'lik adımlar.
  int? get _divisions {
    final total = ProgressFormat.total(widget.item);
    if (total == null) return 20;
    return total <= 1000 ? total : null;
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final value = (_dragValue ?? widget.progress).clamp(0.0, 1.0).toDouble();
    final label = ProgressFormat.label(item, value);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'İlerleme',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            const Spacer(),
            InkWell(
              key: const ValueKey('progress-edit'),
              borderRadius: BorderRadius.circular(6),
              onTap: () => _editManually(context),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.edit_outlined,
                        size: 14, color: AppColors.textSecondary),
                  ],
                ),
              ),
            ),
          ],
        ),
        Slider(
          value: value,
          divisions: _divisions,
          label: label,
          activeColor: AppColors.red,
          inactiveColor: AppColors.divider,
          onChanged: (v) => setState(() => _dragValue = v),
          onChangeEnd: (v) {
            setState(() => _dragValue = null);
            widget.onChanged(v);
          },
        ),
      ],
    );
  }

  Future<void> _editManually(BuildContext context) async {
    final entered = await showDialog<int>(
      context: context,
      builder: (_) => _ProgressInputDialog(
        item: widget.item,
        initial: ProgressFormat.current(widget.item, widget.progress),
      ),
    );
    if (entered == null || !mounted) return;
    widget.onChanged(ProgressFormat.fromInput(widget.item, entered));
  }
}

/// "Kaçıncı sayfadasın?" diyaloğu. Birim yoksa yüzde istenir.
class _ProgressInputDialog extends StatefulWidget {
  const _ProgressInputDialog({required this.item, required this.initial});

  final ContentItem item;
  final int initial;

  @override
  State<_ProgressInputDialog> createState() => _ProgressInputDialogState();
}

class _ProgressInputDialogState extends State<_ProgressInputDialog> {
  late final TextEditingController _controller =
      TextEditingController(text: '${widget.initial}');
  String? _error;

  int get _max => ProgressFormat.maxInput(widget.item);
  bool get _hasUnits => ProgressFormat.hasUnits(widget.item);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final value = int.tryParse(_controller.text.trim());
    if (value == null) {
      setState(() => _error = 'Bir sayı gir');
      return;
    }
    if (value > _max) {
      setState(() => _error = 'En fazla $_max olabilir');
      return;
    }
    Navigator.of(context).pop(value);
  }

  @override
  Widget build(BuildContext context) {
    final unit = ProgressFormat.unit(widget.item.type);
    return AlertDialog(
      backgroundColor: AppColors.card,
      title: Text(_hasUnits ? 'İlerlemeni gir' : 'İlerleme yüzdesi'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        onSubmitted: (_) => _submit(),
        decoration: InputDecoration(
          prefixText: _hasUnits ? null : '%',
          suffixText: _hasUnits ? '/ $_max $unit' : null,
          helperText: '0 ile $_max arası',
          errorText: _error,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Vazgeç'),
        ),
        FilledButton(
          onPressed: _submit,
          style: FilledButton.styleFrom(backgroundColor: AppColors.red),
          child: const Text('Kaydet'),
        ),
      ],
    );
  }
}
