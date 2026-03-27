

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
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
import 'services/local_notification_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart' as firestore;

void main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();

    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    } on FirebaseException catch (e) {
      if (e.code != 'duplicate-app') rethrow;
      debugPrint('ℹ️ Firebase already initialized (native layer), continuing...');
    }

    if (!kIsWeb) {
      await LocalNotificationService().init();
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
  } catch (e, stackTrace) {
    debugPrint('❌ FATAL ERROR during initialization: $e');
    debugPrint('Stack trace: $stackTrace');
    // Show error screen
    runApp(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error, size: 64, color: Colors.red),
                  SizedBox(height: 16),
                  Text(
                    'App Initialization Error',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Error: $e',
                    style: TextStyle(fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
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
