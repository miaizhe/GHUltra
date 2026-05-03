import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io' show Platform;
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import '../l10n/app_localizations.dart';
import 'home_screen.dart'; // Will rename to repos_screen later or use as tab
import 'search_screen.dart';
import 'notifications_screen.dart';
import 'account_screen.dart';
import 'webview_screen.dart';
import '../services/notification_service.dart';

class MainScreen extends StatefulWidget {
  final String token;

  const MainScreen({super.key, required this.token});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  late final List<Widget> _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = [
      HomeScreen(token: widget.token, isTab: true),
      SearchScreen(token: widget.token, isTab: true),
      NotificationsScreen(token: widget.token, isTab: true),
      AccountScreen(token: widget.token),
    ];
    _requestPermissions();
    _listenToNotifications();
  }

  void _requestPermissions() async {
    if (Platform.isAndroid) {
      await Permission.notification.request();
      await Permission.ignoreBatteryOptimizations.request();
    }
  }

  void _listenToNotifications() {
    NotificationStream.stream.stream.listen((data) async {
      if (!mounted) return;
      
      setState(() {
        _currentIndex = 2; // Navigate to Inbox tab
      });

      String? urlToOpen;
      try {
        if (data['url'] != null) {
          final response = await http.get(
            Uri.parse(data['url']),
            headers: {
              'Authorization': 'token ${widget.token}',
              'Accept': 'application/vnd.github.v3+json',
            },
          );
          if (response.statusCode == 200) {
            final respData = jsonDecode(response.body);
            urlToOpen = respData['html_url'];
          }
        }
      } catch (e) {
        debugPrint('Failed to get html_url: $e');
      }

      if (urlToOpen == null) {
        urlToOpen = data['html_url']; // fallback
      }

      if (urlToOpen != null && mounted) {
        if (Platform.isAndroid) {
          // Use Chrome Custom Tabs on Android for Passkey support
          await launchUrl(Uri.parse(urlToOpen!), mode: LaunchMode.inAppBrowserView);
        } else {
          // Use WebView for Windows
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => WebViewScreen(
                url: urlToOpen!,
                title: 'Notification',
              ),
            ),
          );
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _tabs,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.book_outlined),
            selectedIcon: const Icon(Icons.book),
            label: context.l10n('repositories'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.search_outlined),
            selectedIcon: const Icon(Icons.search),
            label: context.l10n('search'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.notifications_outlined),
            selectedIcon: const Icon(Icons.notifications),
            label: context.l10n('inbox'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.person_outline),
            selectedIcon: const Icon(Icons.person),
            label: context.l10n('account'),
          ),
        ],
      ),
    );
  }
}
