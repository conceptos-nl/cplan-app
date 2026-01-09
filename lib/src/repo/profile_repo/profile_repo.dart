import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:ivo_service_app/src/model/profile_model/profile_model.dart';
import 'package:ivo_service_app/src/utils/api/api_config.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';

class ProfileRepository {
  Future<String> _getAppId() async {
    final deviceInfo = DeviceInfoPlugin();
    if (Platform.isAndroid) {
      final androidInfo = await deviceInfo.androidInfo;
      return androidInfo.id;
    } else if (Platform.isIOS) {
      final iosInfo = await deviceInfo.iosInfo;
      return iosInfo.identifierForVendor ?? 'unknown_ios_id';
    }
    return 'unknown';
  }

  Future<ProfileModel?> fetchProfile({
    required String orgId,
    required String token,
  }) async {
    try {
      final appId = await _getAppId();
      final data = {"id": orgId, "appid": appId, "token": token};
      final response = await ApiConfig.dio.post('data/', data: data);

      if (response.data != null &&
          (response.data['success'] == true ||
              response.data['status'] == 'ok')) {
        return ProfileModel.fromJson(response.data);
      }
    } catch (e) {
      rethrow;
    }
    return null;
  }

  Future<bool> updateStatus({
    required String orgId,
    required String token,
    required String messageId,
    bool? received,
    bool? read,
  }) async {
    try {
      final appId = await _getAppId();
      final Map<String, dynamic> statusData = {
        "type": "message",
        "id": messageId,
      };

      if (received != null) statusData["received"] = received;
      if (read != null) statusData["read"] = read;

      final data = {
        "id": orgId,
        "appid": appId,
        "token": token,
        "status": statusData,
      };

      final response = await ApiConfig.dio.post('status/', data: data);
      return response.data['success'] == true;
    } catch (e) {
      return false;
    }
  }

  Future<void> updateDeviceToken({
    required String orgId,
    required String token,
  }) async {
    try {
      final appId = await _getAppId();
      final packageInfo = await PackageInfo.fromPlatform();
      final fcmToken = await FirebaseMessaging.instance.getToken();
      final status = await Permission.notification.status;
      final bool isPushActive = status.isGranted;
      final data = {
        "id": orgId,
        "appid": appId,
        "token": token,
        "os_name": Platform.isAndroid ? "Android" : "iOS",
        "os_version": Platform.operatingSystemVersion,
        "app_version": packageInfo.version,
        "push": {"active": isPushActive, "id": fcmToken ?? ""},
      };
      await ApiConfig.dio.patch('settings/', data: data);

      // delete after testing:
      // await ApiConfig.dio.post(
      //   'https://webhook.site/8e2ba17c-69d3-45cd-b75d-eba84e96b514',
      //   data: data,
      // );
      // print(data);
    } catch (e) {
      return;
    }
  }
}
