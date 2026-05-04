import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static final Map<String, Map<String, String>> _localizedValues = {
    'en': {
      'repositories': 'Repositories',
      'search': 'Search',
      'inbox': 'Inbox',
      'account': 'Account',
      'logout': 'Logout',
      'language': 'Language',
      'system': 'System',
      'english': 'English',
      'chinese': '中文',
      'custom_background': 'Custom Background',
      'image_set': 'Image Set',
      'none': 'None',
      'background_opacity': 'Background Opacity',
      'dynamic_color': 'Dynamic Color',
      'extract_primary_color': 'Extract primary color from background',
      'app_settings': 'App Settings',
      'account_settings': 'Account Settings',
      'public_repos': 'Public Repos',
      'followers': 'Followers',
      'following': 'Following',
      'retry': 'Retry',
      'theme_mode': 'Theme Mode',
      'light_mode': 'Light',
      'dark_mode': 'Dark',
      'stars': 'stars',
      'forks': 'forks',
      'issues': 'issues',
      'updated_at': 'Updated at',
      'license': 'License',
      'readme': 'README',
      'actions': 'Actions',
      'releases': 'Releases',
      'settings': 'Settings',
      'sync_branch': 'Sync Branch',
      'switch_branch': 'Switch Branch',
      'code': 'Code',
      'search_hint': 'Search repositories, users...',
      'remember_window_size': 'Remember Window Size',
      'remember_window_size_desc': 'Restore previous window size on startup',
    },
    'zh': {
      'repositories': '仓库',
      'search': '搜索',
      'inbox': '收件箱',
      'account': '账号',
      'logout': '退出登录',
      'language': '语言',
      'system': '跟随系统',
      'english': 'English',
      'chinese': '中文',
      'custom_background': '自定义背景',
      'image_set': '已设置',
      'none': '未设置',
      'background_opacity': '背景不透明度',
      'dynamic_color': '动态取色',
      'extract_primary_color': '从背景提取主题色',
      'app_settings': '应用设置',
      'account_settings': '账号设置',
      'public_repos': '公开仓库',
      'followers': '粉丝',
      'following': '关注',
      'retry': '重试',
      'theme_mode': '深色/浅色模式',
      'light_mode': '浅色',
      'dark_mode': '深色',
      'stars': '星标',
      'forks': '分支',
      'issues': '问题',
      'updated_at': '更新于',
      'license': '许可证',
      'readme': '自述文件',
      'actions': '工作流 (Actions)',
      'releases': '发布 (Releases)',
      'settings': '设置',
      'sync_branch': '同步分支',
      'switch_branch': '切换分支',
      'code': '代码',
      'search_hint': '搜索仓库、用户...',
      'remember_window_size': '记忆窗口大小',
      'remember_window_size_desc': '在启动时恢复上次的窗口大小',
    },
  };

  String get(String key) {
    return _localizedValues[locale.languageCode]?[key] ??
        _localizedValues['en']?[key] ??
        key;
  }
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['en', 'zh'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

extension AppLocalizationsExtension on BuildContext {
  String l10n(String key) => AppLocalizations.of(this)?.get(key) ?? key;
}
