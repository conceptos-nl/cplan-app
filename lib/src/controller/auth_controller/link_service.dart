import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ivo_service_app/src/model/auth_model/auth_model.dart';

class LinkService extends GetxService {
  final _appLinks = AppLinks();
  StreamSubscription<Uri>? _linkSubscription;

  final Rx<MagicLinkData?> pendingMagicLink = Rx<MagicLinkData?>(null);

  Future<LinkService> init() async {
    Uri? initialUri;
    try {
      initialUri = await _appLinks.getInitialLink();
      if (initialUri != null) {
        _parseUri(initialUri);
      }
    } catch (e) {
      debugPrint("Error reading initial link: $e");
    }

    // uriLinkStream re-delivers the initial link. Processing it twice would
    // run two logins with the same code, and the token stored last might not
    // be the one the backend issued last.
    var skipInitialEcho = initialUri != null;
    _linkSubscription = _appLinks.uriLinkStream.listen(
      (uri) {
        final isEcho = skipInitialEcho && uri == initialUri;
        skipInitialEcho = false;
        if (isEcho) return;
        _parseUri(uri);
      },
      onError: (err) {
        debugPrint("Link stream error: $err");
      },
    );

    return this;
  }

  void _parseUri(Uri uri) {
    var org = uri.queryParameters['org'];
    var user = uri.queryParameters['user'];
    var code = uri.queryParameters['code'];

    if (org == null && uri.toString().contains('?')) {
      try {
        final fallbackQuery = Uri.splitQueryString(uri.toString().split('?').last);
        org ??= fallbackQuery['org'];
        user ??= fallbackQuery['user'];
        code ??= fallbackQuery['code'];
      } catch (e) {
        debugPrint("Link fallback parsing failed: $e");
      }
    }

    if (org == null || user == null || code == null) return;
    pendingMagicLink.value = MagicLinkData(org: org, user: user, code: code);
  }

  void consumeLink() {
    pendingMagicLink.value = null;
  }

  @override
  void onClose() {
    _linkSubscription?.cancel();
    super.onClose();
  }
}