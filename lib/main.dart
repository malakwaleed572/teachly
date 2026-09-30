import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:teachly/core/notifications/notification_service.dart';

import 'package:teachly/firebase_options.dart';
import 'package:teachly/core/localization/app_localization.dart';
import 'package:teachly/core/localization/language_controller.dart';
import 'package:teachly/screens/splash_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
   await NotificationService.instance.initialize();

  final languageController = LanguageController();

  await languageController.loadLanguage();

  runApp(
    TeachlyApp(
      languageController: languageController,
    ),
  );
}

class TeachlyApp extends StatelessWidget {
  final LanguageController languageController;

  const TeachlyApp({
    super.key,
    required this.languageController,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: languageController,
      builder: (context, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,

          locale: languageController.locale,

          supportedLocales: AppLocalizations.supportedLocales,

          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],

          builder: (context, child) {
            return Directionality(
              textDirection:
                  languageController.locale.languageCode == 'ar'
                      ? TextDirection.rtl
                      : TextDirection.ltr,
              child: child ?? const SizedBox(),
            );
          },

          home: SplashScreen(
            languageController: languageController,
          ),
        );
      },
    );
  }
}