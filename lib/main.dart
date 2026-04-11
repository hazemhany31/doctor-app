

import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'firebase_options.dart';
import 'package:flutter/foundation.dart';
import 'config/theme.dart';
import 'screens/auth/login_screen.dart';
import 'screens/main_layout.dart';
import 'services/auth_service.dart';
import 'package:provider/provider.dart';
import 'l10n/app_localizations.dart';
import 'providers/locale_provider.dart';
import 'services/push_notification_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart' as firestore;

void main() async {
  // Global error handling via runZonedGuarded
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      if (!kIsWeb) {
        // Pass all uncaught "fatal" errors from the framework to Crashlytics
        FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;

        // Pass all uncaught asynchronous errors that aren't handled by the Flutter framework to Crashlytics
        PlatformDispatcher.instance.onError = (error, stack) {
          FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
          return true;
        };
      }

      // Initialize App Check (protects Firestore / Storage from unauthorized access)
      // await FirebaseAppCheck.instance.activate(
      //   // ignore: deprecated_member_use
      //   androidProvider: kDebugMode ? AndroidProvider.debug : AndroidProvider.playIntegrity,
      //   // ignore: deprecated_member_use
      //   appleProvider: kDebugMode ? AppleProvider.debug : AppleProvider.deviceCheck,
      // );

    } on FirebaseException catch (e) {
      if (e.code != 'duplicate-app') rethrow;
      debugPrint('ℹ️ Firebase already initialized (native layer), continuing...');
    }

    if (!kIsWeb) {
      await PushNotificationService().initialize(null);
    }

    firestore.FirebaseFirestore.instance.settings = const firestore.Settings(
      persistenceEnabled: true,
      cacheSizeBytes: firestore.Settings.CACHE_SIZE_UNLIMITED,
    );

    runApp(
      ChangeNotifierProvider(
        create: (_) => LocaleProvider(),
        child: const DoctorApp(),
      ),
    );
  }, (error, stackTrace) {
    debugPrint('❌ Uncaught Zoned Error: $error');
    if (!kIsWeb) {
      FirebaseCrashlytics.instance.recordError(error, stackTrace, fatal: true);
    }
    // Only show the error screen in extremely fatal scenario
    runApp(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  const Text(
                    'حدث خطأ غير متوقع',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Text('Error: $error', textAlign: TextAlign.center),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  });
}

class DoctorApp extends StatelessWidget {
  const DoctorApp({super.key});

  @override
  Widget build(BuildContext context) {
    final localeProvider = Provider.of<LocaleProvider>(context);
    return MaterialApp(
      title: 'Doctor App',
      debugShowCheckedModeBanner: false,

      // Theme
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,

      // Localization
      localizationsDelegates: [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('ar'), Locale('en')],
      locale: localeProvider.locale,

      // Authentication Check
      home: AuthCheck(),
    );
  }
}

/// فحص حالة المصادقة
class AuthCheck extends StatelessWidget {
  final _authService = AuthService();

  AuthCheck({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: _authService.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const LoginScreen();
        }

        // Loading — شاشة تحميل احترافية
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 20),
                  Text(
                    'NBIG Doctor',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'جارٍ التحميل...',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ],
              ),
            ),
          );
        }

        // Check if user is logged in
        if (snapshot.hasData && snapshot.data != null) {
          // User is logged in
          return const MainLayout();
        }

        // User is not logged in
        return const LoginScreen();
      },
    );
  }
}
