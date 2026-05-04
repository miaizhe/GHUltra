import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../services/github_service.dart';
import '../widgets/repo_card.dart';
import '../l10n/app_localizations.dart';

class HomeScreen extends StatefulWidget {
  final String token;
  final bool isTab;

  const HomeScreen({super.key, required this.token, this.isTab = false});

  @override
  State<HomeScreen> createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  late GitHubService _service;
  final TextEditingController _searchController = TextEditingController();
  List<dynamic>? _repositories;
  List<dynamic>? _filteredRepositories;
  bool _isLoading = true;
  String? _error;
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _service = GitHubService(widget.token);
    loadData();
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

  Future<void> loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await _service.getUserProfile(); // Validate token still works
      final repos = await _service.getUserRepositories();
      
      if (mounted) {
        setState(() {
          _repositories = repos;
          _filteredRepositories = repos;
          _isLoading = false;
          _filterRepositories(); // re-apply filter if search was active
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
      backgroundColor: Colors.transparent,
      appBar: widget.isTab ? null : AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: context.l10n('search'),
                  border: InputBorder.none,
                  hintStyle: const TextStyle(color: Colors.grey),
                ),
                style: const TextStyle(color: Colors.black),
              )
            : Text(context.l10n('repositories')),
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                if (_isSearching) {
                  _isSearching = false;
                  _searchController.clear();
                } else {
                  _isSearching = true;
                }
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: loadData,
          ),
        ],
      ),
      body: widget.isTab ? _buildTabBody(context) : _buildBody(),
    );
  }

  Widget _buildTabBody(BuildContext context) {
    return Column(
      children: [
        AppBar(
          title: Text(context.l10n('repositories')),
          backgroundColor: Colors.transparent,
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: loadData,
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: context.l10n('search_hint'),
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
        ),
        Expanded(child: _buildBody()),
      ],
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
            const SizedBox(height: 16),
            Text(_error!, style: const TextStyle(color: Colors.redAccent)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: loadData,
              child: Text(context.l10n('retry')),
            ),
          ],
        ),
      );
    }

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: loadData,
        child: ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: _filteredRepositories?.length ?? 0,
          itemBuilder: (context, index) {
            final repo = _filteredRepositories![index];
            return RepoCard(repo: repo)
                .animate()
                .fadeIn(delay: (50 * index).ms)
                .slideX(begin: 0.1);
          },
        ),
      ),
    );
  }
}
