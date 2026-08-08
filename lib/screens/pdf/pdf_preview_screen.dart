import 'dart:io';

import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

import '../../utills/app_colors.dart';
import '../../utills/app_font.dart';

class PdfPreviewScreen extends StatelessWidget {
  const PdfPreviewScreen({
    super.key,
    required this.filePath,
    this.title = 'PDF Preview',
  });

  final String filePath;
  final String title;

  @override
  Widget build(BuildContext context) {
    final file = File(filePath);
    final fileName = filePath.split(Platform.pathSeparator).last;

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
              fileName,
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
      body: !file.existsSync()
          ? Center(
              child: Text(
                'PDF file not found',
                style: TextStyle(
                  fontFamily: FontFamily.montserratMedium,
                  color: AppColors.textSecondary,
                ),
              ),
            )
          : SfPdfViewer.file(file),
    );
  }
}
