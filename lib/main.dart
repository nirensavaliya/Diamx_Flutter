import 'package:diamax_flutter/routes/app_pages.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get_storage/get_storage.dart';
import 'package:provider/provider.dart';

import 'providers/splash_provider.dart';
import 'routes/app_routes.dart';
import 'services/api_service.dart';
import 'services/navigation_service.dart';
import 'services/splash_video.dart';
import 'utills/app_colors.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await GetStorage.init();
  SplashVideo.preload();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);

  final navigationService = NavigationService();
  ApiService.shared(navigationService: navigationService);

  runApp(
    MultiProvider(
      providers: [
        Provider.value(value: navigationService),
        ChangeNotifierProvider(
          lazy: false,
          create: (_) => SplashProvider(navigationService),
        ),
      ],
      child: MyApp(navigationService: navigationService),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, required this.navigationService});

  final NavigationService navigationService;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigationService.navigatorKey,
      debugShowCheckedModeBanner: false,
      initialRoute: AppRoutes.splash,
      routes: AppPages.routes,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: AppColors.background,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          primary: AppColors.primary,
          secondary: AppColors.secondary,
          surface: AppColors.surface,
        ),
      ),
    );
  }
}
