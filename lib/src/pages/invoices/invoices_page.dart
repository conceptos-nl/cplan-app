import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ivo_service_app/src/components/app_bottom_bar/app_bottom_bar.dart';
import 'package:ivo_service_app/src/components/base/base_view.dart';
import 'package:ivo_service_app/src/controller/profile_controller/profile_controller.dart';
import 'package:ivo_service_app/src/model/profile_model/profile_model.dart';
import 'package:ivo_service_app/src/routes/app_routes.dart';

class InvoicesPage extends BaseView<ProfileController> {
  const InvoicesPage({super.key});

  @override
  ProfileController get controller => Get.find<ProfileController>();

  @override
  Widget buildBody(BuildContext context) {
    final theme = context.theme;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Facturen"),
        centerTitle: true,
        elevation: 0,
        backgroundColor: theme.scaffoldBackgroundColor,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: theme.dividerColor, height: 1),
        ),
      ),
      bottomNavigationBar: const AppBottomBar(currentIndex: 2),
      body: RefreshIndicator(
        onRefresh: controller.refreshProfile,
        child: Obx(() {
          if (controller.isLoading.value && controller.profile.value == null) {
            return const SizedBox.shrink();
          }

          final invoices = controller.profile.value?.invoices.list ?? [];

          if (invoices.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.receipt_long_outlined,
                    size: 64,
                    color: theme.disabledColor,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "Geen facturen gevonden",
                    style: theme.textTheme.bodyLarge,
                  ),
                ],
              ),
            );
          }

          // 3. Success state
          return ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(20),
            itemCount: invoices.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              return _InvoiceListItem(
                invoice: invoices[index],
                onTap: () => Get.toNamed(
                  AppRoutes.invoiceDetail,
                  arguments: invoices[index],
                ),
              );
            },
          );
        }),
      ),
    );
  }
}

class _InvoiceListItem extends StatelessWidget {
  final Invoice invoice;
  final VoidCallback onTap;

  const _InvoiceListItem({required this.invoice, required this.onTap});

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
    final statusRaw = invoice.status.toLowerCase();

    Color statusColor;
    String statusLabel;

    if (statusRaw == 'payed') {
      statusColor = const Color(0xFF28A745);
      statusLabel = "Betaald";
    } else if (statusRaw == 'open') {
      statusColor = const Color(0xFFF51853);
      statusLabel = "Open";
    } else if (statusRaw == 'credit') {
      statusColor = Colors.blue;
      statusLabel = "Credit";
    } else {
      statusColor = Colors.grey;
      statusLabel = invoice.status;
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.dividerColor.withValues(alpha: 0.6)),
          boxShadow: [
            if (theme.brightness == Brightness.light)
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Factuur #${invoice.invoiceNo}",
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.textTheme.bodyMedium?.color?.withValues(
                      alpha: 0.8,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatDate(invoice.dateInvoice),
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.textTheme.bodySmall?.color,
                  ),
                ),
              ],
            ),
            Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      "€ ${invoice.amount.toStringAsFixed(2)}",
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        statusLabel,
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 12),
                Icon(Icons.chevron_right, size: 20, color: theme.disabledColor),
              ],
            ),
          ],
        ).paddingAll(16),
      ),
    );
  }
}
