import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ivo_service_app/src/components/app_bottom_bar/app_bottom_bar.dart';
import 'package:ivo_service_app/src/components/base/base_view.dart';
import 'package:ivo_service_app/src/controller/profile_controller/profile_controller.dart';
import 'package:ivo_service_app/src/model/profile_model/profile_model.dart';

class ScheduleListPage extends BaseView<ProfileController> {
  const ScheduleListPage({super.key});

  @override
  ProfileController get controller => Get.find<ProfileController>();

  @override
  Widget buildBody(BuildContext context) {
    final theme = context.theme;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Alle afspraken"),
        centerTitle: true,
        elevation: 0,
        backgroundColor: theme.scaffoldBackgroundColor,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: theme.dividerColor, height: 1),
        ),
      ),
      bottomNavigationBar: const AppBottomBar(currentIndex: 1),
      body: RefreshIndicator(
        onRefresh: controller.refreshProfile,
        child: Obx(() {
          if (controller.isLoading.value && controller.profile.value == null) {
            return const SizedBox.shrink();
          }

          final appointments =
              controller.profile.value?.schedule.appointments ?? [];

          if (appointments.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.calendar_today_outlined,
                    size: 64,
                    color: theme.disabledColor,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "Geen afspraken gevonden",
                    style: theme.textTheme.bodyLarge,
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(20),
            itemCount: appointments.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              return _ScheduleListItem(item: appointments[index]);
            },
          );
        }),
      ),
    );
  }
}

class _ScheduleListItem extends StatelessWidget {
  final ScheduleItem item;
  const _ScheduleListItem({required this.item});

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

  Color _getStatusColor(String colorKey) {
    switch (colorKey.toLowerCase()) {
      case 'success':
        return const Color(0xFF2E7D32);
      case 'danger':
        return const Color(0xFFD32F2F);
      case 'warning':
        return Colors.orange;
      case 'info':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final statusColor = _getStatusColor(item.statusColor);

    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.6)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.calendar_month_outlined,
              color: statusColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _formatDate(item.date),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.title,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.textTheme.bodyMedium?.color?.withValues(
                      alpha: 0.8,
                    ),
                  ),
                ),
              ],
            ),
          ),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 100),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                item.status,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: statusColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ],
      ).paddingAll(16),
    );
  }
}
