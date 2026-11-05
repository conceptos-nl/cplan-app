import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_linkify/flutter_linkify.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:ivo_service_app/src/components/base/base_view.dart';
import 'package:ivo_service_app/src/controller/profile_controller/profile_controller.dart';
import 'package:ivo_service_app/src/model/profile_model/profile_model.dart';

class MessageDetailPage extends BaseView<ProfileController> {
  const MessageDetailPage({super.key});

  @override
  ProfileController get controller => Get.find<ProfileController>();

  Future<void> _onOpenLink(LinkableElement link) async {
    final Uri url = Uri.parse(link.url);
    try {
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        Get.snackbar("Fout", "Kon de link niet openen: ${link.url}");
      }
    } catch (e) {
      Get.snackbar("Fout", "Er is iets misgegaan bij het openen van de link");
    }
  }

  String _formatDate(String dateString) {
    if (dateString.isEmpty) return "";
    try {
      final datePart = dateString.split(' ').first;
      final parts = datePart.split('-');
      if (parts.length == 3) {
        return "${parts[2]}-${parts[1]}-${parts[0]}";
      }
      return datePart;
    } catch (e) {
      return dateString;
    }
  }

  /// "/messageDetail/277" -> "277"
  String? _idFromRouteName(String? name) {
    if (name == null) return null;
    final segments = Uri.parse(name).pathSegments;
    return segments.length >= 2 ? segments.last : null;
  }

  @override
  Widget buildBody(BuildContext context) {
    final theme = context.theme;

    // Read from this page's own route. Get.parameters / Get.arguments are
    // global and get overwritten by any later navigation.
    final settings = ModalRoute.of(context)?.settings;
    final Message? routeMessage =
        settings?.arguments is Message ? settings!.arguments as Message : null;
    final String? messageId =
        routeMessage?.id ?? _idFromRouteName(settings?.name);

    if (messageId != null) {
      controller.markMessageAsRead(messageId);
      // Opened from a push: the message may be newer than the loaded list.
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => controller.loadMessageIfMissing(messageId),
      );
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Get.back(),
        ),
        title: const Text("Bericht"),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: Obx(() {
        if (controller.isLoading.value && controller.profile.value == null) {
          return const SizedBox.shrink();
        }

        final Message? message =
            routeMessage ??
            controller.profile.value?.messages.firstWhereOrNull(
              (m) => m.id == messageId,
            );

        if (message == null) {
          final stillLooking = messageId != null &&
              !controller.settledMessageLookups.contains(messageId);
          if (stillLooking) {
            return const Center(child: CircularProgressIndicator());
          }
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: theme.disabledColor),
                const SizedBox(height: 16),
                Text("Bericht niet gevonden", style: theme.textTheme.bodyLarge),
              ],
            ),
          );
        }

        final String cleanBody = message.body
            .replaceAll(r'\n', '\n')
            .replaceAll('&euro;', '€');

        return SelectionArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message.subject,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _formatDate(message.date),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.disabledColor,
                  ),
                ),
                const Divider(height: 32),

                Linkify(
                  onOpen: _onOpenLink,
                  text: cleanBody,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    height: 1.6,
                    fontSize: 16,
                  ),
                  linkStyle: TextStyle(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                    decoration: TextDecoration.underline,
                  ),
                  options: const LinkifyOptions(humanize: true),
                ),

                const SizedBox(height: 40),
                if (message.statusName.isNotEmpty)
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: theme.disabledColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: 16,
                            color: theme.disabledColor,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            "Status: ${message.statusName}",
                            style: TextStyle(
                              color: theme.disabledColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      }),
    );
  }
}
