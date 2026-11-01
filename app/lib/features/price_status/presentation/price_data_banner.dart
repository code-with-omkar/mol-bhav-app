import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/mb_dimens.dart';
import '../../../core/utils/timestamps.dart';
import '../../../shared/widgets/mb_icon.dart';
import 'price_data_status_cubit.dart';

/// A slim strip above the main screens while the price feeds are behind:
/// "Market prices may be delayed" and when they were last updated. The user
/// can close it; it comes back if the situation changes.
class PriceDataBanner extends StatelessWidget {
  const PriceDataBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PriceDataStatusCubit, PriceDataStatusState>(
      builder: (context, state) {
        if (!state.showBanner) return const SizedBox.shrink();

        final c = context.mbColors;
        final l10n = context.l10n;
        final updated = state.status?.lastUpdatedAt;
        return Semantics(
          container: true,
          liveRegion: true,
          child: Material(
            color: c.surfaceAmber,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: MbSpacing.s4,
                  vertical: MbSpacing.s2,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: MbIcon(MbIcons.info, size: 18, color: c.ink),
                    ),
                    const SizedBox(width: MbSpacing.s3),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.priceDataDelayed,
                            style: context.mbText.body.copyWith(color: c.ink),
                          ),
                          if (updated != null)
                            Text(
                              context.updatedAt(updated),
                              style: context.mbText.caption.copyWith(
                                color: c.inkMuted,
                              ),
                            ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: l10n.priceDataDismiss,
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints.tightFor(
                        width: 32,
                        height: 32,
                      ),
                      onPressed: context.read<PriceDataStatusCubit>().dismiss,
                      icon: MbIcon(MbIcons.close, size: 18, color: c.ink),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
