import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mol_bhav/core/notifications/notification_service.dart';
import 'package:mol_bhav/features/notifications/domain/notification_prefs.dart';
import 'package:mol_bhav/features/notifications/presentation/notification_prefs_cubit.dart';

class _MockRepo extends Mock implements NotificationPrefsRepository {}

class _MockNotifications extends Mock implements NotificationService {}

void main() {
  const defaults = NotificationPrefs.defaults();
  final whatsApp = defaults.copyWith(
    whatsAppEnabled: true,
    alertWhatsAppEnabled: true,
  );

  late _MockRepo repo;
  late _MockNotifications notifications;

  setUpAll(() => registerFallbackValue(defaults));

  setUp(() {
    repo = _MockRepo();
    notifications = _MockNotifications();
    when(() => repo.getPreferences()).thenAnswer((_) async => defaults);
    when(() => notifications.initialize()).thenAnswer((_) async {});
  });

  test('a change still waiting is saved when the screen closes', () async {
    when(
      () => repo.updatePreferences(any()),
    ).thenAnswer((i) async => i.positionalArguments.first as NotificationPrefs);
    final cubit = NotificationPrefsCubit(repo, notifications);
    await cubit.load();

    cubit.update(whatsApp);
    await cubit.close(); // before the 600 ms pause ends

    verify(() => repo.updatePreferences(whatsApp)).called(1);
  });

  test('a failed save goes back to the saved values and says so', () async {
    when(() => repo.updatePreferences(any())).thenAnswer((_) async => null);
    final cubit = NotificationPrefsCubit(repo, notifications);
    await cubit.load();

    cubit.update(whatsApp);
    await Future<void>.delayed(const Duration(milliseconds: 700));

    expect(
      cubit.state,
      const NotificationPrefsLoaded(defaults, saveFailed: true),
    );
    await cubit.close();
  });

  test('turning push on asks for notification permission', () async {
    when(() => repo.getPreferences())
        .thenAnswer((_) async => defaults.copyWith(pushEnabled: false));
    when(
      () => repo.updatePreferences(any()),
    ).thenAnswer((i) async => i.positionalArguments.first as NotificationPrefs);
    final cubit = NotificationPrefsCubit(repo, notifications);
    await cubit.load();

    cubit.update(defaults);

    verify(() => notifications.initialize()).called(1);
    await cubit.close();
  });
}
