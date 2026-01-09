import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ivo_service_app/src/components/app_bottom_bar/app_bottom_bar.dart';
import 'package:ivo_service_app/src/components/base/base_view.dart';
import 'package:ivo_service_app/src/controller/profile_controller/profile_controller.dart';
import 'package:ivo_service_app/src/model/profile_model/profile_model.dart';
import 'package:ivo_service_app/src/routes/app_routes.dart';

class NotificationPage extends BaseView<ProfileController> {
  const NotificationPage({super.key});

  @override
  ProfileController get controller => Get.find<ProfileController>();

  @override
  Widget buildBody(BuildContext context) {
    final theme = context.theme;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Berichten"),
        centerTitle: true,
        elevation: 0,
        backgroundColor: theme.scaffoldBackgroundColor,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: theme.dividerColor, height: 1),
        ),
      ),
      bottomNavigationBar: const AppBottomBar(currentIndex: 3),
      body: RefreshIndicator(
        onRefresh: controller.refreshProfile,
        child: Obx(() {
          if (controller.isLoading.value && controller.profile.value == null) {
            return const SizedBox.shrink();
          }

          final messages = controller.profile.value?.messages ?? [];

          if (messages.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_off_outlined,
                    size: 64,
                    color: theme.disabledColor,
                  ),
                  const SizedBox(height: 16),
                  Text("Geen berichten", style: theme.textTheme.bodyLarge),
                ],
              ),
            );
          }

          return ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(12),
            itemCount: messages.length,
            itemBuilder: (context, index) {
              final message = messages[index];
              return NotificationListItem(
                message: message,
                onTap: () {
                  controller.markMessageAsRead(message.id);

                  Get.toNamed(
                    '${AppRoutes.messageDetail}/${message.id}',
                    arguments: message,
                  );
                },
              );
            },
          );
        }),
      ),
    );
  }
}

class NotificationListItem extends StatelessWidget {
  final Message message;
  final VoidCallback onTap;

  const NotificationListItem({
    super.key,
    required this.message,
    required this.onTap,
  });

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

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final bool isUnread = message.readStatus == "0";

    IconData iconData;
    Color iconColor;

    final String typeIcon = message.typeIcon.isNotEmpty
        ? message.typeIcon
        : 'default';

    switch (typeIcon.toLowerCase()) {
      case 'whatsapp':
        iconData = Icons.chat;
        iconColor = const Color(0xFF25D366);
        break;
      case 'email':
        iconData = Icons.email_outlined;
        iconColor = Colors.blue;
        break;
      case 'sms':
        iconData = Icons.sms_outlined;
        iconColor = Colors.orange;
        break;
      default:
        iconData = Icons.notifications_active_outlined;
        iconColor = theme.colorScheme.primary;
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: isUnread
              ? iconColor.withValues(alpha: 0.03)
              : Colors.transparent,
          border: Border(
            bottom: BorderSide(
              color: theme.dividerColor.withValues(alpha: 0.5),
            ),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(iconData, color: iconColor, size: 24),
                ),
                if (isUnread)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        message.typeName.isNotEmpty
                            ? message.typeName
                            : "Bericht",
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: isUnread ? iconColor : theme.disabledColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        _formatDate(message.date),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.disabledColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    message.subject,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: isUnread ? FontWeight.bold : FontWeight.w500,
                      color: isUnread
                          ? Colors.black
                          : theme.textTheme.bodyMedium?.color?.withValues(
                              alpha: 0.8,
                            ),
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    message.body
                        .replaceAll(RegExp(r'\\n'), ' ')
                        .replaceAll('\n', ' '),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: isUnread
                          ? theme.textTheme.bodyMedium?.color
                          : theme.textTheme.bodyMedium?.color?.withValues(
                              alpha: 0.6,
                            ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (message.statusName.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: theme.disabledColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: 12,
                            color: theme.disabledColor,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            message.statusName,
                            style: theme.textTheme.labelSmall?.copyWith(
                              fontSize: 10,
                              color: theme.disabledColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
