import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/github_service.dart';

class FileViewerScreen extends StatefulWidget {
  final Map<String, dynamic> fileItem;
  final GitHubService service;
  final String? repoFullName; // Needed for updating file

  const FileViewerScreen({
    super.key,
    required this.fileItem,
    required this.service,
    this.repoFullName,
  });

  @override
  State<FileViewerScreen> createState() => _FileViewerScreenState();
}

class _FileViewerScreenState extends State<FileViewerScreen> {
  String? _content;
  bool _isLoading = true;
  String? _error;
  bool _isEditing = false;
  final _editController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadFile();
  }

  @override
  void dispose() {
    _editController.dispose();
    super.dispose();
  }

  Future<void> _loadFile() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      String content = '';
      if (widget.fileItem['content'] != null && widget.fileItem['encoding'] == 'base64') {
        content = utf8.decode(base64.decode(widget.fileItem['content'].replaceAll('\n', '')));
      } else if (widget.fileItem['download_url'] != null) {
        content = await widget.service.getRawFileContent(widget.fileItem['download_url']);
      } else if (widget.fileItem['url'] != null) {
        // Fetch from API url directly
        final response = await widget.service.getRawFileContent(widget.fileItem['url']);
        final decoded = json.decode(response);
        if (decoded['content'] != null && decoded['encoding'] == 'base64') {
          content = utf8.decode(base64.decode(decoded['content'].replaceAll('\n', '')));
        } else {
          content = 'Unsupported encoding.';
        }
      } else {
        content = 'Cannot display this file.';
      }

      if (mounted) {
        setState(() {
          _content = content;
          _editController.text = content;
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

  Future<void> _saveChanges() async {
    if (widget.repoFullName == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Repository context missing. Cannot save.')),
      );
      return;
    }

    final newContent = _editController.text;
    if (newContent == _content) {
      setState(() => _isEditing = false);
      return;
    }

    // Prompt for commit message
    String commitMessage = 'Update ${widget.fileItem['name']} via GHUltra';
    final result = await showDialog<String>(
      context: context,
      builder: (context) {
        final msgController = TextEditingController(text: commitMessage);
        return AlertDialog(
          title: const Text('Commit Changes'),
          content: TextField(
            controller: msgController,
            decoration: const InputDecoration(labelText: 'Commit Message'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(null),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(msgController.text),
              child: const Text('Commit'),
            ),
          ],
        );
      },
    );

    if (result == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // 1. We need the current SHA of the file to update it.
      String path = widget.fileItem['path'] ?? widget.fileItem['name'];
      final fileInfo = await widget.service.getFileInfo(widget.repoFullName!, path);
      final sha = fileInfo['sha'];

      // 2. Commit the change
      await widget.service.updateFile(
        widget.repoFullName!,
        path,
        result,
        newContent,
        sha,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('File updated successfully!')),
        );
        setState(() {
          _isEditing = false;
        });
        _loadFile(); // Reload to get updated content and new SHA
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update file: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.fileItem['name']),
        actions: [
          if (!_isLoading && _error == null && widget.repoFullName != null)
            if (_isEditing)
              IconButton(
                icon: const Icon(Icons.save),
                tooltip: 'Commit Changes',
                onPressed: _saveChanges,
              )
            else
              IconButton(
                icon: const Icon(Icons.edit),
                tooltip: 'Edit File',
                onPressed: () {
                  setState(() => _isEditing = true);
                },
              ),
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.cancel),
              tooltip: 'Cancel Edit',
              onPressed: () {
                setState(() {
                  _isEditing = false;
                  _editController.text = _content ?? '';
                });
              },
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!, style: const TextStyle(color: Colors.red)))
              : _isEditing
                  ? Padding(
                      padding: const EdgeInsets.all(16),
                      child: TextField(
                        controller: _editController,
                        maxLines: null,
                        expands: true,
                        style: const TextStyle(
                          fontFamily: 'Consolas',
                          fontSize: 14,
                        ),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                        ),
                      ),
                    )
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: SelectableText(
                        _content ?? '',
                        style: const TextStyle(
                          fontFamily: 'Consolas', // Monospace
                          fontSize: 14,
                        ),
                      ),
                    ),
    );
  }
}
