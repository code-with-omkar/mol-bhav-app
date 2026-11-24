import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/mb_dimens.dart';
import '../../../core/utils/statuses.dart';
import '../../../shared/widgets/mb_app_bar.dart';
import '../../../shared/widgets/mb_button.dart';
import '../../../shared/widgets/mb_icon.dart';
import '../../../shared/widgets/mb_layout.dart';
import '../../../shared/widgets/mb_state_views.dart';
import '../../../shared/widgets/mb_text_field.dart';
import '../domain/suppliers.dart';
import 'suppliers_cubit.dart';

/// Regional suppliers and hubs. Search by name; a supplier with a phone has a
/// Call button that opens the phone's dialler.
class SuppliersPage extends StatefulWidget {
  const SuppliersPage({super.key});

  @override
  State<SuppliersPage> createState() => _SuppliersPageState();
}

class _SuppliersPageState extends State<SuppliersPage> {
  final _scroll = ScrollController();
  final _search = TextEditingController();

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() {
      if (_scroll.position.extentAfter < 300) {
        context.read<SuppliersCubit>().loadMore();
      }
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    _search.dispose();
    super.dispose();
  }

  Future<void> _call(BuildContext context, Supplier supplier) async {
    final number = supplier.dialNumber;
    if (number == null) return;
    final message = context.l10n.supplierCallFailed;
    final messenger = ScaffoldMessenger.of(context);
    var opened = false;
    try {
      opened = await launchUrl(Uri(scheme: 'tel', path: number));
    } on Object {
      // No dialler on this device.
    }
    if (!opened) {
      messenger.showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cubit = context.read<SuppliersCubit>();
    return Scaffold(
      appBar: MbAppBar(title: l10n.suppliersTitle),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              MbSpacing.s4,
              MbSpacing.s3,
              MbSpacing.s4,
              0,
            ),
            child: MbTextField(
              controller: _search,
              hint: l10n.suppliersSearchHint,
              textInputAction: TextInputAction.search,
              onSubmitted: (v) => cubit.load(search: v),
            ),
          ),
          Expanded(
            child: BlocBuilder<SuppliersCubit, SuppliersState>(
              builder: (context, state) {
                if (state.suppliers.isEmpty) {
                  return switch (state.status) {
                    LoadStatus.failure => MbErrorView(
                      failure: state.failure!,
                      onRetry: cubit.load,
                    ),
                    LoadStatus.ready => MbEmptyView(
                      message: l10n.suppliersEmpty,
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
                    itemCount:
                        state.suppliers.length + (state.loadingMore ? 1 : 0),
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: MbSpacing.s2),
                    itemBuilder: (context, i) => i >= state.suppliers.length
                        ? const Padding(
                            padding: EdgeInsets.all(MbSpacing.s3),
                            child: Center(child: CircularProgressIndicator()),
                          )
                        : _SupplierCard(
                            supplier: state.suppliers[i],
                            onCall: () => _call(context, state.suppliers[i]),
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

class _SupplierCard extends StatelessWidget {
  const _SupplierCard({required this.supplier, required this.onCall});

  final Supplier supplier;
  final VoidCallback onCall;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.mbColors;
    final t = context.mbText;
    return MbCard(
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(supplier.name, style: t.title.copyWith(color: c.ink)),
                Text(
                  '${supplier.districtName}, ${supplier.stateName}',
                  style: t.caption.copyWith(color: c.inkMuted),
                ),
                if (supplier.contactPhone case final phone?)
                  Text(phone, style: t.caption.copyWith(color: c.inkMuted)),
              ],
            ),
          ),
          if (supplier.dialNumber != null)
            MbButton(
              label: l10n.supplierCall,
              icon: MbIcons.phone,
              onPressed: onCall,
            ),
        ],
      ),
    );
  }
}
