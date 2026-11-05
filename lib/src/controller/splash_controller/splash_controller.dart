import 'package:dio/dio.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:ivo_service_app/src/controller/auth_controller/link_service.dart';
import 'package:ivo_service_app/src/controller/profile_controller/profile_controller.dart';
import 'package:ivo_service_app/src/model/auth_model/auth_model.dart';
import 'package:ivo_service_app/src/repo/auth_repo/auth_repo.dart';
import 'package:ivo_service_app/src/routes/app_routes.dart';
import 'package:ivo_service_app/src/utils/api/api_config.dart';
import 'package:ivo_service_app/src/utils/session/session_store.dart';

class SplashController extends GetxController {
  final AuthRepository _repo = AuthRepository();
  final LinkService _linkService = Get.find<LinkService>();

  @override
  void onReady() {
    super.onReady();

    ever(_linkService.pendingMagicLink, _handleMagicLinkRouting);

    // ever() only reports changes. A link that opened the app is already set
    // by now, so handle it here; otherwise the splash never moves on.
    final pendingLink = _linkService.pendingMagicLink.value;
    if (pendingLink == null) {
      _decideNextScreen();
    } else {
      _handleMagicLinkRouting(pendingLink);
    }
  }

  Future<void> _handleMagicLinkRouting(MagicLinkData? data) async {
    if (data == null || !data.isValid) return;

    String? currentToken;
    try {
      currentToken = await SessionStore.readToken();
    } catch (e) {
      debugPrint("Could not read current session, continuing with link: $e");
    }
    final currentOrg = await SessionStore.readOrgId();
    final currentUser = await SessionStore.readUserId();

    if (currentToken != null && (currentOrg != data.org || currentUser != data.user)) {
      final bool? confirmSwitch = await Get.dialog<bool>(
        AlertDialog(
          title: const Text('Account wisselen?'),
          content: const Text('U bent momenteel ingelogd met een ander account. Wilt u uitloggen en wisselen?'),
          actions: [
            TextButton(
              onPressed: () => Get.back(result: false),
              child: const Text('Annuleren'),
            ),
            TextButton(
              onPressed: () => Get.back(result: true),
              child: const Text('Wisselen', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      );

      if (confirmSwitch != true) {
        _linkService.consumeLink();
        _decideNextScreen();
        return;
      }

      try {
        await _repo.logout(currentOrg!, currentToken);
      } catch (e) {
        debugPrint("Old token backend invalidation failed, forcing local wipe anyway: $e");
      }

      await SessionStore.clear();
      Get.delete<ProfileController>(force: true);
    }

    final orgCode = data.org;
    final userId = data.user;
    final accessCode = data.code;

    _linkService.consumeLink();
    _executeMagicLinkLogin(orgCode, userId, accessCode);
  }

  Future<void> _executeMagicLinkLogin(String org, String user, String code) async {
    try {
      final appId = await SessionStore.loginAppId();
      final response = await _repo.login(org, user, code, appId: appId);

      if (response.success && response.token != null) {
        await SessionStore.saveSession(
          token: response.token!,
          orgId: org,
          userId: user,
          appId: appId,
        );

        Get.put(ProfileController(), permanent: true);
        Get.offAllNamed(AppRoutes.home);
      } else {
        Get.snackbar("Inloggen mislukt", "De link is ongeldig of verlopen.");
        _decideNextScreen();
      }
    } catch (e) {
      Get.snackbar("Fout", "Er is iets misgegaan tijdens het inloggen via de link.");
      _decideNextScreen();
    }
  }

  Future<void> _decideNextScreen() async {
    final results = await Future.wait([
      _checkSession(),
      Future.delayed(const Duration(seconds: 2)),
    ]);

    final bool isLoggedIn = results[0] as bool;

    if (isLoggedIn) {
      Get.put(ProfileController(), permanent: true);
      Get.offAllNamed(AppRoutes.home);
    } else {
      Get.offAllNamed(AppRoutes.organizationCode);
    }
  }

  /// Only says "logged out" when there is no session or the backend rejected
  /// it. Anything else (unreadable storage, no network, server trouble)
  /// keeps the user logged in.
  Future<bool> _checkSession() async {
    final String? token;
    final String? orgId;
    try {
      token = await SessionStore.readToken();
      orgId = await SessionStore.readOrgId();
    } catch (e) {
      // e.g. the iOS keychain while the device is locked during a background
      // launch. The token is still there; the home screen retries on resume.
      debugPrint("Session storage unreadable, keeping session: $e");
      try {
        return await SessionStore.readOrgId() != null;
      } catch (_) {
        return false;
      }
    }

    if (token == null || orgId == null) return false;

    try {
      final data = {
        "id": orgId,
        "token": token,
        "appid": await SessionStore.sessionAppId(),
        ...await _repo.getDeviceInfo(),
      };

      final response = await ApiConfig.dio.post('login/', data: data);
      return _isSuccess(response.data);
    } on DioException catch (e) {
      return !ApiConfig.isSessionRejected(e);
    } catch (e) {
      return true;
    }
  }

  bool _isSuccess(dynamic data) {
    if (data is! Map) return false;
    if (data['success'] == true) return true;
    if (data['success'].toString().toLowerCase() == 'true') return true;
    if (data['status']?.toString().toLowerCase() == 'ok') return true;
    return false;
  }
}
