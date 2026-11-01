import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/di/injection.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/session/admin_mode.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/mb_dimens.dart';
import '../../../core/utils/statuses.dart';
import '../../../core/utils/timestamps.dart';
import '../../../shared/widgets/mb_app_bar.dart';
import '../../../shared/widgets/mb_icons.dart';
import '../../../shared/widgets/mb_layout.dart';
import '../../../shared/widgets/mb_price.dart';
import '../../../shared/widgets/mb_state_views.dart';
import '../../../shared/widgets/mb_text_field.dart';
import '../domain/admin_users.dart';
import 'admin_users_cubit.dart';

/// Admin user list: search by phone or name, filter by standing, scroll for
/// more. Tap a user for their details.
class AdminUsersPage extends StatefulWidget {
  const AdminUsersPage({super.key});

  @override
  State<AdminUsersPage> createState() => _AdminUsersPageState();
}

class _AdminUsersPageState extends State<AdminUsersPage> {
  /// Wait for a pause in typing before searching.
  static const _debounce = Duration(milliseconds: 400);

  final _scroll = ScrollController();
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() {
      if (_scroll.position.extentAfter < 300) {
        context.read<AdminUsersCubit>().loadMore();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _scroll.dispose();
    super.dispose();
  }

  void _onSearch(String text) {
    _timer?.cancel();
    _timer = Timer(_debounce, () {
      if (mounted) context.read<AdminUsersCubit>().search(text);
    });
  }

  Future<void> _open(AdminUser user) async {
    final cubit = context.read<AdminUsersCubit>();
    final changed = await context.push<bool>(AppRoutes.adminUser(user.id));
    if (changed ?? false) await cubit.load();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cubit = context.read<AdminUsersCubit>();
    return Scaffold(
      appBar: MbAppBar(
        title: l10n.adminUsersTitle,
        showBack: false,
        actions: [
          MbAppBarAction(
            icon: MbIcons.user,
            label: l10n.adminSwitchToUserView,
            onPressed: () => getIt<AdminMode>().switchToUserView(),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              MbSpacing.s4,
              MbSpacing.s3,
              MbSpacing.s4,
              MbSpacing.s2,
            ),
            child: MbTextField(
              hint: l10n.adminUsersSearchHint,
              icon: MbIcons.search,
              textInputAction: TextInputAction.search,
              onChanged: _onSearch,
              onSubmitted: cubit.search,
            ),
          ),
          BlocBuilder<AdminUsersCubit, AdminUsersState>(
            buildWhen: (a, b) => a.filter != b.filter,
            builder: (context, state) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: MbSpacing.s4),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Wrap(
                  spacing: MbSpacing.s2,
                  children: [
                    for (final f in UserListFilter.values)
                      ChoiceChip(
                        label: Text(switch (f) {
                          UserListFilter.all => l10n.filterAll,
                          UserListFilter.active => l10n.adminUserActive,
                          UserListFilter.suspended => l10n.adminUsersSuspended,
                        }),
                        selected: state.filter == f,
                        onSelected: (_) => cubit.setFilter(f),
                      ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: BlocBuilder<AdminUsersCubit, AdminUsersState>(
              builder: (context, state) {
                if (state.users.isEmpty) {
                  return switch (state.status) {
                    LoadStatus.failure => MbErrorView(
                      failure: state.failure!,
                      onRetry: cubit.load,
                    ),
                    LoadStatus.ready => MbEmptyView(
                      message: l10n.adminUsersEmpty,
                    ),
                    _ => const MbLoadingView(),
                  };
                }
                return RefreshIndicator(
                  onRefresh: cubit.load,
                  child: ListView.separated(
                    controller: _scroll,
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: MbSpacing.screenPadding,
                    itemCount: state.users.length + (state.loadingMore ? 1 : 0),
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: MbSpacing.s2),
                    itemBuilder: (context, i) => i >= state.users.length
                        ? const Padding(
                            padding: EdgeInsets.all(MbSpacing.s3),
                            child: Center(child: CircularProgressIndicator()),
                          )
                        : _UserRow(
                            user: state.users[i],
                            onTap: () => _open(state.users[i]),
                          ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _UserRow extends StatelessWidget {
  const _UserRow({required this.user, required this.onTap});

  final AdminUser user;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.mbColors;
    final t = context.mbText;
    final last = user.lastLoginAt;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(MbRadius.md),
      child: MbCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    user.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: t.title.copyWith(color: c.ink),
                  ),
                ),
                Wrap(
                  spacing: MbSpacing.s1,
                  children: [
                    if (user.isSuspended)
                      MbBadge(
                        label: l10n.adminUsersSuspended,
                        tone: MbBadgeTone.opportunity,
                      ),
                    if (user.isAdmin)
                      MbBadge(
                        label: l10n.adminUserAdminBadge,
                        tone: MbBadgeTone.neutral,
                      ),
                    if (user.isPro)
                      MbBadge(label: l10n.adminUsersPro, tone: MbBadgeTone.pro),
                  ],
                ),
              ],
            ),
            if (user.displayName != null && user.displayName!.trim().isNotEmpty)
              Text(
                user.phoneNumber,
                style: t.caption.copyWith(color: c.inkMuted),
              ),
            Text(
              [
                ?user.place,
                '${l10n.adminUserLastLogin}: '
                    '${last == null ? l10n.adminUserNever : context.timestamp(last)}',
              ].join(' · '),
              style: t.caption.copyWith(color: c.inkMuted),
            ),
          ],
        ),
      ),
    );
  }
}
