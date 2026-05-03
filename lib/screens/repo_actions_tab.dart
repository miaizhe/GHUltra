import 'package:flutter/material.dart';
import '../services/github_service.dart';
import 'workflow_run_detail_screen.dart';

class RepoActionsTab extends StatefulWidget {
  final Map<String, dynamic> repo;
  final GitHubService service;

  const RepoActionsTab({super.key, required this.repo, required this.service});

  @override
  State<RepoActionsTab> createState() => _RepoActionsTabState();
}

class _RepoActionsTabState extends State<RepoActionsTab> {
  List<dynamic>? _workflows;
  List<dynamic>? _workflowRuns;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final fullName = widget.repo['full_name'];
      final workflows = await widget.service.getWorkflows(fullName);
      final runs = await widget.service.getWorkflowRuns(fullName);
      if (mounted) {
        setState(() {
          _workflows = workflows;
          _workflowRuns = runs;
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

  Future<void> _dispatch(int workflowId) async {
    try {
      final fullName = widget.repo['full_name'];
      final defaultBranch = widget.repo['default_branch'] ?? 'main';
      await widget.service.dispatchWorkflow(fullName, workflowId, defaultBranch);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Workflow dispatched successfully!')),
        );
        // Refresh runs after a short delay
        Future.delayed(const Duration(seconds: 2), _loadData);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to dispatch: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_error != null) return Center(child: Text(_error!, style: const TextStyle(color: Colors.red)));

    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          const TabBar(
            labelColor: Color(0xFF24292E),
            unselectedLabelColor: Color(0xFF57606A),
            indicatorColor: Color(0xFF24292E),
            tabs: [
              Tab(text: 'Workflows'),
              Tab(text: 'Recent Runs'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildWorkflowsList(),
                _buildRunsList(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkflowsList() {
    if (_workflows == null || _workflows!.isEmpty) {
      return const Center(child: Text('No workflows found.'));
    }

    return ListView.builder(
      itemCount: _workflows!.length,
      itemBuilder: (context, index) {
        final wf = _workflows![index];
        return ListTile(
          leading: const Icon(Icons.play_circle_outline, color: Color(0xFF2DA44E)),
          title: Text(wf['name']),
          subtitle: Text(wf['state']),
          trailing: IconButton(
            icon: const Icon(Icons.play_arrow),
            tooltip: 'Run Workflow',
            onPressed: () => _dispatch(wf['id']),
          ),
        );
      },
    );
  }

  Widget _buildRunsList() {
    if (_workflowRuns == null || _workflowRuns!.isEmpty) {
      return const Center(child: Text('No recent workflow runs.'));
    }

    return ListView.builder(
      itemCount: _workflowRuns!.length,
      itemBuilder: (context, index) {
        final run = _workflowRuns![index];
        final status = run['status'];
        final conclusion = run['conclusion'];
        
        IconData iconData = Icons.radio_button_unchecked;
        Color iconColor = const Color(0xFF57606A);
        
        if (status == 'completed') {
          if (conclusion == 'success') {
            iconData = Icons.check_circle;
            iconColor = const Color(0xFF2DA44E); // Green
          } else if (conclusion == 'failure') {
            iconData = Icons.cancel;
            iconColor = Colors.redAccent;
          } else {
            iconData = Icons.remove_circle;
            iconColor = const Color(0xFF57606A);
          }
        } else {
          iconData = Icons.sync;
          iconColor = const Color(0xFF0969DA); // Blue for in-progress
        }

        return ListTile(
          leading: Icon(iconData, color: iconColor),
          title: Text(run['display_title'] ?? run['name']),
          subtitle: Text('${run['head_branch']} • ${run['status']}'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => WorkflowRunDetailScreen(
                  run: run,
                  repoFullName: widget.repo['full_name'],
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
