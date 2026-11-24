import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mol_bhav/core/permissions/first_run_permissions.dart';
import 'package:mol_bhav/core/permissions/location_permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _MockLocation extends Mock implements LocationPermissionHandler {}

void main() {
  late _MockLocation location;

  setUp(() => location = _MockLocation());

  Future<FirstRunPermissions> build([Map<String, Object> values = const {}]) async {
    SharedPreferences.setMockInitialValues(values);
    return FirstRunPermissions(await SharedPreferences.getInstance(), location);
  }

  test('a fresh install has the step pending', () async {
    expect((await build()).pending, isTrue);
  });

  test('skipping marks it done and tells the router', () async {
    final step = await build();
    var notified = 0;
    step.addListener(() => notified++);

    await step.finish();

    expect(step.pending, isFalse);
    expect(notified, 1);
  });

  test('once done it stays done on the next launch', () async {
    expect(
      (await build({'permissions.first_run_done': true})).pending,
      isFalse,
    );
  });
}
