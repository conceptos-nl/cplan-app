import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';
import 'package:ivo_service_app/src/controller/base_controller/base_controller.dart';
import 'package:ivo_service_app/src/controller/profile_controller/profile_controller.dart';
import 'package:ivo_service_app/src/model/auth_model/auth_model.dart';
import 'package:ivo_service_app/src/repo/auth_repo/auth_repo.dart';
import 'package:ivo_service_app/src/routes/app_routes.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthController extends BaseController {
  final AuthRepository _repo = AuthRepository();
  final TextEditingController codeController = TextEditingController();
  final TextEditingController userIdController = TextEditingController();
  final TextEditingController accessCodeController = TextEditingController();

  final Rx<Organization?> organization = Rx<Organization?>(null);

  String? _currentOrgCode;

  Future<void> fetchOrg(String code) async {
    if (code.isEmpty) return;
    try {
      isLoading.value = true;
      final result = await _repo.fetchOrganization(code);
      if (result != null) {
        organization.value = result;
        _currentOrgCode = code;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('org_id', code);
      } else {
        Get.snackbar("Fout", "Organisatie niet gevonden");
      }
    } catch (e) {
      Get.snackbar("Fout", "Organisatie niet gevonden");
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> login(
    String userId,
    String accessCode, {
    String? explicitOrgCode,
  }) async {
    String? codeToUse = explicitOrgCode ?? _currentOrgCode;
    if (codeToUse == null) {
      final prefs = await SharedPreferences.getInstance();
      codeToUse = prefs.getString('org_id');
    }

    if (codeToUse == null) {
      Get.snackbar("Fout", "Organisatie code ontbreekt. Start opnieuw.");
      return false;
    }

    try {
      isLoading.value = true;
      final response = await _repo.login(codeToUse, userId, accessCode);

      if (response.success && response.token != null) {
        final prefs = await SharedPreferences.getInstance();
        const secureStorage = FlutterSecureStorage();
        await secureStorage.write(key: 'auth_token', value: response.token);
        await prefs.setString('user_id', userId);
        await prefs.setString('org_id', codeToUse);

        Get.put(ProfileController(), permanent: true);
        Get.offAllNamed(AppRoutes.home);
        return true;
      } else {
        Get.snackbar("Login Mislukt", "Ongeldige gegevens");
        return false;
      }
    } catch (e) {
      Get.snackbar(
        "Fout",
        "Er is iets misgegaan. Neem contact op met support.",
      );
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  @override
  void onClose() {
    codeController.dispose();
    userIdController.dispose();
    accessCodeController.dispose();
    super.onClose();
  }
}