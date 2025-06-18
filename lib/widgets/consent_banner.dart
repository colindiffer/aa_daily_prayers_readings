import 'package:flutter/material.dart';
import '../analytics/consent_manager.dart';
import '../analytics/analytics_service.dart';
import '../widgets/consent_dialog.dart';

class ConsentBanner extends StatelessWidget {
  final Function(bool analyticsConsent, bool marketingConsent)?
  onConsentChanged;
  final VoidCallback? onCompleted;
  final bool showDetailedOptions;

  const ConsentBanner({
    Key? key,
    this.onConsentChanged,
    this.onCompleted,
    this.showDetailedOptions = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(20.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8.0),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Privacy Preferences',
              style: TextStyle(fontSize: 22.0, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16.0),
            const Text(
              'We use data to improve your experience and measure app performance. Please select your preferences below:',
              style: TextStyle(fontSize: 16.0),
            ),
            const SizedBox(height: 24.0),
            _buildConsentOptions(context),
          ],
        ),
      ),
    );
  }

  Widget _buildConsentOptions(BuildContext context) {
    if (showDetailedOptions) {
      return _DetailedConsentOptions(
        onConsentChanged: onConsentChanged,
        onCompleted: onCompleted,
      );
    } else {
      return _SimpleConsentOptions(
        onConsentChanged: onConsentChanged,
        onCompleted: onCompleted,
      );
    }
  }
}

class _SimpleConsentOptions extends StatelessWidget {
  final Function(bool analyticsConsent, bool marketingConsent)?
  onConsentChanged;
  final VoidCallback? onCompleted;

  const _SimpleConsentOptions({this.onConsentChanged, this.onCompleted});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ElevatedButton(
          onPressed: () {
            onConsentChanged?.call(true, true);
            onCompleted?.call();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).primaryColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
          child: const Text('Accept All'),
        ),
        const SizedBox(height: 12),
        ElevatedButton(
          onPressed: () {
            onConsentChanged?.call(false, false);
            onCompleted?.call();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.grey[200],
            foregroundColor: Colors.black87,
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
          child: const Text('Reject All'),
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: () {
            // Show detailed consent dialog
            showDialog(
              context: context,
              builder:
                  (context) => ConsentDialog(
                    onConsentChanged: onConsentChanged,
                    onCompleted: onCompleted,
                  ),
            );
          },
          child: const Text('Customize Settings'),
        ),
      ],
    );
  }
}

class _DetailedConsentOptions extends StatefulWidget {
  final Function(bool analyticsConsent, bool marketingConsent)?
  onConsentChanged;
  final VoidCallback? onCompleted;

  const _DetailedConsentOptions({this.onConsentChanged, this.onCompleted});

  @override
  _DetailedConsentOptionsState createState() => _DetailedConsentOptionsState();
}

class _DetailedConsentOptionsState extends State<_DetailedConsentOptions> {
  bool _analyticsConsent = false;
  bool _marketingConsent = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildConsentSwitch(
          title: 'Analytics',
          description:
              'Allow us to collect app usage data to improve performance and understand how our app is used.',
          value: _analyticsConsent,
          onChanged: (value) {
            setState(() => _analyticsConsent = value);
          },
        ),
        const SizedBox(height: 16),
        _buildConsentSwitch(
          title: 'Marketing',
          description:
              'Allow us to use your data for personalized content and recommendations.',
          value: _marketingConsent,
          onChanged: (value) {
            setState(() => _marketingConsent = value);
          },
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              onPressed: () {
                widget.onConsentChanged?.call(false, false);
                widget.onCompleted?.call();
              },
              child: const Text('Reject All'),
            ),
            const SizedBox(width: 16),
            ElevatedButton(
              onPressed: () {
                widget.onConsentChanged?.call(
                  _analyticsConsent,
                  _marketingConsent,
                );
                widget.onCompleted?.call();
              },
              child: const Text('Save Preferences'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildConsentSwitch({
    required String title,
    required String description,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
            ),
            Switch(value: value, onChanged: onChanged),
          ],
        ),
        Text(
          description,
          style: TextStyle(fontSize: 14, color: Colors.grey[600]),
        ),
      ],
    );
  }
}
