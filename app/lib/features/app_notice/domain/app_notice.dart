import 'package:equatable/equatable.dart';

import '../../../core/error/result.dart';

enum NoticeSeverity {
  info('Info'),
  warning('Warning'),
  maintenance('Maintenance');

  const NoticeSeverity(this.wire);

  /// The name the API uses.
  final String wire;

  /// Unknown values read as [info], the mildest.
  static NoticeSeverity fromWire(String value) =>
      NoticeSeverity.values.firstWhere(
        (s) => s.wire.toLowerCase() == value.toLowerCase(),
        orElse: () => info,
      );
}

/// The one message an admin can show every user (`GET /app-notice`).
class AppNotice extends Equatable {
  const AppNotice({
    required this.isActive,
    required this.severity,
    required this.message,
  });

  /// Nothing to show.
  const AppNotice.off()
    : isActive = false,
      severity = NoticeSeverity.info,
      message = '';

  final bool isActive;
  final NoticeSeverity severity;
  final String message;

  /// Shown, with text. An empty message is never worth a banner.
  bool get isVisible => isActive && message.trim().isNotEmpty;

  /// The app is replaced by a "back soon" page.
  bool get blocksApp => isVisible && severity == NoticeSeverity.maintenance;

  @override
  List<Object?> get props => [isActive, severity, message];
}

abstract interface class AppNoticeRepository {
  /// What users should see: [AppNotice.off] (no text) when it is switched off.
  Future<Result<AppNotice>> get();

  /// Admin: the notice as saved, including the text of one switched off.
  Future<Result<AppNotice>> getForEditing();

  /// Admin: turns the notice on or off, or changes it.
  Future<Result<void>> save(AppNotice notice);
}
