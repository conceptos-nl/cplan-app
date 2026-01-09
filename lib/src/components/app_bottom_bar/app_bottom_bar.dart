import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ivo_service_app/src/pages/contact/contact_page.dart';
import 'package:ivo_service_app/src/pages/home/home_page.dart';
import 'package:ivo_service_app/src/pages/invoices/invoices_page.dart';
import 'package:ivo_service_app/src/pages/notifications/notification_page.dart';
import 'package:ivo_service_app/src/pages/schedule_list/schedule_list_page.dart';

class AppBottomBar extends StatelessWidget {
  final int currentIndex;

  const AppBottomBar({super.key, required this.currentIndex});

  void _handleNavigation(int index) {
    if (currentIndex == index) return;

    const transition = Transition.noTransition;

    switch (index) {
      case 0:
        Get.offAll(() => const HomePage(), transition: transition);
        break;
      case 1:
        Get.offAll(() => const ScheduleListPage(), transition: transition);
        break;
      case 2:
        Get.offAll(() => const InvoicesPage(), transition: transition);
        break;
      case 3:
        Get.offAll(() => const NotificationPage(), transition: transition);
        break;
      case 4:
        Get.offAll(() => const ContactPage(), transition: transition);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final colorScheme = theme.colorScheme;

    final labels = ['Home', 'Planning', 'Facturen', 'Berichten', 'Contact'];
    final icons = [
      Icons.home_outlined,
      Icons.calendar_month_outlined,
      Icons.receipt_long_outlined,
      Icons.chat_bubble_outline,
      Icons.contact_support_outlined,
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      child: Container(
        height: 70,
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(35),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(labels.length, (i) {
            final isSelected = currentIndex == i;
            final activeColor = colorScheme.primary;
            final inactiveColor = colorScheme.onSurface;

            return Expanded(
              child: GestureDetector(
                onTap: () => _handleNavigation(i),
                behavior: HitTestBehavior.opaque,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      icons[i],
                      color: isSelected ? activeColor : inactiveColor,
                      size: 22,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      labels[i],
                      style: TextStyle(
                        color: isSelected ? activeColor : inactiveColor,
                        fontSize: 9,
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}
