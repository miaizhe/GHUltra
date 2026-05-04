import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/github_service.dart';
import '../screens/repo_detail_screen.dart';
import '../screens/issue_detail_screen.dart';
import '../screens/webview_screen.dart';
import '../screens/file_viewer_screen.dart';

import '../screens/user_profile_screen.dart';

Future<void> handleGitHubLink(BuildContext context, String url, GitHubService service, {String? currentRepoFullName, String? currentBranch, String? currentFilePath}) async {
  try {
    Uri uri = Uri.parse(url);
    
    // Check if it's just an internal hash link like "#readme"
    if (!uri.hasScheme && uri.path.isEmpty && uri.hasFragment) {
      return; // Do nothing for simple anchor links
    }

    // Resolve relative links
    if (!uri.hasScheme) {
      if (currentRepoFullName != null) {
        String cleanPath = uri.path;
        if (currentFilePath != null) {
          // Resolve against the current file's path (handles ../ and ./ automatically)
          cleanPath = Uri.parse(currentFilePath).resolve(url).path;
        } else {
          if (cleanPath.startsWith('./')) cleanPath = cleanPath.substring(2);
        }
        if (cleanPath.startsWith('/')) cleanPath = cleanPath.substring(1);
        
        _showLoading(context);
        try {
          final fileInfo = await service.getFileInfo(currentRepoFullName, cleanPath, branch: currentBranch);
          if (context.mounted) {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => FileViewerScreen(
                  fileItem: fileInfo,
                  service: service,
                  repoFullName: currentRepoFullName,
                  branch: currentBranch,
                ),
              ),
            );
            return;
          }
        } catch (e) {
          if (context.mounted) Navigator.pop(context);
          // If it fails (e.g. it's a directory), fallback to webview or external browser
          // For 404s, we show an alert dialog in the app instead of jumping to the browser.
          if (e.toString().contains('404') || e.toString().contains('Not Found')) {
            if (context.mounted) {
              showDialog(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text('Not Found'),
                  content: Text('The path "$cleanPath" could not be found in this branch.'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('OK'),
                    ),
                  ],
                ),
              );
            }
            return;
          }
          
          // If it's not a 404, it might be a directory. Let's try to fetch it as a directory.
          try {
            _showLoading(context);
            final dirInfo = await service.getRepoContents(currentRepoFullName, path: cleanPath, branch: currentBranch);
            if (context.mounted) {
              Navigator.pop(context);
              showDialog(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text('Directory Link'),
                  content: Text('Navigating directly to directories ("$cleanPath") via links is not fully supported in-app yet. Please navigate through the Code tab.'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('OK'),
                    ),
                  ],
                ),
              );
              return;
            }
          } catch (e2) {
             if (context.mounted) Navigator.pop(context);
          }

          // Otherwise build an absolute github.com URL and fallback to webview
          url = 'https://github.com/$currentRepoFullName/blob/${currentBranch ?? 'HEAD'}/$cleanPath';
          uri = Uri.parse(url);
        }
      } else {
        // We cannot handle relative link without context, but we shouldn't throw it to the browser as a relative URL.
        // It will just fail in the browser too.
        return; 
      }
    }

    if (uri.host == 'github.com') {
      final pathSegments = uri.pathSegments;
      
      // https://github.com/owner/repo
      if (pathSegments.length == 2) {
        final fullName = '${pathSegments[0]}/${pathSegments[1]}';
        _showLoading(context);
        try {
          final repoInfo = await service.getRepoInfo(fullName);
          if (context.mounted) {
            Navigator.pop(context); // close loading
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => RepoDetailScreen(repo: repoInfo, token: service.token),
              ),
            );
            return;
          }
        } catch (e) {
          if (context.mounted) Navigator.pop(context); // close loading
          // fallback to external if API fails
        }
      }
      
      // https://github.com/username
      else if (pathSegments.length == 1) {
        final username = pathSegments[0];
        _showLoading(context);
        try {
          // Try to fetch user info to confirm it's a user
          await service.getUserInfo(username);
          if (context.mounted) {
            Navigator.pop(context); // close loading
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => UserProfileScreen(username: username, service: service),
              ),
            );
            return;
          }
        } catch (e) {
          if (context.mounted) Navigator.pop(context); // close loading
          // If not a user (or API failed), fallback
        }
      }
      
      // https://github.com/owner/repo/blob/...
      else if (pathSegments.length >= 4 && pathSegments[2] == 'blob') {
        final fullName = '${pathSegments[0]}/${pathSegments[1]}';
        final branch = pathSegments[3];
        final filePath = pathSegments.sublist(4).join('/');
        
        _showLoading(context);
        try {
          final fileInfo = await service.getFileInfo(fullName, filePath, branch: branch);
          if (context.mounted) {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => FileViewerScreen(
                  fileItem: fileInfo,
                  service: service,
                  repoFullName: fullName,
                  branch: branch,
                ),
              ),
            );
            return;
          }
        } catch (e) {
          if (context.mounted) Navigator.pop(context);
          if (e.toString().contains('404') || e.toString().contains('Not Found')) {
            if (context.mounted) {
              showDialog(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text('Not Found'),
                  content: Text('The path "$filePath" could not be found in this branch.'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('OK'),
                    ),
                  ],
                ),
              );
            }
            return; // Exit here so it doesn't fallback to the browser
          }
        }
      }
      
      // https://github.com/owner/repo/tree/... (Directory links)
      else if (pathSegments.length >= 4 && pathSegments[2] == 'tree') {
        final fullName = '${pathSegments[0]}/${pathSegments[1]}';
        final branch = pathSegments[3];
        final dirPath = pathSegments.sublist(4).join('/');

        _showLoading(context);
        try {
          // Verify if it exists by getting repo contents
          final contents = await service.getRepoContents(fullName, path: dirPath, branch: branch);
          if (context.mounted) {
            Navigator.pop(context);
            // We do not have a dedicated DirectoryViewerScreen, so we'll just show an alert or fallback
            // But since the user wants to stay in app, let's just show an alert that directories are not viewable directly via link yet.
            showDialog(
              context: context,
              builder: (_) => AlertDialog(
                title: const Text('Directory Link'),
                content: Text('Navigating directly to directories ("$dirPath") via links is not fully supported in-app yet. Please navigate through the Code tab.'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('OK'),
                  ),
                ],
              ),
            );
            return;
          }
        } catch (e) {
          if (context.mounted) Navigator.pop(context);
          if (e.toString().contains('404') || e.toString().contains('Not Found')) {
            if (context.mounted) {
              showDialog(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text('Not Found'),
                  content: Text('The directory "$dirPath" could not be found in this branch.'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('OK'),
                    ),
                  ],
                ),
              );
            }
            return; // Exit here
          }
        }
      }
      else if (pathSegments.length >= 4 && (pathSegments[2] == 'issues' || pathSegments[2] == 'pull')) {
        final fullName = '${pathSegments[0]}/${pathSegments[1]}';
        final issueNumberStr = pathSegments[3];
        final issueNumber = int.tryParse(issueNumberStr);
        
        if (issueNumber != null) {
          _showLoading(context);
          try {
            final issueInfo = await service.getIssue(fullName, issueNumber);
            if (context.mounted) {
              Navigator.pop(context); // close loading
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => IssueDetailScreen(
                    issue: issueInfo,
                    repoFullName: fullName,
                    service: service,
                  ),
                ),
              );
              return;
            }
          } catch (e) {
            if (context.mounted) Navigator.pop(context); // close loading
            // fallback
          }
        }
      }
    }

    // Default fallback: open in external browser or webview
    // Note: If we explicitly know it's a 404 from a relative link, we handled it above.
    // If it's a raw github link that fails some other way, we still fallback.
    // Also, if it's an internal fragment link that somehow bypassed the first check (unlikely), don't open browser.
    if (!uri.hasScheme && uri.hasFragment && uri.path.isEmpty) return;

    // If it is a github.com link and we reached here (e.g. 404 on an absolute path, or a directory path),
    // and the user specifically requested 404s not to jump to browser, we should intercept it.
    // But since it's hard to know if it's a 404 without making a request, and we already made requests above,
    // if it fell through, it means it's a link we don't natively support (like a directory blob link, or tree link).
    // Let's just open it in the webview/browser as fallback.
    if (Theme.of(context).platform == TargetPlatform.macOS) {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => WebViewScreen(url: url, title: 'Web'),
        ),
      );
    }
  } catch (e) {
    debugPrint('Error handling link: $e');
  }
}

void _showLoading(BuildContext context) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => const Center(child: CircularProgressIndicator()),
  );
}
