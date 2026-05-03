import 'dart:io';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_windows/webview_windows.dart';

class WebViewScreen extends StatefulWidget {
  final String url;
  final String title;

  const WebViewScreen({super.key, required this.url, required this.title});

  @override
  State<WebViewScreen> createState() => _WebViewScreenState();
}

class _WebViewScreenState extends State<WebViewScreen> {
  final _windowsController = WebviewController();
  bool _isWindowsInitialized = false;
  late final WebViewController _androidController;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (Platform.isWindows) {
      _initWindowsWebView();
    } else {
      _initAndroidWebView();
    }
  }

  Future<void> _initWindowsWebView() async {
    try {
      await _windowsController.initialize();
      await _windowsController.loadUrl(widget.url);
      if (mounted) {
        setState(() {
          _isWindowsInitialized = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to initialize Windows WebView: $e';
        });
      }
    }
  }

  void _initAndroidWebView() {
    _androidController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setUserAgent("Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/114.0.0.0 Safari/537.36")
      ..loadRequest(Uri.parse(widget.url));
  }

  @override
  void dispose() {
    if (Platform.isWindows) {
      _windowsController.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: _error != null
          ? Center(child: Text(_error!, style: const TextStyle(color: Colors.red)))
          : Platform.isWindows
              ? (_isWindowsInitialized
                  ? Webview(_windowsController)
                  : const Center(child: CircularProgressIndicator()))
              : WebViewWidget(controller: _androidController),
    );
  }
}
