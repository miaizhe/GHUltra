import 'package:flutter/material.dart';
import '../services/github_service.dart';
import 'file_viewer_screen.dart';

class RepoSearchTab extends StatefulWidget {
  final Map<String, dynamic> repo;
  final GitHubService service;

  const RepoSearchTab({super.key, required this.repo, required this.service});

  @override
  State<RepoSearchTab> createState() => _RepoSearchTabState();
}

class _RepoSearchTabState extends State<RepoSearchTab> {
  final _searchController = TextEditingController();
  List<dynamic>? _results;
  bool _isLoading = false;
  String? _error;

  Future<void> _search(String query) async {
    if (query.trim().isEmpty) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final fullName = widget.repo['full_name'];
      
      // Delay slightly to prevent rate limiting if the user types quickly
      // In a real app we should use debouncing, but this is a simple wait
      await Future.delayed(const Duration(milliseconds: 500));
      
      // If the user cleared the search box during the delay, abort.
      if (_searchController.text.trim() != query.trim()) return;

      final results = await widget.service.searchCode(fullName, query.trim());
      if (mounted) {
        setState(() {
          _results = results;
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

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search code in this repository...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  _searchController.clear();
                  setState(() {
                    _results = null;
                  });
                },
              ),
            ),
            onSubmitted: _search,
          ),
        ),
        Expanded(
          child: _buildResults(),
        ),
      ],
    );
  }

  Widget _buildResults() {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_error != null) return Center(child: Text(_error!, style: const TextStyle(color: Colors.red)));
    if (_results == null) return const Center(child: Text('Type to search code'));
    if (_results!.isEmpty) return const Center(child: Text('No results found.'));

    return ListView.builder(
      itemCount: _results!.length,
      itemBuilder: (context, index) {
        final item = _results![index];
        return ListTile(
          leading: const Icon(Icons.code),
          title: Text(item['name']),
          subtitle: Text(item['path']),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => FileViewerScreen(
                  fileItem: {
                    'name': item['name'],
                    'url': item['url'],
                  },
                  service: widget.service,
                ),
              ),
            );
          },
        );
      },
    );
  }
}
