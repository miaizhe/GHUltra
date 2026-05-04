import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../services/github_service.dart';

class RepoOverviewTab extends StatefulWidget {
  final Map<String, dynamic> repo;
  final GitHubService service;

  const RepoOverviewTab({super.key, required this.repo, required this.service});

  @override
  State<RepoOverviewTab> createState() => _RepoOverviewTabState();
}

class _RepoOverviewTabState extends State<RepoOverviewTab> {
  String? _readmeContent;
  String? _licenseContent;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final fullName = widget.repo['full_name'];
      final results = await Future.wait([
        widget.service.getReadme(fullName).catchError((_) => <String, dynamic>{}),
        widget.service.getLicense(fullName).catchError((_) => <String, dynamic>{}),
      ]);
      
      final readmeData = results[0];
      final licenseData = results[1];

      String rContent = '';
      if (readmeData.isNotEmpty && readmeData['content'] != null) {
        rContent = utf8.decode(base64.decode(readmeData['content'].replaceAll('\n', '')));
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
          _licenseContent = lContent;
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
                child: Text(
                  widget.repo['full_name'],
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF0969DA)),
                ),
              ),
            ],
          ),
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
