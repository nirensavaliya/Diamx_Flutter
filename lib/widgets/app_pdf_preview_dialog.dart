import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

import '../services/api_service.dart';
import '../utills/app_colors.dart';
import '../utills/app_font.dart';
import '../utills/app_toast.dart';
import '../utills/pdf_file_helper.dart';
import 'app_loader.dart';

/// Full-screen-ish dialog to preview a remote PDF with download / share actions.
class AppPdfPreviewDialog extends StatefulWidget {
  const AppPdfPreviewDialog({
    super.key,
    required this.networkUrl,
    required this.fileName,
    required this.title,
  });

  final String networkUrl;
  final String fileName;
  final String title;

  @override
  State<AppPdfPreviewDialog> createState() => _AppPdfPreviewDialogState();
}

class _AppPdfPreviewDialogState extends State<AppPdfPreviewDialog> {
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
                              _PdfHeaderIconButton(
                                tooltip: 'Download',
                                onPressed: _isBusy ? null : _onDownload,
                                child: const Icon(
                                  Icons.download_rounded,
                                  color: AppColors.white,
                                ),
                              ),
                              const SizedBox(width: 4),
                              _PdfHeaderIconButton(
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
                                          fontFamily:
                                              FontFamily.montserratMedium,
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
                if (_isDownloading)
                  const FullScreenLoader(message: 'Downloading PDF...'),
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

class _PdfHeaderIconButton extends StatelessWidget {
  const _PdfHeaderIconButton({
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
