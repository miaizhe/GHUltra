import 'package:flutter/material.dart';
import '../services/github_service.dart';
import 'file_viewer_screen.dart';

class RepoCodeTab extends StatefulWidget {
  final Map<String, dynamic> repo;
  final GitHubService service;

  const RepoCodeTab({super.key, required this.repo, required this.service});

  @override
  State<RepoCodeTab> createState() => _RepoCodeTabState();
}

class _RepoCodeTabState extends State<RepoCodeTab> {
  List<dynamic>? _contents;
  Map<String, dynamic>? _latestCommit;
  List<dynamic>? _branches;
  String? _currentBranch;
  bool _isLoading = true;
  String? _error;
  final List<String> _pathStack = [''];

  @override
  void initState() {
    super.initState();
    _currentBranch = widget.repo['default_branch'];
    _loadBranches();
    _loadContents('');
  }

  Future<void> _loadBranches() async {
    try {
      final branches = await widget.service.getBranches(widget.repo['full_name']);
      if (mounted) {
        setState(() {
          _branches = branches;
        });
      }
    } catch (e) {
      // Ignore branch load error
    }
  }

  Future<void> _loadContents(String path) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final fullName = widget.repo['full_name'];
      
      // Load contents and commit in parallel if at root
      Future<List<dynamic>> contentsFuture = widget.service.getRepoContents(fullName, path: path, branch: _currentBranch);
      Future<Map<String, dynamic>?> commitFuture = path.isEmpty ? widget.service.getLatestCommit(fullName, branch: _currentBranch) : Future.value(_latestCommit);
      
      final results = await Future.wait([contentsFuture, commitFuture]);
      final contents = results[0] as List<dynamic>;
      final commit = results[1] as Map<String, dynamic>?;
      
      // Sort: directories first, then files
      contents.sort((a, b) {
        if (a['type'] == 'dir' && b['type'] != 'dir') return -1;
        if (a['type'] != 'dir' && b['type'] == 'dir') return 1;
        return (a['name'] as String).compareTo(b['name'] as String);
      });

      if (mounted) {
        setState(() {
          _contents = contents;
          if (path.isEmpty) _latestCommit = commit;
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

  void _navigateTo(String path) {
    setState(() {
      _pathStack.add(path);
    });
    _loadContents(path);
  }

  void _navigateBack() {
    if (_pathStack.length > 1) {
      setState(() {
        _pathStack.removeLast();
      });
      _loadContents(_pathStack.last);
    }
  }

  Future<void> _syncBranch() async {
    final fullName = widget.repo['full_name'];
    final branch = widget.repo['default_branch'] ?? 'main';
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (c) => const Center(child: CircularProgressIndicator()),
      );
      await widget.service.syncBranch(fullName, branch);
      if (mounted) {
        Navigator.pop(context); // close dialog
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Branch synced successfully!')));
        _loadContents(_pathStack.last); // reload
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // close dialog
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Sync failed: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildBranchSelector(),
        if (_pathStack.length == 1 && _latestCommit != null)
          _buildCommitHeader(),
        if (_pathStack.length > 1)
          ListTile(
            leading: const Icon(Icons.folder_open),
            title: const Text('..'),
            onTap: _navigateBack,
          ),
        const Divider(height: 1),
        Expanded(
          child: _buildBody(),
        ),
      ],
    );
  }

  Widget _buildBranchSelector() {
    if (_branches == null) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.white,
      child: Row(
        children: [
          const Icon(Icons.call_split, size: 20, color: Colors.grey),
          const SizedBox(width: 8),
          DropdownButton<String>(
            value: _currentBranch,
            isDense: true,
            underline: const SizedBox.shrink(),
            items: _branches!.map<DropdownMenuItem<String>>((b) {
              return DropdownMenuItem<String>(
                value: b['name'],
                child: Text(b['name']),
              );
            }).toList(),
            onChanged: (val) {
              if (val != null && val != _currentBranch) {
                setState(() {
                  _currentBranch = val;
                  _pathStack.clear();
                  _pathStack.add('');
                });
                _loadContents('');
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCommitHeader() {
    final commit = _latestCommit!['commit'];
    final author = commit['author']['name'] ?? 'Unknown';
    final message = commit['message'] ?? '';
    final isFork = widget.repo['fork'] == true;

    return Container(
      padding: const EdgeInsets.all(16.0),
      color: Colors.grey.shade50,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.commit, size: 16, color: Colors.grey),
                    const SizedBox(width: 8),
                    Text(author, style: const TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: const TextStyle(color: Colors.black87),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (isFork)
            IconButton(
              icon: const Icon(Icons.sync),
              tooltip: 'Sync branch',
              onPressed: _syncBranch,
            ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_error != null) return Center(child: Text(_error!, style: const TextStyle(color: Colors.red)));
    if (_contents == null || _contents!.isEmpty) return const Center(child: Text('No contents found.'));

    return ListView.builder(
      itemCount: _contents!.length,
      itemBuilder: (context, index) {
        final item = _contents![index];
        final isDir = item['type'] == 'dir';
        return ListTile(
          leading: Icon(
            isDir ? Icons.folder : Icons.insert_drive_file,
            color: isDir ? const Color(0xFF0969DA) : const Color(0xFF57606A),
          ),
          title: Text(item['name']),
          onTap: () {
            if (isDir) {
              _navigateTo(item['path']);
            } else {
              // View file
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => FileViewerScreen(
                    fileItem: item,
                    service: widget.service,
                    repoFullName: widget.repo['full_name'],
                    branch: _currentBranch,
                  ),
                ),
              );
            }
          },
        );
      },
    );
  }
}
