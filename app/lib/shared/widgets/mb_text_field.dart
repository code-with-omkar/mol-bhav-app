import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_theme.dart';
import 'mb_field_frame.dart';
import 'mb_icon.dart';

/// Labelled 48px input with optional prefix (`+91`, `₹`), suffix (unit),
/// leading icon, helper and error text. Units go in the suffix, never in the
/// value.
class MbTextField extends StatefulWidget {
  const MbTextField({
    super.key,
    this.controller,
    this.label,
    this.hint,
    this.prefix,
    this.suffix,
    this.icon,
    this.helper,
    this.error,
    this.keyboardType,
    this.inputFormatters,
    this.autofillHints,
    this.textInputAction,
    this.onChanged,
    this.onSubmitted,
    this.enabled = true,
  });

  final TextEditingController? controller;
  final String? label;
  final String? hint;
  final String? prefix;
  final String? suffix;
  final MbIcons? icon;
  final String? helper;
  final String? error;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final Iterable<String>? autofillHints;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final bool enabled;

  @override
  State<MbTextField> createState() => _MbTextFieldState();
}

class _MbTextFieldState extends State<MbTextField> {
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _focus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.mbColors;
    final t = context.mbText;
    final affixStyle = t.fieldInput.copyWith(color: c.inkMuted);

    return MbFieldFrame(
      label: widget.label,
      helper: widget.helper,
      error: widget.error,
      focused: _focus.hasFocus,
      onTap: widget.enabled ? _focus.requestFocus : null,
      child: Row(
        children: [
          if (widget.icon != null) ...[
            MbIcon(widget.icon!, size: 18, color: c.inkMuted),
            const SizedBox(width: 8),
          ],
          if (widget.prefix != null) ...[
            Text(widget.prefix!, style: affixStyle),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Semantics(
              label: widget.label,
              child: TextField(
                controller: widget.controller,
                focusNode: _focus,
                enabled: widget.enabled,
                keyboardType: widget.keyboardType,
                inputFormatters: widget.inputFormatters,
                autofillHints: widget.autofillHints,
                textInputAction: widget.textInputAction,
                onChanged: widget.onChanged,
                onSubmitted: widget.onSubmitted,
                style: t.fieldInput.copyWith(color: c.ink),
                cursorColor: c.primary,
                decoration: InputDecoration(
                  isCollapsed: true,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  hintText: widget.hint,
                  hintStyle: t.fieldPlaceholder.copyWith(color: c.inkMuted),
                ),
              ),
            ),
          ),
          if (widget.suffix != null) ...[
            const SizedBox(width: 8),
            Text(widget.suffix!, style: affixStyle),
          ],
        ],
      ),
    );
  }
}
