import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:ivo_service_app/src/model/auth_model/auth_model.dart';
import 'package:ivo_service_app/src/utils/api/api_config.dart';
import 'package:ivo_service_app/src/utils/session/session_store.dart';
import 'package:package_info_plus/package_info_plus.dart';

class AuthRepository {
  /// OS and app details sent along with the session check.
  Future<Map<String, String>> getDeviceInfo() async {
    final deviceInfo = DeviceInfoPlugin();
    final packageInfo = await PackageInfo.fromPlatform();

    String osName = 'unknown';
    String osVersion = 'unknown';

    if (Platform.isAndroid) {
      final androidInfo = await deviceInfo.androidInfo;
      osName = 'Android';
      osVersion = androidInfo.version.release;
    } else if (Platform.isIOS) {
      final iosInfo = await deviceInfo.iosInfo;
      osName = 'iOS';
      osVersion = iosInfo.systemVersion;
    }

    return {
      "os_name": osName,
      "os_version": osVersion,
      "app_version": packageInfo.version,
    };
  }

  Future<Organization?> fetchOrganization(String code) async {
    try {
      final response = await ApiConfig.dio.post(
        'organization/',
        data: {"id": code},
      );

      final data = response.data;

      if (data['status'] == 'ok' && data['data'] != null) {
        return Organization.fromJson(data['data']);
      }
    } catch (e) {
      rethrow;
    }

    return null;
  }

  /// [appId] must be stored with the session on success; see
  /// [SessionStore.saveSession].
  Future<LoginResponse> login(
    String orgId,
    String userId,
    String accessCode, {
    required String appId,
  }) async {
    try {
      final data = {
        "id": orgId,
        "appid": appId,
        "userid": userId,
        "code": accessCode,
      };
      final response = await ApiConfig.dio.post('login/', data: data);
      return LoginResponse.fromJson(response.data);
    } catch (e) {
      return LoginResponse(success: false, message: e.toString());
    }
  }

  Future<bool> logout(String orgId, String token) async {
    try {
      final data = {
        "id": orgId,
        "appid": await SessionStore.sessionAppId(),
        "token": token,
      };

      final response = await ApiConfig.dio.post('logout/', data: data);

      return response.data['success'] == true ||
          response.data['status'] == 'ok';
    } catch (e) {
      return false;
    }
  }
}
