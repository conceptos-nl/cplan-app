import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:get/get.dart';
import 'package:ivo_service_app/src/model/auth_model/auth_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LinkService extends GetxService {
  final _appLinks = AppLinks();
  StreamSubscription<Uri>? _linkSubscription;

  final Rx<MagicLinkData?> pendingMagicLink = Rx<MagicLinkData?>(null);

  Future<LinkService> init() async {
    final initialUri = await _appLinks.getInitialLink();
    if (initialUri != null) {
      await _handleUri(initialUri);
    }
    _linkSubscription = _appLinks.uriLinkStream.listen((uri) {
      _handleUri(uri);
    });

    return this;
  }

  Future<void> _handleUri(Uri uri) async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getString('auth_token') != null) {
      return;
    }
    final org = uri.queryParameters['org'];
    final user = uri.queryParameters['user'];
    final code = uri.queryParameters['code'];

    if (org != null && user != null && code != null) {
      pendingMagicLink.value = MagicLinkData(org: org, user: user, code: code);
    }
  }

  @override
  void onClose() {
    _linkSubscription?.cancel();
    super.onClose();
  }
}
