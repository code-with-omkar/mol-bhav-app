import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'app_notice_cubit.dart';
import 'notice_strip.dart';

/// The admin's message above the main screens (a note or a warning). The user
/// can close it; a changed message shows again.
class AppNoticeBanner extends StatelessWidget {
  const AppNoticeBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppNoticeCubit, AppNoticeState>(
      builder: (context, state) {
        if (!state.showBanner) return const SizedBox.shrink();
        return NoticeStrip(
          severity: state.notice.severity,
          message: state.notice.message,
          onDismiss: context.read<AppNoticeCubit>().dismiss,
          safeTop: true,
        );
      },
    );
  }
}
