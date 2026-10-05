import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:injectable/injectable.dart';

/// Mobile number + password remembered for the login screen ("Save
/// password", on by default).
class SavedCredentials {
  const SavedCredentials({required this.mobileDigits, required this.password});

  /// The 10 national digits.
  final String mobileDigits;
  final String password;
}

/// Keeps the user's login in the platform keystore / keychain so the login
/// screen can prefill it after a log out or an expired session.
///
/// Android and iOS only: on web the storage key lives next to the data in the
/// browser, so the browser's own password manager is used instead (the login
/// screen confirms the autofill context on success). Logging out clears the
/// session, never the saved login; switching "Save password" off deletes it.
@lazySingleton
class SavedCredentialsStore {
  SavedCredentialsStore(this._storage) : isSupported = !kIsWeb;

  @visibleForTesting
  SavedCredentialsStore.withSupport(this._storage, {required this.isSupported});

  final FlutterSecureStorage _storage;

  /// False on web — the toggle is hidden there.
  final bool isSupported;

  static const _enabledKey = 'auth.save_password';
  static const _mobileKey = 'auth.saved_mobile';
  static const _passwordKey = 'auth.saved_password';

  /// The switch position; on unless the user turned it off.
  Future<bool> readEnabled() async {
    if (!isSupported) return false;
    return await _storage.read(key: _enabledKey) != 'false';
  }

  /// The saved login, or null when unsupported, switched off or never saved.
  Future<SavedCredentials?> read() async {
    if (!await readEnabled()) return null;
    final mobile = await _storage.read(key: _mobileKey);
    final password = await _storage.read(key: _passwordKey);
    if (mobile == null ||
        mobile.isEmpty ||
        password == null ||
        password.isEmpty) {
      return null;
    }
    return SavedCredentials(mobileDigits: mobile, password: password);
  }

  /// Turning it off forgets the saved login straight away.
  Future<void> setEnabled(bool enabled) async {
    if (!isSupported) return;
    await _storage.write(key: _enabledKey, value: '$enabled');
    if (!enabled) await forget();
  }

  /// Called after a successful sign-in or sign-up while the switch is on.
  Future<void> save(SavedCredentials credentials) async {
    if (!await readEnabled()) return;
    await _storage.write(key: _mobileKey, value: credentials.mobileDigits);
    await _storage.write(key: _passwordKey, value: credentials.password);
  }

  /// Drops the saved login (switch off, or the saved password was rejected).
  Future<void> forget() async {
    await _storage.delete(key: _mobileKey);
    await _storage.delete(key: _passwordKey);
  }
}
