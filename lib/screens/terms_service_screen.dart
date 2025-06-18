import 'package:flutter/material.dart';
import '../analytics/analytics_service.dart';

class TermsServiceScreen extends StatefulWidget {
  const TermsServiceScreen({Key? key}) : super(key: key);

  @override
  State<TermsServiceScreen> createState() => _TermsServiceScreenState();
}

class _TermsServiceScreenState extends State<TermsServiceScreen> {
  final AnalyticsService _analytics = AnalyticsService();

  @override
  void initState() {
    super.initState();

    // Track screen view
    _analytics.logEvent(
      name: 'screen_view',
      parameters: {'screen_name': 'terms_service_screen'},
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Terms of Service'), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Terms of Service',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text(
              'Last Updated: January 2023',
              style: TextStyle(fontSize: 14, fontStyle: FontStyle.italic),
            ),
            const SizedBox(height: 24),
            _buildTermSection(
              '1. Acceptance of Terms',
              'By accessing or using the AA Readings app, you agree to be bound by these Terms of Service. If you disagree with any part of the terms, you do not have permission to access the app.',
            ),
            _buildTermSection(
              '2. Use License',
              'Permission is granted to download and use the AA Readings app for personal, non-commercial use only. This is the grant of a license, not a transfer of title.',
            ),
            _buildTermSection(
              '3. Content Disclaimer',
              'The materials on AA Readings app are provided "as is". AA Readings makes no warranties, expressed or implied, and hereby disclaims and negates all other warranties including, without limitation, implied warranties or conditions of merchantability, fitness for a particular purpose, or non-infringement of intellectual property.',
            ),
            _buildTermSection(
              '4. Limitations',
              'In no event shall AA Readings or its suppliers be liable for any damages (including, without limitation, damages for loss of data or profit, or due to business interruption) arising out of the use or inability to use the materials on AA Readings app.',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTermSection(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(content),
        const SizedBox(height: 16),
      ],
    );
  }
}
