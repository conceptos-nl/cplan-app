import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:ivo_service_app/src/model/auth_model/auth_model.dart';
import 'package:ivo_service_app/src/utils/api/api_config.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthRepository {
  Future<Map<String, String>> getDeviceInfo() async {
    final deviceInfo = DeviceInfoPlugin();
    final packageInfo = await PackageInfo.fromPlatform();

    String appId = 'unknown';
    String osName = 'unknown';
    String osVersion = 'unknown';

    if (Platform.isAndroid) {
      final androidInfo = await deviceInfo.androidInfo;
      osName = 'Android';
      osVersion = androidInfo.version.release;
      appId = androidInfo.id;
    } else if (Platform.isIOS) {
      final iosInfo = await deviceInfo.iosInfo;
      osName = 'iOS';
      osVersion = iosInfo.systemVersion;
      appId = iosInfo.identifierForVendor ?? 'unknown_ios_id';
    }

    return {
      "appid": appId,
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

  Future<LoginResponse> login(
    String orgId,
    String userId,
    String accessCode,
  ) async {
    try {
      final deviceData = await getDeviceInfo();
      final data = {
        "id": orgId,
        "appid": deviceData['appid'],
        "userid": userId,
        "code": accessCode,
      };
      final response = await ApiConfig.dio.post('login/', data: data);
      return LoginResponse.fromJson(response.data);
    } catch (e) {
      return LoginResponse(success: false, message: e.toString());
    }
  }

  Future<bool> checkSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      final orgId = prefs.getString('org_id');
      if (token == null || orgId == null) return false;
      final deviceData = await getDeviceInfo();
      final data = {"id": orgId, "appid": deviceData['appid'], "token": token};
      final response = await ApiConfig.dio.post('login/', data: data);
      return LoginResponse.fromJson(response.data).success;
    } catch (e) {
      return false;
    }
  }

  Future<bool> logout(String orgId, String token) async {
    try {
      final deviceData = await getDeviceInfo();
      final data = {"id": orgId, "appid": deviceData['appid'], "token": token};

      final response = await ApiConfig.dio.post('logout/', data: data);

      return response.data['success'] == true ||
          response.data['status'] == 'ok';
    } catch (e) {
      return false;
    }
  }
}
