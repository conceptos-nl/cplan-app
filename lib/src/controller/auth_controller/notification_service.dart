import 'package:get/get.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:ivo_service_app/src/routes/app_routes.dart';
import 'package:ivo_service_app/src/controller/profile_controller/profile_controller.dart';

class NotificationService extends GetxService {
  String? _pendingMessageId;

  Future<NotificationService> init() async {
    OneSignal.Debug.setLogLevel(OSLogLevel.verbose);
    OneSignal.initialize("025a1b58-3714-4f1d-8ad1-efa02bd42605");
    OneSignal.Notifications.requestPermission(true);

    _setupGlobalClickListeners();
    return this;
  }

  void _setupGlobalClickListeners() {
    OneSignal.Notifications.addClickListener((event) {
      final additionalData = event.notification.additionalData;
      if (additionalData != null) {
        final String? messageId = additionalData['id']?.toString();
        if (additionalData['type'] == 'message' && messageId != null) {
          _pendingMessageId = messageId;

          if (Get.isRegistered<ProfileController>()) {
            final controller = Get.find<ProfileController>();
            if (controller.profile.value != null && !controller.isLoading.value) {
              processPendingNotification();
            }
          }
        }
      }
    });
  }

  void processPendingNotification() {
    if (_pendingMessageId != null) {
      final messageId = _pendingMessageId!;
      _pendingMessageId = null;

      Get.toNamed('${AppRoutes.messageDetail}/$messageId');
      
      if (Get.isRegistered<ProfileController>()) {
        Get.find<ProfileController>().markMessageAsRead(messageId);
      }
    }
  }
}