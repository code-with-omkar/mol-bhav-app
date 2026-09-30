import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/l10n/l10n.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/mb_dimens.dart';
import '../../../../shared/widgets/mb_button.dart';
import '../../../../shared/widgets/mb_icon.dart';
import '../../../../shared/widgets/mb_layout.dart';

class PaymentSuccessPage extends StatefulWidget {
  const PaymentSuccessPage({super.key});

  @override
  State<PaymentSuccessPage> createState() => _PaymentSuccessPageState();
}

class _PaymentSuccessPageState extends State<PaymentSuccessPage> {
  double _scale = 0.4;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _scale = 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = context.mbColors;
    final l10n = context.l10n;
    return Scaffold(
      body: SafeArea(
        child: MbCenteredForm(
          children: [
            AnimatedScale(
              scale: _scale,
              duration: const Duration(milliseconds: 450),
              curve: Curves.elasticOut,
              child: Container(
                width: 88,
                height: 88,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: c.surfaceGreen,
                  shape: BoxShape.circle,
                ),
                child: MbIcon(MbIcons.check, size: 44, color: c.primaryText),
              ),
            ),
            const SizedBox(height: MbSpacing.s5),
            Text(
              l10n.paymentSuccess,
              textAlign: TextAlign.center,
              style: context.mbText.h1.copyWith(color: c.ink),
            ),
            const SizedBox(height: MbSpacing.s2),
            Text(
              l10n.paymentSuccessMessage,
              textAlign: TextAlign.center,
              style: context.mbText.body.copyWith(color: c.inkMuted),
            ),
            const SizedBox(height: MbSpacing.s6),
            MbButton(
              label: l10n.exploreProFeatures,
              block: true,
              onPressed: () => context.go(AppRoutes.home),
            ),
          ],
        ),
      ),
    );
  }
}
