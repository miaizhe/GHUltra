import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../services/github_service.dart';
import '../widgets/repo_card.dart';

class SearchScreen extends StatefulWidget {
  final String token;
  final bool isTab;

  const SearchScreen({super.key, required this.token, this.isTab = false});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  late GitHubService _service;
  final _searchController = TextEditingController();
  List<dynamic>? _searchResults;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _service = GitHubService(widget.token);
  }

  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final results = await _service.searchRepositories(query.trim());
      if (mounted) {
        setState(() {
          _searchResults = results;
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
    final searchField = TextField(
      controller: _searchController,
      autofocus: !widget.isTab,
      decoration: InputDecoration(
        hintText: 'Search GitHub repositories...',
        prefixIcon: widget.isTab ? const Icon(Icons.search) : null,
        border: widget.isTab ? OutlineInputBorder(borderRadius: BorderRadius.circular(12)) : InputBorder.none,
        enabledBorder: widget.isTab ? OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.grey, width: 1.0),
        ) : InputBorder.none,
        focusedBorder: widget.isTab ? OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.blue, width: 2.0),
        ) : InputBorder.none,
        filled: widget.isTab,
        contentPadding: widget.isTab ? const EdgeInsets.symmetric(horizontal: 16, vertical: 12) : EdgeInsets.zero,
        suffixIcon: IconButton(
          icon: const Icon(Icons.clear),
          onPressed: () {
            _searchController.clear();
            setState(() {
              _searchResults = null;
            });
          },
        ),
      ),
      textInputAction: TextInputAction.search,
      onSubmitted: _performSearch,
    );

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: widget.isTab ? null : AppBar(
        backgroundColor: Colors.transparent,
        title: searchField,
      ),
      body: widget.isTab
          ? SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: searchField,
                  ),
                  Expanded(child: _buildBody()),
                ],
              ),
            )
          : _buildBody(),
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
          ],
        ),
      );
    }

    if (_searchResults == null) {
      return Center(
        child: Animate(
          effects: const [FadeEffect(), ScaleEffect()],
          child: const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.search, size: 64, color: Color(0xFFD0D7DE)),
              SizedBox(height: 16),
              Text(
                'Type to search repositories globally',
                style: TextStyle(color: Color(0xFF57606A), fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }

    if (_searchResults!.isEmpty) {
      return const Center(
        child: Text(
          'No repositories found.',
          style: TextStyle(color: Color(0xFF57606A), fontSize: 16),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: _searchResults!.length,
      itemBuilder: (context, index) {
        final repo = _searchResults![index];
        return RepoCard(repo: repo)
            .animate()
            .fadeIn(delay: (30 * index).ms)
            .slideX(begin: 0.1);
      },
    );
  }
}
