import 'package:dio/dio.dart';
import 'package:ivo_service_app/src/utils/session/session_expiry.dart';

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
              // login/ failures are handled by the caller; logout/ always
              // ends the session itself.
              final path = error.requestOptions.path;
              if (!path.contains('login/') &&
                  !path.contains('logout/') &&
                  isSessionRejected(error)) {
                await SessionExpiry.expire(reason: _backendMessage(error));
              }
              handler.next(error);
            },
          ),
        );

  /// True only when the backend itself rejected the token/appid pair:
  /// 403 {"success":false,"message":"Apparaat niet meer actief, log opnieuw in."}
  ///
  /// The backend answers 401 for a wrong X-API-KEY, which says nothing about
  /// the user's session. A 403 that isn't the backend's JSON (e.g. an
  /// Apache/ModSecurity HTML error page) says nothing about it either.
  /// Neither may log the user out.
  static bool isSessionRejected(DioException error) {
    return error.response?.statusCode == 403 && error.response?.data is Map;
  }

  static String? _backendMessage(DioException error) {
    final data = error.response?.data;
    return data is Map ? data['message']?.toString() : null;
  }
}
