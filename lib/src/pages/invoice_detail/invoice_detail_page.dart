import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ivo_service_app/src/components/widgets/primary_button.dart';
import 'package:ivo_service_app/src/components/base/base_view.dart';
import 'package:ivo_service_app/src/controller/profile_controller/profile_controller.dart';
import 'package:ivo_service_app/src/model/profile_model/profile_model.dart';
import 'package:url_launcher/url_launcher.dart';

class InvoiceDetailPage extends BaseView<ProfileController> {
  const InvoiceDetailPage({super.key});

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

  Future<void> _launchPaymentUrl(String? urlString) async {
    if (urlString == null || urlString.isEmpty) {
      Get.snackbar("Fout", "Geen betaallink beschikbaar");
      return;
    }
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      Get.snackbar("Fout", "Kon betaalpagina niet openen");
    }
  }

  @override
  Widget buildBody(BuildContext context) {
    final Invoice invoice = Get.arguments as Invoice;

    final theme = context.theme;
    final colorScheme = theme.colorScheme;

    return Obx(() {
      final profile = controller.profile.value;

      if (controller.isLoading.value && profile == null) {
        return const Scaffold(body: SizedBox.shrink());
      }

      final customer = profile?.customer;
      final paymentUrl = profile?.invoices.paymentUrl;

      final statusRaw = invoice.status.toLowerCase();
      final isPaid = statusRaw == 'payed';
      final isOpen = statusRaw == 'open';

      Color statusColor;
      String statusLabel;

      if (isPaid) {
        statusColor = const Color(0xFF2E7D32);
        statusLabel = "BETAALD";
      } else if (isOpen) {
        statusColor = const Color(0xFFD32F2F);
        statusLabel = "OPEN";
      } else {
        statusColor = Colors.orange;
        statusLabel = invoice.status.toUpperCase();
      }

      final statusBg = statusColor.withValues(alpha: 0.1);

      final addressStr = customer != null
          ? "${customer.address} ${customer.number}, ${customer.city}"
          : "";

      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, size: 20),
            onPressed: () => Get.back(),
          ),
          title: Text(
            "Factuur #${invoice.invoiceNo}",
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          centerTitle: true,
          elevation: 0,
          backgroundColor: Colors.transparent,
        ),
        body: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: theme.dividerColor),
                  boxShadow: [
                    if (theme.brightness == Brightness.light)
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                  ],
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: statusBg,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isPaid ? Icons.check_circle : Icons.info,
                            size: 16,
                            color: statusColor,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            statusLabel,
                            style: TextStyle(
                              color: statusColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text("Totaalbedrag", style: theme.textTheme.bodyMedium),
                    const SizedBox(height: 4),
                    Text(
                      "€ ${invoice.amount.toStringAsFixed(2)}",
                      style: theme.textTheme.displayMedium?.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w800,
                        fontSize: 36,
                      ),
                    ),
                    if (!isPaid && invoice.amountPayed > 0)
                      Text(
                        "(Betaald: € ${invoice.amountPayed.toStringAsFixed(2)})",
                        style: theme.textTheme.bodySmall,
                      ).paddingOnly(top: 8),
                  ],
                ).paddingAll(24),
              ),
              const SizedBox(height: 24),
              Container(
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: theme.dividerColor),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        _buildInfoItem(
                          context,
                          "Factuurdatum",
                          _formatDate(invoice.dateInvoice),
                        ),
                        const SizedBox(width: 16),
                        _buildInfoItem(
                          context,
                          "Betaalmethode",
                          invoice.paymentType.isNotEmpty
                              ? invoice.paymentType
                              : "-",
                        ),
                      ],
                    ),
                    if (addressStr.isNotEmpty) ...[
                      const Divider(height: 32),
                      Row(
                        children: [
                          _buildInfoItem(context, "Adres", addressStr),
                        ],
                      ),
                    ],
                  ],
                ).paddingAll(20),
              ),
              const SizedBox(height: 24),
              Text(
                "Betaaloverzicht",
                style: theme.textTheme.titleSmall,
              ).paddingSymmetric(horizontal: 4),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: theme.dividerColor),
                ),
                child: Column(
                  children: [
                    _buildSummaryRow(
                      context,
                      "Subtotaal",
                      "€ ${invoice.subtotal.toStringAsFixed(2)}",
                    ),
                    const SizedBox(height: 12),
                    _buildSummaryRow(
                      context,
                      "BTW",
                      "€ ${invoice.vat.toStringAsFixed(2)}",
                    ),
                    const Divider(height: 24),
                    _buildSummaryRow(
                      context,
                      "Totaal",
                      "€ ${invoice.amount.toStringAsFixed(2)}",
                      isBold: true,
                    ),
                  ],
                ).paddingAll(16),
              ),
            ],
          ).paddingAll(24),
        ),
        bottomNavigationBar: isOpen
            ? Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.scaffoldBackgroundColor,
                  border: Border(top: BorderSide(color: theme.dividerColor)),
                ),
                child: SafeArea(
                  child: PrimaryButton(
                    text:
                        "Direct betalen € ${(invoice.amount - invoice.amountPayed).toStringAsFixed(2)}",
                    onPressed: () => _launchPaymentUrl(paymentUrl),
                  ),
                ),
              )
            : null,
      );
    });
  }

  Widget _buildInfoItem(BuildContext context, String label, String value) {
    final theme = context.theme;
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.disabledColor,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(
    BuildContext context,
    String label,
    String amount, {
    bool isBold = false,
  }) {
    final theme = context.theme;
    final style = isBold
        ? theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)
        : theme.textTheme.bodyMedium;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: style),
        Text(amount, style: style),
      ],
    );
  }
}
