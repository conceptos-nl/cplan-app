import 'package:get/get.dart';
import 'package:ivo_service_app/src/controller/auth_controller/link_service.dart';
import 'package:ivo_service_app/src/controller/profile_controller/profile_controller.dart';
import 'package:ivo_service_app/src/model/auth_model/auth_model.dart';
import 'package:ivo_service_app/src/repo/auth_repo/auth_repo.dart';
import 'package:ivo_service_app/src/routes/app_routes.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthController extends GetxController {
  final AuthRepository _repo = AuthRepository();

  var isLoading = false.obs;
  final Rx<Organization?> organization = Rx<Organization?>(null);

  String? _currentOrgCode;

  @override
  void onInit() {
    super.onInit();

    _checkAndHandleMagicLink();

    ever(Get.find<LinkService>().pendingMagicLink, (MagicLinkData? data) {
      if (data != null) {
        _checkAndHandleMagicLink();
      }
    });
  }

  Future<void> _checkAndHandleMagicLink() async {
    final linkService = Get.find<LinkService>();
    final data = linkService.pendingMagicLink.value;

    if (data != null && data.isValid) {
      linkService.pendingMagicLink.value = null;

      await fetchOrg(data.org);
      if (organization.value != null) {
        await login(data.user, data.code);
      }
    }
  }

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

  Future<void> login(
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
      return;
    }

    try {
      isLoading.value = true;
      final response = await _repo.login(codeToUse, userId, accessCode);

      if (response.success && response.token != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', response.token!);
        await prefs.setString('user_id', userId);
        await prefs.setString('org_id', codeToUse);

        Get.put(ProfileController(), permanent: true);
        Get.offAllNamed(AppRoutes.home);
      } else {
        Get.snackbar("Login Mislukt", "Ongeldige gegevens");
      }
    } catch (e) {
      Get.snackbar(
        "Fout",
        "Er is iets misgegaan. Neem contact op met support.",
      );
    } finally {
      isLoading.value = false;
    }
  }
}
