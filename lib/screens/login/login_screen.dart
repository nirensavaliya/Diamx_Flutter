import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../providers/login_provider.dart';
import '../../routes/app_routes.dart';
import '../../models/branch.dart';
import '../../utills/app_colors.dart';
import '../../utills/app_font.dart';
import '../../utills/app_images.dart';
import '../../widgets/app_loader.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
      child: Consumer<LoginProvider>(
        builder: (context, provider, child) {
          return Stack(
            fit: StackFit.expand,
            children: [
              Scaffold(
                backgroundColor: AppColors.background,
                body: SingleChildScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  child: Column(
                    children: [
                      const _LoginHeader(),
                      Transform.translate(
                        offset: const Offset(0, -42),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: _LoginCard(provider: provider),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (provider.isLoading)
                const FullScreenLoader(message: 'Signing you in...'),
              if (provider.isBranchesLoading && !provider.isLoading)
                const FullScreenLoader(message: 'Loading branches...'),
            ],
          );
        },
      ),
    );
  }
}

class _LoginHeader extends StatelessWidget {
  const _LoginHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 320,
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
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(42)),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 92,
              height: 92,
              decoration: BoxDecoration(
                color: AppColors.white.withValues(alpha: 0.13),
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.white.withValues(alpha: 0.45),
                ),
              ),
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Image.asset(AppImages.imgDiamond, fit: BoxFit.contain),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'DIAMX',
              style: TextStyle(
                fontFamily: FontFamily.montserratExtraBold,
                color: AppColors.white,
                fontSize: 30,
                letterSpacing: 7,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'DIAMOND MANAGEMENT',
              style: TextStyle(
                fontFamily: FontFamily.montserratMedium,
                color: AppColors.secondary,
                fontSize: 10,
                letterSpacing: 2.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoginCard extends StatelessWidget {
  const _LoginCard({required this.provider});

  final LoginProvider provider;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 26),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryDark.withValues(alpha: 0.14),
            blurRadius: 35,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Welcome Back',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: FontFamily.montserratBold,
              color: AppColors.textPrimary,
              fontSize: 24,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Sign in to continue to your account',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: FontFamily.montserratRegular,
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 28),
          _LoginTextField(
            controller: provider.usernameController,
            label: 'Username',
            hint: 'Enter your username',
            icon: Icons.person_outline_rounded,
            errorText: provider.usernameError,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 18),
          _LoginTextField(
            controller: provider.passwordController,
            label: 'Password',
            hint: 'Enter your password',
            icon: Icons.lock_outline_rounded,
            errorText: provider.passwordError,
            obscureText: !provider.isPasswordVisible,
            textInputAction: TextInputAction.next,
            suffixIcon: IconButton(
              onPressed: provider.togglePasswordVisibility,
              icon: Icon(
                provider.isPasswordVisible
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(height: 18),
          _BranchDropdown(provider: provider),
          const SizedBox(height: 26),
          SizedBox(
            height: 56,
            child: FilledButton(
              onPressed: provider.isLoading ? null : () => _submit(context),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                disabledBackgroundColor: AppColors.primaryLight,
                foregroundColor: AppColors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 4,
                shadowColor: AppColors.primary.withValues(alpha: 0.35),
              ),
              child: Text(
                'LOGIN',
                style: TextStyle(
                  fontFamily: FontFamily.montserratSemiBold,
                  fontSize: 15,
                  letterSpacing: 1.4,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submit(BuildContext context) async {
    FocusScope.of(context).unfocus();
    final success = await provider.login();

    if (!context.mounted) return;

    if (!success) {
      final message = provider.loginError;
      if (message != null && message.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      }
      return;
    }

    Navigator.pushNamedAndRemoveUntil(
      context,
      AppRoutes.main,
      (route) => false,
    );
  }
}

class _BranchDropdown extends StatelessWidget {
  const _BranchDropdown({required this.provider});

  final LoginProvider provider;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Branch',
          style: TextStyle(
            fontFamily: FontFamily.montserratSemiBold,
            color: AppColors.textPrimary,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<Branch>(
          key: ValueKey(
            '${provider.branches.length}-${provider.selectedBranch?.ledgerId}',
          ),
          initialValue: provider.selectedBranch,
          isExpanded: true,
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: AppColors.primary,
          ),
          decoration: InputDecoration(
            hintText: provider.isBranchesLoading
                ? 'Loading branches...'
                : 'Select branch',
            errorText: provider.branchError ?? provider.branchesError,
            prefixIcon: const Icon(
              Icons.apartment_outlined,
              color: AppColors.primary,
            ),
            filled: true,
            fillColor: AppColors.background,
            hintStyle: TextStyle(
              fontFamily: FontFamily.montserratRegular,
              color: AppColors.textSecondary.withValues(alpha: 0.65),
              fontSize: 13,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 17,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: const BorderSide(color: AppColors.secondary),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: const BorderSide(
                color: AppColors.primary,
                width: 1.6,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: const BorderSide(color: AppColors.error),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: const BorderSide(color: AppColors.error, width: 1.6),
            ),
          ),
          items: provider.branches
              .map(
                (branch) => DropdownMenuItem<Branch>(
                  value: branch,
                  child: Text(
                    branch.displayName,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: FontFamily.montserratMedium,
                      color: AppColors.textPrimary,
                      fontSize: 14,
                    ),
                  ),
                ),
              )
              .toList(),
          onChanged: provider.isBranchesLoading
              ? null
              : (branch) => provider.selectBranch(branch),
        ),
      ],
    );
  }
}

class _LoginTextField extends StatelessWidget {
  const _LoginTextField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.errorText,
    this.obscureText = false,
    this.textInputAction,
    this.suffixIcon,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final String? errorText;
  final bool obscureText;
  final TextInputAction? textInputAction;
  final Widget? suffixIcon;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: FontFamily.montserratSemiBold,
            color: AppColors.textPrimary,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: obscureText,
          textInputAction: textInputAction,
          autofillHints: obscureText
              ? const [AutofillHints.password]
              : const [AutofillHints.username],
          style: TextStyle(
            fontFamily: FontFamily.montserratMedium,
            color: AppColors.textPrimary,
            fontSize: 14,
          ),
          decoration: InputDecoration(
            hintText: hint,
            errorText: errorText,
            prefixIcon: Icon(icon, color: AppColors.primary),
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: AppColors.background,
            hintStyle: TextStyle(
              fontFamily: FontFamily.montserratRegular,
              color: AppColors.textSecondary.withValues(alpha: 0.65),
              fontSize: 13,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 17,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: const BorderSide(color: AppColors.secondary),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: const BorderSide(
                color: AppColors.primary,
                width: 1.6,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: const BorderSide(color: AppColors.error),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: const BorderSide(color: AppColors.error, width: 1.6),
            ),
          ),
        ),
      ],
    );
  }
}
