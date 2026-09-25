import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_theme.dart';
import '../../core/theme/mb_dimens.dart';

/// Single-digit OTP boxes backed by one hidden text field, so SMS autofill
/// (`oneTimeCode`), paste and backspace all work natively.
class MbOtpInput extends StatefulWidget {
  const MbOtpInput({
    super.key,
    required this.controller,
    required this.semanticLabel,
    this.length = 6,
    this.hasError = false,
    this.autofocus = true,
    this.onChanged,
  });

  final TextEditingController controller;
  final String semanticLabel;
  final int length;
  final bool hasError;
  final bool autofocus;
  final ValueChanged<String>? onChanged;

  @override
  State<MbOtpInput> createState() => _MbOtpInputState();
}

class _MbOtpInputState extends State<MbOtpInput> {
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _focus.addListener(_rebuild);
    widget.controller.addListener(_rebuild);
  }

  @override
  void didUpdateWidget(MbOtpInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_rebuild);
      widget.controller.addListener(_rebuild);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_rebuild);
    _focus.dispose();
    super.dispose();
  }

  void _rebuild() => setState(() {});

  void _focusField() {
    _focus.requestFocus();
    final text = widget.controller.text;
    widget.controller.selection = TextSelection.collapsed(offset: text.length);
  }

  @override
  Widget build(BuildContext context) {
    final code = widget.controller.text;
    final active = code.length.clamp(0, widget.length - 1);

    return Stack(
      children: [
        Positioned.fill(
          child: Opacity(
            opacity: 0,
            alwaysIncludeSemantics: true,
            child: Semantics(
              label: widget.semanticLabel,
              child: TextField(
                controller: widget.controller,
                focusNode: _focus,
                autofocus: widget.autofocus,
                keyboardType: TextInputType.number,
                autofillHints: const [AutofillHints.oneTimeCode],
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(widget.length),
                ],
                onChanged: widget.onChanged,
                showCursor: false,
                enableInteractiveSelection: false,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  counterText: '',
                ),
              ),
            ),
          ),
        ),
        ExcludeSemantics(
          child: GestureDetector(
            onTap: _focusField,
            behavior: HitTestBehavior.opaque,
            child: Row(
              children: [
                for (var i = 0; i < widget.length; i++) ...[
                  if (i > 0) const SizedBox(width: MbSpacing.s2),
                  _Box(
                    digit: i < code.length ? code[i] : '',
                    active: _focus.hasFocus && i == active,
                    error: widget.hasError,
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _Box extends StatelessWidget {
  const _Box({required this.digit, required this.active, required this.error});

  final String digit;
  final bool active;
  final bool error;

  @override
  Widget build(BuildContext context) {
    final c = context.mbColors;
    final border = error
        ? c.priceUp
        : active
        ? c.primary
        : c.borderStrong;
    return Container(
      width: 48,
      height: 56,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: c.surfaceCard,
        borderRadius: BorderRadius.circular(MbRadius.sm),
        border: Border.all(color: border),
        boxShadow: active && !error
            ? [BoxShadow(color: c.primary, spreadRadius: 1)]
            : null,
      ),
      child: Text(digit, style: context.mbText.otpDigit.copyWith(color: c.ink)),
    );
  }
}
