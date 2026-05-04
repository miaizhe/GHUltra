import 'package:flutter/material.dart';
import '../services/github_service.dart';
import '../widgets/repo_card.dart';

class UserProfileScreen extends StatefulWidget {
  final String username;
  final GitHubService service;

  const UserProfileScreen({super.key, required this.username, required this.service});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  Map<String, dynamic>? _userProfile;
  List<dynamic>? _repositories;
  List<dynamic>? _filteredRepositories;
  bool _isLoading = true;
  String? _error;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
    _searchController.addListener(_filterRepositories);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterRepositories() {
    final query = _searchController.text.toLowerCase();
    if (query.isEmpty) {
      setState(() {
        _filteredRepositories = _repositories;
      });
    } else {
      setState(() {
        _filteredRepositories = _repositories?.where((repo) {
          final name = (repo['name'] as String?)?.toLowerCase() ?? '';
          final description = (repo['description'] as String?)?.toLowerCase() ?? '';
          return name.contains(query) || description.contains(query);
        }).toList();
      });
    }
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final profileFuture = widget.service.getUserInfo(widget.username);
      final reposFuture = widget.service.getUserPublicRepositories(widget.username);

      final results = await Future.wait([
        profileFuture.catchError((_) => <String, dynamic>{}),
        reposFuture.catchError((_) => <dynamic>[]),
      ]);

      if (mounted) {
        setState(() {
          _userProfile = results[0] as Map<String, dynamic>?;
          _repositories = results[1] as List<dynamic>?;
          _filteredRepositories = _repositories;
          if (_userProfile == null || _userProfile!.isEmpty) {
            _error = 'User not found';
          }
          _isLoading = false;
          _filterRepositories();
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
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.username),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      backgroundColor: const Color(0xFFF6F8FA),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_error != null) return Center(child: Text(_error!, style: const TextStyle(color: Colors.red)));
    if (_userProfile == null || _userProfile!.isEmpty) return const Center(child: Text('User not found.'));

    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 40,
              backgroundImage: NetworkImage(_userProfile!['avatar_url'] ?? ''),
              backgroundColor: Colors.transparent,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _userProfile!['name'] ?? _userProfile!['login'] ?? 'Unknown User',
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '@${_userProfile!['login']}',
                    style: const TextStyle(fontSize: 16, color: Color(0xFF57606A)),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (_userProfile!['bio'] != null) ...[
          Text(_userProfile!['bio'], style: const TextStyle(fontSize: 16)),
          const SizedBox(height: 16),
        ],
        Row(
          children: [
            const Icon(Icons.group, size: 16, color: Color(0xFF57606A)),
            const SizedBox(width: 4),
            Text('${_userProfile!['followers'] ?? 0} followers', style: const TextStyle(color: Color(0xFF57606A))),
            const SizedBox(width: 16),
            Text('${_userProfile!['following'] ?? 0} following', style: const TextStyle(color: Color(0xFF57606A))),
          ],
        ),
        const SizedBox(height: 24),
        const Divider(),
        const SizedBox(height: 16),
        const Text('Public Repositories', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Find a repository...',
            prefixIcon: const Icon(Icons.search),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.0),
              borderSide: const BorderSide(color: Color(0xFFD0D7DE)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.0),
              borderSide: const BorderSide(color: Color(0xFFD0D7DE)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.0),
              borderSide: const BorderSide(color: Color(0xFF0969DA), width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            filled: true,
            fillColor: const Color(0xFFF6F8FA),
          ),
        ),
        const SizedBox(height: 16),
        if (_filteredRepositories == null || _filteredRepositories!.isEmpty)
          const Text('No public repositories found.', style: TextStyle(color: Color(0xFF57606A)))
        else
          ..._filteredRepositories!.map((repo) => Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: RepoCard(repo: repo),
          )),
      ],
    );
  }
}
