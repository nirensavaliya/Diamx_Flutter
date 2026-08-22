import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

import '../../models/invoice.dart';
import '../../models/print_template.dart';
import '../../providers/invoice_print_provider.dart';
import '../../providers/invoice_provider.dart';
import '../../services/api_service.dart';
import '../../utills/app_colors.dart';
import '../../utills/app_font.dart';
import '../../utills/app_toast.dart';
import '../../utills/pdf_file_helper.dart';
import '../../widgets/app_loader.dart';

class InvoiceDetailScreen extends StatefulWidget {
  const InvoiceDetailScreen({super.key, required this.invoice});

  final Invoice invoice;

  @override
  State<InvoiceDetailScreen> createState() => _InvoiceDetailScreenState();
}

class _InvoiceDetailScreenState extends State<InvoiceDetailScreen> {
  late Invoice _invoice;
  bool _isItemsLoading = true;
  String? _itemsError;
  bool _isPrintBusy = false;
  String _printBusyMessage = '';

  @override
  void initState() {
    super.initState();
    _invoice = widget.invoice;
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadItems());
  }

  bool get _needsSignatureForPrint {
    final raw = _invoice.orderStatusRaw.trim().toUpperCase();
    if (raw.contains('DELIVERED')) return false;
    if (raw.contains('PENDING')) return true;
    return _invoice.status == InvoiceStatus.pending;
  }

  Future<void> _loadItems() async {
    setState(() {
      _isItemsLoading = true;
      _itemsError = null;
    });

    try {
      final items = await context.read<InvoiceProvider>().loadInvoiceItems(
        _invoice.id,
      );
      if (!mounted) return;
      setState(() {
        _invoice = _invoice.copyWith(items: items);
        _isItemsLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _itemsError = error.toString().replaceFirst('Bad state: ', '');
        _isItemsLoading = false;
      });
    }
  }

  Future<void> _onPrintInvoice() async {
    if (_isPrintBusy || _isItemsLoading) return;

    if (_invoice.items.isEmpty) {
      Utils().showToast(
        context: context,
        title: 'Error',
        message: _itemsError ?? 'No diamonds available to print.',
        isSuccess: false,
      );
      return;
    }

    final printProvider = InvoicePrintProvider(_invoice, bootstrap: false);
    printProvider.toggleSelectAll();

    setState(() {
      _isPrintBusy = true;
      _printBusyMessage = 'Loading print options...';
    });

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

      // Hide loader so format dialog is visible.
      setState(() {
        _isPrintBusy = false;
        _printBusyMessage = '';
      });

      final shouldPrint = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (_) => ChangeNotifierProvider<InvoicePrintProvider>.value(
          value: printProvider,
          child: _InvoicePrintFormatDialog(
            showSignatureAction: _needsSignatureForPrint,
          ),
        ),
      );
      if (!mounted || shouldPrint != true) return;

      setState(() {
        _isPrintBusy = true;
        _printBusyMessage = 'Generating PDF...';
      });

      final success = await printProvider.generatePdf(autoDownload: false);
      if (!mounted) return;

      if (!success) {
        Utils().showToast(
          context: context,
          title: 'Error',
          message: printProvider.errorMessage?.trim().isNotEmpty == true
              ? printProvider.errorMessage!
              : 'Unable to generate PDF. Please try again.',
          isSuccess: false,
        );
        return;
      }

      final url = printProvider.lastPdfUrl;
      if (url == null || url.isEmpty) {
        Utils().showToast(
          context: context,
          title: 'Error',
          message: 'PDF url not found.',
          isSuccess: false,
        );
        return;
      }

      setState(() {
        _isPrintBusy = false;
        _printBusyMessage = '';
      });

      await showDialog<void>(
        context: context,
        barrierDismissible: true,
        builder: (_) => _InvoicePdfDialog(
          networkUrl: url,
          fileName:
              'Diamx_${_invoice.id.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_')}_Invoice.pdf',
          title: 'Invoice PDF · ${_invoice.id}',
        ),
      );
      if (mounted) await _loadItems();
    } finally {
      printProvider.dispose();
      if (mounted) {
        setState(() {
          _isPrintBusy = false;
          _printBusyMessage = '';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        toolbarHeight: 90,
        backgroundColor: AppColors.primaryDark,
        foregroundColor: AppColors.white,
        surfaceTintColor: Colors.transparent,
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
                right: -25,
                top: -28,
                child: Icon(
                  Icons.receipt_long_outlined,
                  color: AppColors.white.withValues(alpha: 0.08),
                  size: 125,
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
              'Invoice Details',
              style: TextStyle(
                fontFamily: FontFamily.montserratBold,
                color: AppColors.white,
                fontSize: 19,
              ),
            ),
            // const SizedBox(height: 4),
            // Text(
            //   _invoice.id,
            //   style: TextStyle(
            //     fontFamily: FontFamily.montserratMedium,
            //     color: AppColors.white.withValues(alpha: 0.68),
            //     fontSize: 9.5,
            //     letterSpacing: 0.8,
            //   ),
            // ),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
        children: [
          _BillingCard(invoice: _invoice),
          const SizedBox(height: 16),
          Row(
            children: [
              Text(
                'Diamond Details',
                style: TextStyle(
                  fontFamily: FontFamily.montserratBold,
                  color: AppColors.textPrimary,
                  fontSize: 18,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.09),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${_invoice.diamondCount} Diamonds',
                  style: TextStyle(
                    fontFamily: FontFamily.montserratSemiBold,
                    color: AppColors.primary,
                    fontSize: 9,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_itemsError != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(
                _itemsError!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: FontFamily.montserratMedium,
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
            )
          else if (!_isItemsLoading && _invoice.items.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(
                'No diamond details found',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: FontFamily.montserratMedium,
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
            )
          else if (!_isItemsLoading)
            ..._invoice.items.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _InvoiceItemCard(item: item),
              ),
            ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: Border(
              top: BorderSide(
                color: AppColors.secondary.withValues(alpha: 0.8),
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryDark.withValues(alpha: 0.1),
                blurRadius: 22,
                offset: const Offset(0, -6),
              ),
            ],
          ),
          child: SizedBox(
            height: 54,
            child: FilledButton.icon(
              onPressed: (_isPrintBusy || _isItemsLoading)
                  ? null
                  : _onPrintInvoice,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                disabledBackgroundColor: AppColors.primaryLight,
                foregroundColor: AppColors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              icon: const Icon(Icons.print_outlined),
              label: Text(
                'PRINT INVOICE',
                style: TextStyle(
                  fontFamily: FontFamily.montserratSemiBold,
                  fontSize: 12,
                  letterSpacing: 1,
                ),
              ),
            ),
          ),
        ),
      ),
        ),
        if (_isItemsLoading)
          const FullScreenLoader(message: 'Loading diamonds...'),
        if (_isPrintBusy)
          FullScreenLoader(
            message: _printBusyMessage.isNotEmpty
                ? _printBusyMessage
                : 'Please wait...',
          ),
      ],
    );
  }
}

class _BillingCard extends StatelessWidget {
  const _BillingCard({required this.invoice});

  final Invoice invoice;

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
    final party = invoice.customerName.isNotEmpty
        ? invoice.customerName
        : invoice.title;
    final dateText = invoice.dateLabel.isNotEmpty
        ? invoice.dateLabel
        : _date(invoice.date);

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 15, 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
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
                      party,
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
                        if (dateText.isNotEmpty) dateText,
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
                child: _OverviewMetric(
                  label: 'TotalCts',
                  value: invoice.totalCarat.toStringAsFixed(3),
                ),
              ),
              Expanded(
                child: _OverviewMetric(
                  label: 'Total Pcs',
                  value: pcsValue,
                ),
              ),
              Expanded(
                child: _OverviewMetric(
                  label: 'Rate',
                  value: _formatNumber(rate),
                ),
              ),
              Expanded(
                child: _OverviewMetric(
                  label: 'Final Amt',
                  value: _money(finalAmt, invoice.currencyName),
                  highlight: true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _OverviewMetric extends StatelessWidget {
  const _OverviewMetric({
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

class _InvoiceItemCard extends StatelessWidget {
  const _InvoiceItemCard({required this.item});

  final InvoiceItem item;

  String _text(String value) {
    final text = value.trim();
    return text.isEmpty ? '-' : text;
  }

  String _discount(double value) {
    if (value == 0) return '-';
    if (value == value.roundToDouble()) return value.toStringAsFixed(0);
    return value.toStringAsFixed(2);
  }

  @override
  Widget build(BuildContext context) {
    final amt = item.total != 0 ? _money(item.total) : '-';
    final cts = item.carat > 0 ? '${item.carat.toStringAsFixed(3)} Cts' : '-';
    final ctsPrice = item.pricePerCarat != 0 ? _money(item.pricePerCarat) : '-';
    final labLabel = item.labReportNo.trim().isNotEmpty
        ? item.labReportNo.trim()
        : _text(item.lab);

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.secondary),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryDark.withValues(alpha: 0.045),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _text(item.shape),
                style: TextStyle(
                  fontFamily: FontFamily.montserratBold,
                  color: AppColors.textPrimary,
                  fontSize: 12,
                ),
              ),
              Text(
                cts,
                style: TextStyle(
                  fontFamily: FontFamily.montserratBold,
                  color: AppColors.textPrimary,
                  fontSize: 11.5,
                ),
              ),
              Text(
                _text(item.color),
                style: TextStyle(
                  fontFamily: FontFamily.montserratSemiBold,
                  color: AppColors.textPrimary,
                  fontSize: 11,
                ),
              ),
              Text(
                _text(item.clarity),
                style: TextStyle(
                  fontFamily: FontFamily.montserratSemiBold,
                  color: AppColors.textPrimary,
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _text(item.stockNumber),
                style: TextStyle(
                  fontFamily: FontFamily.montserratSemiBold,
                  color: AppColors.textPrimary,
                  fontSize: 11,
                ),
              ),
              Text(
                '${_text(item.cut)}  ${_text(item.polish)}  ${_text(item.symm)}',
                style: TextStyle(
                  fontFamily: FontFamily.montserratSemiBold,
                  color: AppColors.textPrimary,
                  fontSize: 11,
                ),
              ),
              Flexible(
                child: Text(
                  labLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.end,
                  style: TextStyle(
                    fontFamily: FontFamily.montserratMedium,
                    color: AppColors.textSecondary,
                    fontSize: 10.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _discount(item.discount),
                style: TextStyle(
                  fontFamily: FontFamily.montserratSemiBold,
                  color: AppColors.textPrimary,
                  fontSize: 11,
                ),
              ),
              Text(
                'Total : $amt',
                style: TextStyle(
                  fontFamily: FontFamily.montserratBold,
                  color: AppColors.primary,
                  fontSize: 11.5,
                ),
              ),
              Text(
                '\$/CTS : $ctsPrice',
                style: TextStyle(
                  fontFamily: FontFamily.montserratBold,
                  color: AppColors.primary,
                  fontSize: 11.5,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

String _formatNumber(double value) {
  if (value == value.roundToDouble()) {
    return value.toStringAsFixed(0);
  }
  return value.toStringAsFixed(2);
}

String _money(double value, [String currency = '']) {
  final code = currency.trim().isEmpty ? 'USD' : currency.trim();
  final symbol = code.toUpperCase() == 'USD' ? '\$' : '$code ';
  return '$symbol${value.toStringAsFixed(2)}';
}

String _date(DateTime value) {
  return '${value.day.toString().padLeft(2, '0')}/'
      '${value.month.toString().padLeft(2, '0')}/${value.year}';
}

class _InvoicePdfDialog extends StatefulWidget {
  const _InvoicePdfDialog({
    required this.networkUrl,
    required this.fileName,
    required this.title,
  });

  final String networkUrl;
  final String fileName;
  final String title;

  @override
  State<_InvoicePdfDialog> createState() => _InvoicePdfDialogState();
}

class _InvoicePdfDialogState extends State<_InvoicePdfDialog> {
  String? _localPath;
  bool _isDownloading = false;
  bool _isSharing = false;

  bool get _isBusy => _isDownloading || _isSharing;

  @override
  Widget build(BuildContext context) {
    final url = widget.networkUrl.trim();
    final localFile =
        (_localPath != null && _localPath!.isNotEmpty) ? File(_localPath!) : null;
    final hasLocalFile = localFile != null && localFile.existsSync();
    final media = MediaQuery.of(context);
    final maxWidth = media.size.width - 24;
    final maxHeight = media.size.height - media.viewPadding.vertical - 48;

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 24),
      child: Material(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(18),
        clipBehavior: Clip.antiAlias,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: maxWidth,
            maxHeight: maxHeight,
            minWidth: 280,
            minHeight: 320,
          ),
          child: SizedBox(
            width: maxWidth,
            height: maxHeight * 0.92,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Column(
              children: [
                ColoredBox(
                  color: AppColors.primaryDark,
                  child: SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              widget.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontFamily: FontFamily.montserratSemiBold,
                                color: AppColors.white,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          _InvoicePdfHeaderIconButton(
                            tooltip: 'Download',
                            onPressed: _isBusy ? null : _onDownload,
                            child: _isDownloading
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppColors.white,
                                    ),
                                  )
                                : const Icon(
                                    Icons.download_rounded,
                                    color: AppColors.white,
                                  ),
                          ),
                          const SizedBox(width: 4),
                          _InvoicePdfHeaderIconButton(
                            tooltip: 'Share',
                            onPressed: _isBusy ? null : _onShare,
                            child: const Icon(
                              Icons.share_rounded,
                              color: AppColors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: ColoredBox(
                    color: AppColors.background,
                    child: hasLocalFile
                        ? SfPdfViewer.file(
                            localFile,
                            canShowScrollHead: true,
                            canShowScrollStatus: true,
                            enableDoubleTapZooming: true,
                          )
                        : (url.isNotEmpty
                              ? SfPdfViewer.network(
                                  url,
                                  canShowScrollHead: true,
                                  canShowScrollStatus: true,
                                  enableDoubleTapZooming: true,
                                )
                              : Center(
                                  child: Text(
                                    'PDF not available',
                                    style: TextStyle(
                                      fontFamily: FontFamily.montserratMedium,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                )),
                  ),
                ),
                ColoredBox(
                  color: AppColors.surface,
                  child: SafeArea(
                    top: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
                      child: SizedBox(
                        width: double.infinity,
                        height: 44,
                        child: FilledButton.icon(
                          onPressed: _isBusy
                              ? null
                              : () => Navigator.of(context).pop(),
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: AppColors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          icon: const Icon(Icons.close_rounded, size: 18),
                          label: Text(
                            'Close',
                            style: TextStyle(
                              fontFamily: FontFamily.montserratSemiBold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
                if (_isSharing)
                  const FullScreenLoader(message: 'Preparing to share...'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<String?> _ensureLocalFile({
    required bool showSuccessToast,
    bool forceDownload = false,
  }) async {
    if (!forceDownload) {
      final existing = _localPath?.trim() ?? '';
      if (existing.isNotEmpty && File(existing).existsSync()) {
        return existing;
      }
    }

    final url = widget.networkUrl.trim();
    if (url.isEmpty) {
      if (mounted) {
        Utils().showToast(
          context: context,
          title: 'Error',
          message: 'PDF url not found.',
          isSuccess: false,
        );
      }
      return null;
    }

    try {
      final tempDir = await getTemporaryDirectory();
      final tempPath =
          '${tempDir.path}${Platform.pathSeparator}${widget.fileName}';
      final path = await ApiService.shared().downloadFile(
        url: url,
        savePath: tempPath,
      );
      if (!mounted) return path;
      setState(() => _localPath = path);

      // Explicit Download action → public Downloads on Android.
      if (forceDownload && Platform.isAndroid) {
        await PdfFileHelper.saveToPublicDownloads(
          sourcePath: path,
          fileName: widget.fileName,
        );
        if (showSuccessToast && mounted) {
          Utils().showToast(
            context: context,
            title: 'Success',
            message: 'PDF saved to Downloads.',
            isSuccess: true,
          );
        }
      } else if (showSuccessToast &&
          mounted &&
          !PdfFileHelper.needsUserSavePicker) {
        Utils().showToast(
          context: context,
          title: 'Success',
          message: 'PDF downloaded successfully.',
          isSuccess: true,
        );
      }
      return path;
    } catch (error) {
      if (mounted) {
        Utils().showToast(
          context: context,
          title: 'Error',
          message: PdfFileHelper.errorMessage(error),
          isSuccess: false,
        );
      }
      return null;
    }
  }

  Future<void> _onDownload() async {
    setState(() => _isDownloading = true);
    try {
      final path = await _ensureLocalFile(
        showSuccessToast: true,
        forceDownload: true,
      );
      if (path == null || !mounted) return;

      // iPhone cannot write to system Downloads; open share sheet so user
      // can choose Save to Files → Downloads / On My iPhone.
      if (PdfFileHelper.needsUserSavePicker) {
        await PdfFileHelper.shareLocalFile(
          context: context,
          filePath: path,
          title: widget.title,
        );
      }
    } finally {
      if (mounted) setState(() => _isDownloading = false);
    }
  }

  Future<void> _onShare() async {
    setState(() => _isSharing = true);
    try {
      final path = await _ensureLocalFile(showSuccessToast: false);
      if (path == null || !mounted) return;

      await PdfFileHelper.shareLocalFile(
        context: context,
        filePath: path,
        title: widget.title,
      );
    } catch (_) {
      if (mounted) {
        Utils().showToast(
          context: context,
          title: 'Error',
          message: 'Unable to share PDF. Please try again.',
          isSuccess: false,
        );
      }
    } finally {
      if (mounted) setState(() => _isSharing = false);
    }
  }
}

class _InvoicePdfHeaderIconButton extends StatelessWidget {
  const _InvoicePdfHeaderIconButton({
    required this.tooltip,
    required this.onPressed,
    required this.child,
  });

  final String tooltip;
  final VoidCallback? onPressed;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.white.withValues(alpha: 0.12),
      shape: const CircleBorder(),
      child: IconButton(
        tooltip: tooltip,
        onPressed: onPressed,
        icon: child,
      ),
    );
  }
}

class _InvoicePrintFormatDialog extends StatelessWidget {
  const _InvoicePrintFormatDialog({required this.showSignatureAction});

  final bool showSignatureAction;

  @override
  Widget build(BuildContext context) {
    final maxWidth = MediaQuery.sizeOf(context).width - 48;

    return Consumer<InvoicePrintProvider>(
      builder: (context, provider, _) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          title: Text(
            'Print Invoice',
            style: TextStyle(
              fontFamily: FontFamily.montserratBold,
              color: AppColors.textPrimary,
              fontSize: 18,
            ),
          ),
          content: SizedBox(
            width: maxWidth.clamp(280, 380),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Print Format',
                  style: TextStyle(
                    fontFamily: FontFamily.montserratSemiBold,
                    color: AppColors.textPrimary,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<PrintTemplate>(
                  key: ValueKey(
                    '${provider.printOptions.length}-${provider.selectedPrint?.printId}',
                  ),
                  initialValue: provider.selectedPrint,
                  isExpanded: true,
                  icon: const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: AppColors.primary,
                    size: 20,
                  ),
                  decoration: InputDecoration(
                    hintText: provider.isLoadingPrintList
                        ? 'Loading...'
                        : 'Select print format',
                    errorText: provider.printListError,
                    filled: true,
                    fillColor: AppColors.white,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 14,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(
                        color: AppColors.secondary.withValues(alpha: 0.8),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(
                        color: AppColors.primary,
                        width: 1.4,
                      ),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: AppColors.error),
                    ),
                    focusedErrorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: AppColors.error),
                    ),
                  ),
                  items: provider.printOptions
                      .map(
                        (option) => DropdownMenuItem<PrintTemplate>(
                          value: option,
                          child: Text(
                            option.printName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: FontFamily.montserratMedium,
                              fontSize: 12,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: provider.isBusy
                      ? null
                      : (value) => provider.selectPrint(value),
                ),
                if (showSignatureAction) ...[
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          provider.hasSignature
                              ? 'Signature added'
                              : 'Add signature',
                          style: TextStyle(
                            fontFamily: FontFamily.montserratMedium,
                            color: provider.hasSignature
                                ? AppColors.success
                                : AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: provider.isBusy
                            ? null
                            : () => _openSignature(context, provider),
                        tooltip: 'Signature',
                        style: IconButton.styleFrom(
                          backgroundColor: AppColors.primary.withValues(
                            alpha: 0.1,
                          ),
                          foregroundColor: AppColors.primary,
                        ),
                        icon: provider.isUploadingSignature
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.primary,
                                ),
                              )
                            : Icon(
                                provider.hasSignature
                                    ? Icons.draw_rounded
                                    : Icons.gesture_rounded,
                              ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: provider.isBusy
                  ? null
                  : () => Navigator.pop(context, false),
              child: Text(
                'Cancel',
                style: TextStyle(fontFamily: FontFamily.montserratMedium),
              ),
            ),
            FilledButton(
              onPressed: provider.isBusy
                  ? null
                  : () => _onPrintPressed(context, provider),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
              ),
              child: Text(
                'Print',
                style: TextStyle(fontFamily: FontFamily.montserratSemiBold),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _openSignature(
    BuildContext context,
    InvoicePrintProvider provider,
  ) async {
    final signature = await showDialog<Uint8List>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _InvoiceDetailSignatureDialog(),
    );
    if (signature == null || !context.mounted) return;

    final uploaded = await provider.uploadSignature(
      signatureBytes: signature,
      fileName: 'signature.png',
    );
    if (!context.mounted) return;

    if (!uploaded) {
      Utils().showToast(
        context: context,
        title: 'Error',
        message: provider.signatureMessage?.trim().isNotEmpty == true
            ? provider.signatureMessage!
            : 'Signature upload failed.',
        isSuccess: false,
      );
      return;
    }

    final okMessage = provider.signatureMessage?.trim();
    Utils().showToast(
      context: context,
      title: 'Success',
      message: (okMessage != null && okMessage.isNotEmpty)
          ? okMessage
          : 'Signature uploaded.',
      isSuccess: true,
    );

    // Same as before: after signature success, continue to PDF view.
    if (provider.selectedPrint == null) {
      Utils().showToast(
        context: context,
        title: 'Error',
        message: 'Please select a print format.',
        isSuccess: false,
      );
      return;
    }
    if (!context.mounted) return;
    Navigator.pop(context, true);
  }

  void _onPrintPressed(BuildContext context, InvoicePrintProvider provider) {
    if (provider.selectedPrint == null) {
      Utils().showToast(
        context: context,
        title: 'Error',
        message: 'Please select a print format.',
        isSuccess: false,
      );
      return;
    }
    if (showSignatureAction && !provider.hasSignature) {
      Utils().showToast(
        context: context,
        title: 'Error',
        message: 'Please add signature before printing.',
        isSuccess: false,
      );
      return;
    }
    Navigator.pop(context, true);
  }
}

class _InvoiceDetailSignatureDialog extends StatefulWidget {
  const _InvoiceDetailSignatureDialog();

  @override
  State<_InvoiceDetailSignatureDialog> createState() =>
      _InvoiceDetailSignatureDialogState();
}

class _InvoiceDetailSignatureDialogState
    extends State<_InvoiceDetailSignatureDialog> {
  final GlobalKey _signatureKey = GlobalKey();
  final List<Offset?> _points = [];
  bool _isSaving = false;

  @override
  Widget build(BuildContext context) {
    final maxWidth = MediaQuery.sizeOf(context).width - 48;

    return AlertDialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      title: Text(
        'Draw Signature',
        style: TextStyle(
          fontFamily: FontFamily.montserratBold,
          color: AppColors.textPrimary,
          fontSize: 18,
        ),
      ),
      content: SizedBox(
        width: maxWidth.clamp(280, 360),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Use your finger to sign inside the box.',
                style: TextStyle(
                  fontFamily: FontFamily.montserratRegular,
                  color: AppColors.textSecondary,
                  fontSize: 11,
                ),
              ),
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                height: 150,
                decoration: BoxDecoration(
                  color: const Color(0xFFF7F3EC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.primaryLight),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      const ColoredBox(color: Color(0xFFF7F3EC)),
                      Positioned.fill(
                        child: RepaintBoundary(
                          key: _signatureKey,
                          child: ColoredBox(
                            color: Colors.transparent,
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onPanStart: (details) {
                                setState(
                                  () => _points.add(details.localPosition),
                                );
                              },
                              onPanUpdate: (details) {
                                setState(
                                  () => _points.add(details.localPosition),
                                );
                              },
                              onPanEnd: (_) {
                                setState(() => _points.add(null));
                              },
                              child: CustomPaint(
                                painter: _InvoiceDetailSignaturePainter(_points),
                                child: const SizedBox.expand(),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.pop(context),
          child: Text(
            'Cancel',
            style: TextStyle(fontFamily: FontFamily.montserratMedium),
          ),
        ),
        TextButton(
          onPressed: _isSaving || _points.isEmpty
              ? null
              : () => setState(() => _points.clear()),
          child: Text(
            'Clear',
            style: TextStyle(fontFamily: FontFamily.montserratMedium),
          ),
        ),
        FilledButton(
          onPressed: _isSaving || _points.isEmpty ? null : _saveSignature,
          style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
          child: _isSaving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    color: AppColors.white,
                    strokeWidth: 2,
                  ),
                )
              : Text(
                  'Save',
                  style: TextStyle(fontFamily: FontFamily.montserratSemiBold),
                ),
        ),
      ],
    );
  }

  Future<void> _saveSignature() async {
    setState(() => _isSaving = true);
    await WidgetsBinding.instance.endOfFrame;
    final boundary =
        _signatureKey.currentContext?.findRenderObject()
            as RenderRepaintBoundary?;
    final image = await boundary?.toImage(pixelRatio: 3);
    final data = await image?.toByteData(format: ui.ImageByteFormat.png);
    if (!mounted) return;
    Navigator.pop(context, data?.buffer.asUint8List());
  }
}

class _InvoiceDetailSignaturePainter extends CustomPainter {
  const _InvoiceDetailSignaturePainter(this.points);

  final List<Offset?> points;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    for (var index = 0; index < points.length - 1; index++) {
      final current = points[index];
      final next = points[index + 1];
      if (current != null && next != null) {
        canvas.drawLine(current, next, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _InvoiceDetailSignaturePainter oldDelegate) =>
      true;
}

