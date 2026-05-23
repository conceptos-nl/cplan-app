import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:ivo_service_app/src/controller/auth_controller/link_service.dart';
import 'package:ivo_service_app/src/controller/profile_controller/profile_controller.dart';
import 'package:ivo_service_app/src/model/auth_model/auth_model.dart';
import 'package:ivo_service_app/src/repo/auth_repo/auth_repo.dart';
import 'package:ivo_service_app/src/routes/app_routes.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ivo_service_app/src/utils/api/api_config.dart';

class SplashController extends GetxController {
  final AuthRepository _repo = AuthRepository();
  final LinkService _linkService = Get.find<LinkService>();

  @override
  void onReady() {
    super.onReady();
    
    ever(_linkService.pendingMagicLink, _handleMagicLinkRouting);

    if (_linkService.pendingMagicLink.value == null) {
      _decideNextScreen();
    }
  }

  Future<void> _handleMagicLinkRouting(MagicLinkData? data) async {
    if (data == null || !data.isValid) return;

    final prefs = await SharedPreferences.getInstance();
    const secureStorage = FlutterSecureStorage();
    final currentToken = await secureStorage.read(key: 'auth_token');
    final currentOrg = prefs.getString('org_id');
    final currentUser = prefs.getString('user_id');

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

      await prefs.clear();
      await secureStorage.delete(key: 'auth_token');
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
      final response = await _repo.login(org, user, code);
      
      if (response.success && response.token != null) {
        final prefs = await SharedPreferences.getInstance();
        const secureStorage = FlutterSecureStorage();
        await secureStorage.write(key: 'auth_token', value: response.token!);
        await prefs.setString('user_id', user);
        await prefs.setString('org_id', org);

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

  Future<bool> _checkSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      const secureStorage = FlutterSecureStorage();
      final token = await secureStorage.read(key: 'auth_token');
      final orgId = prefs.getString('org_id');

      if (token == null || orgId == null) return false;

      final deviceData = await _repo.getDeviceInfo();
      final data = {"id": orgId, "token": token, ...deviceData};

      final response = await ApiConfig.dio.post('login/', data: data);
      return _isSuccess(response.data);
    } catch (e) {
      if (e is DioException && 
         (e.response?.statusCode == 401 || e.response?.statusCode == 403)) {
        return false;
      }
      const secureStorage = FlutterSecureStorage();
      return await secureStorage.read(key: 'auth_token') != null;
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