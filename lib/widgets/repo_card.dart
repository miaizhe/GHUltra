import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../screens/repo_detail_screen.dart';

class RepoCard extends StatelessWidget {
  final Map<String, dynamic> repo;

  const RepoCard({super.key, required this.repo});

  Future<void> _openRepo(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('github_token');
    if (token != null && context.mounted) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => RepoDetailScreen(repo: repo, token: token),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _openRepo(context),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.book, color: Color(0xFF57606A), size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      repo['full_name'] ?? repo['name'],
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0969DA),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFFD0D7DE)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      (repo['private'] ?? false) ? 'Private' : 'Public',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF57606A),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  )
                ],
              ),
              if (repo['description'] != null) ...[
                const SizedBox(height: 8),
                Text(
                  repo['description'],
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF57606A),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  if (repo['language'] != null) ...[
                    Container(
                      width: 12,
                      height: 12,
                      decoration: const BoxDecoration(
                        color: Color(0xFF0969DA),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      repo['language'],
                      style: const TextStyle(fontSize: 12, color: Color(0xFF57606A)),
                    ),
                    const SizedBox(width: 16),
                  ],
                  const Icon(Icons.star_border, size: 16, color: Color(0xFF57606A)),
                  const SizedBox(width: 4),
                  Text(
                    '${repo['stargazers_count'] ?? 0}',
                    style: const TextStyle(fontSize: 12, color: Color(0xFF57606A)),
                  ),
                  const SizedBox(width: 16),
                  const Icon(Icons.call_split, size: 16, color: Color(0xFF57606A)),
                  const SizedBox(width: 4),
                  Text(
                    '${repo['forks_count'] ?? 0}',
                    style: const TextStyle(fontSize: 12, color: Color(0xFF57606A)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
