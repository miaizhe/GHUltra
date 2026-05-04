import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../services/github_service.dart';
import '../utils/link_handler.dart';

class IssueDetailScreen extends StatefulWidget {
  final Map<String, dynamic> issue;
  final String repoFullName;
  final GitHubService service;

  const IssueDetailScreen({
    super.key,
    required this.issue,
    required this.repoFullName,
    required this.service,
  });

  @override
  State<IssueDetailScreen> createState() => _IssueDetailScreenState();
}

class _IssueDetailScreenState extends State<IssueDetailScreen> {
  List<dynamic>? _comments;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadComments();
  }

  Future<void> _loadComments() async {
    if (widget.issue['comments'] == 0) {
      if (mounted) {
        setState(() {
          _comments = [];
          _isLoading = false;
        });
      }
      return;
    }

    try {
      final comments = await widget.service.getIssueComments(
        widget.repoFullName,
        widget.issue['number'],
      );
      if (mounted) {
        setState(() {
          _comments = comments;
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

  Widget _buildCommentCard(Map<String, dynamic> comment, {bool isOriginalIssue = false}) {
    final author = comment['user']['login'];
    final avatarUrl = comment['user']['avatar_url'];
    final body = comment['body'] ?? '*No description provided.*';
    final createdAt = DateTime.parse(comment['created_at']).toLocal();
    final timeStr = '${createdAt.year}-${createdAt.month.toString().padLeft(2, '0')}-${createdAt.day.toString().padLeft(2, '0')} ${createdAt.hour.toString().padLeft(2, '0')}:${createdAt.minute.toString().padLeft(2, '0')}';

    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFFD0D7DE), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            decoration: const BoxDecoration(
              color: Color(0xFFF6F8FA),
              borderRadius: BorderRadius.vertical(top: Radius.circular(11)),
              border: Border(bottom: BorderSide(color: Color(0xFFD0D7DE), width: 1)),
            ),
            child: Row(
              children: [
                InkWell(
                  onTap: () => handleGitHubLink(context, 'https://github.com/$author', widget.service),
                  child: CircleAvatar(
                    backgroundImage: NetworkImage(avatarUrl),
                    radius: 14,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      style: const TextStyle(fontSize: 14, color: Color(0xFF24292E)),
                      children: [
                        TextSpan(text: author, style: const TextStyle(fontWeight: FontWeight.w600)),
                        const TextSpan(text: ' commented on '),
                        TextSpan(text: timeStr, style: const TextStyle(color: Color(0xFF57606A))),
                      ],
                    ),
                  ),
                ),
                if (isOriginalIssue)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFFD0D7DE)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text('Author', style: TextStyle(fontSize: 12, color: Color(0xFF57606A))),
                  ),
              ],
            ),
          ),
          // Body
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: MarkdownBody(
              data: body,
              selectable: true,
              onTapLink: (text, href, title) {
                if (href != null) {
                  handleGitHubLink(context, href, widget.service, currentRepoFullName: widget.repoFullName);
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isClosed = widget.issue['state'] == 'closed';
    final IconData statusIcon = isClosed ? Icons.check_circle_outline : Icons.error_outline;
    final Color statusColor = isClosed ? Colors.purple : const Color(0xFF2DA44E);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Issue #${widget.issue['number']}'),
        backgroundColor: Colors.white,
        elevation: 1,
        foregroundColor: Colors.black,
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    widget.issue['title'],
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  // Status Badge & Info
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: statusColor,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(statusIcon, color: Colors.white, size: 16),
                            const SizedBox(width: 4),
                            Text(
                              isClosed ? 'Closed' : 'Open',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          '${widget.issue['user']['login']} opened this issue • ${widget.issue['comments']} comments',
                          style: const TextStyle(color: Color(0xFF57606A), fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  // Original Issue Body
                  _buildCommentCard(widget.issue, isOriginalIssue: true),
                  
                  const Divider(height: 32),
                ],
              ),
            ),
          ),
          
          // Comments
          if (_isLoading)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(32.0),
                child: Center(child: CircularProgressIndicator()),
              ),
            )
          else if (_error != null)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Center(child: Text(_error!, style: const TextStyle(color: Colors.red))),
              ),
            )
          else if (_comments != null && _comments!.isNotEmpty)
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    return _buildCommentCard(_comments![index]);
                  },
                  childCount: _comments!.length,
                ),
              ),
            )
          else
            const SliverToBoxAdapter(child: SizedBox.shrink()),
            
          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    );
  }
}
