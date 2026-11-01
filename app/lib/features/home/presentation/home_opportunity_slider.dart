import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/mb_dimens.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/timestamps.dart';
import '../../../shared/widgets/category_visuals.dart';
import '../../../shared/widgets/mb_cards.dart';
import '../domain/home_entities.dart';

/// Top opportunities on Home, one card at a time: swipe left/right (or tap a
/// dot) to move between them. The height follows the card on screen, so a
/// short card never leaves a gap and a long one is never clipped.
class HomeOpportunitySlider extends StatefulWidget {
  const HomeOpportunitySlider({super.key, required this.items});

  final List<TopOpportunity> items;

  @override
  State<HomeOpportunitySlider> createState() => _HomeOpportunitySliderState();
}

class _HomeOpportunitySliderState extends State<HomeOpportunitySlider> {
  static const _duration = Duration(milliseconds: 280);

  int _index = 0;

  /// +1 when moving to the next card, -1 for the previous one; sets which
  /// side the new card slides in from.
  int _direction = 1;

  @override
  void didUpdateWidget(HomeOpportunitySlider oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_index >= widget.items.length) {
      _index = widget.items.isEmpty ? 0 : widget.items.length - 1;
    }
  }

  void _go(int index) {
    if (index < 0 || index >= widget.items.length || index == _index) return;
    setState(() {
      _direction = index > _index ? 1 : -1;
      _index = index;
    });
  }

  void _onSwipe(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0;
    if (velocity.abs() < 150) return;
    // Right-to-left reads as "next" in left-to-right languages.
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final next = (velocity < 0) != rtl;
    _go(next ? _index + 1 : _index - 1);
  }

  @override
  Widget build(BuildContext context) {
    final items = widget.items;
    if (items.isEmpty) return const SizedBox.shrink();
    final item = items[_index];
    final many = items.length > 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GestureDetector(
          onHorizontalDragEnd: many ? _onSwipe : null,
          behavior: HitTestBehavior.translucent,
          child: AnimatedSize(
            duration: _duration,
            curve: Curves.easeOut,
            alignment: Alignment.topCenter,
            child: AnimatedSwitcher(
              duration: _duration,
              switchInCurve: Curves.easeOut,
              switchOutCurve: Curves.easeIn,
              layoutBuilder: (current, previous) => Stack(
                alignment: Alignment.topCenter,
                children: [...previous, ?current],
              ),
              transitionBuilder: (child, animation) {
                final incoming = child.key == ValueKey(_index);
                final dx = (incoming ? 1.0 : -1.0) * _direction * 0.25;
                return FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween(
                      begin: Offset(dx, 0),
                      end: Offset.zero,
                    ).animate(animation),
                    child: child,
                  ),
                );
              },
              child: KeyedSubtree(
                key: ValueKey(_index),
                child: _OpportunityCard(item: item),
              ),
            ),
          ),
        ),
        if (many) ...[
          const SizedBox(height: MbSpacing.s2),
          _Dots(count: items.length, index: _index, onTap: _go),
        ],
      ],
    );
  }
}

class _OpportunityCard extends StatelessWidget {
  const _OpportunityCard({required this.item});

  final TopOpportunity item;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final top = item;
    return MbOpportunityCard(
      product: top.product,
      meta: top.referenceMarketName != null && top.savingsPercent != null
          ? l10n.opportunityMeta(
              formatPercent(top.savingsPercent!),
              top.referenceMarketName!,
            )
          : top.priceSource,
      time: context.timestamp(top.updatedAt),
      price: formatInr(top.price),
      unit: top.unit,
      change: top.change,
      percent: top.percent,
      trend: top.trend.length > 1 ? top.trend : null,
      insight: top.bestMarketName == null
          ? null
          : l10n.bestPriceIn(top.bestMarketName!),
      thumb: categoryIcon(top.categoryCode),
      tone: categoryTint(top.categoryCode),
      actionLabel: top.opportunityId != null
          ? l10n.viewDetails
          : l10n.compareMarkets,
      onAction: () => top.opportunityId != null
          ? context.push(AppRoutes.opportunity(top.opportunityId!))
          : context.go(AppRoutes.marketsFor(commodityId: top.commodityId)),
    );
  }
}

/// Page dots; each is a 24px tap target around a small dot.
class _Dots extends StatelessWidget {
  const _Dots({required this.count, required this.index, required this.onTap});

  final int count;
  final int index;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.mbColors;
    final l10n = context.l10n;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < count; i++)
          Semantics(
            button: true,
            selected: i == index,
            label: l10n.homeOpportunityPosition(i + 1, count),
            child: InkResponse(
              onTap: () => onTap(i),
              radius: 14,
              child: SizedBox(
                width: 24,
                height: 24,
                child: Center(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: i == index ? 18 : 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: i == index ? c.primary : c.border,
                      borderRadius: BorderRadius.circular(MbRadius.pill),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
