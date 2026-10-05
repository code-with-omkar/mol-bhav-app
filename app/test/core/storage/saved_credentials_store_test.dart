import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mol_bhav/core/storage/saved_credentials_store.dart';

class _MockStorage extends Mock implements FlutterSecureStorage {}

void main() {
  late _MockStorage storage;
  final values = <String, String>{};

  setUp(() {
    storage = _MockStorage();
    values.clear();
    when(() => storage.read(key: any(named: 'key')))
        .thenAnswer((i) async => values[i.namedArguments[#key] as String]);
    when(
      () => storage.write(
        key: any(named: 'key'),
        value: any(named: 'value'),
      ),
    ).thenAnswer((i) async {
      values[i.namedArguments[#key] as String] =
          i.namedArguments[#value] as String;
    });
    when(() => storage.delete(key: any(named: 'key'))).thenAnswer((i) async {
      values.remove(i.namedArguments[#key] as String);
    });
  });

  SavedCredentialsStore store({bool supported = true}) =>
      SavedCredentialsStore.withSupport(storage, isSupported: supported);

  const login = SavedCredentials(
    mobileDigits: '9876543210',
    password: 'kanda2026',
  );

  test('is on by default and returns what was saved', () async {
    final s = store();
    expect(await s.readEnabled(), isTrue);

    await s.save(login);
    final read = await s.read();

    expect(read?.mobileDigits, '9876543210');
    expect(read?.password, 'kanda2026');
  });

  test('switching off forgets the saved login and stops saving', () async {
    final s = store();
    await s.save(login);

    await s.setEnabled(false);
    await s.save(login);

    expect(await s.readEnabled(), isFalse);
    expect(await s.read(), isNull);
    expect(values.keys, ['auth.save_password']);
  });

  test('does nothing where unsupported (web)', () async {
    final s = store(supported: false);

    await s.save(login);

    expect(await s.readEnabled(), isFalse);
    expect(await s.read(), isNull);
    expect(values, isEmpty);
  });
}
