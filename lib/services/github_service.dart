import 'dart:convert';
import 'package:http/http.dart' as http;

class GitHubService {
  final String token;
  static const String _baseUrl = 'https://api.github.com';

  GitHubService(this.token);

  Map<String, String> get _headers => {
        'Authorization': 'token $token',
        'Accept': 'application/vnd.github.v3+json',
      };

  Future<Map<String, dynamic>> getUserProfile() async {
    final response = await http.get(
      Uri.parse('$_baseUrl/user'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load user profile: ${response.statusCode}');
    }
  }

  Future<List<dynamic>> getUserRepositories() async {
    final response = await http.get(
      // Fetch more per page, or we'd need to handle pagination to truly get all repos.
      // For now, let's fetch 100 to ensure we catch recent forks.
      Uri.parse('$_baseUrl/user/repos?sort=updated&per_page=100&t=${DateTime.now().millisecondsSinceEpoch}'),
      headers: {
        ..._headers,
        'Cache-Control': 'no-cache',
      },
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load repositories');
    }
  }

  Future<List<dynamic>> searchRepositories(String query) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/search/repositories?q=$query&sort=stars&order=desc'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['items'];
    } else {
      throw Exception('Failed to search repositories');
    }
  }

  // --- Repo Details & Files ---

  Future<List<dynamic>> getBranches(String fullName) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/repos/$fullName/branches?per_page=100'),
      headers: _headers,
    );
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load branches');
    }
  }

  Future<Map<String, dynamic>?> getLatestCommit(String fullName, {String? branch}) async {
    String url = '$_baseUrl/repos/$fullName/commits?per_page=1';
    if (branch != null) {
      url += '&sha=$branch';
    }
    final response = await http.get(Uri.parse(url), headers: _headers);
    if (response.statusCode == 200) {
      final List<dynamic> commits = json.decode(response.body);
      if (commits.isNotEmpty) return commits.first;
    }
    return null;
  }

  Future<Map<String, dynamic>> getBranchInfo(String fullName, String branch) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/repos/$fullName/branches/$branch'),
      headers: _headers,
    );
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load branch info');
    }
  }

  Future<Map<String, dynamic>> compareCommits(String fullName, String base, String head) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/repos/$fullName/compare/$base...$head'),
      headers: _headers,
    );
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to compare commits');
    }
  }

  Future<Map<String, dynamic>> getRepoInfo(String fullName) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/repos/$fullName'),
      headers: _headers,
    );
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load repo info');
    }
  }

  Future<void> syncBranch(String fullName, String branch) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/repos/$fullName/merge-upstream'),
      headers: _headers,
      body: json.encode({'branch': branch}),
    );
    if (response.statusCode != 200 && response.statusCode != 201 && response.statusCode != 409) {
      throw Exception('Failed to sync branch: ${response.body}');
    }
  }

  Future<void> updateRepoSettings(String fullName, Map<String, dynamic> data) async {
    final response = await http.patch(
      Uri.parse('$_baseUrl/repos/$fullName'),
      headers: _headers,
      body: json.encode(data),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to update repo settings: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> getReadme(String fullName) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/repos/$fullName/readme'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else if (response.statusCode == 404) {
      return {}; // No README
    } else {
      throw Exception('Failed to load README');
    }
  }

  Future<Map<String, dynamic>> getLicense(String fullName) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/repos/$fullName/license'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else if (response.statusCode == 404) {
      return {}; // No license found
    } else {
      throw Exception('Failed to load license');
    }
  }

  Future<Map<String, dynamic>> getFileInfo(String fullName, String path, {String? branch}) async {
    String url = '$_baseUrl/repos/$fullName/contents/$path';
    if (branch != null) {
      url += '?ref=$branch';
    }
    final response = await http.get(
      Uri.parse(url),
      headers: _headers,
    );
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to get file info');
    }
  }

  Future<void> updateFile(String fullName, String path, String message, String content, String sha, {String? branch}) async {
    final body = {
      'message': message,
      'content': base64.encode(utf8.encode(content)),
      'sha': sha,
    };
    if (branch != null) {
      body['branch'] = branch;
    }

    final response = await http.put(
      Uri.parse('$_baseUrl/repos/$fullName/contents/$path'),
      headers: _headers,
      body: json.encode(body),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Failed to update file: ${response.body}');
    }
  }

  Future<List<dynamic>> getRepoContents(String fullName, {String path = '', String? branch}) async {
    String url = '$_baseUrl/repos/$fullName/contents/$path';
    if (branch != null) {
      url += '?ref=$branch';
    }
    final response = await http.get(
      Uri.parse(url),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final decoded = json.decode(response.body);
      if (decoded is List) return decoded;
      if (decoded is Map) return [decoded]; // Single file
      return [];
    } else {
      throw Exception('Failed to load repo contents');
    }
  }

  Future<String> getRawFileContent(String downloadUrl) async {
    final response = await http.get(
      Uri.parse(downloadUrl),
      headers: {'Authorization': 'token $token'}, // Raw URL sometimes needs auth
    );
    if (response.statusCode == 200) {
      return response.body;
    } else {
      throw Exception('Failed to download file');
    }
  }

  // --- Actions ---

  Future<List<dynamic>> getWorkflows(String fullName) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/repos/$fullName/actions/workflows?per_page=100'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      return json.decode(response.body)['workflows'];
    } else if (response.statusCode == 404) {
      return []; // Actions not enabled or no workflows
    } else {
      throw Exception('Failed to load workflows: ${response.statusCode}');
    }
  }

  Future<List<dynamic>> getWorkflowRuns(String fullName) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/repos/$fullName/actions/runs?per_page=50'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      return json.decode(response.body)['workflow_runs'];
    } else if (response.statusCode == 404) {
      return []; // Actions not enabled
    } else {
      throw Exception('Failed to load workflow runs: ${response.statusCode}');
    }
  }

  Future<void> dispatchWorkflow(String fullName, int workflowId, String ref) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/repos/$fullName/actions/workflows/$workflowId/dispatches'),
      headers: _headers,
      body: json.encode({'ref': ref}),
    );

    if (response.statusCode != 204) {
      throw Exception('Failed to dispatch workflow: ${response.body}');
    }
  }

  Future<List<dynamic>> getWorkflowRunJobs(String fullName, int runId) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/repos/$fullName/actions/runs/$runId/jobs'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      return json.decode(response.body)['jobs'];
    } else {
      throw Exception('Failed to load workflow run jobs');
    }
  }

  Future<String?> getJobLogs(String fullName, int jobId) async {
    // Note: GitHub Actions API requires 'Accept: application/vnd.github.v3+json' usually,
    // but for logs, we need 'Accept: application/vnd.github.v3+json' for the metadata
    // or just let it redirect. However, some endpoints require you to NOT send the standard headers
    // on the redirected URL (like Amazon S3 signature mismatch errors if you send Authorization header).
    
    final request = http.Request('GET', Uri.parse('$_baseUrl/repos/$fullName/actions/jobs/$jobId/logs'));
    request.headers.addAll(_headers);
    request.followRedirects = false; // Manually handle redirect

    final client = http.Client();
    try {
      final response = await client.send(request);

      if (response.statusCode == 200) {
        return await response.stream.bytesToString();
      } else if (response.statusCode == 302 || response.statusCode == 301) {
        final location = response.headers['location'];
        if (location != null) {
          // IMPORTANT: Do NOT send GitHub authorization headers to the redirect URL (usually AWS S3/Azure Blob)
          final redirectResponse = await http.get(Uri.parse(location));
          if (redirectResponse.statusCode == 200) {
            return redirectResponse.body;
          } else {
            throw Exception('Failed to download log from redirect: ${redirectResponse.statusCode}');
          }
        }
        throw Exception('Redirect location missing');
      } else if (response.statusCode == 404) {
        // Log is not ready yet
        return null;
      } else {
        throw Exception('Failed to load job logs. Status: ${response.statusCode}');
      }
    } finally {
      client.close();
    }
  }

  // --- Releases ---

  Future<List<dynamic>> getReleases(String fullName) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/repos/$fullName/releases'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load releases');
    }
  }

  // --- Search Code ---

  Future<List<dynamic>> searchCode(String fullName, String query) async {
    // According to GitHub API docs, the q parameter needs to contain the search term and modifiers like repo:owner/name
    final q = '$query repo:$fullName';
    
    // Instead of using replace() which does its own encoding that might mess up the 'repo:owner/name' part,
    // let's construct the query string manually. The GitHub API expects the query parameter 'q' to be encoded,
    // but sometimes standard Uri encoding encodes the colon ':' which GitHub search API handles fine, 
    // but just to be safe and match standard curl behavior:
    final encodedQuery = Uri.encodeQueryComponent(q);
    final uri = Uri.parse('$_baseUrl/search/code?q=$encodedQuery');
    
    final response = await http.get(
      uri,
      headers: _headers,
    );

    if (response.statusCode == 200) {
      return json.decode(response.body)['items'];
    } else {
      throw Exception('Failed to search code: ${response.statusCode} - ${response.body}');
    }
  }

  // --- Star & Fork ---

  Future<bool> checkStarStatus(String fullName) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/user/starred/$fullName'),
      headers: _headers,
    );
    return response.statusCode == 204;
  }

  Future<void> starRepo(String fullName) async {
    final response = await http.put(
      Uri.parse('$_baseUrl/user/starred/$fullName'),
      headers: _headers,
    );
    if (response.statusCode != 204) {
      throw Exception('Failed to star repository');
    }
  }

  Future<void> unstarRepo(String fullName) async {
    final response = await http.delete(
      Uri.parse('$_baseUrl/user/starred/$fullName'),
      headers: _headers,
    );
    if (response.statusCode != 204) {
      throw Exception('Failed to unstar repository');
    }
  }

  Future<Map<String, dynamic>> forkRepo(String fullName) async {
    // The most standard way to send a POST request with no body in Dart HTTP package
    // is to provide an empty string as body. This naturally sets Content-Length to 0
    // and avoids the issue where http.post drops headers.
    final response = await http.post(
      Uri.parse('$_baseUrl/repos/$fullName/forks'),
      headers: {
        ..._headers,
        'Content-Type': 'application/json',
      },
      body: '',
    );
    
    if (response.statusCode == 202 || response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to fork repository: ${response.statusCode} - ${response.body}');
    }
  }

  // --- Issues ---

  Future<List<dynamic>> getIssues(String fullName, {String state = 'open'}) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/repos/$fullName/issues?state=$state&per_page=100'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load issues: ${response.statusCode} - ${response.body}');
    }
  }

  Future<Map<String, dynamic>> getIssue(String fullName, int issueNumber) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/repos/$fullName/issues/$issueNumber'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load issue: ${response.statusCode} - ${response.body}');
    }
  }

  Future<List<dynamic>> getIssueComments(String fullName, int issueNumber) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/repos/$fullName/issues/$issueNumber/comments?per_page=100'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load issue comments: ${response.statusCode} - ${response.body}');
    }
  }

  // --- Notifications ---

  Future<List<dynamic>> getNotifications() async {
    final response = await http.get(
      Uri.parse('$_baseUrl/notifications?all=false'), // get unread notifications
      headers: _headers,
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load notifications');
    }
  }
}
