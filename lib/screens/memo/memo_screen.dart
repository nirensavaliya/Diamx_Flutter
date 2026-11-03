import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/memo.dart';
import '../../providers/memo_print_provider.dart';
import '../../providers/memo_provider.dart';
import '../../routes/app_routes.dart';
import '../../utills/app_colors.dart';
import '../../utills/app_font.dart';
import '../../utills/app_images.dart';
import '../../utills/app_toast.dart';
import '../../widgets/app_list_shimmer.dart';
import '../../widgets/app_loader.dart';
import '../../widgets/app_party_dropdown.dart';
import '../../widgets/app_pdf_preview_dialog.dart';
import '../../widgets/delivery_info_dialog.dart';

class MemoScreen extends StatefulWidget {
  const MemoScreen({super.key});

  @override
  State<MemoScreen> createState() => _MemoScreenState();
}

class _MemoScreenState extends State<MemoScreen> {
  String? _downloadingMemoId;

  bool _isDelivered(Memo memo) {
    final raw = memo.memoStatusRaw.trim().toUpperCase();
    if (raw.contains('DELIVERED')) return true;
    if (raw.contains('PENDING')) return false;
    return memo.status == MemoStatus.dispatched;
  }

  Future<void> _downloadDeliveredPdf(Memo memo) async {
    if (_downloadingMemoId != null) return;

    setState(() => _downloadingMemoId = memo.id);
    final printProvider = MemoPrintProvider(memo, bootstrap: false);
    if (memo.diamonds.isNotEmpty) {
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

      final safeId = memo.id.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
      final fileName = 'Diamx_${safeId}_Memo.pdf';
      if (!mounted) return;

      setState(() => _downloadingMemoId = null);

      await showDialog<void>(
        context: context,
        barrierDismissible: true,
        builder: (_) => AppPdfPreviewDialog(
          networkUrl: url,
          fileName: fileName,
          title: 'Memo PDF · ${memo.id}',
        ),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _downloadingMemoId = null);
      Utils().showToast(
        context: context,
        title: 'Error',
        message: error.toString().replaceFirst('Exception: ', ''),
        isSuccess: false,
      );
    } finally {
      printProvider.dispose();
      if (mounted && _downloadingMemoId != null) {
        setState(() => _downloadingMemoId = null);
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
        elevation: 0,
        centerTitle: false,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.primaryDark,
                AppColors.primary,
                AppColors.primaryLight,
              ],
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                right: -28,
                top: -16,
                child: Icon(
                  Icons.diamond_outlined,
                  size: 130,
                  color: AppColors.white.withValues(alpha: 0.08),
                ),
              ),
              Positioned(
                right: 70,
                bottom: -36,
                child: Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.accent.withValues(alpha: 0.12),
                      width: 18,
                    ),
                  ),
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
              'Memos',
              style: TextStyle(
                fontFamily: FontFamily.montserratBold,
                color: AppColors.white,
                fontSize: 20,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              'Track every diamond movement',
              style: TextStyle(
                fontFamily: FontFamily.montserratRegular,
                color: AppColors.white.withValues(alpha: 0.72),
                fontSize: 10.5,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
      body: Consumer<MemoProvider>(
        builder: (context, provider, child) {
          return Stack(
            fit: StackFit.expand,
            children: [
              NotificationListener<ScrollNotification>(
                onNotification: (notification) {
                  if (notification is! ScrollUpdateNotification) {
                    return false;
                  }
                  if (!provider.hasMore ||
                      provider.isLoadingMore ||
                      provider.isMemosLoading) {
                    return false;
                  }
                  final metrics = notification.metrics;
                  if (metrics.maxScrollExtent <= 0) return false;
                  if (metrics.pixels < metrics.maxScrollExtent - 240) {
                    return false;
                  }
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (!context.mounted) return;
                    final p = context.read<MemoProvider>();
                    if (p.hasMore && !p.isLoadingMore && !p.isMemosLoading) {
                      p.loadMoreMemos();
                    }
                  });
                  return false;
                },
                child: RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: () => context.read<MemoProvider>().loadMemos(
                        reset: true,
                        silent: true,
                      ),
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
                            child: _DeliveredStatusDropdown(provider: provider),
                          ),
                          const SizedBox(width: 10),
                          SizedBox(
                            width: 150,
                            child: PartyDropdown(provider: provider),
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
                            hintText: 'Search memo by name or number',
                            hintStyle: TextStyle(
                              fontFamily: FontFamily.montserratRegular,
                              color: AppColors.textSecondary,
                              fontSize: 11.5,
                            ),
                            prefixIcon: Padding(
                              padding: const EdgeInsets.all(10),
                              child: Container(
                                width: 34,
                                height: 34,
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(
                                    alpha: 0.09,
                                  ),
                                  borderRadius: BorderRadius.circular(11),
                                ),
                                child: const Icon(
                                  Icons.search_rounded,
                                  color: AppColors.primary,
                                  size: 19,
                                ),
                              ),
                            ),
                            filled: true,
                            fillColor: AppColors.surface,
                            contentPadding: const EdgeInsets.symmetric(
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
                              'All Memos',
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
                              color: AppColors.primary.withValues(alpha: 0.09),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '${provider.memos.length} RECORDS',
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
              if (provider.isMemosLoading && !provider.isLoadingMore)
                const AppListCardShimmer()
              else if (provider.memos.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Text(
                      provider.memosError ?? 'No matching memos found',
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
                    itemCount: provider.memos.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 14),
                    itemBuilder: (context, index) {
                      final memo = provider.memos[index];
                      return _MemoCard(
                        memo: memo,
                        isDelivered: _isDelivered(memo),
                        isDownloading: _downloadingMemoId == memo.id,
                        onDownload: () => _downloadDeliveredPdf(memo),
                        onTap: () async {
                          final result = await Navigator.pushNamed(
                            context,
                            AppRoutes.memoDetail,
                            arguments: {
                              'memo': memo,
                              'deliveredStatus':
                                  provider.selectedDeliveredStatus,
                            },
                          );
                          if (!context.mounted) return;
                          if (result == true) {
                            await context.read<MemoProvider>().loadMemos(
                                  reset: true,
                                  silent: true,
                                );
                          }
                        },
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
              ),
              if (provider.isPartiesLoading)
                const FullScreenLoader(message: 'Loading parties...'),
              if (provider.isMemosLoading &&
                  !provider.isLoadingMore &&
                  !provider.isPartiesLoading)
                const FullScreenLoader(message: 'Loading memos...'),
              if (_downloadingMemoId != null)
                const FullScreenLoader(message: 'Downloading PDF...'),
            ],
          );
        },
      ),
    );
  }
}

class _DeliveredStatusDropdown extends StatelessWidget {
  const _DeliveredStatusDropdown({required this.provider});

