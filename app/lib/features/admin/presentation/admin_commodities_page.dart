import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/mb_dimens.dart';
import '../../../core/utils/statuses.dart';
import '../../../shared/widgets/mb_app_bar.dart';
import '../../../shared/widgets/mb_button.dart';
import '../../../shared/widgets/mb_layout.dart';
import '../../../shared/widgets/mb_multi_select_field.dart';
import '../../../shared/widgets/mb_select_field.dart';
import '../../../shared/widgets/mb_state_views.dart';
import '../domain/admin_commodities.dart';
import 'admin_commodities_cubit.dart';

/// Add commodities from the price feed to the catalog as products: pick the
/// sub-category and unit they belong to, pick the commodities, and each becomes
/// a product that prices can land on at the next pull. The list comes from the
/// last full pull.
class AdminCommoditiesPage extends StatelessWidget {
  const AdminCommoditiesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cubit = context.read<AdminCommoditiesCubit>();
    return Scaffold(
      appBar: MbAppBar(title: l10n.adminCommoditiesTitle),
      body: BlocConsumer<AdminCommoditiesCubit, AdminCommoditiesState>(
        listenWhen: (a, b) => b.importFailure != null,
        listener: (context, state) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(failureMessage(context, state.importFailure!)),
            ),
          );
          cubit.failureShown();
        },
        builder: (context, state) {
          final setup = state.setup.data;
          if (setup == null) {
            return state.setup.status == LoadStatus.failure
                ? MbErrorView(
                    failure: state.setup.failure!,
                    onRetry: cubit.load,
                  )
                : const MbLoadingView();
          }
          return setup.options.commodities.isEmpty
              ? const _NoFeedList()
              : _Form(setup: setup, state: state);
        },
      ),
    );
  }
}

/// No full pull has recorded the feed's commodities yet.
class _NoFeedList extends StatelessWidget {
  const _NoFeedList();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.mbColors;
    return ListView(
      padding: MbSpacing.screenPadding,
      children: [
        Text(
          l10n.adminCommoditiesNoFeed,
          style: context.mbText.body.copyWith(color: c.inkMuted),
        ),
        const SizedBox(height: MbSpacing.s4),
        MbButton(
          label: l10n.adminMarketsOpenSchedules,
          variant: MbButtonVariant.secondary,
          onPressed: () => context.go(AppRoutes.adminAppSchedules),
        ),
      ],
    );
  }
}

class _Form extends StatefulWidget {
  const _Form({required this.setup, required this.state});

  final CommoditiesSetup setup;
  final AdminCommoditiesState state;

  @override
  State<_Form> createState() => _FormState();
}

class _FormState extends State<_Form> {
  String? _subCategoryId;
  String? _unitId;
  Set<String> _commodities = {};

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.mbColors;
    final t = context.mbText;
    final importing = widget.state.importing;
    final targets = widget.setup.targets;
    final all = widget.setup.options.commodities;
    final chosen = [
      for (final m in all)
        if (_commodities.contains(m)) m,
    ];
    final ready =
        _subCategoryId != null && _unitId != null && chosen.isNotEmpty;

    return BlocListener<AdminCommoditiesCubit, AdminCommoditiesState>(
      // A finished import starts the next one from a clean list.
      listenWhen: (a, b) => b.result != null && a.result != b.result,
      listener: (context, _) => setState(() => _commodities = {}),
      child: ListView(
        padding: MbSpacing.screenPadding,
        children: [
          Text(
            l10n.adminCommoditiesIntro,
            style: t.body.copyWith(color: c.inkMuted),
          ),
          const SizedBox(height: MbSpacing.s4),
          MbSelectField<String>(
            label: l10n.adminCommoditiesSubCategory,
            hint: l10n.adminCommoditiesChooseSubCategory,
            items: [
              for (final s in targets.subCategories)
                MbSelectItem(value: s.id, label: s.label),
            ],
            value: _subCategoryId,
            onChanged: importing
                ? null
                : (v) => setState(() => _subCategoryId = v),
          ),
          const SizedBox(height: MbSpacing.s3),
          MbSelectField<String>(
            label: l10n.adminCommoditiesUnit,
            hint: l10n.adminCommoditiesChooseUnit,
            items: [
              for (final u in targets.units)
                MbSelectItem(value: u.id, label: u.label),
            ],
            value: _unitId,
            onChanged: importing ? null : (v) => setState(() => _unitId = v),
          ),
          const SizedBox(height: MbSpacing.s3),
          MbMultiSelectField(
            label: l10n.adminCommoditiesCommodities,
            emptyLabel: l10n.adminCommoditiesChoose,
            options: all,
            selected: _commodities,
            enabled: !importing,
            onChanged: (v) => setState(() => _commodities = v),
          ),
          const SizedBox(height: MbSpacing.s5),
          MbButton(
            label: l10n.adminCommoditiesAdd(chosen.length),
            block: true,
            isLoading: importing,
            onPressed: !ready || importing
                ? null
                : () => context.read<AdminCommoditiesCubit>().importCommodities(
                    subCategoryId: _subCategoryId!,
                    unitId: _unitId!,
                    commodities: chosen,
                  ),
          ),
          if (widget.state.result case final result?) ...[
            const SizedBox(height: MbSpacing.s4),
            _ResultCard(result: result),
          ],
        ],
      ),
    );
  }
}

/// What the last import did: how many were added and, grouped by reason, the
/// ones that were not.
class _ResultCard extends StatelessWidget {
  const _ResultCard({required this.result});

  final ImportCommoditiesResult result;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.mbColors;
    final t = context.mbText;
    final byReason = <FeedCommoditySkipReason, List<String>>{};
    for (final s in result.skipped) {
      byReason.putIfAbsent(s.reason, () => []).add(s.commodity);
    }
    return MbCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.adminCommoditiesAdded(result.created),
            style: t.title.copyWith(color: c.ink),
          ),
          if (result.created > 0) ...[
            const SizedBox(height: MbSpacing.s1),
            Text(
              l10n.adminCommoditiesAddedHint,
              style: t.caption.copyWith(color: c.inkMuted),
            ),
          ],
          if (byReason.isNotEmpty) ...[
            const SizedBox(height: MbSpacing.s3),
            Text(
              l10n.adminMarketsNotAdded,
              style: t.title.copyWith(color: c.ink),
            ),
            for (final entry in byReason.entries) ...[
              const SizedBox(height: MbSpacing.s2),
              Text(
                _reason(l10n, entry.key),
                style: t.caption.copyWith(color: c.inkMuted),
              ),
              Text(
                entry.value.join(', '),
                style: t.body.copyWith(color: c.ink),
              ),
            ],
          ],
        ],
      ),
    );
  }

  static String _reason(
    AppLocalizations l10n,
    FeedCommoditySkipReason reason,
  ) => switch (reason) {
    FeedCommoditySkipReason.notInFeed => l10n.adminCommoditiesSkipNotInFeed,
    FeedCommoditySkipReason.alreadyInCatalog =>
      l10n.adminMarketsSkipAlreadyInCatalog,
    FeedCommoditySkipReason.codeInvalid => l10n.adminMarketsSkipCodeInvalid,
    FeedCommoditySkipReason.nameInvalid => l10n.adminMarketsSkipNameInvalid,
  };
}
