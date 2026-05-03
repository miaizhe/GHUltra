import 'dart:async';
import 'package:flutter/material.dart';
import '../services/github_service.dart';
import 'job_logs_screen.dart';

class WorkflowRunDetailScreen extends StatefulWidget {
  final Map<String, dynamic> run;
  final String repoFullName;
  final GitHubService service;

  const WorkflowRunDetailScreen({
    super.key,
    required this.run,
    required this.repoFullName,
    required this.service,
  });

  @override
  State<WorkflowRunDetailScreen> createState() => _WorkflowRunDetailScreenState();
}

class _WorkflowRunDetailScreenState extends State<WorkflowRunDetailScreen> {
  List<dynamic>? _jobs;
  bool _isLoading = true;
  String? _error;
  Timer? _pollingTimer;

  @override
  void initState() {
    super.initState();
    _loadJobs();
    
    // Poll every 5 seconds to update job status in real-time
    if (widget.run['status'] != 'completed') {
      _pollingTimer = Timer.periodic(const Duration(seconds: 5), (_) {
        _loadJobs(isBackground: true);
      });
    }
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadJobs({bool isBackground = false}) async {
    if (!isBackground) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }

    try {
      final jobs = await widget.service.getWorkflowRunJobs(widget.repoFullName, widget.run['id']);
      if (mounted) {
        setState(() {
          _jobs = jobs;
          _isLoading = false;
        });
        
        // Stop polling if all jobs are completed
        bool allCompleted = true;
        for (var job in jobs) {
          if (job['status'] != 'completed') {
            allCompleted = false;
            break;
          }
        }
        if (allCompleted) {
          _pollingTimer?.cancel();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          if (!isBackground) _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  IconData _getIconForStatus(String? status, String? conclusion) {
    if (status == 'completed') {
      if (conclusion == 'success') return Icons.check_circle;
      if (conclusion == 'failure') return Icons.cancel;
      return Icons.remove_circle;
    }
    return Icons.sync;
  }

  Color _getColorForStatus(String? status, String? conclusion) {
    if (status == 'completed') {
      if (conclusion == 'success') return const Color(0xFF2DA44E);
      if (conclusion == 'failure') return Colors.redAccent;
      return const Color(0xFF57606A);
    }
    return const Color(0xFF0969DA);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Workflow Run Details'),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header summary
          Container(
            padding: const EdgeInsets.all(16.0),
            color: Colors.white,
            width: double.infinity,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      _getIconForStatus(widget.run['status'], widget.run['conclusion']),
                      color: _getColorForStatus(widget.run['status'], widget.run['conclusion']),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.run['display_title'] ?? widget.run['name'],
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text('Branch: ${widget.run['head_branch']} • Commit: ${widget.run['head_sha']?.substring(0, 7)}'),
                const SizedBox(height: 4),
                Text('Triggered by: ${widget.run['actor']?['login'] ?? 'Unknown'}'),
              ],
            ),
          ),
          const Divider(height: 1),
          
          // Jobs list
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text('Jobs', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
          Expanded(
            child: _buildJobsList(),
          ),
        ],
      ),
    );
  }

  Widget _buildJobsList() {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_error != null) return Center(child: Text(_error!, style: const TextStyle(color: Colors.red)));
    if (_jobs == null || _jobs!.isEmpty) {
      return const Center(child: Text('No jobs found for this run.'));
    }

    return ListView.builder(
      itemCount: _jobs!.length,
      itemBuilder: (context, index) {
        final job = _jobs![index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: ExpansionTile(
            leading: Icon(
              _getIconForStatus(job['status'], job['conclusion']),
              color: _getColorForStatus(job['status'], job['conclusion']),
            ),
            title: Text(job['name']),
            subtitle: Text('${job['status']} • ${job['conclusion'] ?? 'in progress'}'),
            trailing: IconButton(
              icon: const Icon(Icons.receipt_long),
              tooltip: 'View Logs',
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => JobLogsScreen(
                      job: job,
                      repoFullName: widget.repoFullName,
                      service: widget.service,
                    ),
                  ),
                );
              },
            ),
            children: [
              if (job['steps'] != null)
                ...((job['steps'] as List).map((step) {
                  return ListTile(
                    dense: true,
                    leading: Icon(
                      _getIconForStatus(step['status'], step['conclusion']),
                      color: _getColorForStatus(step['status'], step['conclusion']),
                      size: 16,
                    ),
                    title: Text(step['name'], style: const TextStyle(fontSize: 14)),
                    trailing: step['completed_at'] != null && step['started_at'] != null
                        ? Text(
                            '${DateTime.parse(step['completed_at']).difference(DateTime.parse(step['started_at'])).inSeconds}s',
                            style: const TextStyle(fontSize: 12, color: Color(0xFF57606A)),
                          )
                        : null,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => JobLogsScreen(
                            job: job,
                            repoFullName: widget.repoFullName,
                            service: widget.service,
                            stepNumber: step['number'],
                          ),
                        ),
                      );
                    },
                  );
                }).toList()),
            ],
          ),
        );
      },
    );
  }
}
