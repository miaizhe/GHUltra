import 'package:flutter/material.dart';

class RepoSettingsTab extends StatelessWidget {
  final Map<String, dynamic> repo;

  const RepoSettingsTab({super.key, required this.repo});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ListTile(
          title: const Text('Repository Name'),
          subtitle: Text(repo['name']),
        ),
        ListTile(
          title: const Text('Description'),
          subtitle: Text(repo['description'] ?? 'No description'),
        ),
        ListTile(
          title: const Text('Visibility'),
          subtitle: Text((repo['private'] ?? false) ? 'Private' : 'Public'),
        ),
        ListTile(
          title: const Text('Default Branch'),
          subtitle: Text(repo['default_branch'] ?? 'main'),
        ),
        ListTile(
          title: const Text('Language'),
          subtitle: Text(repo['language'] ?? 'Unknown'),
        ),
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
