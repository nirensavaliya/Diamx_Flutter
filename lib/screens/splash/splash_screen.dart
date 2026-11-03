import 'dart:math' as math;

import 'package:diamax_flutter/utills/app_images.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../../services/splash_video.dart';
import '../../utills/app_colors.dart';
import '../../utills/app_font.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2600),
  )..forward();

  late final Animation<double> _diamondScale =
      Tween<double>(begin: 0.72, end: 1).animate(
        CurvedAnimation(
          parent: _controller,
          curve: const Interval(0, 0.4, curve: Curves.easeOutBack),
        ),
      );

  late final Animation<double> _diamondFade = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0, 0.32, curve: Curves.easeOut),
  );

  late final Animation<double> _sparkleFade = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0.32, 0.7, curve: Curves.easeOut),
  );

  late final Animation<double> _textAnimation = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0.44, 0.85, curve: Curves.easeOutCubic),
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.primaryDark, AppColors.primary, AppColors.primaryLight],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Column(
              children: [
                const Spacer(flex: 4),
                SizedBox(
                  width: 320,
                  height: 260,
                  child: Stack(
                    alignment: Alignment.center,
                    clipBehavior: Clip.none,
                    children: [
                      AnimatedBuilder(
                        animation: _controller,
                        builder: (context, child) {
                          return _DiamondHalo(progress: _controller.value);
                        },
                      ),
                      FadeTransition(
                        opacity: _sparkleFade,
                        child: ScaleTransition(
                          scale: _sparkleFade,
                          child: const _Sparkles(),
                        ),
                      ),
                      FadeTransition(
                        opacity: _diamondFade,
                        child: ScaleTransition(
                          scale: _diamondScale,
                          child: const _DiamondVideo(),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                const _BrandSection(),
                // FadeTransition(
                //   opacity: _textAnimation,
                //   child: SlideTransition(
                //     position: Tween<Offset>(
                //       begin: const Offset(0, 0.4),
                //       end: Offset.zero,
                //     ).animate(_textAnimation),
                //     child:
                //   ),
                // ),
                const Spacer(flex: 5),
                FadeTransition(
                  opacity: _textAnimation,
                  child: Column(
                    children: [
                      _AnimatedGoldLine(controller: _controller),
                      const SizedBox(height: 16),
                      Text(
                        'A WORLD OF BRILLIANCE',
                        style: TextStyle(
                          fontFamily: FontFamily.montserratMedium,
                          color: AppColors.background,
                          fontSize: 9,
                          letterSpacing: 2.6,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DiamondVideo extends StatefulWidget {
  const _DiamondVideo();

  @override
  State<_DiamondVideo> createState() => _DiamondVideoState();
}

class _DiamondVideoState extends State<_DiamondVideo> {
  VideoPlayerController? _videoController;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    // Preloaded in main() so the video is already (mostly) loaded by now.
    final controller = SplashVideo.controller;
    if (controller == null) return;

    _videoController = controller;
    if (controller.value.isInitialized) {
      _ready = true;
      controller.play();
      return;
    }
    SplashVideo.ready?.then((_) {
      if (!mounted || !controller.value.isInitialized) return;
      setState(() => _ready = true);
      controller.play();
    });
  }

  @override
  void dispose() {
    SplashVideo.release();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _videoController;

    return SizedBox(
      width: 250,
      height: 210,
      child: _ready && controller != null
          ? ShaderMask(
              blendMode: BlendMode.dstIn,
              shaderCallback: (bounds) => const RadialGradient(
                colors: [Colors.white, Colors.white, Colors.transparent],
                stops: [0, 0.68, 1],
              ).createShader(bounds),
              child: ColorFiltered(
                colorFilter: const ColorFilter.matrix([
                  1,
                  0,
                  0,
                  0,
                  0,
                  0,
                  1,
                  0,
                  0,
                  0,
                  0,
                  0,
                  1,
                  0,
                  0,
                  1,
                  1,
                  1,
                  0,
                  0,
                ]),
                child: FittedBox(
                  fit: BoxFit.cover,
                  clipBehavior: Clip.hardEdge,
                  child: SizedBox(
                    width: controller.value.size.width,
                    height: controller.value.size.height,
                    child: VideoPlayer(controller),
                  ),
                ),
              ),
            )
          : const SizedBox.shrink(),
    );
  }
}

class _DiamondHalo extends StatelessWidget {
  const _DiamondHalo({required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    final pulse = 0.55 + math.sin(progress * math.pi * 2.5).abs() * 0.45;

    return IgnorePointer(
      child: Container(
        width: 270,
        height: 220,
        decoration: BoxDecoration(
          gradient: RadialGradient(
            colors: [
              const Color(0xFFAEEBFF).withValues(alpha: 0.20 * pulse),
              AppColors.accent.withValues(alpha: 0.10 * pulse),
              Colors.transparent,
            ],
            stops: const [0, 0.42, 1],
          ),
        ),
      ),
    );
  }
}

class _Sparkles extends StatelessWidget {
  const _Sparkles();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 320,
      height: 260,
      child: Stack(
        children: [
          Positioned(
            top: 26,
            right: 44,
            child: Icon(Icons.auto_awesome, size: 22, color: AppColors.accent),
          ),
          Positioned(
            top: 54,
            left: 30,
            child: Icon(Icons.auto_awesome, size: 14, color: Colors.white70),
          ),
          Positioned(
            right: 16,
            bottom: 92,
            child: Icon(Icons.auto_awesome, size: 12, color: Colors.white70),
          ),
          Positioned(
            left: 14,
            bottom: 78,
            child: Icon(Icons.auto_awesome, size: 10, color: AppColors.accent),
          ),
          Positioned(
            bottom: 22,
            right: 108,
            child: Icon(Icons.auto_awesome, size: 12, color: AppColors.accent),
          ),
        ],
      ),
    );
  }
}

class _BrandSection extends StatelessWidget {
  const _BrandSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ShaderMask(
        //   shaderCallback: (bounds) => const LinearGradient(
        //     colors: [Color(0xFFF3D99A), AppColors.accent, Color(0xFFFFE9B7)],
        //   ).createShader(bounds),
        //   child: Text(
        //     'DIAMX',
        //     style: TextStyle(
        //       fontFamily: FontFamily.montserratExtraBold,
        //       color: AppColors.white,
        //       fontSize: 39,
        //       letterSpacing: 9,
        //     ),
        //   ),
        // ),
        // const SizedBox(height: 10),
        // Text(
        //   'D I A M X   M A N A G E M E N T',
        //   style: TextStyle(
        //     fontFamily: FontFamily.montserratMedium,
        //     color: AppColors.secondary,
        //     fontSize: 9,
        //     letterSpacing: 2.8,
        //   ),
        // ),
        Image.asset(
          AppImages.appLogoTwo,
          height: 65,
          fit: BoxFit.contain,
        ),
      ],
    );
  }
}

class _AnimatedGoldLine extends StatelessWidget {
  const _AnimatedGoldLine({required this.controller});

  final AnimationController controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        final progress = Curves.easeOut.transform(
          ((controller.value - 0.45) / 0.35).clamp(0.0, 1.0),
        );

        return Container(
          width: 110 * progress,
          height: 1.5,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                Colors.transparent,
                AppColors.accent,
                Colors.transparent,
              ],
            ),
            borderRadius: BorderRadius.circular(2),
          ),
        );
      },
    );
  }
}
