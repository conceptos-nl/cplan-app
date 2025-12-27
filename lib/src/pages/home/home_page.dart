import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ivo_service_app/src/components/app_bottom_bar/app_bottom_bar.dart';
import 'package:ivo_service_app/src/components/base/base_view.dart';
import 'package:ivo_service_app/src/controller/profile_controller/profile_controller.dart';
import 'package:ivo_service_app/src/model/profile_model/profile_model.dart';
import 'package:ivo_service_app/src/routes/app_routes.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:snow_fall_animation/snow_fall_animation.dart';
import 'package:url_launcher/url_launcher.dart';

class HomePage extends BaseView<ProfileController> {
  const HomePage({super.key});

  @override
  ProfileController get controller => Get.find<ProfileController>();

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

  Future<void> _launchExternalUrl(String urlString) async {
    if (urlString.isEmpty) return;
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      Get.snackbar("Error", "Could not open the external page");
    }
  }

  @override
  Widget buildBody(BuildContext context) {
    final theme = context.theme;
    final colorScheme = theme.colorScheme;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!controller.isNotificationEnabled.value &&
          !controller.hasShownNotificationPrompt) {
        controller.hasShownNotificationPrompt = true;

        Future.delayed(const Duration(seconds: 2), () {
          if (context.mounted && !controller.isNotificationEnabled.value) {
            _showStayInLoopSheet(context);
          }
        });
      }
    });

    return Scaffold(
      bottomNavigationBar: const AppBottomBar(currentIndex: 0),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: controller.refreshProfile,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Obx(() {
              final profile = controller.profile.value;
              final org = controller.organization.value;

              if (controller.isLoading.value && profile == null) {
                return const SizedBox.shrink();
              }

              if (profile == null && !controller.isLoading.value) {
                return Center(
                  child: Text(
                    controller.errorMessage.value.isNotEmpty
                        ? controller.errorMessage.value
                        : "Geen gegevens gevonden",
                  ),
                ).paddingAll(24);
              }

              final customer = profile!.customer;
              final invoiceData = profile.invoices;
              final hasOpenInvoices = invoiceData.totalOpenInvoices > 0;
              final nextAppointments = profile.schedule.next.take(4).toList();

              return Stack(
                children: [
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: ClipRect(
                      child: SizedBox(
                        height: 300,
                        child: const IgnorePointer(
                          child: SnowFallAnimation(
                            config: SnowfallConfig(
                              numberOfSnowflakes: 60,
                              speed: 0.5,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          InkWell(
                            onTap: () => Get.toNamed(AppRoutes.profile),
                            borderRadius: BorderRadius.circular(8),
                            child: Row(
                              children: [
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: colorScheme.primary.withValues(
                                      alpha: 0.1,
                                    ),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.person,
                                    color: colorScheme.primary,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Welkom terug,",
                                      style: theme.textTheme.bodyMedium,
                                    ),
                                    Text(
                                      customer.name,
                                      style: theme.textTheme.titleLarge
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 18,
                                          ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            onPressed: () =>
                                Get.toNamed(AppRoutes.contactOrganization),
                            icon: Icon(
                              Icons.contact_support_outlined,
                              color: colorScheme.primary,
                            ),
                            tooltip: "Contact",
                          ),
                          IconButton(
                            onPressed: () =>
                                Get.toNamed(AppRoutes.notifications),
                            icon: Obx(() {
                              final unreadCount =
                                  controller.profile.value?.messages
                                      .where((m) => m.readStatus == "0")
                                      .length ??
                                  0;
                              return Badge(
                                isLabelVisible: unreadCount > 0,
                                label: Text("$unreadCount"),
                                child: const Icon(Icons.notifications_outlined),
                              );
                            }),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      if (org != null &&
                          (org.logo.isNotEmpty || org.name.isNotEmpty))
                        Container(
                          width: double.infinity,
                          margin: const EdgeInsets.only(bottom: 24),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: theme.cardColor,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: theme.dividerColor.withValues(alpha: 0.5),
                            ),
                            boxShadow: [
                              if (theme.brightness == Brightness.light)
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.03),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                            ],
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (org.logo.isNotEmpty) ...[
                                Image.network(
                                  org.logo,
                                  height: 60,
                                  fit: BoxFit.contain,
                                  errorBuilder: (c, o, s) => const SizedBox(),
                                ),
                                const SizedBox(height: 12),
                              ],
                              if (org.name.isNotEmpty)
                                Text(
                                  org.name,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                            ],
                          ),
                        ),
                      if (hasOpenInvoices) ...[
                        _buildActionRequiredCard(
                          context,
                          count: invoiceData.totalOpenInvoices,
                          totalAmount: invoiceData.totalOpenAmount,
                          paymentUrl: invoiceData.paymentUrl,
                        ),
                        const SizedBox(height: 32),
                      ],
                      if (nextAppointments.isNotEmpty) ...[
                        Text(
                          "Volgende afspraken",
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 130,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            physics: const BouncingScrollPhysics(),
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            itemCount: nextAppointments.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(width: 12),
                            itemBuilder: (context, index) {
                              return SizedBox(
                                width: MediaQuery.of(context).size.width * 0.82,
                                child: _buildNextAppointmentCard(
                                  context,
                                  nextAppointments[index],
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 32),
                      ],
                      Container(
                        decoration: BoxDecoration(
                          color: theme.cardColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: theme.dividerColor),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.location_on_outlined,
                              color: colorScheme.primary,
                              size: 28,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Adres",
                                    style: theme.textTheme.labelLarge?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    "${customer.address} ${customer.number}, ${customer.city}",
                                    style: theme.textTheme.bodyMedium,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ).paddingAll(16),
                      ),
                      const SizedBox(height: 32),
                      Row(
                        children: [
                          Expanded(
                            child: _buildGridActionCard(
                              context,
                              title: "Alle afspraken",
                              icon: Icons.calendar_month_outlined,
                              color: Colors.blue,
                              onTap: () => Get.toNamed(AppRoutes.scheduleList),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildGridActionCard(
                              context,
                              title: "Alle facturen",
                              icon: Icons.receipt_long_outlined,
                              color: colorScheme.secondary,
                              onTap: () => Get.toNamed(AppRoutes.invoiceList),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                    ],
                  ).paddingAll(24),
                ],
              );
            }),
          ),
        ),
      ),
    );
  }

  Widget _buildGridActionCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    final theme = context.theme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 120,
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: theme.dividerColor.withValues(alpha: 0.5)),
          boxShadow: [
            if (theme.brightness == Brightness.light)
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNextAppointmentCard(BuildContext context, ScheduleItem item) {
    final theme = context.theme;
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.primary.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(
                color: theme.dividerColor.withValues(alpha: 0.5),
              ),
            ),
            child: Icon(
              Icons.calendar_month_outlined,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _formatDate(item.date),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.title,
                  style: theme.textTheme.bodyMedium?.copyWith(fontSize: 16),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    item.status,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionRequiredCard(
    BuildContext context, {
    required int count,
    required double totalAmount,
    required String paymentUrl,
  }) {
    const dangerColor = Color(0xFFF51853);
    const dangerBgColor = Color(0xFFFFF0F4);
    final theme = context.theme;

    return Container(
      decoration: BoxDecoration(
        color: dangerBgColor,
        borderRadius: BorderRadius.circular(16),
        border: const Border(left: BorderSide(color: dangerColor, width: 4)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: dangerColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.priority_high,
                  color: dangerColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Actie vereist",
                    style: TextStyle(
                      color: dangerColor,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    "U heeft $count openstaande facturen",
                    style: const TextStyle(color: dangerColor, fontSize: 13),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Center(
              child: Text(
                "€ ${totalAmount.toStringAsFixed(2)}",
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ).paddingAll(16),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _launchExternalUrl(paymentUrl),
              style: ElevatedButton.styleFrom(
                backgroundColor: dangerColor,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                "Direct betalen",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ).paddingAll(16),
    );
  }

  void _showStayInLoopSheet(BuildContext context) {
    final theme = context.theme;

    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.notifications_active,
                size: 32,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              "Blijf op de hoogte",
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              "Schakel meldingen in om aankondigingen van ons te ontvangen en te weten wanneer uw factuur gereed is.",
              style: theme.textTheme.bodyMedium?.copyWith(
                height: 1.5,
                color: theme.textTheme.bodyMedium?.color?.withValues(
                  alpha: 0.7,
                ),
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  Get.back();
                  var status = await Permission.notification.status;
                  if (status.isPermanentlyDenied) {
                    Get.defaultDialog(
                      title: "Meldingen zijn uitgeschakeld",
                      titleStyle: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      content: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 30),
                        child: Text(
                          "Uw meldingen zijn geblokkeerd. Ga naar Instellingen > Meldingen en schakel ze in om updates te ontvangen.",
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium,
                        ),
                      ),
                      textConfirm: "Open Instellingen",
                      textCancel: "Annuleren",
                      confirmTextColor: Colors.white,
                      buttonColor: theme.colorScheme.primary,
                      onConfirm: () {
                        Get.back();
                        openAppSettings();
                      },
                    );
                    return;
                  }

                  if (!status.isGranted) {
                    final result = await Permission.notification.request();

                    if (result.isGranted) {
                      await controller.syncDeviceData();
                    }
                  } else {
                    await controller.syncDeviceData();
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  "Meldingen inschakelen",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Get.back(),
                child: Text(
                  "Nu niet",
                  style: TextStyle(
                    color: theme.disabledColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
      isDismissible: false,
      enableDrag: false,
    );
  }
}
