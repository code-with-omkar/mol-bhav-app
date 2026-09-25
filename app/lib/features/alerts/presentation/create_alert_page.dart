import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/locale/app_language.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/mb_dimens.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/statuses.dart';
import '../../../shared/widgets/category_visuals.dart';
import '../../../shared/widgets/mb_app_bar.dart';
import '../../../shared/widgets/mb_button.dart';
import '../../../shared/widgets/mb_chip_group.dart';
import '../../../shared/widgets/mb_icons.dart';
import '../../../shared/widgets/mb_layout.dart';
import '../../../shared/widgets/mb_panels.dart';
import '../../../shared/widgets/mb_price.dart';
import '../../../shared/widgets/mb_select_field.dart';
import '../../../shared/widgets/mb_state_views.dart';
import '../../../shared/widgets/mb_text_field.dart';
import '../domain/alerts.dart';
import 'alerts_cubits.dart';

/// Threshold alert rule: product, market, condition, value, channels.
class CreateAlertPage extends StatelessWidget {
  const CreateAlertPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cubit = context.read<CreateAlertCubit>();
    return BlocConsumer<CreateAlertCubit, CreateAlertState>(
      listenWhen: (p, n) => p.submitStatus != n.submitStatus,
      listener: (context, state) {
        if (state.submitStatus == SubmitStatus.success) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(l10n.alertSaved)));
          context.pop();
        } else if (state.submitStatus == SubmitStatus.failure) {
          showFailureSnackBar(context, state.submitFailure!);
        }
      },
      builder: (context, state) {
        final options = state.options;
        return Scaffold(
          appBar: MbAppBar(title: l10n.createAlertTitle),
          body: switch (options.status) {
            LoadStatus.failure => MbErrorView(
              failure: options.failure!,
              onRetry: cubit.load,
            ),
            LoadStatus.ready => _Form(state: state, options: options.data!),
            _ => const MbLoadingView(),
          },
          bottomNavigationBar: options.status == LoadStatus.ready
              ? MbFooter(
                  child: MbButton(
                    label: l10n.saveAlert,
                    size: MbButtonSize.lg,
                    block: true,
                    isLoading: state.submitStatus == SubmitStatus.submitting,
                    onPressed: state.canSubmit ? cubit.submit : null,
                  ),
                )
              : null,
        );
      },
    );
  }
}

class _Form extends StatelessWidget {
  const _Form({required this.state, required this.options});

  final CreateAlertState state;
  final AlertOptions options;

  @override
  Widget build(BuildContext context) {
    final c = context.mbColors;
    final t = context.mbText;
    final l10n = context.l10n;
    final cubit = context.read<CreateAlertCubit>();
    final product = state.product;
    final percent = state.condition == PriceCondition.percent;
    final current = state.currentPrice;
    final language = AppLanguage.fromCode(options.whatsappLanguage);
    const gap = SizedBox(height: MbSpacing.s4);

    return ListView(
      padding: MbSpacing.screenPadding,
      children: [
        MbSelectField<String>(
          label: l10n.productLabel,
          icon: product == null
              ? MbIcons.others
              : categoryIcon(product.categoryCode),
          value: state.productId,
          onChanged: cubit.selectProduct,
          items: [
            for (final p in options.products)
              MbSelectItem(value: p.id, label: p.name),
          ],
        ),
        gap,
        MbSelectField<String>(
          label: l10n.marketLabel,
          icon: MbIcons.market,
          value: state.marketId,
          onChanged: cubit.selectMarket,
          items: [
            for (final m in options.markets)
              MbSelectItem(value: m.id, label: m.name),
          ],
        ),
        gap,
        Text(l10n.notifyWhen, style: t.fieldLabel.copyWith(color: c.ink)),
        const SizedBox(height: MbSpacing.s2),
        MbChipGroup<PriceCondition>.single(
          semanticLabel: l10n.notifyWhen,
          value: state.condition,
          onChanged: cubit.selectCondition,
          options: [
            MbChipOption(
              value: PriceCondition.below,
              label: l10n.conditionBelow,
            ),
            MbChipOption(
              value: PriceCondition.above,
              label: l10n.conditionAbove,
            ),
            MbChipOption(
              value: PriceCondition.percent,
              label: l10n.conditionPercent,
            ),
          ],
        ),
        gap,
        MbTextField(
          label: percent ? l10n.changeLabel : l10n.priceLabel,
          prefix: percent ? null : '₹',
          suffix: percent ? '%' : (product == null ? null : '/${product.unit}'),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
          ],
          onChanged: cubit.valueChanged,
          helper: current == null
              ? null
              : l10n.currentPriceIn(
                  current.marketName,
                  '${formatInr(current.price)}/${current.unit}',
                ),
        ),
        gap,
        Text(l10n.sendVia, style: t.fieldLabel.copyWith(color: c.ink)),
        const SizedBox(height: 6),
        MbGroup(
          children: [
            MbListItem(
              icon: MbIcons.alert,
              title: l10n.pushNotification,
              trailing: MbToggle(
                value: state.push,
                onChanged: cubit.togglePush,
                semanticLabel: l10n.pushNotification,
              ),
            ),
            MbListItem(
              icon: MbIcons.message,
              iconTone: MbTone.green,
              title: l10n.whatsapp,
              subtitle: options.whatsappNumber == null
                  ? null
                  : language == null
                  ? options.whatsappNumber
                  : l10n.whatsappTarget(
                      options.whatsappNumber!,
                      language.nativeName,
                    ),
              trailing: MbToggle(
                value: state.whatsapp,
                onChanged: cubit.toggleWhatsapp,
                semanticLabel: l10n.whatsapp,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
