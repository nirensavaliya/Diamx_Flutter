import 'package:video_player/video_player.dart';

/// Preloads the splash diamond video at app startup so the splash screen
/// can play it immediately, even on a fresh install.
class SplashVideo {
  SplashVideo._();

  static VideoPlayerController? controller;
  static Future<void>? ready;

  static void preload() {
    if (controller != null) return;

    final videoController = VideoPlayerController.asset(
      'assets/videos/diamond_spin.mp4',
    );
    try {
      videoController
        ..setLooping(true)
        ..setVolume(0);
      ready = videoController.initialize().catchError((_) {});
      controller = videoController;
    } catch (_) {
      // Video playback unavailable on this platform; splash falls back.
    }
  }

  static void release() {
    try {
      controller?.dispose();
    } catch (_) {
      // Platform view unavailable.
    }
    controller = null;
    ready = null;
  }
}
