import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../services/github_service.dart';
import 'repo_detail_screen.dart';
import '../utils/link_handler.dart';

class RepoOverviewTab extends StatefulWidget {
  final Map<String, dynamic> repo;
  final GitHubService service;

  const RepoOverviewTab({super.key, required this.repo, required this.service});

  @override
  State<RepoOverviewTab> createState() => RepoOverviewTabState();
}

class RepoOverviewTabState extends State<RepoOverviewTab> {
  String? _readmeContent;
  String? _readmePath;
  String? _licenseContent;
  Map<String, dynamic>? _repoInfo;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final fullName = widget.repo['full_name'];
      final results = await Future.wait([
        widget.service.getReadme(fullName).catchError((_) => <String, dynamic>{}),
        widget.service.getLicense(fullName).catchError((_) => <String, dynamic>{}),
        widget.service.getRepoInfo(fullName).catchError((_) => <String, dynamic>{}),
      ]);
      
      final readmeData = results[0];
      final licenseData = results[1];
      final repoInfo = results[2];

      String rContent = '';
      String? rPath;
      if (readmeData.isNotEmpty && readmeData['content'] != null) {
        rContent = utf8.decode(base64.decode(readmeData['content'].replaceAll('\n', '')));
        rPath = readmeData['path'];
      } else {
        rContent = '*No README found for this repository.*';
      }

      String lContent = '';
      if (licenseData.isNotEmpty && licenseData['content'] != null) {
        lContent = utf8.decode(base64.decode(licenseData['content'].replaceAll('\n', '')));
      }

      if (mounted) {
        setState(() {
          _readmeContent = rContent;
          _readmePath = rPath;
          _licenseContent = lContent;
          _repoInfo = repoInfo;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load overview data';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Repo Info Header
          Row(
            children: [
              const Icon(Icons.book, size: 32, color: Color(0xFF0969DA)),
              const SizedBox(width: 12),
              Expanded(
                child: InkWell(
                  onTap: () {
                    final owner = widget.repo['owner']['login'];
                    handleGitHubLink(context, 'https://github.com/$owner', widget.service);
                  },
                  child: Text(
                    widget.repo['full_name'],
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF0969DA)),
                  ),
                ),
              ),
            ],
          ),
          if (_repoInfo != null && _repoInfo!['parent'] != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.call_split, size: 16, color: Color(0xFF57606A)),
                const SizedBox(width: 8),
                const Text('forked from ', style: TextStyle(color: Color(0xFF57606A))),
                InkWell(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => RepoDetailScreen(
                          repo: _repoInfo!['parent'],
                          token: widget.service.token,
                        ),
                      ),
                    );
                  },
                  child: Text(
                    _repoInfo!['parent']['full_name'],
                    style: const TextStyle(
                      color: Color(0xFF0969DA),
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 16),
          if (widget.repo['description'] != null) ...[
            Text(
              widget.repo['description'],
              style: const TextStyle(fontSize: 16, color: Color(0xFF57606A)),
            ),
            const SizedBox(height: 16),
          ],
          Row(
            children: [
              const Icon(Icons.star_border, size: 20, color: Color(0xFF57606A)),
              const SizedBox(width: 4),
              Text('${widget.repo['stargazers_count'] ?? 0} stars', style: const TextStyle(color: Color(0xFF57606A))),
              const SizedBox(width: 16),
              const Icon(Icons.call_split, size: 20, color: Color(0xFF57606A)),
              const SizedBox(width: 4),
              Text('${widget.repo['forks_count'] ?? 0} forks', style: const TextStyle(color: Color(0xFF57606A))),
              if (widget.repo['license'] != null && widget.repo['license']['name'] != null) ...[
                const SizedBox(width: 16),
                const Icon(Icons.gavel, size: 20, color: Color(0xFF57606A)),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    widget.repo['license']['name'],
                    style: const TextStyle(color: Color(0xFF57606A)),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),
          // Clone options
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final cloneUrl = widget.repo['clone_url'];
                    if (cloneUrl != null) {
                      await Clipboard.setData(ClipboardData(text: cloneUrl));
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('HTTPS Clone URL copied to clipboard')),
                        );
                      }
                    }
                  },
                  icon: const Icon(Icons.link, size: 16),
                  label: const Text('HTTPS', style: TextStyle(fontSize: 12)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF24292E),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final sshUrl = widget.repo['ssh_url'];
                    if (sshUrl != null) {
                      await Clipboard.setData(ClipboardData(text: sshUrl));
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('SSH Clone URL copied to clipboard')),
                        );
                      }
                    }
                  },
                  icon: const Icon(Icons.terminal, size: 16),
                  label: const Text('SSH', style: TextStyle(fontSize: 12)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF24292E),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 16),
          
          // README Section
          const Text(
            'README',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildReadme(),
          
          if (_licenseContent != null && _licenseContent!.isNotEmpty) ...[
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),
            const Text(
              'License',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildLicense(),
          ],
        ],
      ),
    );
  }

  Widget _buildReadme() {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_error != null) return Text(_error!, style: const TextStyle(color: Colors.red));
    
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFD0D7DE)),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(16),
      child: MarkdownBody(
        data: _readmeContent ?? '',
        selectable: true,
        onTapLink: (text, href, title) {
          if (href != null) {
            handleGitHubLink(
              context, 
              href, 
              widget.service, 
              currentRepoFullName: widget.repo['full_name'],
              currentBranch: widget.repo['default_branch'],
              currentFilePath: _readmePath,
            );
          }
        },
      ),
    );
  }

  Widget _buildLicense() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFD0D7DE)),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(16),
      child: SelectableText(
        _licenseContent ?? '',
        style: const TextStyle(
          fontFamily: 'monospace',
          fontSize: 13,
          color: Color(0xFF24292E),
        ),
      ),
    );
  }
}
