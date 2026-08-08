import 'dart:io';

import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

import '../../utills/app_colors.dart';
import '../../utills/app_font.dart';

class PdfPreviewScreen extends StatelessWidget {
  const PdfPreviewScreen({
    super.key,
    this.filePath,
    this.networkUrl,
    this.title = 'PDF Preview',
  }) : assert(
         filePath != null || networkUrl != null,
         'Provide filePath or networkUrl',
       );

  final String? filePath;
  final String? networkUrl;
  final String title;

  @override
  Widget build(BuildContext context) {
    final localPath = filePath?.trim() ?? '';
    final url = networkUrl?.trim() ?? '';
    final localFile = localPath.isNotEmpty ? File(localPath) : null;
    final hasLocalFile = localFile != null && localFile.existsSync();
    final subtitle = hasLocalFile
        ? localPath.split(Platform.pathSeparator).last
        : (url.isNotEmpty ? url : 'PDF');

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primaryDark,
        surfaceTintColor: Colors.transparent,
        foregroundColor: AppColors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontFamily: FontFamily.montserratSemiBold,
                fontSize: 16,
              ),
            ),
            Text(
              subtitle,
              style: TextStyle(
                fontFamily: FontFamily.montserratRegular,
                fontSize: 11,
                color: AppColors.secondary.withValues(alpha: 0.85),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
      body: url.isNotEmpty
          ? SfPdfViewer.network(url)
          : hasLocalFile
          ? SfPdfViewer.file(localFile)
          : Center(
              child: Text(
                'PDF file not found',
                style: TextStyle(
                  fontFamily: FontFamily.montserratMedium,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
    );
  }
}
