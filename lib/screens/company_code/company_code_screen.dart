import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../providers/company_code_provider.dart';
import '../../utills/app_colors.dart';
import '../../utills/app_font.dart';
import '../../utills/app_images.dart';
import '../../widgets/app_loader.dart';

class CompanyCodeScreen extends StatelessWidget {
  const CompanyCodeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
      child: Consumer<CompanyCodeProvider>(
        builder: (context, provider, child) {
          return Stack(
            fit: StackFit.expand,
            children: [
              Scaffold(
                backgroundColor: AppColors.background,
                body: SingleChildScrollView(
                  child: Column(
                    children: [
                      const _CompanyCodeHeader(),
                      Transform.translate(
                        offset: const Offset(0, -28),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: _CompanyCodeCard(provider: provider),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (provider.isLoading)
                const FullScreenLoader(message: 'Verifying product...'),
            ],
          );
        },
      ),
    );
  }
}

class _CompanyCodeHeader extends StatelessWidget {
  const _CompanyCodeHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 280,
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
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(36)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              AppImages.imgDiamond,
              width: 92,
              height: 68,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 14),
            Text(
              'DIAMX',
              style: TextStyle(
                fontFamily: FontFamily.montserratExtraBold,
                color: AppColors.white,
                fontSize: 30,
                fontWeight: FontWeight.w600,
                letterSpacing: 6,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'ELEGANCE IN EVERY DETAIL',
              style: TextStyle(
                fontFamily: FontFamily.montserratMedium,
                color: AppColors.secondary,
                fontSize: 10,
                letterSpacing: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CompanyCodeCard extends StatelessWidget {
  const _CompanyCodeCard({required this.provider});

  final CompanyCodeProvider provider;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryDark.withValues(alpha: 0.12),
            blurRadius: 30,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Enter Your Client Code',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: FontFamily.montserratBold,
              color: AppColors.textPrimary,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Enter the 6 character code provided by your company',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: FontFamily.montserratRegular,
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 26),
          TextField(
            controller: provider.clientCodeController,
            textAlign: TextAlign.center,
            textCapitalization: TextCapitalization.characters,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp('[a-zA-Z0-9]')),
              UpperCaseTextFormatter(),
            ],
            style: TextStyle(
              fontFamily: FontFamily.montserratSemiBold,
              color: AppColors.textPrimary,
              fontSize: 22,
              fontWeight: FontWeight.w600,
              letterSpacing: 10,
            ),
            decoration: InputDecoration(
              counterText: '',
              hintText: 'ABC123',
              hintStyle: TextStyle(
                fontFamily: FontFamily.montserratRegular,
                color: AppColors.textSecondary.withValues(alpha: 0.45),
                letterSpacing: 8,
              ),
              errorText: provider.errorMessage,
              filled: true,
              fillColor: AppColors.background,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 18,
                vertical: 18,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AppColors.primaryLight),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(
                  color: AppColors.primary,
                  width: 2,
                ),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AppColors.error),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AppColors.error, width: 2),
              ),
            ),
          ),
          const SizedBox(height: 22),
          FilledButton(
            onPressed: provider.isLoading
                ? null
                : () => provider.loadCompanies(context),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.white,
              disabledBackgroundColor: AppColors.primaryLight,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: Text(
              'Save Client Code',
              style: TextStyle(
                fontFamily: FontFamily.montserratSemiBold,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 14),
          // TextButton(
          //   onPressed: () {
          //     Navigator.pushReplacementNamed(context, AppRoutes.login);
          //   },
          //   child: Text(
          //     'Guest Login',
          //     style: TextStyle(
          //       fontFamily: FontFamily.montserratSemiBold,
          //       color: AppColors.primaryDark,
          //       decoration: TextDecoration.underline,
          //       fontSize: 16,
          //       fontWeight: FontWeight.w600,
          //     ),
          //   ),
          // ),
          // if (provider.companies.isNotEmpty) ...[
          //   const SizedBox(height: 26),
          //   const Divider(),
          //   const SizedBox(height: 18),
          //   Text(
          //     'Select Company',
          //     textAlign: TextAlign.center,
          //     style: TextStyle(
          //       fontFamily: FontFamily.montserratBold,
          //       color: AppColors.textPrimary,
          //       fontSize: 19,
          //       fontWeight: FontWeight.w700,
          //     ),
          //   ),
          //   const SizedBox(height: 16),
          //   DropdownButtonFormField<String>(
          //     initialValue: provider.selectedCompany,
          //     hint: Text(
          //       'Choose your company',
          //       style: TextStyle(fontFamily: FontFamily.montserratRegular),
          //     ),
          //     items: provider.companies
          //         .map(
          //           (company) => DropdownMenuItem(
          //             value: company,
          //             child: Text(
          //               company,
          //               style: TextStyle(
          //                 fontFamily: FontFamily.montserratMedium,
          //               ),
          //             ),
          //           ),
          //         )
          //         .toList(),
          //     onChanged: provider.selectCompany,
          //     decoration: InputDecoration(
          //       filled: true,
          //       fillColor: AppColors.background,
          //       border: OutlineInputBorder(
          //         borderRadius: BorderRadius.circular(14),
          //       ),
          //     ),
          //   ),
          //   const SizedBox(height: 18),
          //   FilledButton(
          //     onPressed: provider.selectedCompany == null
          //         ? null
          //         : () {
          //             Navigator.pushReplacementNamed(context, AppRoutes.login);
          //           },
          //     style: FilledButton.styleFrom(
          //       backgroundColor: AppColors.primaryDark,
          //       padding: const EdgeInsets.symmetric(vertical: 16),
          //       shape: RoundedRectangleBorder(
          //         borderRadius: BorderRadius.circular(14),
          //       ),
          //     ),
          //     child: Text(
          //       'Next',
          //       style: TextStyle(fontFamily: FontFamily.montserratSemiBold),
          //     ),
          //   ),
          // ],
        ],
      ),
    );
  }
}

class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return newValue.copyWith(text: newValue.text.toUpperCase());
  }
}
