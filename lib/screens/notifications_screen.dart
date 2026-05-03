import 'package:flutter/material.dart';
import '../services/github_service.dart';
import 'webview_screen.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

class NotificationsScreen extends StatefulWidget {
  final String token;
  final bool isTab;

  const NotificationsScreen({super.key, required this.token, this.isTab = false});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  late GitHubService _service;
  List<dynamic>? _notifications;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _service = GitHubService(widget.token);
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final notifications = await _service.getNotifications();
      if (mounted) {
        setState(() {
          _notifications = notifications;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadNotifications,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_error != null) return Center(child: Text(_error!, style: const TextStyle(color: Colors.red)));
    if (_notifications == null || _notifications!.isEmpty) {
      return const Center(child: Text('No unread notifications! 🎉'));
    }

    return RefreshIndicator(
      onRefresh: _loadNotifications,
      child: ListView.builder(
        itemCount: _notifications!.length,
        itemBuilder: (context, index) {
          final notif = _notifications![index];
          final subject = notif['subject'];
          final repo = notif['repository'];
          
          IconData icon;
          Color iconColor = const Color(0xFF0969DA);

          switch (subject['type']) {
            case 'Issue':
              icon = Icons.error_outline;
              iconColor = const Color(0xFF2DA44E);
              break;
            case 'PullRequest':
              icon = Icons.call_merge;
              iconColor = const Color(0xFF8250DF); // GitHub purple
              break;
            case 'Release':
              icon = Icons.local_offer_outlined;
              break;
            case 'Discussion':
              icon = Icons.forum_outlined;
              break;
            default:
              icon = Icons.notifications_none;
              iconColor = const Color(0xFF57606A);
          }

          return ListTile(
            leading: Icon(icon, color: iconColor),
            title: Text(subject['title']),
            subtitle: Text('${repo['full_name']} • ${notif['reason']}'),
            onTap: () async {
              String? urlToOpen;
              try {
                if (subject['url'] != null) {
                  final response = await http.get(
                    Uri.parse(subject['url']),
                    headers: {
                      'Authorization': 'token ${widget.token}',
                      'Accept': 'application/vnd.github.v3+json',
                    },
                  );
                  if (response.statusCode == 200) {
                    final data = jsonDecode(response.body);
                    urlToOpen = data['html_url'];
                  }
                }
              } catch (e) {
                debugPrint('Failed to get html_url: $e');
              }
              
              if (urlToOpen == null && subject['latest_comment_url'] != null) {
                 try {
                  final response = await http.get(
                    Uri.parse(subject['latest_comment_url']),
                    headers: {
                      'Authorization': 'token ${widget.token}',
                      'Accept': 'application/vnd.github.v3+json',
                    },
                  );
                  if (response.statusCode == 200) {
                    final data = jsonDecode(response.body);
                    urlToOpen = data['html_url'];
                  }
                } catch (e) {
                  debugPrint('Failed to get html_url from comment: $e');
                }
              }

              if (urlToOpen == null) {
                urlToOpen = repo['html_url'];
              }

              if (urlToOpen != null && mounted) {
                if (Theme.of(context).platform == TargetPlatform.android) {
                  // Use url_launcher for Android Custom Tabs which supports Passkeys (WebAuthn)
                  await launchUrl(Uri.parse(urlToOpen!), mode: LaunchMode.inAppBrowserView);
                } else {
                  // For Windows and others use the embedded WebView
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => WebViewScreen(
                        url: urlToOpen!,
                        title: subject['title'] ?? 'Notification',
                      ),
                    ),
                  );
                }
              } else if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Cannot find a link to open for this notification.')),
                );
              }
            },
          );
        },
      ),
    );
  }
}
