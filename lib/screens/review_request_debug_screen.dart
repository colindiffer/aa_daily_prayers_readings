import 'package:flutter/material.dart';
import '../services/review_request_service.dart';

/// Debug screen for testing review request functionality
/// This should only be used during development and testing
class ReviewRequestDebugScreen extends StatefulWidget {
  const ReviewRequestDebugScreen({super.key});

  @override
  State<ReviewRequestDebugScreen> createState() => _ReviewRequestDebugScreenState();
}

class _ReviewRequestDebugScreenState extends State<ReviewRequestDebugScreen> {
  Map<String, dynamic> _stats = {};
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() => _loading = true);
    final stats = await ReviewRequestService.getStatistics();
    setState(() {
      _stats = stats;
      _loading = false;
    });
  }

  Future<void> _resetData() async {
    setState(() => _loading = true);
    await ReviewRequestService.resetData();
    await _loadStats();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Review request data reset!')),
    );
  }

  Future<void> _initialize() async {
    setState(() => _loading = true);
    await ReviewRequestService.initialize();
    await _loadStats();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Review request service initialized!')),
    );
  }

  Future<void> _testReviewPage() async {
    await ReviewRequestService.openReviewPage();
    await _loadStats();
  }

  Widget _buildInfoCard(String title, String value) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Review Request Debug'),
        backgroundColor: Colors.blue.shade600,
        foregroundColor: Colors.white,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Review Request Statistics',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  _buildInfoCard(
                    'First Open Date',
                    _stats['firstOpenDate'] ?? 'Not set',
                  ),
                  
                  _buildInfoCard(
                    'Last Decline Date',
                    _stats['lastDeclineDate'] ?? 'Never declined',
                  ),
                  
                  _buildInfoCard(
                    'Has Reviewed',
                    (_stats['hasReviewed'] ?? false) ? 'Yes' : 'No',
                  ),
                  
                  _buildInfoCard(
                    'Request Count',
                    (_stats['requestCount'] ?? 0).toString(),
                  ),
                  
                  _buildInfoCard(
                    'Should Show Banner',
                    (_stats['shouldShow'] ?? false) ? 'YES' : 'NO',
                  ),
                  
                  const SizedBox(height: 24),
                  
                  const Text(
                    'Test Actions',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  ElevatedButton.icon(
                    onPressed: _initialize,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Initialize Service'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                  
                  const SizedBox(height: 8),
                  
                  ElevatedButton.icon(
                    onPressed: _testReviewPage,
                    icon: const Icon(Icons.star),
                    label: const Text('Test Review Page'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                  
                  const SizedBox(height: 8),
                  
                  ElevatedButton.icon(
                    onPressed: _resetData,
                    icon: const Icon(Icons.delete_forever),
                    label: const Text('Reset All Data'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                  
                  const SizedBox(height: 8),
                  
                  ElevatedButton.icon(
                    onPressed: _loadStats,
                    icon: const Icon(Icons.update),
                    label: const Text('Refresh Stats'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey.shade600,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '⚠️ Development Only',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.orange,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'This screen is for testing purposes only. In production:\n'
                          '• Banner appears 24 hours after first open\n'
                          '• If declined, waits 14 days before showing again\n'
                          '• Once user reviews, banner never shows again',
                          style: TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
