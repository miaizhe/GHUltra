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
  bool _isLoading = true;
  String? _error;
  final List<String> _pathStack = [''];

  @override
  void initState() {
    super.initState();
    _loadContents('');
  }

  Future<void> _loadContents(String path) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final fullName = widget.repo['full_name'];
      final contents = await widget.service.getRepoContents(fullName, path);
      
      // Sort: directories first, then files
      contents.sort((a, b) {
        if (a['type'] == 'dir' && b['type'] != 'dir') return -1;
        if (a['type'] != 'dir' && b['type'] == 'dir') return 1;
        return (a['name'] as String).compareTo(b['name'] as String);
      });

      if (mounted) {
        setState(() {
          _contents = contents;
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

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
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
