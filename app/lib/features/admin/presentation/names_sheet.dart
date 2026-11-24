import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/error/failure.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/mb_dimens.dart';
import '../../../shared/widgets/mb_button.dart';
import '../../../shared/widgets/mb_state_views.dart';
import '../../../shared/widgets/mb_text_field.dart';
import '../domain/admin_categories.dart';
import '../domain/admin_products.dart';

/// Opens the [NamesSheet] as a bottom sheet.
Future<void> showNamesSheet(
  BuildContext context, {
  required String title,
  required bool isNew,
  Map<String, String> names = const {},
  bool isActive = true,
  required Future<Failure?> Function(
    String code,
    Map<String, String> names,
    bool isActive,
  )
  onSave,
}) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  shape: const RoundedRectangleBorder(
    borderRadius: BorderRadius.vertical(top: Radius.circular(MbRadius.lg)),
  ),
  builder: (_) => NamesSheet(
    title: title,
    isNew: isNew,
    names: names,
    isActive: isActive,
    onSave: onSave,
  ),
);

/// Add or edit a category, sub-category or variant: its code (new only), names, and
/// on/off (edit only). Stays open if the save is refused, showing why.
class NamesSheet extends StatefulWidget {
  const NamesSheet({
    super.key,
    required this.title,
    required this.isNew,
    required this.names,
    required this.isActive,
    required this.onSave,
  });

  final String title;
  final bool isNew;
  final Map<String, String> names;
  final bool isActive;
  final Future<Failure?> Function(
    String code,
    Map<String, String> names,
    bool isActive,
  )
  onSave;

  @override
  State<NamesSheet> createState() => _NamesSheetState();
}

class _NamesSheetState extends State<NamesSheet> {
  final _code = TextEditingController();
  late final Map<String, TextEditingController> _names = {
    for (final lang in productNameLanguages)
      lang: TextEditingController(text: widget.names[lang] ?? ''),
  };
  late bool _isActive = widget.isActive;

  bool _showErrors = false;
  bool _saving = false;
  Failure? _failure;

  Map<String, String> get _values => {
    for (final e in _names.entries) e.key: e.value.text,
  };

  Set<CategoryProblem> get _problems =>
      categoryProblems(isNew: widget.isNew, code: _code.text, names: _values);

  @override
  void dispose() {
    _code.dispose();
    for (final c in _names.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (_problems.isNotEmpty) {
      setState(() => _showErrors = true);
      return;
    }
    setState(() {
      _saving = true;
      _failure = null;
    });
    final failure = await widget.onSave(_code.text, _values, _isActive);
    if (!mounted) return;
    if (failure == null) {
      Navigator.of(context).pop();
    } else {
      setState(() {
        _saving = false;
        _failure = failure;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.mbColors;
    final t = context.mbText;
    final problems = _showErrors ? _problems : <CategoryProblem>{};
    final labels = {
      'en': l10n.adminProductNameEn,
      'hi': l10n.adminProductNameHi,
      'mr': l10n.adminProductNameMr,
    };

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(MbSpacing.s4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(widget.title, style: t.title.copyWith(color: c.ink)),
            if (widget.isNew) ...[
              const SizedBox(height: MbSpacing.s3),
              MbTextField(
                controller: _code,
                label: l10n.adminProductCode,
                helper: l10n.adminCategoryCodeHint,
                enabled: !_saving,
                inputFormatters: [
                  LengthLimitingTextInputFormatter(40),
                  FilteringTextInputFormatter.allow(RegExp(r'[a-z0-9-]')),
                ],
                error: problems.contains(CategoryProblem.codeInvalid)
                    ? l10n.adminProductErrCode
                    : null,
              ),
            ],
            for (final lang in productNameLanguages) ...[
              const SizedBox(height: MbSpacing.s3),
              MbTextField(
                controller: _names[lang],
                label: labels[lang],
                helper: lang == 'en' ? null : l10n.adminProductNameOptional,
                enabled: !_saving,
                inputFormatters: [
                  LengthLimitingTextInputFormatter(productNameMaxLength),
                ],
                error:
                    lang == 'en' &&
                        problems.contains(CategoryProblem.englishMissing)
                    ? l10n.adminProductErrEnglish
                    : null,
              ),
            ],
            if (!widget.isNew)
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  l10n.adminProductActive,
                  style: t.body.copyWith(color: c.ink),
                ),
                subtitle: Text(
                  l10n.adminCategoryActiveHint,
                  style: t.caption.copyWith(color: c.inkMuted),
                ),
                value: _isActive,
                onChanged: _saving
                    ? null
                    : (v) => setState(() => _isActive = v),
              ),
            if (_failure != null) ...[
              const SizedBox(height: MbSpacing.s2),
              Text(
                failureMessage(context, _failure!),
                style: t.caption.copyWith(color: c.priceUp),
              ),
            ],
            const SizedBox(height: MbSpacing.s4),
            MbButton(
              label: l10n.adminCategorySave,
              block: true,
              isLoading: _saving,
              onPressed: _saving ? null : _save,
            ),
          ],
        ),
      ),
    );
  }
}
