import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/invoice.dart';
import '../../providers/invoice_office_delivery_print_provider.dart';
import '../../providers/invoice_office_delivery_provider.dart';
import '../../routes/app_routes.dart';
import '../../services/api_service.dart';
import '../../utills/app_colors.dart';
import '../../utills/app_font.dart';
import '../../utills/app_toast.dart';
import '../../utills/pdf_file_helper.dart';
import '../../widgets/app_list_shimmer.dart';
import '../../widgets/app_loader.dart';
import '../../widgets/delivery_info_dialog.dart';
import '../../widgets/searchable_party_picker.dart';

class InvoiceOfficeDeliveryScreen extends StatefulWidget {
  const InvoiceOfficeDeliveryScreen({super.key});

  @override
  State<InvoiceOfficeDeliveryScreen> createState() => _InvoiceOfficeDeliveryScreenState();
}

class _InvoiceOfficeDeliveryScreenState extends State<InvoiceOfficeDeliveryScreen> {
  String? _downloadingInvoiceId;

  bool _isDelivered(Invoice invoice) {
    final raw = invoice.orderStatusRaw.trim().toUpperCase();
    if (raw.contains('DELIVERED')) return true;
    if (raw.contains('PENDING')) return false;
    return invoice.status == InvoiceStatus.paid;
  }

