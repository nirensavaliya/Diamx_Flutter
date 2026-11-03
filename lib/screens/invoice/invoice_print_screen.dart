import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:provider/provider.dart';

import '../../models/invoice.dart';
import '../../models/print_template.dart';
import '../../providers/invoice_print_provider.dart';
import '../../utills/app_colors.dart';
import '../../utills/app_font.dart';
import '../../utills/app_images.dart';
import '../../utills/app_toast.dart';
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
              appBar: AppBar(
                toolbarHeight: 90,
                backgroundColor: AppColors.primaryDark,
                surfaceTintColor: Colors.transparent,
                foregroundColor: AppColors.white,
                elevation: 0,
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
                        right: -24,
                        top: -28,
                        child: Icon(
                          Icons.picture_as_pdf_outlined,
                          color: AppColors.white.withValues(alpha: 0.08),
                          size: 122,
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
                        icon: const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          size: 18,
                        ),
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
               /*     const SizedBox(height: 4),
                    Text(
                      provider.invoice.id,
                      style: TextStyle(
                        fontFamily: FontFamily.montserratRegular,
                        color: AppColors.white.withValues(alpha: 0.68),
                        fontSize: 9.5,
                      ),
                    ),*/
                  ],
                ),
              ),
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
                            size: 20,
                          ),
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.primary,
                            backgroundColor: AppColors.primary.withValues(
                              alpha: 0.08,
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 11,
                              vertical: 7,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
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
                    _PrintTemplateDropdown(provider: provider),
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
                  child: Builder(
                    builder: (buttonContext) {
                      return SizedBox(
                        height: 54,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                AppColors.primary,
                                AppColors.primaryDark,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.2),
                                blurRadius: 14,
                                offset: const Offset(0, 7),
                              ),
                            ],
                          ),
                          child: FilledButton.icon(
                            onPressed: provider.isBusy
                                ? null
                                : () => _generatePdf(buttonContext, provider),
                            style: FilledButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              disabledBackgroundColor: AppColors.primaryLight,
                              shadowColor: Colors.transparent,
                              foregroundColor: AppColors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            icon: const Icon(
                              Icons.picture_as_pdf_outlined,
                              size: 20,
                            ),
                            label: Text(
                              'GENERATE & DOWNLOAD PDF',
                              style: TextStyle(
                                fontFamily: FontFamily.montserratSemiBold,
                                fontSize: 11,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
            if (provider.isLoadingPrintList)
              const FullScreenLoader(message: 'Loading print options...'),
            if (provider.isGenerating)
              const FullScreenLoader(message: 'Generating PDF...'),
            if (provider.isUploadingSignature)
              const FullScreenLoader(message: 'Uploading signature...'),
          ],
        );
      },
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

    if (!context.mounted) return;

    if (!success) {
      final message = provider.errorMessage?.trim();
      Utils().showToast(
        context: context,
        title: 'Error',
        message: (message != null && message.isNotEmpty)
            ? message
            : 'Unable to generate PDF. Please try again.',
        isSuccess: false,
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          provider.lastSavedPath != null
              ? 'PDF saved successfully'
              : 'Opening PDF...',
          style: TextStyle(fontFamily: FontFamily.montserratMedium),
        ),
        backgroundColor: AppColors.primaryDark,
      ),
    );

    final path = provider.lastSavedPath;
    final url = provider.lastPdfUrl;
    if ((path == null || path.isEmpty) && (url == null || url.isEmpty)) {
      return;
    }
    if (!context.mounted) return;

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PdfPreviewScreen(
          filePath: path,
          networkUrl: url,
          title: 'Invoice PDF',
        ),
      ),
    );
  }
}

class _PrintHeader extends StatelessWidget {
  const _PrintHeader({required this.provider});

  final InvoicePrintProvider provider;

  @override
  Widget build(BuildContext context) {
    final total = provider.invoice.items.length;
    final selected = provider.selectedItemIds.length;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primaryDark, AppColors.primary, Color(0xFF14634E)],
          stops: [0, 0.62, 1],
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
      child: Stack(
        children: [
          Positioned(
            right: -22,
            bottom: -32,
            child: Icon(
              Icons.receipt_long_outlined,
              color: AppColors.white.withValues(alpha: 0.08),
              size: 115,
            ),
          ),
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: AppColors.accent,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryDark.withValues(alpha: 0.22),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.picture_as_pdf_outlined,
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
                      provider.invoice.id,
                      style: TextStyle(
                        fontFamily: FontFamily.montserratSemiBold,
                        color: AppColors.secondary,
                        fontSize: 9,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'Choose diamonds for your PDF',
                      style: TextStyle(
                        fontFamily: FontFamily.montserratBold,
                        color: AppColors.white,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              minHeight: 5,
                              value: total == 0 ? 0 : selected / total,
                              backgroundColor: AppColors.white.withValues(
                                alpha: 0.14,
                              ),
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                AppColors.accent,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 9),
                        Text(
                          '$selected/$total',
                          style: TextStyle(
                            fontFamily: FontFamily.montserratSemiBold,
                            color: AppColors.white.withValues(alpha: 0.82),
                            fontSize: 9,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
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
              color: selected
                  ? AppColors.primary
                  : AppColors.secondary.withValues(alpha: 0.9),
              width: selected ? 1.4 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: selected
                    ? AppColors.primary.withValues(alpha: 0.1)
                    : AppColors.primaryDark.withValues(alpha: 0.04),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
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

class _PrintTemplateDropdown extends StatelessWidget {
  const _PrintTemplateDropdown({required this.provider});

  final InvoicePrintProvider provider;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(21),
        border: Border.all(color: AppColors.secondary.withValues(alpha: 0.9)),
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
        ],
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
        border: Border.all(color: AppColors.secondary.withValues(alpha: 0.9)),
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
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
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
                      'Digital Signature',
                      style: TextStyle(
                        fontFamily: FontFamily.montserratSemiBold,
                        color: AppColors.textPrimary,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Draw signature, then tap Save to upload',
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
                  onPressed: provider.isBusy
                      ? null
                      : () => _openSignaturePad(context),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    backgroundColor: AppColors.primary.withValues(alpha: 0.04),
                    side: BorderSide(
                      color: AppColors.primary.withValues(alpha: 0.55),
                    ),
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
                  onPressed: provider.isBusy ? null : provider.clearSignature,
                  tooltip: 'Remove signature',
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

    if (signature == null || !context.mounted) return;

    final success = await provider.uploadSignature(
      signatureBytes: signature,
      fileName: 'signature.png',
    );
    if (!context.mounted) return;

    final message = provider.signatureMessage;
    if (message == null || message.isEmpty) return;

    Utils().showToast(
      context: context,
      title: success ? 'Success' : 'Error',
      message: message,
      isSuccess: success,
    );
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
            // Rectangular pad: border/bg for UI only; capture layer is transparent.
            Container(
              width: 360,
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
                              painter: _SignaturePainter(_points),
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
  bool shouldRepaint(covariant _SignaturePainter oldDelegate) => true;
}

