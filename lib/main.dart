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
  
  final prefs = await SharedPreferences.getInstance();

  if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
    await windowManager.ensureInitialized();
    
    final remember = prefs.getBool('rememberWindowSize') ?? false;
    Size initialSize = const Size(1200, 800);
    
    if (remember) {
      final width = prefs.getDouble('windowWidth');
      final height = prefs.getDouble('windowHeight');
      if (width != null && height != null) {
        initialSize = Size(width, height);
      }
    }
    
    WindowOptions windowOptions = WindowOptions(
      size: initialSize,
      center: true,
      skipTaskbar: false,
    );
    
    windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
    });
  }

  await NotificationService().init();

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

class GHUltraApp extends StatefulWidget {
  final String? initialToken;

  const GHUltraApp({super.key, this.initialToken});

  @override
  State<GHUltraApp> createState() => _GHUltraAppState();
}

class _GHUltraAppState extends State<GHUltraApp> with WindowListener {
  @override
  void initState() {
    super.initState();
    if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
      windowManager.addListener(this);
    }
  }

  @override
  void dispose() {
    if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
      windowManager.removeListener(this);
    }
    super.dispose();
  }

  @override
  void onWindowResized() async {
    final prefs = await SharedPreferences.getInstance();
    final remember = prefs.getBool('rememberWindowSize') ?? false;
    if (remember) {
      final size = await windowManager.getSize();
      await prefs.setDouble('windowWidth', size.width);
      await prefs.setDouble('windowHeight', size.height);
    }
  }

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
        builder: (context, child) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          final defaultBgColor = isDark ? const Color(0xFF0D1117) : Colors.white;
          final overlayColor = defaultBgColor.withOpacity(settings.backgroundOpacity);

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
                  child: Container(color: overlayColor),
                ),
                Positioned.fill(child: child!),
              ],
            );
          }

          return Container(
            color: defaultBgColor,
            child: child,
          );
        },
        home: widget.initialToken != null && widget.initialToken!.isNotEmpty
            ? MainScreen(token: widget.initialToken!)
            : const LoginScreen(),
      );
    },
  );
}
}
