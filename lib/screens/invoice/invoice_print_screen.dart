import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:provider/provider.dart';

import '../../models/invoice.dart';
import '../../providers/invoice_print_provider.dart';
import '../../utills/app_colors.dart';
import '../../utills/app_font.dart';
import '../../utills/app_images.dart';
import '../../widgets/app_loader.dart';
import '../pdf/pdf_preview_screen.dart';

class InvoicePrintScreen extends StatelessWidget {
  const InvoicePrintScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<InvoicePrintProvider>(
      builder: (context, provider, child) {
        return Stack(
          fit: StackFit.expand,
          children: [
            Scaffold(
              backgroundColor: AppColors.background,
              appBar: _buildAppBar(context, provider.invoice.id),
              body: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 28),
                child: Column(
                  children: [
                    _PrintHeader(provider: provider),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Select Diamonds',
                            style: TextStyle(
                              fontFamily: FontFamily.montserratBold,
                              color: AppColors.textPrimary,
                              fontSize: 17,
                            ),
                          ),
                        ),
                        TextButton.icon(
                          onPressed: provider.toggleSelectAll,
                          icon: Icon(
                            provider.isAllSelected
                                ? Icons.check_box_rounded
                                : Icons.check_box_outline_blank_rounded,
                            size: 19,
                          ),
                          label: Text(
                            provider.isAllSelected ? 'Clear All' : 'Select All',
                            style: TextStyle(
                              fontFamily: FontFamily.montserratSemiBold,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ...provider.invoice.items.map(
                      (item) => Padding(
                        padding: const EdgeInsets.only(bottom: 11),
                        child: _SelectableItemCard(
                          item: item,
                          selected: provider.selectedItemIds.contains(item.id),
                          onTap: () => provider.toggleItem(item.id),
                        ),
                      ),
                    ),
                    if (provider.errorMessage != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        provider.errorMessage!,
                        style: TextStyle(
                          fontFamily: FontFamily.montserratMedium,
                          color: AppColors.error,
                          fontSize: 11,
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    _SignatureSection(provider: provider),
                  ],
                ),
              ),
              bottomNavigationBar: SafeArea(
                top: false,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryDark.withValues(alpha: 0.1),
                        blurRadius: 22,
                        offset: const Offset(0, -6),
                      ),
                    ],
                  ),
                  child: Builder(
                    builder: (buttonContext) {
                      return SizedBox(
                        height: 54,
                        child: FilledButton.icon(
                          onPressed: provider.isGenerating
                              ? null
                              : () => _generatePdf(buttonContext, provider),
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            disabledBackgroundColor: AppColors.primaryLight,
                            foregroundColor: AppColors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          icon: const Icon(Icons.picture_as_pdf_outlined),
                          label: Text(
                            'GENERATE & DOWNLOAD INVOICE',
                            style: TextStyle(
                              fontFamily: FontFamily.montserratSemiBold,
                              fontSize: 11,
                              letterSpacing: 0.7,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
            if (provider.isGenerating)
              const FullScreenLoader(message: 'Generating invoice PDF...'),
          ],
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, String invoiceId) {
    return AppBar(
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
            'Print Invoice',
            style: TextStyle(
              fontFamily: FontFamily.montserratBold,
              color: AppColors.white,
              fontSize: 19,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            invoiceId,
            style: TextStyle(
              fontFamily: FontFamily.montserratMedium,
              color: AppColors.white.withValues(alpha: 0.68),
              fontSize: 9.5,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _generatePdf(
    BuildContext context,
    InvoicePrintProvider provider,
  ) async {
    final renderBox = context.findRenderObject() as RenderBox?;
    final origin = renderBox == null
        ? null
        : renderBox.localToGlobal(Offset.zero) & renderBox.size;
    final success = await provider.generatePdf(sharePositionOrigin: origin);

    if (!context.mounted || !success) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Invoice PDF saved successfully',
          style: TextStyle(fontFamily: FontFamily.montserratMedium),
        ),
        backgroundColor: AppColors.primaryDark,
      ),
    );

    final path = provider.lastSavedPath;
    if (path == null || !context.mounted) return;

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PdfPreviewScreen(filePath: path, title: 'Invoice PDF'),
      ),
    );
  }
}

class _PrintHeader extends StatelessWidget {
  const _PrintHeader({required this.provider});

  final InvoicePrintProvider provider;

  @override
  Widget build(BuildContext context) {
    final count = provider.selectedItemIds.length;
    final total = provider.invoice.items.length;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primaryDark, AppColors.primary, Color(0xFF14634E)],
        ),
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.2),
            blurRadius: 22,
            offset: const Offset(0, 11),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: AppColors.accent,
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Icon(
              Icons.receipt_long_outlined,
              color: AppColors.primaryDark,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Choose diamonds for invoice',
                  style: TextStyle(
                    fontFamily: FontFamily.montserratBold,
                    color: AppColors.white,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 9),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    minHeight: 5,
                    value: total == 0 ? 0 : count / total,
                    backgroundColor: AppColors.white.withValues(alpha: 0.14),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      AppColors.accent,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '$count of $total selected',
                  style: TextStyle(
                    fontFamily: FontFamily.montserratRegular,
                    color: AppColors.white.withValues(alpha: 0.75),
                    fontSize: 9,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SelectableItemCard extends StatelessWidget {
  const _SelectableItemCard({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final InvoiceItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? AppColors.primary.withValues(alpha: 0.07)
          : AppColors.surface,
      borderRadius: BorderRadius.circular(19),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(19),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(19),
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.secondary,
              width: selected ? 1.4 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: selected
                      ? AppColors.primary
                      : AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: selected
                    ? const Icon(
                        Icons.check_rounded,
                        color: AppColors.white,
                        size: 20,
                      )
                    : Padding(
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
                      item.stockNumber,
                      style: TextStyle(
                        fontFamily: FontFamily.montserratSemiBold,
                        color: AppColors.textPrimary,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${item.shape} • ${item.carat.toStringAsFixed(2)} ct'
                      ' • ${item.color}/${item.clarity}',
                      style: TextStyle(
                        fontFamily: FontFamily.montserratRegular,
                        color: AppColors.textSecondary,
                        fontSize: 9,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '\$${item.total.toStringAsFixed(2)}',
                style: TextStyle(
                  fontFamily: FontFamily.montserratBold,
                  color: AppColors.primaryDark,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SignatureSection extends StatelessWidget {
  const _SignatureSection({required this.provider});

  final InvoicePrintProvider provider;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(21),
        border: Border.all(color: AppColors.secondary),
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
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, AppColors.primaryDark],
                  ),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Icon(
                  Icons.draw_outlined,
                  color: AppColors.secondary,
                  size: 21,
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Authorized Signature',
                      style: TextStyle(
                        fontFamily: FontFamily.montserratSemiBold,
                        color: AppColors.textPrimary,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Add a signature to the generated invoice',
                      style: TextStyle(
                        fontFamily: FontFamily.montserratRegular,
                        color: AppColors.textSecondary,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (provider.hasSignature) ...[
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              height: 90,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.secondary),
              ),
              child: Image.memory(provider.signature!, fit: BoxFit.contain),
            ),
          ],
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _openSignaturePad(context),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(13),
                    ),
                  ),
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: Text(
                    provider.hasSignature
                        ? 'Update Signature'
                        : 'Add Signature',
                    style: TextStyle(
                      fontFamily: FontFamily.montserratSemiBold,
                      fontSize: 11,
                    ),
                  ),
                ),
              ),
              if (provider.hasSignature) ...[
                const SizedBox(width: 10),
                IconButton(
                  onPressed: provider.clearSignature,
                  icon: const Icon(
                    Icons.delete_outline_rounded,
                    color: AppColors.error,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _openSignaturePad(BuildContext context) async {
    final signature = await showDialog<Uint8List>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _SignatureDialog(),
    );
    if (signature != null) provider.setSignature(signature);
  }
}

class _SignatureDialog extends StatefulWidget {
  const _SignatureDialog();

  @override
  State<_SignatureDialog> createState() => _SignatureDialogState();
}

class _SignatureDialogState extends State<_SignatureDialog> {
  final GlobalKey _signatureKey = GlobalKey();
  final List<Offset?> _points = [];
  bool _isSaving = false;

  @override
  Widget build(BuildContext context) {
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
        width: 360,
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
            RepaintBoundary(
              key: _signatureKey,
              child: Container(
                height: 190,
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.primaryLight),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onPanStart: (details) =>
                        setState(() => _points.add(details.localPosition)),
                    onPanUpdate: (details) =>
                        setState(() => _points.add(details.localPosition)),
                    onPanEnd: (_) => setState(() => _points.add(null)),
                    child: CustomPaint(
                      painter: _SignaturePainter(_points),
                      size: Size.infinite,
                    ),
                  ),
                ),
              ),
            ),
          ],
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

class _SignaturePainter extends CustomPainter {
  const _SignaturePainter(this.points);

  final List<Offset?> points;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.textPrimary
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
  bool shouldRepaint(covariant _SignaturePainter oldDelegate) => true;
}
