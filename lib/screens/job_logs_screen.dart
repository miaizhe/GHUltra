import 'dart:async';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/github_service.dart';
import 'webview_screen.dart';

class JobLogsScreen extends StatefulWidget {
  final Map<String, dynamic> job;
  final String repoFullName;
  final GitHubService service;
  final int? stepNumber; // Optional: If provided, filter logs for this step
  final String? stepName; // Used for UI title

  const JobLogsScreen({
    super.key,
    required this.job,
    required this.repoFullName,
    required this.service,
    this.stepNumber,
    this.stepName,
  });

  @override
  State<JobLogsScreen> createState() => _JobLogsScreenState();
}

class _JobLogsScreenState extends State<JobLogsScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  
  String? _logs;
  List<String> _logLines = [];
  bool _isLoading = true;
  String? _error;
  Timer? _pollingTimer;
  bool _autoScroll = true;
  bool _isSearching = false;
   String _searchQuery = '';
   final List<int> _searchResults = [];
   int _currentSearchIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadLogs();

    // If job is not completed, poll for new logs
    if (widget.job['status'] != 'completed') {
      _pollingTimer = Timer.periodic(const Duration(seconds: 5), (_) {
        _loadLogs(isBackground: true);
      });
    }

    _scrollController.addListener(() {
      // If user scrolls up, disable auto-scroll. If they reach bottom, enable it.
      if (_scrollController.hasClients) {
        if (_scrollController.position.pixels < _scrollController.position.maxScrollExtent - 50) {
          if (_autoScroll) setState(() => _autoScroll = false);
        } else {
          if (!_autoScroll) setState(() => _autoScroll = true);
        }
      }
    });
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadLogs({bool isBackground = false}) async {
    if (!isBackground) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }

    try {
      final logs = await widget.service.getJobLogs(widget.repoFullName, widget.job['id']);
      
      String processedLogs = logs ?? ''; // logs can be null if 404 (initializing)
      
      // If a specific step is requested, we need to extract only that part.
      // GitHub raw logs prefix lines with timestamps, e.g., "2023-10-27T10:00:00.0000000Z ".
      // The format of sections in raw logs often has "##[group]Run step_name" and "##[endgroup]".
      // Since raw text logs might not perfectly separate by step number without parsing timestamps/groups,
      // we'll try a basic group parsing if stepNumber is provided. 
      // If it fails or logs don't use groups, we might fallback to full logs, but let's try.
      if (widget.stepNumber != null && processedLogs.isNotEmpty) {
        // This is a heuristic approach to extract a specific step's log from the raw job log text.
        // It searches for the step name (if we knew it) or tries to parse groups.
        // For simplicity and robustness, if we can't reliably parse the raw text by step number, 
        // we display the full log but maybe inform the user.
        // To do this accurately, we would need to match the step name from widget.job['steps'][stepNumber-1]['name']
        try {
          final step = widget.job['steps'].firstWhere((s) => s['number'] == widget.stepNumber, orElse: () => null);
          if (step != null) {
            final stepName = step['name'];
            final lines = processedLogs.split('\n');
            List<String> stepLines = [];
            bool inStep = false;
            
            for (var line in lines) {
              // Check for group start. The exact format can vary, often contains the step name.
              if (line.contains('##[group]') && line.contains(stepName)) {
                inStep = true;
              } else if (inStep && line.contains('##[group]')) {
                // Started a new step
                inStep = false;
                break; 
              }
              
              if (inStep) {
                stepLines.add(line);
              }
            }
            
            if (stepLines.isNotEmpty) {
              processedLogs = stepLines.join('\n');
            }
          }
        } catch (_) {
          // Ignore parse errors, show full logs
        }
      }

      // GitHub sometimes returns empty body for logs that are still initializing
      if (processedLogs.trim().isEmpty) {
        processedLogs = 'Waiting for logs to initialize...';
      }

      if (mounted) {
        setState(() {
          _logs = processedLogs;
          _logLines = _logs?.split('\n') ?? [];
          _isLoading = false;
          
          if (_searchQuery.isNotEmpty) {
            _performSearch(_searchQuery);
          }
        });

        if (_autoScroll && _searchQuery.isEmpty) {
          _scrollToBottom();
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

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }
  
  void _performSearch(String query) {
    setState(() {
      _searchQuery = query;
      _searchResults.clear();
      _currentSearchIndex = 0;
      
      if (query.isNotEmpty) {
        for (int i = 0; i < _logLines.length; i++) {
          if (_logLines[i].toLowerCase().contains(query.toLowerCase())) {
            _searchResults.add(i);
          }
        }
      }
    });
    
    if (_searchResults.isNotEmpty) {
      _scrollToSearchResult();
    }
  }
  
  void _nextSearchResult() {
    if (_searchResults.isEmpty) return;
    setState(() {
      _currentSearchIndex = (_currentSearchIndex + 1) % _searchResults.length;
    });
    _scrollToSearchResult();
  }
  
  void _prevSearchResult() {
    if (_searchResults.isEmpty) return;
    setState(() {
      _currentSearchIndex = (_currentSearchIndex - 1 + _searchResults.length) % _searchResults.length;
    });
    _scrollToSearchResult();
  }
  
  void _scrollToSearchResult() {
    if (_searchResults.isEmpty) return;
    
    setState(() => _autoScroll = false);
    
    final targetIndex = _searchResults[_currentSearchIndex];
    final estimatedOffset = targetIndex * 22.0; // 22 is approx line height
    
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        estimatedOffset.clamp(0.0, _scrollController.position.maxScrollExtent),
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Widget _buildSearchBar() {
    return Container(
      color: const Color(0xFF1E1E1E),
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: const InputDecoration(
                hintText: 'Search logs...',
                hintStyle: TextStyle(color: Colors.grey, fontSize: 14),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.all(8),
              ),
              onChanged: _performSearch,
              onSubmitted: (_) => _nextSearchResult(),
            ),
          ),
          if (_searchResults.isNotEmpty)
            Text(
              '${_currentSearchIndex + 1}/${_searchResults.length}',
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
          IconButton(
            icon: const Icon(Icons.keyboard_arrow_up, color: Colors.white, size: 20),
            onPressed: _searchResults.isEmpty ? null : _prevSearchResult,
          ),
          IconButton(
            icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white, size: 20),
            onPressed: _searchResults.isEmpty ? null : _nextSearchResult,
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white, size: 20),
            onPressed: () {
              setState(() {
                _isSearching = false;
                _searchQuery = '';
                _searchController.clear();
                _searchResults.clear();
              });
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.stepNumber != null 
            ? 'Step Logs' 
            : '${widget.job['name']} Logs'),
        actions: [
          IconButton(
            icon: const Icon(Icons.public),
            tooltip: 'View in App Browser',
            onPressed: () async {
              final url = widget.job['html_url'];
              if (url != null) {
                if (Theme.of(context).platform == TargetPlatform.macOS) {
                  // Use external browser on macOS since WKWebView lacks passkey support
                  if (await canLaunchUrl(Uri.parse(url))) {
                    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
                  }
                } else {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => WebViewScreen(
                        url: url,
                        title: widget.stepName != null ? 'Step: ${widget.stepName}' : 'Job Logs',
                      ),
                    ),
                  );
                }
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.open_in_browser),
            tooltip: 'Open in External Browser',
            onPressed: () async {
              final url = widget.job['html_url'];
              if (url != null && await canLaunchUrl(Uri.parse(url))) {
                await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) {
                  _searchQuery = '';
                  _searchController.clear();
                  _searchResults.clear();
                }
              });
            },
          ),
          if (widget.job['status'] != 'completed')
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: Center(
                child: SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
        ],
      ),
      backgroundColor: const Color(0xFF0D1117), // GitHub Dark Dimmed background for logs
      body: Column(
        children: [
          if (_isSearching) _buildSearchBar(),
          Expanded(
            child: _isLoading && (_logs == null || _logs!.isEmpty)
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(child: Text(_error!, style: const TextStyle(color: Colors.red)))
                    : _logs == null || _logs!.isEmpty
                        ? const Center(child: Text('No logs available yet.', style: TextStyle(color: Colors.white70)))
                        : Scrollbar(
                            controller: _scrollController,
                            thumbVisibility: true,
                            trackVisibility: true,
                            thickness: 8.0,
                            radius: const Radius.circular(4),
                            child: ListView.builder(
                              controller: _scrollController,
                              padding: const EdgeInsets.all(8.0),
                              itemCount: _logLines.length,
                              itemBuilder: (context, index) {
                                final line = _logLines[index];
                                final isMatch = _searchResults.isNotEmpty && _searchResults.contains(index);
                                final isCurrentMatch = _searchResults.isNotEmpty && _searchResults[_currentSearchIndex] == index;
                                
                                return Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 1.0),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Line Number
                                      SizedBox(
                                        width: 40,
                                        child: Text(
                                          '${index + 1}',
                                          textAlign: TextAlign.right,
                                          style: const TextStyle(
                                            color: Colors.grey,
                                            fontFamily: 'Consolas',
                                            fontSize: 13,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      // Log Content
                                      Expanded(
                                        child: Container(
                                           color: isCurrentMatch 
                                               ? Colors.orange.withAlpha(128) 
                                               : (isMatch ? Colors.yellow.withAlpha(51) : Colors.transparent),
                                           child: Text(
                                            line,
                                            style: const TextStyle(
                                              color: Color(0xFFE6EDF3),
                                              fontFamily: 'Consolas',
                                              fontSize: 13,
                                              height: 1.5,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
          ),
        ],
      ),
      floatingActionButton: !_autoScroll && !_isSearching
          ? FloatingActionButton(
              mini: true,
              backgroundColor: const Color(0xFF24292E),
              onPressed: () {
                setState(() => _autoScroll = true);
                _scrollToBottom();
              },
              child: const Icon(Icons.arrow_downward, color: Colors.white),
            )
          : null,
    );
  }
}
