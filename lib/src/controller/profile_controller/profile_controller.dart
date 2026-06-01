import 'package:app_badge_plus/app_badge_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';
import 'package:ivo_service_app/src/controller/auth_controller/notification_service.dart';
import 'package:ivo_service_app/src/controller/base_controller/base_controller.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:ivo_service_app/src/model/auth_model/auth_model.dart';
import 'package:ivo_service_app/src/model/profile_model/profile_model.dart';
import 'package:ivo_service_app/src/repo/auth_repo/auth_repo.dart';
import 'package:ivo_service_app/src/repo/profile_repo/profile_repo.dart';
import 'package:ivo_service_app/src/routes/app_routes.dart';
import 'package:shared_preferences/shared_preferences.dart';


class ProfileController extends BaseController with WidgetsBindingObserver {
  final ProfileRepository _repo = ProfileRepository();
  final AuthRepository _authRepo = AuthRepository();

  final Rx<ProfileModel?> profile = Rx<ProfileModel?>(null);
  final Rx<Organization?> organization = Rx<Organization?>(null);

  final RxString errorMessage = ''.obs;
  final RxBool isNotificationEnabled = false.obs;
  bool hasShownNotificationPrompt = false;
  DateTime? _lastFetchTime;

  final Set<String> _openingMessages = {};

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);
    fetchUserProfile();
    syncDeviceData();

    OneSignal.Notifications.addPermissionObserver((permission) {
      syncDeviceData();
    });
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    super.onClose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkAndRefresh();

      Future.delayed(const Duration(milliseconds: 300), () {
        final currentPermission = OneSignal.Notifications.permission;
        if (currentPermission != isNotificationEnabled.value) {
          syncDeviceData();
        }
      });
    }
  }

  void _checkAndRefresh() {
    if (_lastFetchTime == null) return;
    final now = DateTime.now();
    final difference = now.difference(_lastFetchTime!);
    if (difference.inSeconds >= 60) {
      fetchUserProfile(showLoading: false);
    }
  }

  Future<void> markMessageAsRead(String messageId) async {
    if (_openingMessages.contains(messageId)) return;
    _openingMessages.add(messageId);

    try {
      final currentMessage = profile.value?.messages.firstWhereOrNull(
        (m) => m.id == messageId,
      );

      if (currentMessage != null && currentMessage.readStatus == "1") {
        return;
      }

      final prefs = await SharedPreferences.getInstance();
      const secureStorage = FlutterSecureStorage();
      final token = await secureStorage.read(key: 'auth_token');
      final orgId = prefs.getString('org_id');

      if (token != null && orgId != null) {
        final success = await _repo.updateStatus(
          orgId: orgId,
          token: token,
          messageId: messageId,
          read: true,
        );

        if (success) {
          await fetchUserProfile(showLoading: false);
        }
      }
    } catch (e) {
      debugPrint("Error marking message as read: $e");
    } finally {
      _openingMessages.remove(messageId);
    }
  }

  Future<void> fetchUserProfile({bool showLoading = true}) async {
    try {
      if (showLoading && profile.value == null) {
        isLoading.value = true;
      }
      errorMessage.value = '';

      final prefs = await SharedPreferences.getInstance();
      const secureStorage = FlutterSecureStorage();
      final token = await secureStorage.read(key: 'auth_token');
      final orgId = prefs.getString('org_id');

      if (token == null || orgId == null) {
        _handleSessionExpiry("Apparaat niet meer actief, log opnieuw in.");
        return;
      }

      final results = await Future.wait([
        _repo.fetchProfile(orgId: orgId, token: token),
        _authRepo.fetchOrganization(orgId),
      ]);

      final profileResult = results[0] as ProfileModel?;
      final orgResult = results[1] as Organization?;

      if (profileResult != null) {
        profile.value = profileResult;
        final unreadCount = profileResult.messages
            .where((m) => m.readStatus == "0")
            .length;
        _updateSystemBadge(unreadCount);

        if (Get.isRegistered<NotificationService>()) {
          Get.find<NotificationService>().processPendingNotification();
        }
      }

      if (orgResult != null) {
        organization.value = orgResult;
      }

      _lastFetchTime = DateTime.now();
    } catch (e) {
      if (showLoading) {
        errorMessage.value = "Kan profiel niet laden. Controleer uw netwerkverbinding.";
      }
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _handleSessionExpiry(String reason) async {
    final prefs = await SharedPreferences.getInstance();
    const secureStorage = FlutterSecureStorage();
    await prefs.clear();
    await secureStorage.delete(key: 'auth_token');
    Get.delete<ProfileController>(force: true);
    Get.offAllNamed(AppRoutes.organizationCode);
    Get.snackbar("Sessie beëindigd", reason);
  }

  Future<void> refreshProfile() async {
    await fetchUserProfile(showLoading: false);
  }

  Future<void> logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      const secureStorage = FlutterSecureStorage();
      final token = await secureStorage.read(key: 'auth_token');
      final orgId = prefs.getString('org_id');
      if (token != null && orgId != null) {
        await _authRepo.logout(orgId, token);
      }
    } catch (e) {
      // Ignored
    } finally {
      await _handleSessionExpiry("Succesvol uitgelogd");
    }
  }

  Future<void> syncDeviceData() async {
    final bool isPushActive = OneSignal.Notifications.permission;
    isNotificationEnabled.value = isPushActive;

    final prefs = await SharedPreferences.getInstance();
    const secureStorage = FlutterSecureStorage();

    final token = await secureStorage.read(key: 'auth_token');
    final orgId = prefs.getString('org_id');

    if (token != null && orgId != null) {
      await _repo.updateDeviceToken(
        orgId: orgId, 
        token: token, 
        isPushActive: isPushActive,
      );
    }
  }

  void _updateSystemBadge(int count) async {
    try {
      if (await AppBadgePlus.isSupported()) {
        AppBadgePlus.updateBadge(count);
      }
    } catch (e) {
      debugPrint("Badge Sync Error: $e");
    }
  }
}
