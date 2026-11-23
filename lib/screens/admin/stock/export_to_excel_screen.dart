import 'package:flutter/material.dart';

import '../../../utills/app_colors.dart';
import '../../../utills/app_font.dart';
import '../dashboard/CommonScaffold.dart';

class ExportToExcelScreen extends StatefulWidget {
  final VoidCallback? onBackTap;
  final VoidCallback? onDownloadTap;
  final VoidCallback? onShareTap;
  final int selectedRecords;

  const ExportToExcelScreen({
    super.key,
    this.onBackTap,
    this.onDownloadTap,
    this.onShareTap,
    this.selectedRecords = 245,
  });

  @override
  State<ExportToExcelScreen> createState() => _ExportToExcelScreenState();
}

class _ExportToExcelScreenState extends State<ExportToExcelScreen> {
  final TextEditingController _expiryController = TextEditingController(
    text: '07/12/2026',
  );

  final TextEditingController _passwordController = TextEditingController(
    text: '1234',
  );

  bool _isPasswordVisible = false;

  @override
  void dispose() {
    _expiryController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _selectExpiryDate() async {
    final now = DateTime.now();

    final parts = _expiryController.text.split('/');
    DateTime initialDate = DateTime(now.year, now.month, now.day);

    if (parts.length == 3) {
      final day = int.tryParse(parts[0]);
      final month = int.tryParse(parts[1]);
      final year = int.tryParse(parts[2]);

      if (day != null && month != null && year != null) {
        initialDate = DateTime(year, month, day);
      }
    }

    if (initialDate.isBefore(now)) {
      initialDate = now;
    }

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: DateTime(now.year + 5),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: AppColors.primaryDark,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null) {
      setState(() {
        _expiryController.text =
            '${pickedDate.day.toString().padLeft(2, '0')}/'
            '${pickedDate.month.toString().padLeft(2, '0')}/'
            '${pickedDate.year}';
      });
    }
  }

  void _downloadExcel() {
    if (widget.onDownloadTap != null) {
      widget.onDownloadTap!();
    } else {
      _showMessage('Connect your Excel export functionality.');
    }
  }

  void _shareLink() {
    if (widget.onShareTap != null) {
      widget.onShareTap!();
    } else {
      _showMessage('Connect your share link functionality.');
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontSize: 12)),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CommonScaffold(
      title: 'Export to Excel',
      showBack: true,
      onBackTap: widget.onBackTap,
      body: Container(
        color: AppColors.background,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
          children: [
            _buildSuccessHeader(),
            const SizedBox(height: 18),
            _buildDownloadButton(),
            const SizedBox(height: 9),
            _buildShareButton(),
            const SizedBox(height: 22),
            _buildShareSettingsTitle(),
            const SizedBox(height: 12),
            _buildExpiryDateField(),
            const SizedBox(height: 9),
            _buildPasswordField(),
            const SizedBox(height: 14),
            _buildInformationNote(),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccessHeader() {
    return Column(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: const BoxDecoration(
            color: Color(0xFF249B50),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.check_rounded, color: Colors.white, size: 32),
        ),
        const SizedBox(height: 8),
        Text(
          'Report Ready!',
          style: TextStyle(
            fontFamily: FontFamily.montserratBold,
            fontSize: 16,
            color: AppColors.primaryDark,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          '${widget.selectedRecords} records selected',
          style: TextStyle(
            fontFamily: FontFamily.montserratMedium,
            fontSize: 11.5,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildDownloadButton() {
    return SizedBox(
      height: 46,
      child: ElevatedButton(
        onPressed: _downloadExcel,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF249B50),
          foregroundColor: Colors.white,
          elevation: 2,
          shadowColor: const Color(0xFF249B50).withValues(alpha: 0.2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.download_rounded, size: 20),
            const SizedBox(width: 9),
            Text(
              'Download Excel',
              style: TextStyle(
                fontFamily: FontFamily.montserratBold,
                fontSize: 13,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShareButton() {
    return SizedBox(
      height: 46,
      child: OutlinedButton(
        onPressed: _shareLink,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primaryDark,
          side: BorderSide(color: AppColors.primary, width: 1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.share_rounded, size: 19, color: AppColors.primaryDark),
            const SizedBox(width: 9),
            Text(
              'Share Link',
              style: TextStyle(
                fontFamily: FontFamily.montserratBold,
                fontSize: 13,
                color: AppColors.primaryDark,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShareSettingsTitle() {
    return Text(
      'Share Settings',
      style: TextStyle(
        fontFamily: FontFamily.montserratBold,
        fontSize: 14,
        color: AppColors.primaryDark,
      ),
    );
  }

  Widget _buildExpiryDateField() {
    return Row(
      children: [
        SizedBox(
          width: 105,
          child: Text(
            'Expiry Date',
            style: TextStyle(
              fontFamily: FontFamily.montserratMedium,
              fontSize: 11,
              color: AppColors.primaryDark,
            ),
          ),
        ),
        Expanded(
          child: _buildInputContainer(
            child: TextField(
              controller: _expiryController,
              readOnly: true,
              onTap: _selectExpiryDate,
              style: TextStyle(
                fontFamily: FontFamily.montserratSemiBold,
                fontSize: 12,
                color: AppColors.primaryDark,
              ),
              decoration: InputDecoration(
                isDense: true,
                border: InputBorder.none,
                prefixIcon: Icon(
                  Icons.calendar_month_rounded,
                  size: 17,
                  color: AppColors.primaryDark,
                ),
                prefixIconConstraints: const BoxConstraints(
                  minWidth: 28,
                  minHeight: 30,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordField() {
    return Row(
      children: [
        SizedBox(
          width: 105,
          child: Text(
            'Password\n(Optional)',
            style: TextStyle(
              fontFamily: FontFamily.montserratMedium,
              fontSize: 11,
              height: 1.4,
              color: AppColors.primaryDark,
            ),
          ),
        ),
        Expanded(
          child: _buildInputContainer(
            child: TextField(
              controller: _passwordController,
              obscureText: !_isPasswordVisible,
              style: TextStyle(
                fontFamily: FontFamily.montserratSemiBold,
                fontSize: 12,
                color: AppColors.primaryDark,
              ),
              decoration: InputDecoration(
                isDense: true,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                suffixIcon: IconButton(
                  onPressed: () {
                    setState(() {
                      _isPasswordVisible = !_isPasswordVisible;
                    });
                  },
                  icon: Icon(
                    _isPasswordVisible
                        ? Icons.visibility_off_rounded
                        : Icons.visibility_rounded,
                    size: 17,
                    color: AppColors.primaryDark,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 35,
                    minHeight: 35,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInputContainer({required Widget child}) {
    return Container(
      height: 42,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.secondary.withValues(alpha: 0.85)),
      ),
      child: child,
    );
  }

  Widget _buildInformationNote() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.info_rounded, size: 17, color: Color(0xFF2677C9)),
        const SizedBox(width: 9),
        Expanded(
          child: Text(
            'Share link will include selected records only.',
            style: TextStyle(
              fontFamily: FontFamily.montserratMedium,
              fontSize: 10.5,
              height: 1.4,
              color: AppColors.primaryDark,
            ),
          ),
        ),
      ],
    );
  }
}
