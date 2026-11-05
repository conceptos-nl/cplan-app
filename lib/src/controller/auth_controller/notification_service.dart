import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:ivo_service_app/src/routes/app_routes.dart';
import 'package:ivo_service_app/src/controller/profile_controller/profile_controller.dart';

/// Push notifications through Firebase Cloud Messaging (OneSignal until 1.2.1).
///
/// Backend payload contract, in the FCM `data` block:
/// `{"type": "message", "id": "123"}` (id = the message id).
/// iOS rich notifications (sender avatar) additionally read `sender_name` and
/// `sender_logo`, and need `mutable-content: 1` in the APNs payload.
class NotificationService extends GetxService {
  bool _ready = false;
  String? _pendingMessageId;

  Future<NotificationService> init() async {
    // Never throw: main() registers the other services after this one.
    try {
      await Firebase.initializeApp();
      final messaging = FirebaseMessaging.instance;

      // iOS: show banners while the app is open, as OneSignal did.
      await messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      FirebaseMessaging.onMessageOpenedApp.listen(_onNotificationOpened);
      FirebaseMessaging.onMessage.listen(_onForegroundMessage);
      messaging.onTokenRefresh.listen((_) => _syncDevice());

      // Not awaited: with UIScene it can wait for the scene to connect, and
      // that must not hold up runApp().
      messaging.getInitialMessage().then((message) {
        if (message != null) _onNotificationOpened(message);
      });

      _ready = true;
    } catch (e) {
      debugPrint("Push notifications unavailable: $e");
    }
    return this;
  }

  Future<bool> isPermissionGranted() async {
    if (!_ready) return false;
    try {
      final settings = await FirebaseMessaging.instance
          .getNotificationSettings();
      return _isAllowed(settings.authorizationStatus);
    } catch (e) {
      return false;
    }
  }

  /// Shows the system prompt (iOS, Android 13+).
  Future<bool> requestPermission() async {
    if (!_ready) return false;
    try {
      final settings = await FirebaseMessaging.instance.requestPermission();
      return _isAllowed(settings.authorizationStatus);
    } catch (e) {
      return false;
    }
  }

  static bool _isAllowed(AuthorizationStatus status) =>
      status == AuthorizationStatus.authorized ||
      status == AuthorizationStatus.provisional;

  /// The FCM registration token, sent to the backend as `push.id`.
  Future<String?> getPushToken() async {
    if (!_ready) return null;
    try {
      final messaging = FirebaseMessaging.instance;
      if (Platform.isIOS) {
        // getToken() throws until APNs has issued a device token. If it is
        // still missing, onTokenRefresh fires once it arrives and syncs then.
        var apnsToken = await messaging.getAPNSToken();
        for (var i = 0; apnsToken == null && i < 5; i++) {
          await Future.delayed(const Duration(seconds: 1));
          apnsToken = await messaging.getAPNSToken();
        }
        if (apnsToken == null) return null;
      }
      final token = await messaging.getToken();
      // For sending test pushes from the Firebase console. Debug builds only.
      if (kDebugMode) debugPrint("FCM token: $token");
      return token;
    } catch (e) {
      debugPrint("FCM token unavailable: $e");
      return null;
    }
  }

  void _onNotificationOpened(RemoteMessage message) {
    final messageId = _messageIdOf(message);
    if (messageId == null) return;
    _pendingMessageId = messageId;

    if (Get.isRegistered<ProfileController>()) {
      final controller = Get.find<ProfileController>();
      if (controller.profile.value != null && !controller.isLoading.value) {
        processPendingNotification();
      }
    }
  }

  void _onForegroundMessage(RemoteMessage message) {
    if (Get.isRegistered<ProfileController>()) {
      Get.find<ProfileController>().refreshProfile();
    }

    // iOS shows the system banner (presentation options above). Android never
    // displays FCM notifications while the app is in the foreground, so show
    // an in-app banner instead.
    if (!Platform.isAndroid) return;
    final notification = message.notification;
    if (notification == null) return;

    Get.snackbar(
      notification.title ?? '',
      notification.body ?? '',
      snackPosition: SnackPosition.TOP,
      duration: const Duration(seconds: 5),
      onTap: (_) {
        Get.closeCurrentSnackbar();
        _onNotificationOpened(message);
      },
    );
  }

  String? _messageIdOf(RemoteMessage message) {
    if (message.data['type'] != 'message') return null;
    return message.data['id']?.toString();
  }

  void _syncDevice() {
    if (Get.isRegistered<ProfileController>()) {
      Get.find<ProfileController>().syncDeviceData();
    }
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
