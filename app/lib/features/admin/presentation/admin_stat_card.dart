import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/mb_dimens.dart';
import '../../../shared/widgets/mb_layout.dart';

enum AdminTrend { up, down, flat }

/// How a figure moved against an earlier period, e.g. `+12.5%`.
class AdminChange {
  const AdminChange(this.text, this.trend);

  final String text;
  final AdminTrend trend;
}

/// One headline figure: a value over its label, with an optional change.
class AdminStat {
  const AdminStat(this.label, this.value, {this.change});

  final String label;
  final String value;
  final AdminChange? change;
}

/// A [change] as a small coloured line (more is good for ads: green up, red
/// down, muted when flat).
class AdminChangeText extends StatelessWidget {
  const AdminChangeText(this.change, {super.key});

  final AdminChange change;

  @override
  Widget build(BuildContext context) {
    final c = context.mbColors;
    final color = switch (change.trend) {
      AdminTrend.up => c.primaryText,
      AdminTrend.down => c.priceUp,
      AdminTrend.flat => c.inkMuted,
    };
    final arrow = switch (change.trend) {
      AdminTrend.up => '▲ ',
      AdminTrend.down => '▼ ',
      AdminTrend.flat => '',
    };
    return Text(
      '$arrow${change.text}',
      style: context.mbText.caption.copyWith(color: color),
    );
  }
}

/// A titled card with a two-column grid of [AdminStat]s, an optional badge
/// beside the title and an optional footnote.
class AdminStatCard extends StatelessWidget {
  const AdminStatCard({
    super.key,
    required this.title,
    required this.stats,
    this.badge,
    this.note,
  });

  final String title;
  final List<AdminStat> stats;
  final Widget? badge;
  final String? note;

  @override
  Widget build(BuildContext context) {
    final c = context.mbColors;
    final t = context.mbText;
    return MbCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(title, style: t.title.copyWith(color: c.ink)),
              ),
              ?badge,
            ],
          ),
          const SizedBox(height: MbSpacing.s3),
          Wrap(
            runSpacing: MbSpacing.s3,
            children: [
              for (final s in stats)
                FractionallySizedBox(
                  widthFactor: 0.5,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(s.value, style: t.h2.copyWith(color: c.ink)),
                      Text(
                        s.label,
                        style: t.caption.copyWith(color: c.inkMuted),
                      ),
                      if (s.change != null) AdminChangeText(s.change!),
                    ],
                  ),
                ),
            ],
          ),
          if (note != null) ...[
            const SizedBox(height: MbSpacing.s3),
            Text(note!, style: t.caption.copyWith(color: c.inkMuted)),
          ],
        ],
      ),
    );
  }
}
