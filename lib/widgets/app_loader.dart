import 'package:flutter/material.dart';

import '../utills/app_colors.dart';
import '../utills/app_font.dart';
import '../utills/app_images.dart';

class AppLoader {
  AppLoader._();

  static OverlayEntry? _entry;

  static void show(BuildContext context, {String message = 'Please wait...'}) {
    if (_entry != null) return;

    _entry = OverlayEntry(builder: (_) => FullScreenLoader(message: message));
    Overlay.of(context, rootOverlay: true).insert(_entry!);
  }

  static void hide() {
    _entry?.remove();
    _entry = null;
  }
}

class FullScreenLoader extends StatelessWidget {
  const FullScreenLoader({super.key, this.message = 'Please wait...'});

  final String message;

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: Material(
        color: AppColors.primaryDark.withValues(alpha: 0.72),
        child: Center(
          child: Container(
            width: 168,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 26),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryDark.withValues(alpha: 0.22),
                  blurRadius: 26,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const _DiamondPulse(),
                const SizedBox(height: 18),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: FontFamily.montserratMedium,
                    color: AppColors.textPrimary,
                    fontSize: 12,
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

class _DiamondPulse extends StatefulWidget {
  const _DiamondPulse();

  @override
  State<_DiamondPulse> createState() => _DiamondPulseState();
}

class _DiamondPulseState extends State<_DiamondPulse>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat(reverse: true);

  late final Animation<double> _scale = Tween<double>(
    begin: 0.88,
    end: 1.08,
  ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scale,
      child: Container(
        width: 62,
        height: 62,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.primary, AppColors.primaryDark],
          ),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppColors.accent.withValues(alpha: 0.38),
              blurRadius: 18,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(13),
          child: Image.asset(
            AppImages.imgDiamond,
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}