  Future<void> _downloadDeliveredPdf(Invoice invoice) async {
    if (_downloadingInvoiceId != null) return;

    setState(() => _downloadingInvoiceId = invoice.id);
    final printProvider = InvoiceOfficeDeliveryPrintProvider(invoice, bootstrap: false);
    if (invoice.items.isNotEmpty) {
      printProvider.toggleSelectAll();
    }

    try {
      await printProvider.loadPrintList();
      if (!mounted) return;

      if (printProvider.printListError != null &&
          printProvider.printListError!.trim().isNotEmpty &&
          printProvider.printOptions.isEmpty) {
        Utils().showToast(
          context: context,
          title: 'Error',
          message: printProvider.printListError!,
          isSuccess: false,
        );
        return;
      }

      final success = await printProvider.generatePdf(autoDownload: false);
      if (!mounted) return;

      if (!success) {
        Utils().showToast(
          context: context,
          title: 'Error',
          message: printProvider.errorMessage?.trim().isNotEmpty == true
              ? printProvider.errorMessage!
              : 'Unable to generate PDF.',
          isSuccess: false,
        );
        return;
      }

      final url = printProvider.lastPdfUrl?.trim() ?? '';
      if (url.isEmpty) {
        Utils().showToast(
          context: context,
          title: 'Error',
          message: 'PDF url not found.',
          isSuccess: false,
        );
        return;
      }

      final safeId = invoice.id.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
      final fileName = 'Diamx_${safeId}_Invoice.pdf';
      final path = await PdfFileHelper.downloadAndSavePdf(
        url: url,
        fileName: fileName,
        downloadFile: ApiService.shared().downloadFile,
      );
      if (!mounted) return;

      setState(() => _downloadingInvoiceId = null);

      if (PdfFileHelper.needsUserSavePicker) {
        await PdfFileHelper.shareLocalFile(
          context: context,
          filePath: path,
          title: 'Invoice Office PDF · ${invoice.id}',
        );
      } else {
        Utils().showToast(
          context: context,
          title: 'Success',
          message: 'PDF saved to Downloads.',
          isSuccess: true,
        );
      }
    } catch (error) {
      if (!mounted) return;
      setState(() => _downloadingInvoiceId = null);
      Utils().showToast(
        context: context,
        title: 'Error',
        message: PdfFileHelper.errorMessage(error),
        isSuccess: false,
      );
    } finally {
      printProvider.dispose();
      if (mounted && _downloadingInvoiceId != null) {
        setState(() => _downloadingInvoiceId = null);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        toolbarHeight: 96,
        backgroundColor: AppColors.primaryDark,
        surfaceTintColor: Colors.transparent,
        foregroundColor: AppColors.white,
        centerTitle: false,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.primaryDark,
                AppColors.primary,
                Color(0xFF14634E),
              ],
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                right: -24,
                top: -20,
                child: Icon(
                  Icons.receipt_long_outlined,
                  size: 125,
                  color: AppColors.white.withValues(alpha: 0.08),
                ),
              ),
            ],
          ),
        ),
        leading: Padding(
          padding: const EdgeInsets.only(left: 10),
          child: Center(
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AppColors.white.withValues(alpha: 0.1),
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.white.withValues(alpha: 0.12),
                ),
              ),
              child: IconButton(
                onPressed: () => Navigator.pop(context),
                padding: EdgeInsets.zero,
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
              ),
            ),
          ),
        ),
        titleSpacing: 12,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Sale Invoices',
              style: TextStyle(
                fontFamily: FontFamily.montserratBold,
                color: AppColors.white,
                fontSize: 20,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              'Track billing and deliveries',
              style: TextStyle(
                fontFamily: FontFamily.montserratRegular,
                color: AppColors.white.withValues(alpha: 0.72),
                fontSize: 10.5,
              ),
            ),
          ],
        ),
      ),
      body: Consumer<InvoiceOfficeDeliveryProvider>(
        builder: (context, provider, child) {
          return Stack(
            children: [
              NotificationListener<ScrollNotification>(
                onNotification: (notification) {
                  if (notification is! ScrollUpdateNotification &&
                      notification is! OverscrollNotification) {
                    return false;
                  }
                  if (!provider.hasMore ||
                      provider.isLoadingMore ||
                      provider.isInvoicesLoading) {
                    return false;
                  }
                  final metrics = notification.metrics;
                  if (metrics.maxScrollExtent <= 0) return false;
                  if (metrics.pixels >= metrics.maxScrollExtent - 320) {
                    provider.loadMoreInvoices();
                  }
                  return false;
                },
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  ),
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
                    sliver: SliverToBoxAdapter(
                      child: Column(
                        children: [
                          _SummarySection(provider: provider),
                          const SizedBox(height: 20),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child:_DeliveredStatusDropdown(provider: provider),
                              ),
                              const SizedBox(width: 10),
                              SizedBox(
                                width: 150,
                                child: _InvoicePartyDropdown(provider: provider),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(17),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primaryDark.withValues(
                                    alpha: 0.07,
                                  ),
                                  blurRadius: 16,
                                  offset: const Offset(0, 7),
                                ),
                              ],
                            ),
                            child: TextField(
                              controller: provider.searchController,
                              style: TextStyle(
                                fontFamily: FontFamily.montserratMedium,
                                color: AppColors.textPrimary,
                                fontSize: 13,
                              ),
                              decoration: InputDecoration(
                                hintText: 'Search invoice or customer',
                                hintStyle: TextStyle(
                                  fontFamily: FontFamily.montserratRegular,
                                  color: AppColors.textSecondary,
                                  fontSize: 11.5,
                                ),
                                prefixIcon: const Icon(
                                  Icons.search_rounded,
                                  color: AppColors.primary,
                                ),
                                filled: true,
                                fillColor: AppColors.surface,
                                contentPadding:
                                const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(17),
                                  borderSide: BorderSide(
                                    color: AppColors.secondary.withValues(
                                      alpha: 0.8,
                                    ),
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(17),
                                  borderSide: const BorderSide(
                                    color: AppColors.primary,
                                    width: 1.4,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'All Invoices',
                                  style: TextStyle(
                                    fontFamily: FontFamily.montserratBold,
                                    color: AppColors.textPrimary,
                                    fontSize: 18,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 11,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(
                                    alpha: 0.09,
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  '${provider.invoices.length} RECORDS',
                                  style: TextStyle(
                                    fontFamily: FontFamily.montserratSemiBold,
                                    color: AppColors.primary,
                                    fontSize: 8.5,
                                    letterSpacing: 0.7,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (provider.isInvoicesLoading && !provider.isLoadingMore)
                    const AppListCardShimmer()
                  else if (provider.invoices.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: Text(
                          provider.invoicesError ??
                              'No matching invoices found',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: FontFamily.montserratMedium,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    )
                  else ...[
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                      sliver: SliverList.separated(
                        itemCount: provider.invoices.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final invoice = provider.invoices[index];
                          return _InvoiceCard(
                            invoice: invoice,
                            isDelivered: _isDelivered(invoice),
                            isDownloading: _downloadingInvoiceId == invoice.id,
                            onDownload: () => _downloadDeliveredPdf(invoice),
                            onTap: () => Navigator.pushNamed(
                              context,
                              AppRoutes.invoiceOfficeDeliveryDetail,
                              arguments: invoice,
                            ),
                          );
                        },
                      ),
                    ),
                    if (provider.isLoadingMore)
                      const SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(16, 0, 16, 28),
                          child: Center(
                            child: SizedBox(
                              width: 28,
                              height: 28,
                              child: CircularProgressIndicator(strokeWidth: 2.4),
                            ),
                          ),
                        ),
                      ),
                  ],
                ],
              ),
              ),
              if (provider.isPartiesLoading)
                const FullScreenLoader(message: 'Loading parties...'),
              if (provider.isInvoicesLoading &&
                  !provider.isLoadingMore &&
                  !provider.isPartiesLoading)
                const FullScreenLoader(message: 'Loading invoices...'),
              if (_downloadingInvoiceId != null)
                const FullScreenLoader(message: 'Downloading PDF...'),
            ],
          );
        },
      ),
    );
  }
}

