import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:window_manager/window_manager.dart';
import 'dart:io' show Platform, File;
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'l10n/app_localizations.dart';
import 'screens/login_screen.dart';
import 'screens/main_screen.dart';
import 'services/notification_service.dart';
import 'providers/app_settings_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
    await windowManager.ensureInitialized();
  }

  await NotificationService().init();

  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('github_token');

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppSettingsProvider()),
      ],
      child: GHUltraApp(initialToken: token),
    ),
  );
}

class GHUltraApp extends StatelessWidget {
  final String? initialToken;

  const GHUltraApp({super.key, this.initialToken});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppSettingsProvider>(
      builder: (context, settings, child) {
        Color primaryColor = settings.dynamicColor ?? const Color(0xFF24292E);
        
        return MaterialApp(
          title: 'GHUltra',
          debugShowCheckedModeBanner: false,
          locale: settings.locale,
          supportedLocales: const [
            Locale('en', 'US'),
            Locale('zh', 'CN'),
          ],
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          themeMode: settings.themeMode,
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: primaryColor,
              primary: primaryColor,
              secondary: const Color(0xFF0969DA),
              surface: const Color(0xFFFFFFFF),
              brightness: Brightness.light,
            ),
            scaffoldBackgroundColor: Colors.transparent, // Important for background image
            useMaterial3: true,
            fontFamily: 'Roboto',
            appBarTheme: const AppBarTheme(
              backgroundColor: Colors.transparent,
              elevation: 0,
              scrolledUnderElevation: 2,
              iconTheme: IconThemeData(color: Color(0xFF24292E)),
              titleTextStyle: TextStyle(
                color: Color(0xFF24292E),
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            cardTheme: CardThemeData(
              color: Colors.white.withOpacity(0.9), // slight transparency for cards
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: Color(0xFFD0D7DE), width: 1),
              ),
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2DA44E),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
            inputDecorationTheme: InputDecorationTheme(
              filled: true,
              fillColor: Colors.white.withOpacity(0.9),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFD0D7DE)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFD0D7DE)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF0969DA), width: 2),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
            navigationBarTheme: NavigationBarThemeData(
              backgroundColor: settings.backgroundImagePath != null 
                  ? Colors.white.withOpacity(0.8) 
                  : const Color(0xFFFFFFFF),
              indicatorColor: primaryColor.withOpacity(0.2),
            ),
          ),
          darkTheme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: primaryColor,
              primary: primaryColor,
              secondary: const Color(0xFF58A6FF),
              surface: const Color(0xFF0D1117),
              brightness: Brightness.dark,
            ),
            scaffoldBackgroundColor: Colors.transparent, // Important for background image
            useMaterial3: true,
            fontFamily: 'Roboto',
            appBarTheme: const AppBarTheme(
              backgroundColor: Colors.transparent,
              elevation: 0,
              scrolledUnderElevation: 2,
              iconTheme: IconThemeData(color: Color(0xFFC9D1D9)),
              titleTextStyle: TextStyle(
                color: Color(0xFFC9D1D9),
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            cardTheme: CardThemeData(
              color: const Color(0xFF161B22).withOpacity(0.9), // slight transparency for cards
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: Color(0xFF30363D), width: 1),
              ),
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF238636),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
            inputDecorationTheme: InputDecorationTheme(
              filled: true,
              fillColor: const Color(0xFF161B22).withOpacity(0.9),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF30363D)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF30363D)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF58A6FF), width: 2),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
            navigationBarTheme: NavigationBarThemeData(
              backgroundColor: settings.backgroundImagePath != null 
                  ? const Color(0xFF0D1117).withOpacity(0.8) 
                  : const Color(0xFF0D1117),
              indicatorColor: primaryColor.withOpacity(0.2),
            ),
          ),
          home: _buildHomeWithBackground(settings),
        );
      },
    );
  }

  Widget _buildHomeWithBackground(AppSettingsProvider settings) {
    Widget child = initialToken != null && initialToken!.isNotEmpty
        ? MainScreen(token: initialToken!)
        : const LoginScreen();

    if (settings.backgroundImagePath != null && settings.backgroundImagePath!.isNotEmpty) {
      return Stack(
        children: [
          Positioned.fill(
            child: Image.file(
              File(settings.backgroundImagePath!),
              fit: BoxFit.cover,
            ),
          ),
          Positioned.fill(
            child: Container(
              color: Colors.white.withOpacity(settings.backgroundOpacity),
            ),
          ),
          Positioned.fill(child: child),
        ],
      );
    }
    
    // Default background
    return Container(
      color: const Color(0xFFF6F8FA),
      child: child,
    );
  }
}
