import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

class OAuthService {
  // Replace these with your actual GitHub OAuth App credentials.
  // DO NOT COMMIT REAL SECRETS IN PRODUCTION. 
  // For a public client, you usually use a proxy server, but for local testing:
  static const String clientId = 'Ov23ligEuF8mGYEWVbOR'; 
  static const String clientSecret = '83a694c076814a07884078c853faa884e9daf319';
  
  static const int _port = 8080;
  static const String _redirectUri = 'http://localhost:$_port/callback';

  Future<String?> authenticate() async {
    // 1. Start local server to listen for the redirect
    HttpServer server = await HttpServer.bind(InternetAddress.loopbackIPv4, _port);
    
    // 2. Open browser for user to authenticate
    final authUrl = Uri.parse(
        'https://github.com/login/oauth/authorize?client_id=$clientId&redirect_uri=$_redirectUri&scope=repo,user');
    
    if (await canLaunchUrl(authUrl)) {
      await launchUrl(authUrl, mode: LaunchMode.externalApplication);
    } else {
      server.close();
      throw Exception('Could not launch browser');
    }

    // 3. Wait for the redirect callback
    String? code;
    await for (HttpRequest request in server) {
      if (request.uri.path == '/callback') {
        code = request.uri.queryParameters['code'];
        
        request.response
          ..statusCode = HttpStatus.ok
          ..headers.contentType = ContentType.html
          ..write('<html><body><h1>Authentication Successful!</h1><p>You can close this window and return to GHUltra.</p><script>window.close();</script></body></html>');
        await request.response.close();
        break; // Stop listening after we get the code
      }
    }
    
    await server.close();

    if (code != null) {
      // 4. Exchange code for token
      return await _exchangeCodeForToken(code);
    }
    return null;
  }

  Future<String?> _exchangeCodeForToken(String code) async {
    final response = await http.post(
      Uri.parse('https://github.com/login/oauth/access_token'),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'client_id': clientId,
        'client_secret': clientSecret,
        'code': code,
        'redirect_uri': _redirectUri,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['access_token'];
    } else {
      throw Exception('Failed to exchange code for token');
    }
  }
}
