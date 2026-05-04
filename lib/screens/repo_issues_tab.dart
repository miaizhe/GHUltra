import 'package:flutter/material.dart';
import '../services/github_service.dart';
import 'issue_detail_screen.dart';

class RepoIssuesTab extends StatefulWidget {
  final Map<String, dynamic> repo;
  final GitHubService service;

  const RepoIssuesTab({super.key, required this.repo, required this.service});

  @override
  State<RepoIssuesTab> createState() => _RepoIssuesTabState();
}

class _RepoIssuesTabState extends State<RepoIssuesTab> {
  List<dynamic>? _issues;
  bool _isLoading = true;
  String? _error;
  String _currentState = 'open'; // 'open' or 'closed'

  @override
  void initState() {
    super.initState();
    _loadIssues();
  }

  Future<void> _loadIssues() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final issues = await widget.service.getIssues(
        widget.repo['full_name'], 
        state: _currentState
      );
      
      // The GitHub API returns pull requests in the issues endpoint too,
      // so we might want to filter them out if we strictly want issues.
      final filteredIssues = issues.where((issue) => issue['pull_request'] == null).toList();

      if (mounted) {
        setState(() {
          _issues = filteredIssues;
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

  void _openIssue(Map<String, dynamic> issue) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => IssueDetailScreen(
          issue: issue,
          repoFullName: widget.repo['full_name'],
          service: widget.service,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Status filter
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          color: Colors.white,
          child: Row(
            children: [
              FilterChip(
                label: const Text('Open'),
                selected: _currentState == 'open',
                onSelected: (selected) {
                  if (selected && _currentState != 'open') {
                    setState(() => _currentState = 'open');
                    _loadIssues();
                  }
                },
                selectedColor: Colors.green.withOpacity(0.2),
                checkmarkColor: Colors.green,
              ),
              const SizedBox(width: 8),
              FilterChip(
                label: const Text('Closed'),
                selected: _currentState == 'closed',
                onSelected: (selected) {
                  if (selected && _currentState != 'closed') {
                    setState(() => _currentState = 'closed');
                    _loadIssues();
                  }
                },
                selectedColor: Colors.red.withOpacity(0.2),
                checkmarkColor: Colors.red,
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: _loadIssues,
                tooltip: 'Refresh Issues',
              )
            ],
          ),
        ),
        const Divider(height: 1),
        // Issues List
        Expanded(
          child: _buildBody(),
        ),
      ],
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(child: Text(_error!, style: const TextStyle(color: Colors.red)));
    }

    if (_issues == null || _issues!.isEmpty) {
      return Center(
        child: Text(
          'No $_currentState issues found.',
          style: const TextStyle(color: Color(0xFF57606A), fontSize: 16),
        ),
      );
    }

    return ListView.separated(
      itemCount: _issues!.length,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final issue = _issues![index];
        final isClosed = issue['state'] == 'closed';
        final IconData icon = isClosed ? Icons.check_circle_outline : Icons.error_outline;
        final Color iconColor = isClosed ? Colors.purple : const Color(0xFF2DA44E);

        return ListTile(
          leading: Icon(icon, color: iconColor),
          title: Text(
            issue['title'],
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '#${issue['number']} opened by ${issue['user']['login']}',
                  style: const TextStyle(color: Color(0xFF57606A), fontSize: 13),
                ),
                if (issue['labels'] != null && (issue['labels'] as List).isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: (issue['labels'] as List).map((label) {
                        final String hexColor = label['color'] ?? 'dEDEDE';
                        final Color labelColor = Color(int.parse('FF$hexColor', radix: 16));
                        // Determine text color based on label background luminance
                        final Color textColor = labelColor.computeLuminance() > 0.5 ? Colors.black : Colors.white;

                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: labelColor,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.black12),
                          ),
                          child: Text(
                            label['name'],
                            style: TextStyle(fontSize: 11, color: textColor, fontWeight: FontWeight.w500),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
              ],
            ),
          ),
          trailing: issue['comments'] > 0
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.mode_comment_outlined, size: 14, color: Color(0xFF57606A)),
                    const SizedBox(width: 4),
                    Text('${issue['comments']}', style: const TextStyle(color: Color(0xFF57606A))),
                  ],
                )
              : null,
          onTap: () => _openIssue(issue),
        );
      },
    );
  }
}
