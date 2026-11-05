import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ivo_service_app/src/utils/api/api_config.dart';
import 'package:ivo_service_app/src/utils/session/session_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SessionStore.readToken', () {
    test('moves a 1.0.x token from SharedPreferences into secure storage',
        () async {
      SharedPreferences.setMockInitialValues({
        'auth_token': 'legacy-token',
        'org_id': '00000',
      });
      FlutterSecureStorage.setMockInitialValues({});

      expect(await SessionStore.readToken(), 'legacy-token');

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('auth_token'), isNull);
      expect(
        await const FlutterSecureStorage().read(key: 'auth_token'),
        'legacy-token',
      );
      expect(await SessionStore.readToken(), 'legacy-token');
    });

    test('prefers the secure token and drops a stale legacy copy', () async {
      SharedPreferences.setMockInitialValues({'auth_token': 'stale'});
      FlutterSecureStorage.setMockInitialValues({'auth_token': 'current'});

      expect(await SessionStore.readToken(), 'current');
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('auth_token'), isNull);
    });

    test('returns null when there is no session', () async {
      SharedPreferences.setMockInitialValues({});
      FlutterSecureStorage.setMockInitialValues({});

      expect(await SessionStore.readToken(), isNull);
    });
  });

  group('SessionStore session lifecycle', () {
    test('saveSession stores the login appid; clear removes everything',
        () async {
      SharedPreferences.setMockInitialValues({});
      FlutterSecureStorage.setMockInitialValues({});

      await SessionStore.saveSession(
        token: 't',
        orgId: '00000',
        userId: '1',
        appId: 'android-id-123',
      );
      expect(await SessionStore.sessionAppId(), 'android-id-123');
      expect(await SessionStore.readOrgId(), '00000');
      expect(await SessionStore.readUserId(), '1');

      await SessionStore.clear();
      expect(await SessionStore.readToken(), isNull);
      expect(await SessionStore.readOrgId(), isNull);
      expect(await SessionStore.readUserId(), isNull);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('session_app_id'), isNull);
    });
  });

  group('ApiConfig.isSessionRejected', () {
    DioException errorWith(int status, dynamic body) {
      final options = RequestOptions(path: 'data/');
      return DioException(
        requestOptions: options,
        response: Response(
          requestOptions: options,
          statusCode: status,
          data: body,
        ),
      );
    }

    test('backend 403 JSON (dead session) logs out', () {
      expect(
        ApiConfig.isSessionRejected(errorWith(403, {
          'success': false,
          'message': 'Apparaat niet meer actief, log opnieuw in.',
        })),
        isTrue,
      );
    });

    test('401 wrong API key does not log out', () {
      expect(
        ApiConfig.isSessionRejected(errorWith(401, {
          'status': 'failed',
          'message': 'Incorrect authorization key found',
        })),
        isFalse,
      );
    });

    test('non-JSON 403 (web server / firewall page) does not log out', () {
      expect(
        ApiConfig.isSessionRejected(
          errorWith(403, '<html><body>Forbidden</body></html>'),
        ),
        isFalse,
      );
    });

    test('no response (offline / timeout) does not log out', () {
      expect(
        ApiConfig.isSessionRejected(
          DioException(requestOptions: RequestOptions(path: 'data/')),
        ),
        isFalse,
      );
    });
  });
}
