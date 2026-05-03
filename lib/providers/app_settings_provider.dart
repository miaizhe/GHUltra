import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:palette_generator/palette_generator.dart';

class AppSettingsProvider extends ChangeNotifier {
  SharedPreferences? _prefs;

  String _languageCode = 'system'; // 'system', 'zh', 'en'
  String? _backgroundImagePath;
  double _backgroundOpacity = 0.5;
  bool _enableDynamicColor = false;
  Color? _dynamicColor;

  String get languageCode => _languageCode;
  String? get backgroundImagePath => _backgroundImagePath;
  double get backgroundOpacity => _backgroundOpacity;
  bool get enableDynamicColor => _enableDynamicColor;
  Color? get dynamicColor => _dynamicColor;

  AppSettingsProvider() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    _prefs = await SharedPreferences.getInstance();
    _languageCode = _prefs?.getString('languageCode') ?? 'system';
    _backgroundImagePath = _prefs?.getString('backgroundImagePath');
    _backgroundOpacity = _prefs?.getDouble('backgroundOpacity') ?? 0.5;
    _enableDynamicColor = _prefs?.getBool('enableDynamicColor') ?? false;

    if (_enableDynamicColor && _backgroundImagePath != null) {
      await _extractDynamicColor();
    }
    notifyListeners();
  }

  Future<void> setLanguage(String lang) async {
    _languageCode = lang;
    await _prefs?.setString('languageCode', lang);
    notifyListeners();
  }

  Future<void> setBackgroundImage(String? path) async {
    _backgroundImagePath = path;
    if (path == null) {
      await _prefs?.remove('backgroundImagePath');
      _dynamicColor = null;
    } else {
      await _prefs?.setString('backgroundImagePath', path);
      if (_enableDynamicColor) {
        await _extractDynamicColor();
      }
    }
    notifyListeners();
  }

  Future<void> setBackgroundOpacity(double opacity) async {
    _backgroundOpacity = opacity;
    await _prefs?.setDouble('backgroundOpacity', opacity);
    notifyListeners();
  }

  Future<void> setEnableDynamicColor(bool enable) async {
    _enableDynamicColor = enable;
    await _prefs?.setBool('enableDynamicColor', enable);
    if (enable && _backgroundImagePath != null) {
      await _extractDynamicColor();
    } else {
      _dynamicColor = null;
    }
    notifyListeners();
  }

  Future<void> _extractDynamicColor() async {
    if (_backgroundImagePath == null) return;
    try {
      final imageProvider = FileImage(File(_backgroundImagePath!));
      final paletteGenerator = await PaletteGenerator.fromImageProvider(imageProvider);
      _dynamicColor = paletteGenerator.dominantColor?.color ?? paletteGenerator.vibrantColor?.color;
    } catch (e) {
      debugPrint('Failed to extract color: $e');
    }
  }

  Locale? get locale {
    if (_languageCode == 'zh') return const Locale('zh', 'CN');
    if (_languageCode == 'en') return const Locale('en', 'US');
    return null; // follows system
  }
}
