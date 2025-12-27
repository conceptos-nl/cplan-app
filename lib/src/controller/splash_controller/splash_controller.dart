import 'package:get/get.dart';
import 'package:ivo_service_app/src/controller/profile_controller/profile_controller.dart';
import 'package:ivo_service_app/src/repo/auth_repo/auth_repo.dart';
import 'package:ivo_service_app/src/routes/app_routes.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ivo_service_app/src/utils/api/api_config.dart';

class SplashController extends GetxController {
  final AuthRepository _repo = AuthRepository();

  @override
  void onInit() {
    super.onInit();
    _decideNextScreen();
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
      final token = prefs.getString('auth_token');
      final orgId = prefs.getString('org_id');

      if (token == null || orgId == null) return false;

      final deviceData = await _repo.getDeviceInfo();
      final data = {"id": orgId, "token": token, ...deviceData};

      final response = await ApiConfig.dio.post('login/', data: data);

      return _isSuccess(response.data);
    } catch (e) {
      return false;
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