  final MemoProvider provider;

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
            borderSide: const BorderSide(
              color: AppColors.primary,
              width: 1.4,
            ),
          ),
        ),
        items: MemoProvider.deliveredStatusOptions
            .map(
              (status) => DropdownMenuItem<String>(
                value: status,
                child: Text(
                  status,
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
        onChanged: provider.isMemosLoading
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

  final MemoProvider provider;

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

class _MemoCard extends StatelessWidget {
  const _MemoCard({
    required this.memo,
    required this.onTap,
    required this.isDelivered,
    required this.isDownloading,
    required this.onDownload,
  });

  final Memo memo;
  final VoidCallback onTap;
  final bool isDelivered;
  final bool isDownloading;
  final VoidCallback onDownload;

  @override
  Widget build(BuildContext context) {
    final isPending = memo.status == MemoStatus.pending;
    final statusColor = isPending ? AppColors.accentDark : AppColors.success;
    final pcsValue = memo.totalPcs > 0
        ? _formatNumber(memo.totalPcs)
        : memo.pendingStone.toString();
    final finalAmt = memo.dollarPrice != 0
        ? memo.dollarPrice
        : (memo.total != 0 ? memo.total : memo.pendingAmount);

    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: statusColor.withValues(alpha: 0.22)),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryDark.withValues(alpha: 0.055),
                blurRadius: 17,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(19),
            child: Stack(
              children: [
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  child: Container(width: 4, color: statusColor),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 17, 16, 17),
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
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  AppColors.primary,
                                  AppColors.primaryDark,
                                ],
                              ),
                              borderRadius: BorderRadius.circular(13),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary.withValues(
                                    alpha: 0.18,
                                  ),
                                  blurRadius: 10,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(9),
                              child: Image.asset(
                                AppImages.imgDiamond,
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  memo.customerName.isNotEmpty
                                      ? memo.customerName
                                      : memo.name,
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
                                    memo.id,
                                    if (memo.dateLabel.isNotEmpty)
                                      memo.dateLabel,
                                  ].join(' · '),
                                  style: TextStyle(
                                    fontFamily: FontFamily.montserratMedium,
                                    color: AppColors.textSecondary,
                                    fontSize: 9.5,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                                if (memo.entryBy.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    'Entry By: ${memo.entryBy}',
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
                              border: Border.all(
                                color: statusColor.withValues(alpha: 0.18),
                              ),
                            ),
                            child: Text(
                              memo.statusLabel,
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
                                title: 'Delivery Info · ${memo.id}',
                                billingCompanyName: memo.billingCompanyName,
                                billingName: memo.billingName,
                                billingAddress: memo.billingAddress,
                                shippingCompanyName: memo.shippingCompanyName,
                                shippingAddress: memo.shippingAddress,
                                cityName: memo.cityName,
                                stateName: memo.stateName,
                                deliverBy: memo.deliverBy,
                                deliverAssignBy: memo.deliverAssignBy,
                                deliverDate: memo.deliverDate,
                                deliveredDate: memo.deliveredDate,
                                mailTelephoneNo: memo.mailTelephoneNo,
                                shipTelephoneNo: memo.shipTelephoneNo,
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
                        color: AppColors.secondary.withValues(alpha: 0.85),
                      ),
                      const SizedBox(height: 13),
                      Row(
                        children: [
                          Expanded(
                            child: _PriceColumn(
                              label: 'TotalCts',
                              value: memo.totalCarat.toStringAsFixed(3),
                            ),
                          ),
                          Expanded(
                            child: _PriceColumn(
                              label: 'Total Pcs',
                              value: pcsValue,
                            ),
                          ),
                          Expanded(
                            child: _PriceColumn(
                              label: 'Rate',
                              value: _formatNumber(memo.ppc),
                            ),
                          ),
                          Expanded(
                            child: _PriceColumn(
                              label: 'Final Amt',
                              value: _money(finalAmt, memo.currencyName),
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
                          Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.09),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.chevron_right_rounded,
                              color: AppColors.primary,
                              size: 20,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PriceColumn extends StatelessWidget {
  const _PriceColumn({
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
            fontSize: 8.5,
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
            fontSize: 10.5,
          ),
        ),
      ],
    );
  }
}

String _money(double value, [String currency = '']) {
  final code = currency.trim().isEmpty ? 'USD' : currency.trim();
  final symbol = code.toUpperCase() == 'USD' ? '\$' : '$code ';
  return '$symbol${value.toStringAsFixed(2)}';
}
