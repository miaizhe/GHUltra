import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../services/github_service.dart';
import '../providers/app_settings_provider.dart';
import '../l10n/app_localizations.dart';
import 'login_screen.dart';

class AccountScreen extends StatefulWidget {
  final String token;

  const AccountScreen({super.key, required this.token});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  late GitHubService _service;
  Map<String, dynamic>? _userProfile;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _service = GitHubService(widget.token);
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final profile = await _service.getUserProfile();
      if (mounted) {
        setState(() {
          _userProfile = profile;
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

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('github_token');
    if (!mounted) return;
    // PushAndRemoveUntil to clear navigation stack
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(context.l10n('account')),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.redAccent),
            onPressed: _logout,
            tooltip: context.l10n('logout'),
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
            const SizedBox(height: 16),
            Text(_error!, style: const TextStyle(color: Colors.redAccent)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadProfile,
              child: Text(context.l10n('retry')),
            ),
          ],
        ),
      );
    }

    if (_userProfile == null) return const SizedBox();

    return ListView(
      padding: const EdgeInsets.all(24.0),
      children: [
        Center(
          child: CircleAvatar(
            radius: 60,
            backgroundImage: NetworkImage(_userProfile!['avatar_url'] ?? ''),
            backgroundColor: Colors.transparent,
          ),
        ),
        const SizedBox(height: 24),
        Center(
          child: Text(
            _userProfile!['name'] ?? _userProfile!['login'] ?? 'Unknown User',
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 8),
        Center(
          child: Text(
            '@${_userProfile!['login']}',
            style: const TextStyle(fontSize: 16, color: Color(0xFF57606A)),
          ),
        ),
        const SizedBox(height: 32),
        if (_userProfile!['bio'] != null) ...[
          const Text('Bio', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          Text(_userProfile!['bio'], style: const TextStyle(fontSize: 16)),
          const SizedBox(height: 24),
        ],
        const Divider(),
        ListTile(
          leading: const Icon(Icons.group),
          title: Text(context.l10n('followers')),
          trailing: Text('${_userProfile!['followers'] ?? 0}'),
        ),
        ListTile(
          leading: const Icon(Icons.person_add),
          title: Text(context.l10n('following')),
          trailing: Text('${_userProfile!['following'] ?? 0}'),
        ),
        ListTile(
          leading: const Icon(Icons.book),
          title: Text(context.l10n('public_repos')),
          trailing: Text('${_userProfile!['public_repos'] ?? 0}'),
        ),
        const SizedBox(height: 24),
        const Divider(),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Text(context.l10n('app_settings'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ),
        Consumer<AppSettingsProvider>(
          builder: (context, settings, child) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ListTile(
                  leading: const Icon(Icons.language),
                  title: Text(context.l10n('language')),
                  trailing: DropdownButton<String>(
                    value: settings.languageCode,
                    items: [
                      DropdownMenuItem(value: 'system', child: Text(context.l10n('system'))),
                      DropdownMenuItem(value: 'en', child: Text(context.l10n('english'))),
                      DropdownMenuItem(value: 'zh', child: Text(context.l10n('chinese'))),
                    ],
                    onChanged: (val) {
                      if (val != null) settings.setLanguage(val);
                    },
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.brightness_medium),
                  title: Text(context.l10n('theme_mode')),
                  trailing: DropdownButton<ThemeMode>(
                    value: settings.themeMode,
                    items: [
                      DropdownMenuItem(value: ThemeMode.system, child: Text(context.l10n('system'))),
                      DropdownMenuItem(value: ThemeMode.light, child: Text(context.l10n('light_mode'))),
                      DropdownMenuItem(value: ThemeMode.dark, child: Text(context.l10n('dark_mode'))),
                    ],
                    onChanged: (val) {
                      if (val != null) settings.setThemeMode(val);
                    },
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.wallpaper),
                  title: Text(context.l10n('custom_background')),
                  subtitle: Text(settings.backgroundImagePath != null ? context.l10n('image_set') : context.l10n('none')),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (settings.backgroundImagePath != null)
                        IconButton(
                          icon: const Icon(Icons.clear, color: Colors.red),
                          onPressed: () => settings.setBackgroundImage(null),
                        ),
                      IconButton(
                        icon: const Icon(Icons.image_search),
                        onPressed: () async {
                          FilePickerResult? result = await FilePicker.platform.pickFiles(
                            type: FileType.image,
                          );
                          if (result != null && result.files.single.path != null) {
                            settings.setBackgroundImage(result.files.single.path!);
                          }
                        },
                      ),
                    ],
                  ),
                ),
                if (settings.backgroundImagePath != null) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Row(
                      children: [
                        Text('${context.l10n('background_opacity')}:'),
                        Expanded(
                          child: Slider(
                            value: settings.backgroundOpacity,
                            min: 0.0,
                            max: 1.0,
                            onChanged: (val) => settings.setBackgroundOpacity(val),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SwitchListTile(
                    secondary: const Icon(Icons.color_lens),
                    title: Text(context.l10n('dynamic_color')),
                    subtitle: Text(context.l10n('extract_primary_color')),
                    value: settings.enableDynamicColor,
                    onChanged: (val) => settings.setEnableDynamicColor(val),
                  ),
                ],
              ],
            );
          },
        ),
        const SizedBox(height: 24),
        const Divider(),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Text(context.l10n('account_settings'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ),
        const SizedBox(height: 8),
        ElevatedButton.icon(
          onPressed: _logout,
          icon: const Icon(Icons.logout),
          label: Text(context.l10n('logout')),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.redAccent,
          ),
        )
      ],
    );
  }
}
