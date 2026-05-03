import 'package:flutter/material.dart';
import '../services/github_service.dart';

class RepoSettingsTab extends StatefulWidget {
  final Map<String, dynamic> repo;
  final GitHubService service;

  const RepoSettingsTab({super.key, required this.repo, required this.service});

  @override
  State<RepoSettingsTab> createState() => _RepoSettingsTabState();
}

class _RepoSettingsTabState extends State<RepoSettingsTab> {
  late Map<String, dynamic> _repo;
  bool _isEditing = false;

  late TextEditingController _nameController;
  late TextEditingController _descController;
  late TextEditingController _websiteController;
  bool _hasIssues = true;
  bool _hasProjects = true;
  bool _hasWiki = true;

  @override
  void initState() {
    super.initState();
    _repo = Map<String, dynamic>.from(widget.repo);
    _initControllers();
  }

  void _initControllers() {
    _nameController = TextEditingController(text: _repo['name']);
    _descController = TextEditingController(text: _repo['description'] ?? '');
    _websiteController = TextEditingController(text: _repo['homepage'] ?? '');
    _hasIssues = _repo['has_issues'] ?? true;
    _hasProjects = _repo['has_projects'] ?? true;
    _hasWiki = _repo['has_wiki'] ?? true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _websiteController.dispose();
    super.dispose();
  }

  Future<void> _saveSettings() async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (c) => const Center(child: CircularProgressIndicator()),
      );

      final updates = {
        'name': _nameController.text,
        'description': _descController.text,
        'homepage': _websiteController.text,
        'has_issues': _hasIssues,
        'has_projects': _hasProjects,
        'has_wiki': _hasWiki,
      };

      await widget.service.updateRepoSettings(_repo['full_name'], updates);

      if (mounted) {
        Navigator.pop(context); // close dialog
        setState(() {
          _repo.addAll(updates);
          _isEditing = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Settings updated!')));
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // close dialog
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to update: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('General Settings', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            if (!_isEditing)
              TextButton.icon(
                icon: const Icon(Icons.edit),
                label: const Text('Edit'),
                onPressed: () => setState(() => _isEditing = true),
              )
            else
              Row(
                children: [
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _isEditing = false;
                        _initControllers(); // reset
                      });
                    },
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton(
                    onPressed: _saveSettings,
                    child: const Text('Save'),
                  ),
                ],
              ),
          ],
        ),
        const SizedBox(height: 16),
        if (_isEditing) ...[
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(labelText: 'Repository Name', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _descController,
            decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder()),
            maxLines: 3,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _websiteController,
            decoration: const InputDecoration(labelText: 'Website (Homepage)', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 16),
          SwitchListTile(
            title: const Text('Has Issues'),
            value: _hasIssues,
            onChanged: (v) => setState(() => _hasIssues = v),
          ),
          SwitchListTile(
            title: const Text('Has Projects'),
            value: _hasProjects,
            onChanged: (v) => setState(() => _hasProjects = v),
          ),
          SwitchListTile(
            title: const Text('Has Wiki'),
            value: _hasWiki,
            onChanged: (v) => setState(() => _hasWiki = v),
          ),
        ] else ...[
          ListTile(
            title: const Text('Repository Name'),
            subtitle: Text(_repo['name']),
          ),
          ListTile(
            title: const Text('Description'),
            subtitle: Text(_repo['description'] ?? 'No description'),
          ),
          ListTile(
            title: const Text('Website'),
            subtitle: Text(_repo['homepage']?.isNotEmpty == true ? _repo['homepage'] : 'No website'),
          ),
          ListTile(
            title: const Text('Visibility'),
            subtitle: Text((_repo['private'] ?? false) ? 'Private' : 'Public'),
          ),
          ListTile(
            title: const Text('Default Branch'),
            subtitle: Text(_repo['default_branch'] ?? 'main'),
          ),
          ListTile(
            title: const Text('Language'),
            subtitle: Text(_repo['language'] ?? 'Unknown'),
          ),
          ListTile(
            title: const Text('Features'),
            subtitle: Text([
              if (_repo['has_issues'] == true) 'Issues',
              if (_repo['has_projects'] == true) 'Projects',
              if (_repo['has_wiki'] == true) 'Wiki',
            ].join(', ')),
          ),
        ],
        const Divider(),
        const ListTile(
          title: Text(
            'Danger Zone',
            style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
          ),
        ),
        ListTile(
          title: const Text('Delete Repository', style: TextStyle(color: Colors.red)),
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Not implemented in this demo.')),
            );
          },
        ),
      ],
    );
  }
}
