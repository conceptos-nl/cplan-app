import 'package:ivo_service_app/src/model/profile_model/profile_model.dart';
import 'package:ivo_service_app/src/repo/auth_repo/auth_repo.dart';
import 'package:ivo_service_app/src/utils/api/api_config.dart';
import 'package:ivo_service_app/src/utils/session/session_store.dart';

class ProfileRepository {
  // The backend binds the token to the appid it was issued for.
  Future<String> _getAppId() => SessionStore.sessionAppId();

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
    required bool isPushActive,
    required String? pushId,
  }) async {
    try {
      final appId = await _getAppId();

      final data = {
        "id": orgId,
        "appid": appId,
        "token": token,
        // Same os_name / os_version / app_version as the session check:
        // "Android" + "14", not Platform.operatingSystemVersion (on Android
        // that is the Linux kernel string).
        ...await AuthRepository().getDeviceInfo(),
        // Since 1.3.0 `push.id` is an FCM registration token (OneSignal
        // subscription id before that); the backend picks the channel by
        // app_version.
        "push": {"active": isPushActive, "id": pushId ?? ""},
      };
      
      await ApiConfig.dio.patch('settings/', data: data);
      
    } catch (e) {
      return;
    }
  }
}
