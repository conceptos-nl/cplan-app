import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Single owner of everything that makes up a logged-in session.
///
/// Two rules keep users from being logged out by accident:
///  * A failed storage read throws; only a genuinely missing token is `null`.
///    Callers must never treat a read error as "logged out".
///  * Every authenticated request sends the `appid` the session was created
///    with. The backend binds the token to that appid and answers 403 when it
///    changes.
class SessionStore {
  SessionStore._();

  static const _tokenKey = 'auth_token';
  static const _orgKey = 'org_id';
  static const _userKey = 'user_id';
  static const _sessionAppIdKey = 'session_app_id';

  static const FlutterSecureStorage _secure = FlutterSecureStorage();
  static const MethodChannel _deviceChannel = MethodChannel(
    'com.conceptos.cplan/device',
  );

  /// Returns the auth token, or `null` when there is none.
  ///
  /// Up to 1.0.x the token lived in SharedPreferences. 1.1.0 moved it to
  /// secure storage without migrating it, which logged out every upgrading
  /// user. Any token still sitting in SharedPreferences is moved over here.
  static Future<String?> readToken() async {
    final prefs = await SharedPreferences.getInstance();
    final legacyToken = prefs.getString(_tokenKey);
    final token = await _secure.read(key: _tokenKey);

    if (token != null) {
      if (legacyToken != null) await prefs.remove(_tokenKey);
      return token;
    }
    if (legacyToken == null) return null;

    await _secure.write(key: _tokenKey, value: legacyToken);
    await prefs.remove(_tokenKey);
    return legacyToken;
  }

  static Future<String?> readOrgId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_orgKey);
  }

  static Future<String?> readUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userKey);
  }

  /// Remembers the organisation picked on the code screen, before login.
  static Future<void> saveOrgId(String orgId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_orgKey, orgId);
  }

  static Future<void> saveSession({
    required String token,
    required String orgId,
    required String userId,
    required String appId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await _secure.write(key: _tokenKey, value: token);
    await prefs.setString(_orgKey, orgId);
    await prefs.setString(_userKey, userId);
    await prefs.setString(_sessionAppIdKey, appId);
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_orgKey);
    await prefs.remove(_userKey);
    await prefs.remove(_sessionAppIdKey);
    await prefs.remove(_tokenKey);
    await _secure.delete(key: _tokenKey);
  }

  /// The appid to log in with: stable for this device across OS updates.
  ///
  /// Android previously sent `Build.ID` (the firmware build label, e.g.
  /// "UP1A.231005.007"). It changes on every system update and is shared by
  /// every phone on the same firmware, so sessions died after OS updates.
  /// `ANDROID_ID` is per device + signing key and survives OS updates.
  static Future<String> loginAppId() async {
    if (Platform.isAndroid) {
      try {
        final androidId = await _deviceChannel.invokeMethod<String>(
          'getAndroidId',
        );
        if (androidId != null && androidId.isNotEmpty) return androidId;
      } catch (e) {
        debugPrint('ANDROID_ID unavailable, falling back to Build.ID: $e');
      }
    }
    return _legacyAppId();
  }

  /// The appid the current session was created with.
  ///
  /// Sessions created before 1.3.0 have none stored. They were created with
  /// the legacy value, so that value is frozen here. Without this, an Android
  /// OS update would still change it and the backend would reject the session.
  static Future<String> sessionAppId() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_sessionAppIdKey);
    if (stored != null) return stored;

    final legacy = await _legacyAppId();
    // 'unknown_ios_id' means identifierForVendor was briefly unavailable
    // (device locked after reboot). Don't freeze that value.
    if (legacy != _unknownIosId) {
      await prefs.setString(_sessionAppIdKey, legacy);
    }
    return legacy;
  }

  static const _unknownIosId = 'unknown_ios_id';

  /// What 1.0.0 – 1.2.1 sent as `appid`.
  static Future<String> _legacyAppId() async {
    final deviceInfo = DeviceInfoPlugin();
    if (Platform.isAndroid) {
      return (await deviceInfo.androidInfo).id;
    }
    if (Platform.isIOS) {
      return (await deviceInfo.iosInfo).identifierForVendor ?? _unknownIosId;
    }
    return 'unknown';
  }
}
