import 'package:equatable/equatable.dart';

class NotificationPrefs extends Equatable {
  const NotificationPrefs({
    required this.pushEnabled,
    required this.alertPushEnabled,
    required this.priceUpdatePushEnabled,
    required this.whatsAppEnabled,
    required this.alertWhatsAppEnabled,
  });

  const NotificationPrefs.defaults()
    : pushEnabled = true,
      alertPushEnabled = true,
      priceUpdatePushEnabled = false,
      whatsAppEnabled = false,
      alertWhatsAppEnabled = false;

  final bool pushEnabled;
  final bool alertPushEnabled;
  final bool priceUpdatePushEnabled;
  final bool whatsAppEnabled;
  final bool alertWhatsAppEnabled;

  NotificationPrefs copyWith({
    bool? pushEnabled,
    bool? alertPushEnabled,
    bool? priceUpdatePushEnabled,
    bool? whatsAppEnabled,
    bool? alertWhatsAppEnabled,
  }) => NotificationPrefs(
    pushEnabled: pushEnabled ?? this.pushEnabled,
    alertPushEnabled: alertPushEnabled ?? this.alertPushEnabled,
    priceUpdatePushEnabled:
        priceUpdatePushEnabled ?? this.priceUpdatePushEnabled,
    whatsAppEnabled: whatsAppEnabled ?? this.whatsAppEnabled,
    alertWhatsAppEnabled: alertWhatsAppEnabled ?? this.alertWhatsAppEnabled,
  );

  @override
  List<Object?> get props => [
    pushEnabled,
    alertPushEnabled,
    priceUpdatePushEnabled,
    whatsAppEnabled,
    alertWhatsAppEnabled,
  ];
}

abstract interface class NotificationPrefsRepository {
  Future<NotificationPrefs> getPreferences();

  Future<NotificationPrefs> updatePreferences(NotificationPrefs prefs);
}
