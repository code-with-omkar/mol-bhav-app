import 'package:flutter_test/flutter_test.dart';
import 'package:mol_bhav/core/network/api_config.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('normalizeServerAddress', () {
    test('a bare host and port gets the scheme and the API path', () {
      expect(
        normalizeServerAddress('192.168.1.14:5189'),
        'http://192.168.1.14:5189/api/v1',
      );
    });

    test('a URL without a path gets the API path', () {
      expect(
        normalizeServerAddress('http://192.168.1.14:5189'),
        'http://192.168.1.14:5189/api/v1',
      );
      expect(
        normalizeServerAddress('https://api.example.com/'),
        'https://api.example.com/api/v1',
      );
    });

    test('a URL that already has a path is kept as typed', () {
      expect(
        normalizeServerAddress('http://192.168.1.14:5189/api/v1/'),
        'http://192.168.1.14:5189/api/v1',
      );
      expect(
        normalizeServerAddress('http://host:5189/custom/v2'),
        'http://host:5189/custom/v2',
      );
    });

    test('surrounding spaces are ignored', () {
      expect(
        normalizeServerAddress('  10.0.0.5:5189  '),
        'http://10.0.0.5:5189/api/v1',
      );
    });

    test('blank text and other schemes are not addresses', () {
      expect(normalizeServerAddress(''), isNull);
      expect(normalizeServerAddress('   '), isNull);
      expect(normalizeServerAddress('ftp://host/api'), isNull);
      expect(normalizeServerAddress('http://'), isNull);
    });
  });

  group('ApiConfig', () {
    late SharedPreferences prefs;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      await ApiConfig.save(prefs, null);
    });

    tearDown(() => ApiConfig.save(prefs, null));

    test('uses the build default until a server is saved', () {
      expect(ApiConfig.baseUrl, ApiConfig.defaultBaseUrl);
      expect(ApiConfig.isOverridden, isFalse);
    });

    test(
      'a saved server replaces the default and survives a restart',
      () async {
        await ApiConfig.save(prefs, 'http://192.168.1.14:5189/api/v1');
        expect(ApiConfig.baseUrl, 'http://192.168.1.14:5189/api/v1');
        expect(ApiConfig.isOverridden, isTrue);

        // A fresh start reads it back from the device.
        await ApiConfig.save(prefs, 'http://192.168.1.14:5189/api/v1');
        ApiConfig.restore(prefs);
        expect(ApiConfig.baseUrl, 'http://192.168.1.14:5189/api/v1');
      },
    );

    test('resetting goes back to the build default', () async {
      await ApiConfig.save(prefs, 'http://192.168.1.14:5189/api/v1');

      await ApiConfig.save(prefs, null);
      ApiConfig.restore(prefs);

      expect(ApiConfig.baseUrl, ApiConfig.defaultBaseUrl);
      expect(ApiConfig.isOverridden, isFalse);
    });
  });
}
