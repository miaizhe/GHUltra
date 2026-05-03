import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../services/github_service.dart';
import '../widgets/repo_card.dart';

class HomeScreen extends StatefulWidget {
  final String token;
  final bool isTab;

  const HomeScreen({super.key, required this.token, this.isTab = false});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late GitHubService _service;
  List<dynamic>? _repositories;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _service = GitHubService(widget.token);
    _loadData();
  }

  Future<void> _loadData() async {
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
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: widget.isTab ? null : AppBar(
        title: const Text('Repositories'),
        backgroundColor: Colors.transparent,
      ),
      body: _buildBody(),
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
              onPressed: _loadData,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: _repositories?.length ?? 0,
        itemBuilder: (context, index) {
          final repo = _repositories![index];
          return RepoCard(repo: repo)
              .animate()
              .fadeIn(delay: (50 * index).ms)
              .slideX(begin: 0.1);
        },
      ),
    );
  }
}
