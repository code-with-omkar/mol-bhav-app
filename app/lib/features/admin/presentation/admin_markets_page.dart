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
import '../domain/admin_ingestion.dart';
import '../domain/admin_markets.dart';
import 'admin_markets_cubit.dart';

/// Add markets from the price feed to the catalog: pick a state, pick its
/// markets, and each becomes a mandi (with its district) that prices can land
/// on at the next pull. The lists come from the last full pull.
class AdminMarketsPage extends StatelessWidget {
  const AdminMarketsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cubit = context.read<AdminMarketsCubit>();
    return Scaffold(
      appBar: MbAppBar(title: l10n.adminMarketsTitle),
      body: BlocConsumer<AdminMarketsCubit, AdminMarketsState>(
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
          return setup.options.isEmpty
              ? const _NoFeedList()
              : _Form(options: setup.options, state: state);
        },
      ),
    );
  }
}

/// No full pull has recorded the feed's markets yet.
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
          l10n.adminMarketsNoFeed,
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
  const _Form({required this.options, required this.state});

  final FilterOptions options;
  final AdminMarketsState state;

  @override
  State<_Form> createState() => _FormState();
}

class _FormState extends State<_Form> {
  String? _stateName;
  Set<String> _markets = {};

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.mbColors;
    final t = context.mbText;
    final importing = widget.state.importing;
    final markets = _stateName == null
        ? const <String>[]
        : widget.options.marketsIn({_stateName!});
    final chosen = [
      for (final m in markets)
        if (_markets.contains(m)) m,
    ];

    return BlocListener<AdminMarketsCubit, AdminMarketsState>(
      // A finished import starts the next one from a clean list.
      listenWhen: (a, b) => b.result != null && a.result != b.result,
      listener: (context, _) => setState(() => _markets = {}),
      child: ListView(
        padding: MbSpacing.screenPadding,
        children: [
          Text(
            l10n.adminMarketsIntro,
            style: t.body.copyWith(color: c.inkMuted),
          ),
          const SizedBox(height: MbSpacing.s4),
          MbSelectField<String>(
            label: l10n.adminMarketsState,
            hint: l10n.adminMarketsChooseState,
            items: [
              for (final s in widget.options.states)
                MbSelectItem(value: s, label: s),
            ],
            value: _stateName,
            onChanged: importing
                ? null
                : (s) => setState(() {
                    _stateName = s;
                    _markets = {};
                  }),
          ),
          const SizedBox(height: MbSpacing.s3),
          MbMultiSelectField(
            label: l10n.adminMarketsMarkets,
            emptyLabel: l10n.adminMarketsChoose,
            options: markets,
            selected: _markets,
            enabled: _stateName != null && !importing,
            onChanged: (v) => setState(() => _markets = v),
          ),
          const SizedBox(height: MbSpacing.s5),
          MbButton(
            label: l10n.adminMarketsAdd(chosen.length),
            block: true,
            isLoading: importing,
            onPressed: chosen.isEmpty || importing
                ? null
                : () => context.read<AdminMarketsCubit>().importMarkets(
                    _stateName!,
                    chosen,
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

  final ImportMarketsResult result;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.mbColors;
    final t = context.mbText;
    final byReason = <FeedMarketSkipReason, List<String>>{};
    for (final s in result.skipped) {
      byReason.putIfAbsent(s.reason, () => []).add(s.market);
    }
    return MbCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.adminMarketsAdded(result.created),
            style: t.title.copyWith(color: c.ink),
          ),
          if (result.created > 0) ...[
            const SizedBox(height: MbSpacing.s1),
            Text(
              l10n.adminMarketsAddedHint,
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

  static String _reason(AppLocalizations l10n, FeedMarketSkipReason reason) =>
      switch (reason) {
        FeedMarketSkipReason.notInFeed => l10n.adminMarketsSkipNotInFeed,
        FeedMarketSkipReason.alreadyInCatalog =>
          l10n.adminMarketsSkipAlreadyInCatalog,
        FeedMarketSkipReason.codeInvalid => l10n.adminMarketsSkipCodeInvalid,
        FeedMarketSkipReason.districtUnknown =>
          l10n.adminMarketsSkipDistrictUnknown,
        FeedMarketSkipReason.nameInvalid => l10n.adminMarketsSkipNameInvalid,
      };
}
