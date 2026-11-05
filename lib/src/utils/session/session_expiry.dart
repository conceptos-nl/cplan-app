import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:ivo_service_app/src/controller/profile_controller/profile_controller.dart';
import 'package:ivo_service_app/src/routes/app_routes.dart';
import 'package:ivo_service_app/src/utils/session/session_store.dart';

class SessionExpiry {
  SessionExpiry._();

  static bool _inProgress = false;

  /// Wipes the local session and returns to the organisation code screen.
  ///
  /// Parallel requests (data/ + organization/) can fail together; only the
  /// first one runs this.
  static Future<void> expire({String? reason}) async {
    if (_inProgress) return;
    _inProgress = true;
    try {
      try {
        await SessionStore.clear();
      } catch (e) {
        debugPrint('Clearing session storage failed: $e');
      }
      Get.delete<ProfileController>(force: true);
      Get.offAllNamed(AppRoutes.organizationCode);
      if (reason != null && reason.isNotEmpty) {
        Get.snackbar("Sessie beëindigd", reason);
      }
    } finally {
      _inProgress = false;
    }
  }
}
