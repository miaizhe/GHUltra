import 'package:flutter/material.dart';
import '../services/github_service.dart';
import 'repo_overview_tab.dart';
import 'repo_code_tab.dart';
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

  @override
  void initState() {
    super.initState();
    _service = GitHubService(widget.token);
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 6,
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.repo['name']),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
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
