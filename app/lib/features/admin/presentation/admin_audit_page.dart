import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/mb_dimens.dart';
import '../../../core/utils/statuses.dart';
import '../../../core/utils/timestamps.dart';
import '../../../shared/widgets/mb_app_bar.dart';
import '../../../shared/widgets/mb_layout.dart';
import '../../../shared/widgets/mb_price.dart';
import '../../../shared/widgets/mb_state_views.dart';
import '../domain/admin_audit.dart';
import 'admin_audit_cubit.dart';

/// What admins changed, newest first: what was done, by whom and when. Read
/// only; entries cannot be edited or removed.
class AdminAuditPage extends StatefulWidget {
  const AdminAuditPage({super.key});

  @override
  State<AdminAuditPage> createState() => _AdminAuditPageState();
}

class _AdminAuditPageState extends State<AdminAuditPage> {
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() {
      if (_scroll.position.extentAfter < 300) {
        context.read<AdminAuditCubit>().loadMore();
      }
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cubit = context.read<AdminAuditCubit>();
    return Scaffold(
      appBar: MbAppBar(title: l10n.adminAuditTitle),
      body: BlocBuilder<AdminAuditCubit, AdminAuditState>(
        builder: (context, state) {
          if (state.entries.isEmpty) {
            return switch (state.status) {
              LoadStatus.failure => MbErrorView(
                failure: state.failure!,
                onRetry: cubit.load,
              ),
              LoadStatus.ready => MbEmptyView(message: l10n.adminAuditEmpty),
              _ => const MbLoadingView(),
            };
          }
          return RefreshIndicator(
            onRefresh: cubit.load,
            child: ListView.separated(
              controller: _scroll,
              physics: const AlwaysScrollableScrollPhysics(),
              padding: MbSpacing.screenPadding,
              itemCount: state.entries.length + (state.loadingMore ? 1 : 0),
              separatorBuilder: (_, _) => const SizedBox(height: MbSpacing.s2),
              itemBuilder: (context, i) => i >= state.entries.length
                  ? const Padding(
                      padding: EdgeInsets.all(MbSpacing.s3),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  : _EntryCard(entry: state.entries[i]),
            ),
          );
        },
      ),
    );
  }
}

class _EntryCard extends StatelessWidget {
  const _EntryCard({required this.entry});

  final AuditEntry entry;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.mbColors;
    final t = context.mbText;
    return MbCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  entry.summary,
                  style: t.title.copyWith(color: c.ink),
                ),
              ),
              const SizedBox(width: MbSpacing.s2),
              MbBadge(label: entry.area, tone: MbBadgeTone.neutral),
            ],
          ),
          const SizedBox(height: MbSpacing.s1),
          Text(
            '${l10n.adminAuditBy(entry.actorName ?? l10n.adminAuditUnknownActor)}'
            ' · ${context.timestamp(entry.occurredAt)}',
            style: t.caption.copyWith(color: c.inkMuted),
          ),
          if (entry.target != null)
            Text(
              entry.target!,
              style: t.caption.copyWith(color: c.inkMuted),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
        ],
      ),
    );
  }
}
