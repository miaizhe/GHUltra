import 'package:flutter/material.dart';
import '../services/github_service.dart';
import 'repo_overview_tab.dart';
import 'repo_code_tab.dart';
import 'repo_issues_tab.dart';
import 'repo_actions_tab.dart';
import 'repo_search_tab.dart';
import 'repo_releases_tab.dart';
import 'repo_settings_tab.dart';

class RepoDetailScreen extends StatefulWidget {
  final Map<String, dynamic> repo;
  final String token;

  const RepoDetailScreen({super.key, required this.repo, required this.token});

  @override
  State<RepoDetailScreen> createState() => _RepoDetailScreenState();
}

class _RepoDetailScreenState extends State<RepoDetailScreen> {
  late GitHubService _service;
  final GlobalKey<RepoOverviewTabState> _overviewKey = GlobalKey<RepoOverviewTabState>();
  
  bool _isStarred = false;
  bool _isCheckingStar = true;
  bool _isOwnRepo = true; // Assume true until we know otherwise

  @override
  void initState() {
    super.initState();
    _service = GitHubService(widget.token);
    _checkStatus();
  }

  Future<void> _checkStatus() async {
    try {
      final profile = await _service.getUserProfile();
      final isOwn = profile['login'] == widget.repo['owner']['login'];
      
      bool isStarred = false;
      if (!isOwn) {
        isStarred = await _service.checkStarStatus(widget.repo['full_name']);
      }
      
      if (mounted) {
        setState(() {
          _isOwnRepo = isOwn;
          _isStarred = isStarred;
          _isCheckingStar = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isCheckingStar = false;
        });
      }
    }
  }

  Future<void> _toggleStar() async {
    final originalState = _isStarred;
    setState(() {
      _isStarred = !_isStarred;
    });
    try {
      if (originalState) {
        await _service.unstarRepo(widget.repo['full_name']);
      } else {
        await _service.starRepo(widget.repo['full_name']);
      }
    } catch (e) {
      setState(() {
        _isStarred = originalState;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to update star status')));
      }
    }
  }

  Future<void> _forkRepo() async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Forking repository...')));
      final forkedRepo = await _service.forkRepo(widget.repo['full_name']);
      
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        final forkedName = forkedRepo['full_name'] ?? 'your account';
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Successfully forked to $forkedName.'),
            action: forkedRepo['full_name'] != null ? SnackBarAction(
              label: 'View',
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => RepoDetailScreen(
                      repo: forkedRepo,
                      token: widget.token,
                    ),
                  ),
                );
              },
            ) : null,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        // Show a dialog with the exact error so we can debug it
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Fork Error'),
            content: SingleChildScrollView(child: Text(e.toString())),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 7,
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.repo['name']),
          actions: [
            if (!_isOwnRepo) ...[
              if (_isCheckingStar)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0),
                  child: Center(
                    child: SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                )
              else
                IconButton(
                  icon: Icon(_isStarred ? Icons.star : Icons.star_border),
                  color: _isStarred ? Colors.amber : null,
                  tooltip: _isStarred ? 'Unstar' : 'Star',
                  onPressed: _toggleStar,
                ),
              IconButton(
                icon: const Icon(Icons.call_split),
                tooltip: 'Fork',
                onPressed: _forkRepo,
              ),
            ],
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'Refresh Data',
              onPressed: () {
                _overviewKey.currentState?.loadData();
              },
            ),
          ],
          bottom: const TabBar(
            isScrollable: true,
            labelColor: Color(0xFF0969DA),
            unselectedLabelColor: Color(0xFF57606A),
            indicatorColor: Color(0xFF0969DA),
            tabs: [
              Tab(icon: Icon(Icons.info_outline), text: 'Overview'),
              Tab(icon: Icon(Icons.code), text: 'Code'),
              Tab(icon: Icon(Icons.error_outline), text: 'Issues'),
              Tab(icon: Icon(Icons.local_offer_outlined), text: 'Releases'),
              Tab(icon: Icon(Icons.play_circle_outline), text: 'Actions'),
              Tab(icon: Icon(Icons.search), text: 'Search'),
              Tab(icon: Icon(Icons.settings), text: 'Settings'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            RepoOverviewTab(key: _overviewKey, repo: widget.repo, service: _service),
            RepoCodeTab(repo: widget.repo, service: _service),
            RepoIssuesTab(repo: widget.repo, service: _service),
            RepoReleasesTab(repo: widget.repo, service: _service),
            RepoActionsTab(repo: widget.repo, service: _service),
            RepoSearchTab(repo: widget.repo, service: _service),
            RepoSettingsTab(repo: widget.repo, service: _service),
          ],
        ),
      ),
    );
  }
}
