import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'data/sound_service.dart';
import 'screens/splash_screen.dart';
import 'theme/app_colors.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SoundService.instance.init();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));
  runApp(const FreeTheKeyApp());
}

class FreeTheKeyApp extends StatelessWidget {
  const FreeTheKeyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Free The Key',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.dark(
          primary: AppColors.primary,
          surface: AppColors.boardBg,
          onSurface: AppColors.textPrimary,
        ),
        scaffoldBackgroundColor: AppColors.background,
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
      ),
      home: const SplashScreen(),
    );
  }
}
