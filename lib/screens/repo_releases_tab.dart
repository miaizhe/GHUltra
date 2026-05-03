import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/github_service.dart';

class RepoReleasesTab extends StatefulWidget {
  final Map<String, dynamic> repo;
  final GitHubService service;

  const RepoReleasesTab({super.key, required this.repo, required this.service});

  @override
  State<RepoReleasesTab> createState() => _RepoReleasesTabState();
}

class _RepoReleasesTabState extends State<RepoReleasesTab> {
  List<dynamic>? _releases;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadReleases();
  }

  Future<void> _loadReleases() async {
    try {
      final fullName = widget.repo['full_name'];
      final releases = await widget.service.getReleases(fullName);
      if (mounted) {
        setState(() {
          _releases = releases;
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

  Future<void> _launchUrl(String urlString) async {
    final url = Uri.parse(urlString);
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open download link')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_error != null) return Center(child: Text(_error!, style: const TextStyle(color: Colors.red)));
    if (_releases == null || _releases!.isEmpty) {
      return const Center(child: Text('No releases found.'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _releases!.length,
      itemBuilder: (context, index) {
        final release = _releases![index];
        final List<dynamic> assets = release['assets'] ?? [];

        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.local_offer, color: Color(0xFF2DA44E)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        release['name'] ?? release['tag_name'] ?? 'Unnamed Release',
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                    ),
                    if (release['prerelease'] == true)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF8C5), // yellow
                          border: Border.all(color: const Color(0xFFD4A72C)),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text('Pre-release', style: TextStyle(fontSize: 12, color: Color(0xFF9A6700))),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFDAFBE1), // green
                          border: Border.all(color: const Color(0xFF2DA44E)),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text('Latest', style: TextStyle(fontSize: 12, color: Color(0xFF1A7F37))),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Published at ${release['published_at']?.toString().split('T').first ?? 'Unknown date'}',
                  style: const TextStyle(color: Color(0xFF57606A), fontSize: 12),
                ),
                const SizedBox(height: 16),
                if (release['body'] != null && release['body'].toString().isNotEmpty) ...[
                  MarkdownBody(
                    data: release['body'],
                    selectable: true,
                  ),
                  const SizedBox(height: 16),
                ],
                if (assets.isNotEmpty) ...[
                  const Divider(),
                  const Text('Assets', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 8),
                  ...assets.map((asset) {
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.download),
                      title: Text(asset['name']),
                      subtitle: Text('${(asset['size'] / 1024 / 1024).toStringAsFixed(2)} MB'),
                      trailing: IconButton(
                        icon: const Icon(Icons.open_in_new),
                        tooltip: 'Download',
                        onPressed: () => _launchUrl(asset['browser_download_url']),
                      ),
                      onTap: () => _launchUrl(asset['browser_download_url']),
                    );
                  }).toList(),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
