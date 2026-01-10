import 'package:dio/dio.dart';
import 'package:get/get.dart';
import 'package:ivo_service_app/src/routes/app_routes.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiConfig {
  static const String _baseUrl = 'https://api.cplan.nl/v1/app/';

  static final Dio dio =
      Dio(
          BaseOptions(
            baseUrl: _baseUrl,
            connectTimeout: const Duration(seconds: 10),
            receiveTimeout: const Duration(seconds: 10),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              'X-API-KEY': 'e0a5ecfd-0fbd-43ae-8a23-b24d9921d314',
            },
          ),
        )
        ..interceptors.add(
          InterceptorsWrapper(
            onError: (error, handler) async {
              if (error.response?.statusCode == 401 ||
                  error.response?.statusCode == 403) {
                if (!error.requestOptions.path.contains('login/')) {
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.clear();
                  Get.offAllNamed(AppRoutes.organizationCode);
                }
              }
              handler.next(error);
            },
          ),
        );
}
