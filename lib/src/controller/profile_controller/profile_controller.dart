import 'package:app_badge_plus/app_badge_plus.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ivo_service_app/src/controller/auth_controller/notification_service.dart';
import 'package:ivo_service_app/src/controller/base_controller/base_controller.dart';
import 'package:ivo_service_app/src/model/auth_model/auth_model.dart';
import 'package:ivo_service_app/src/model/profile_model/profile_model.dart';
import 'package:ivo_service_app/src/repo/auth_repo/auth_repo.dart';
import 'package:ivo_service_app/src/repo/profile_repo/profile_repo.dart';
import 'package:ivo_service_app/src/utils/session/session_expiry.dart';
import 'package:ivo_service_app/src/utils/session/session_store.dart';


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

  /// Message ids whose reload has finished. The detail screen only says
  /// "not found" for these; before that it shows a spinner.
  final RxSet<String> settledMessageLookups = <String>{}.obs;
  final Set<String> _messageLookupsInFlight = {};

  NotificationService? get _notifications =>
      Get.isRegistered<NotificationService>()
          ? Get.find<NotificationService>()
          : null;

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);
    fetchUserProfile();
    syncDeviceData();
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

      // The user may have toggled notifications in the system settings.
      Future.delayed(const Duration(milliseconds: 300), () async {
        final granted = await _notifications?.isPermissionGranted() ?? false;
        if (granted != isNotificationEnabled.value) {
          syncDeviceData();
        }
      });
    }
  }

  void _checkAndRefresh() {
    // The first load failed (offline, or storage unreadable at launch).
    if (profile.value == null && !isLoading.value) {
      fetchUserProfile();
      return;
    }
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

      final token = await SessionStore.readToken();
      final orgId = await SessionStore.readOrgId();

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

  /// A push usually announces a message newer than the loaded profile, so
  /// reload once before the detail screen gives up on it.
  Future<void> loadMessageIfMissing(String messageId) async {
    final isLoaded =
        profile.value?.messages.any((m) => m.id == messageId) ?? false;
    if (isLoaded ||
        settledMessageLookups.contains(messageId) ||
        _messageLookupsInFlight.contains(messageId)) {
      return;
    }

    _messageLookupsInFlight.add(messageId);
    try {
      await fetchUserProfile(showLoading: false);
    } finally {
      _messageLookupsInFlight.remove(messageId);
      settledMessageLookups.add(messageId);
    }
  }

  Future<void> fetchUserProfile({bool showLoading = true}) async {
    try {
      if (showLoading && profile.value == null) {
        isLoading.value = true;
      }
      errorMessage.value = '';

      // A read error throws into the catch below and is shown as an error.
      // Only a token that is really gone ends the session.
      final token = await SessionStore.readToken();
      final orgId = await SessionStore.readOrgId();

      if (token == null || orgId == null) {
        await SessionExpiry.expire(
          reason: "Apparaat niet meer actief, log opnieuw in.",
        );
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

        _notifications?.processPendingNotification();
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

  Future<void> refreshProfile() async {
    await fetchUserProfile(showLoading: false);
  }

  Future<void> logout() async {
    try {
      final token = await SessionStore.readToken();
      final orgId = await SessionStore.readOrgId();
      if (token != null && orgId != null) {
        await _authRepo.logout(orgId, token);
      }
    } catch (e) {
      // Ignored
    } finally {
      await SessionExpiry.expire(reason: "Succesvol uitgelogd");
    }
  }

  Future<void> syncDeviceData() async {
    final notifications = _notifications;
    final bool isPushActive =
        await notifications?.isPermissionGranted() ?? false;
    isNotificationEnabled.value = isPushActive;

    try {
      final token = await SessionStore.readToken();
      final orgId = await SessionStore.readOrgId();
      if (token == null || orgId == null) return;

      await _repo.updateDeviceToken(
        orgId: orgId,
        token: token,
        isPushActive: isPushActive,
        pushId: await notifications?.getPushToken(),
      );
    } catch (e) {
      debugPrint("Device sync failed: $e");
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
