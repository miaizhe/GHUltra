import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:window_manager/window_manager.dart';
import 'dart:io' show Platform;
import '../services/github_service.dart';
import '../services/oauth_service.dart';
import 'main_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _tokenController = TextEditingController();
  bool _isLoading = false;
  bool _isOAuthLoading = false;
  String? _errorMessage;

  Future<void> _handleTokenLogin(String token) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final service = GitHubService(token);
      await service.getUserProfile(); // Validate token

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('github_token', token);

      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => MainScreen(token: token)),
      );
    } catch (e) {
      setState(() {
        _errorMessage = 'Invalid token or network error';
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _login() async {
    final token = _tokenController.text.trim();
    if (token.isEmpty) {
      setState(() => _errorMessage = 'Please enter a Personal Access Token');
      return;
    }
    await _handleTokenLogin(token);
  }

  Future<void> _oauthLogin() async {
    setState(() {
      _isOAuthLoading = true;
      _errorMessage = null;
    });

    try {
      final oauth = OAuthService();
      final token = await oauth.authenticate();

      // Bring window back to front after browser auth on desktop
      if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
        await windowManager.show();
        await windowManager.focus();
      }

      if (token != null) {
        await _handleTokenLogin(token);
      } else {
        setState(() {
          _errorMessage = 'Authentication was cancelled or failed.';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'OAuth Error: ${e.toString()}';
      });
    } finally {
      if (mounted) {
        setState(() => _isOAuthLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(
                  Icons.code, // Placeholder for GitHub icon
                  size: 80,
                  color: Color(0xFF24292E),
                ).animate().scale(duration: 500.ms, curve: Curves.easeOutBack),
                const SizedBox(height: 24),
                const Text(
                  'Welcome to GHUltra',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF24292E),
                  ),
                ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2),
                const SizedBox(height: 8),
                const Text(
                  'Sign in to continue',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Color(0xFF57606A),
                  ),
                ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.2),
                const SizedBox(height: 48),
                
                // One-Click OAuth Login Button
                ElevatedButton.icon(
                  icon: const Icon(Icons.open_in_browser),
                  onPressed: (_isLoading || _isOAuthLoading) ? null : _oauthLogin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF24292E), // GitHub Dark
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  label: _isOAuthLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text('Login with GitHub (Web)'),
                ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2),
                
                const SizedBox(height: 32),
                const Row(
                  children: [
                    Expanded(child: Divider(color: Color(0xFFD0D7DE))),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Text('OR', style: TextStyle(color: Color(0xFF57606A))),
                    ),
                    Expanded(child: Divider(color: Color(0xFFD0D7DE))),
                  ],
                ).animate().fadeIn(delay: 500.ms),
                const SizedBox(height: 32),

                // Manual Token Fallback
                TextField(
                  controller: _tokenController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Personal Access Token',
                    prefixIcon: const Icon(Icons.key),
                    errorText: _errorMessage,
                  ),
                  onSubmitted: (_) => _login(),
                ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.2),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: (_isLoading || _isOAuthLoading) ? null : _login,
                  child: _isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text('Sign In with Token'),
                ).animate().fadeIn(delay: 700.ms).slideY(begin: 0.2),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