class _InvoicePartyDropdown extends StatelessWidget {
  const _InvoicePartyDropdown({required this.provider});

  final InvoiceOfficeDeliveryProvider provider;

  @override
  Widget build(BuildContext context) {
    return SearchablePartyPicker(
      parties: provider.parties,
      selectedParty: provider.selectedParty,
      isLoading: provider.isPartiesLoading,
      errorText: provider.partiesError,
      hintText: 'Party',
      onChanged: provider.selectParty,
    );
  }
}

class _DeliveredStatusDropdown extends StatelessWidget {
  const _DeliveredStatusDropdown({required this.provider});

  final InvoiceOfficeDeliveryProvider provider;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(17),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryDark.withValues(alpha: 0.07),
            blurRadius: 16,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: DropdownButtonFormField<String>(
        key: ValueKey(provider.selectedDeliveredStatus),
        initialValue: provider.selectedDeliveredStatus,
        isExpanded: true,
        icon: const Icon(
          Icons.keyboard_arrow_down_rounded,
          color: AppColors.primary,
          size: 20,
        ),
        decoration: InputDecoration(
          hintText: 'Status',
          filled: true,
          fillColor: AppColors.surface,
          prefixIcon: const Icon(
            Icons.filter_list_rounded,
            color: AppColors.primary,
            size: 18,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 14,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(17),
            borderSide: BorderSide(
              color: AppColors.secondary.withValues(alpha: 0.8),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(17),
            borderSide: const BorderSide(color: AppColors.primary, width: 1.4),
          ),
        ),
        items: InvoiceOfficeDeliveryProvider.deliveredStatusOptions
            .map(
              (status) => DropdownMenuItem<String>(
                value: status,
                child: Text(
                  status,
                  style: TextStyle(
                    fontFamily: FontFamily.montserratMedium,
                    fontSize: 12,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            )
            .toList(),
        onChanged: provider.isInvoicesLoading
            ? null
            : (status) {
                if (status == null) return;
                provider.selectDeliveredStatus(status);
              },
      ),
    );
  }
}

class _SummarySection extends StatelessWidget {
  const _SummarySection({required this.provider});

  final InvoiceOfficeDeliveryProvider provider;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            // Expanded(
            //   child: _SummaryChip(
            //     label: 'Pcs',
            //     value: _formatNumber(provider.totalPcs),
            //     color: AppColors.primary,
            //   ),
            // ),
            // const SizedBox(width: 8),
            Expanded(
              child: _SummaryChip(
                label: 'Count',
                value: provider.totalCount.toString(),
                color: AppColors.accentDark,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _SummaryChip(
                label: 'AvgRate',
                value: _formatNumber(provider.totalRate),
                color: AppColors.success,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _SummaryChip(
                label: 'Total Amt',
                value: _formatNumber(provider.totalAmt),
                color: AppColors.primaryDark,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _SummaryChip(
                label: 'Total CTC',
                value: _formatNumber(provider.totalCts),
                color: AppColors.accent,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

String _formatNumber(double value) {
  if (value == value.roundToDouble()) {
    return value.toStringAsFixed(0);
  }
  return value.toStringAsFixed(2);
}

class _SummaryChip extends StatelessWidget {
  const _SummaryChip({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            value,
            style: TextStyle(
              fontFamily: FontFamily.montserratBold,
              color: AppColors.textPrimary,
              fontSize: 13,
            ),
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: FontFamily.montserratMedium,
                color: AppColors.textSecondary,
                fontSize: 10,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InvoiceCard extends StatelessWidget {
  const _InvoiceCard({
    required this.invoice,
    required this.onTap,
    required this.isDelivered,
    required this.isDownloading,
    required this.onDownload,
  });

  final Invoice invoice;
  final VoidCallback onTap;
  final bool isDelivered;
  final bool isDownloading;
  final VoidCallback onDownload;

  @override
  Widget build(BuildContext context) {
    final isPending = invoice.status == InvoiceStatus.pending;
    final statusColor = isPending ? AppColors.accentDark : AppColors.success;
    final pcsValue = invoice.totalPcs > 0
        ? _formatNumber(invoice.totalPcs)
        : invoice.diamondCount.toString();
    final rate = invoice.averageRate;
    final finalAmt = invoice.listGrandTotal != 0
        ? invoice.listGrandTotal
        : invoice.grandTotal;

    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.fromLTRB(18, 16, 15, 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: statusColor.withValues(alpha: 0.22)),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryDark.withValues(alpha: 0.05),
                blurRadius: 16,
                offset: const Offset(0, 7),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.primary, AppColors.primaryDark],
                      ),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: const Icon(
                      Icons.receipt_long_outlined,
                      color: AppColors.secondary,
                      size: 21,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          invoice.customerName.isNotEmpty
                              ? invoice.customerName
                              : invoice.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: FontFamily.montserratSemiBold,
                            color: AppColors.textPrimary,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          [
                            invoice.id,
                            if (invoice.dateLabel.isNotEmpty) invoice.dateLabel,
                          ].join(' · '),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: FontFamily.montserratRegular,
                            color: AppColors.textSecondary,
                            fontSize: 9.5,
                          ),
                        ),
                        if (invoice.entryBy.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Entry By: ${invoice.entryBy}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: FontFamily.montserratRegular,
                              color: AppColors.textSecondary,
                              fontSize: 9.5,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.11),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      invoice.statusLabel,
                      style: TextStyle(
                        fontFamily: FontFamily.montserratSemiBold,
                        color: statusColor,
                        fontSize: 8.5,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Material(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: () => DeliveryInfoDialog.showForMemo(
                        context: context,
                        title: 'Delivery Info · ${invoice.id}',
                        billingCompanyName: invoice.billingCompanyName,
                        billingName: invoice.billingName,
                        billingAddress: invoice.billingAddress,
                        shippingCompanyName: invoice.shippingCompanyName,
                        shippingAddress: invoice.shippingAddress,
                        cityName: invoice.cityName,
                        stateName: invoice.stateName,
                        deliverBy: invoice.deliverBy,
                        deliverAssignBy: invoice.deliverAssignBy,
                        deliverDate: invoice.deliverDate,
                        deliveredDate: invoice.deliveredDate,
                        mailTelephoneNo: invoice.mailTelephoneNo,
                        shipTelephoneNo: invoice.shipTelephoneNo,
                      ),
                      child: const Padding(
                        padding: EdgeInsets.all(6),
                        child: Icon(
                          Icons.info_outline_rounded,
                          size: 16,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Divider(
                height: 1,
                color: AppColors.secondary.withValues(alpha: 0.9),
              ),
              const SizedBox(height: 13),
              Row(
                children: [
                  Expanded(
                    child: _InvoiceValue(
                      label: 'TotalCts',
                      value: invoice.totalCarat.toStringAsFixed(3),
                    ),
                  ),
                  Expanded(
                    child: _InvoiceValue(label: 'Total Pcs', value: pcsValue),
                  ),
                  Expanded(
                    child: _InvoiceValue(
                      label: 'Rate',
                      value: _formatNumber(rate),
                    ),
                  ),
                  Expanded(
                    child: _InvoiceValue(
                      label: 'Final Amt',
                      value: _money(finalAmt),
                      highlight: true,
                    ),
                  ),
                  if (isDelivered) ...[
                    Material(
                      color: AppColors.primary.withValues(alpha: 0.09),
                      shape: const CircleBorder(),
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: isDownloading ? null : onDownload,
                        child: SizedBox(
                          width: 28,
                          height: 28,
                          child: Center(
                            child: isDownloading
                                ? const SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppColors.primary,
                                    ),
                                  )
                                : const Icon(
                                    Icons.download_rounded,
                                    color: AppColors.primary,
                                    size: 16,
                                  ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                  ],
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.primary,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InvoiceValue extends StatelessWidget {
  const _InvoiceValue({
    required this.label,
    required this.value,
    this.highlight = false,
  });

  final String label;
  final String value;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: FontFamily.montserratRegular,
            color: AppColors.textSecondary,
            fontSize: 8,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontFamily: FontFamily.montserratSemiBold,
            color: highlight ? AppColors.primary : AppColors.textPrimary,
            fontSize: 9.5,
          ),
        ),
      ],
    );
  }
}

String _money(double value) => '\$${value.toStringAsFixed(2)}';
