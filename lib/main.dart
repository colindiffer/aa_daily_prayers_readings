import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'widgets/consent_banner.dart';
import 'screens/readings_screen.dart';
import 'services/notification_service.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:io' show Platform;
import 'analytics/analytics_service.dart';
import 'analytics/consent_manager.dart';
import 'screens/consent_settings_screen.dart';
import 'screens/about_page.dart';
import 'services/logger_service.dart';
import 'services/review_request_service.dart';

void main() async {
  // Ensure Flutter is initialized
  WidgetsFlutterBinding.ensureInitialized();
  
  // Add global error handler
  FlutterError.onError = (FlutterErrorDetails details) {
    debugPrint('Flutter Error: ${details.exception}');
    debugPrint('Stack trace: ${details.stack}');
  };

  debugPrint('=== APP STARTING ===');

  try {
    // Enable edge-to-edge mode without setting deprecated color properties
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.edgeToEdge,
    );
    debugPrint('System UI mode set');

    // Initialize Firebase
    try {
      await Firebase.initializeApp();
      debugPrint('✅ Firebase initialized successfully');
    } catch (e) {
      debugPrint('❌ Firebase initialization error: $e');
      // Continue without Firebase for now
    }

    // Initialize Logger Service
    try {
      await LoggerService().init();
      LoggerService().log('App started');
      debugPrint('✅ Logger service initialized');
    } catch (e) {
      debugPrint('❌ Logger initialization error: $e');
    }

    // Initialize Analytics Service (which initializes consent manager)
    try {
      final analyticsService = AnalyticsService();
      await analyticsService.initialize();
      debugPrint('✅ Analytics service initialized');
    } catch (e) {
      debugPrint('❌ Analytics initialization error: $e');
    }

    // Initialize Review Request Service
    try {
      await ReviewRequestService.initialize();
      debugPrint('✅ Review request service initialized');
    } catch (e) {
      debugPrint('❌ Review request service initialization error: $e');
    }

    // Initialize timezones and notifications
    try {
      // Initialize notifications service
      await NotificationService().initNotification();
      debugPrint('✅ Notification service initialized');

      // Schedule daily notifications based on user preferences
      await NotificationService().scheduleDailyNotifications();
      debugPrint('✅ Daily notifications scheduled');
    } catch (e) {
      debugPrint('❌ Notification initialization error: $e');
    }

    // Request permissions
    try {
      await requestPermissions();
      debugPrint('✅ Permissions requested');
    } catch (e) {
      debugPrint('❌ Permission request error: $e');
    }

    debugPrint('=== STARTING APP UI ===');
    // Run the app
    runApp(const MyApp());

  } catch (e, stackTrace) {
    debugPrint('❌ CRITICAL ERROR IN MAIN: $e');
    debugPrint('Stack trace: $stackTrace');
    
    // Run a minimal app if everything fails
    runApp(MaterialApp(
      home: Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              const Text('App failed to initialize'),
              const SizedBox(height: 8),
              Text('Error: $e', style: const TextStyle(fontSize: 12)),
            ],
          ),
        ),
      ),
    ));
  }
}

// ✅ Function to Request Permissions at Runtime
Future<void> requestPermissions() async {
  if (Platform.isIOS) {
    // Request notification permissions for iOS
    final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
        FlutterLocalNotificationsPlugin();
    final bool? result = await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);
    debugPrint('iOS Notification permissions granted: $result');
  }

  if (Platform.isAndroid) {
    // Request Android permissions
    final notificationStatus = await Permission.notification.status;
    if (notificationStatus.isDenied) {
      final status = await Permission.notification.request();
      debugPrint('Android notification permission status: $status');
    }

    final exactAlarmStatus = await Permission.scheduleExactAlarm.status;
    if (exactAlarmStatus.isDenied) {
      final status = await Permission.scheduleExactAlarm.request();
      debugPrint('Android exact alarm permission status: $status');
    }

    try {
      final batteryOptStatus =
          await Permission.ignoreBatteryOptimizations.status;
      if (batteryOptStatus.isDenied) {
        final status = await Permission.ignoreBatteryOptimizations.request();
        debugPrint('Android battery optimization permission status: $status');
      }
    } catch (e) {
      debugPrint('Error requesting battery optimization permission: $e');
    }
  }
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final AnalyticsService _analyticsService = AnalyticsService();
  bool _showConsentUI = false;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    debugPrint('MyApp initState called');
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      debugPrint('Checking consent status...');
      await _checkConsentStatus();
      debugPrint('Consent status checked');
      
      setState(() {
        _isLoading = false;
      });
    } catch (e, stackTrace) {
      debugPrint('Error in app initialization: $e');
      debugPrint('Stack trace: $stackTrace');
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _checkConsentStatus() async {
    try {
      // For iOS simulator testing, skip consent UI and set default consent
      if (Platform.isIOS) {
        debugPrint('Running on iOS - setting default consent for testing');
        final consent = {
          ConsentType.analytics: ConsentState.granted,
          ConsentType.adStorage: ConsentState.denied,
          ConsentType.adUserData: ConsentState.denied,
          ConsentType.adPersonalization: ConsentState.denied,
        };
        _analyticsService.consentManager.updateAllConsent(consent);
        setState(() {
          _showConsentUI = false;
        });
        return;
      }

      final analyticsConsent = _analyticsService.consentManager.getConsentState(
        ConsentType.analytics,
      );

      if (analyticsConsent == ConsentState.notSet) {
        setState(() {
          _showConsentUI = true;
        });
        debugPrint('Consent UI will be shown');
      } else {
        debugPrint('Consent already set: $analyticsConsent');
      }
    } catch (e) {
      debugPrint('Error checking consent status: $e');
      // Continue without showing consent UI if there's an error
    }
  }

  void _handleConsentChanged(Map<ConsentType, ConsentState> consent) {
    setState(() {
      _showConsentUI = false;
    });

    // Log event about consent decision
    _analyticsService.logEvent(
      name: 'consent_decision',
      parameters: {
        'analytics_consent':
            consent[ConsentType.analytics] == ConsentState.granted
                ? 'granted'
                : 'denied',
        'ad_storage_consent':
            consent[ConsentType.adStorage] == ConsentState.granted
                ? 'granted'
                : 'denied',
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('MyApp build called - isLoading: $_isLoading, showConsent: $_showConsentUI, error: $_error');
    
    return MaterialApp(
      title: 'AA Daily Prayers & Readings',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: _buildHomeScreen(),
      routes: {
        '/settings/consent': (context) => const ConsentSettingsScreen(),
        '/about': (context) => const AboutPage(),
      },
    );
  }

  Widget _buildHomeScreen() {
    if (_isLoading) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              const Text('Loading...'),
              const SizedBox(height: 8),
              Text('Initializing app...', style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      );
    }

    if (_error != null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.orange),
              const SizedBox(height: 16),
              const Text('Something went wrong'),
              const SizedBox(height: 8),
              Text(_error!, style: const TextStyle(fontSize: 12)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _error = null;
                    _isLoading = true;
                  });
                  _initializeApp();
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_showConsentUI) {
      return _buildConsentScreen();
    }

    // Show the main readings screen
    return const ReadingsScreen();
  }

  Widget _buildConsentScreen() {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: ConsentBanner(
              onConsentChanged: (analyticsConsent, marketingConsent) {
                // Convert to the consent format expected by our ConsentManager
                final consent = {
                  ConsentType.analytics: analyticsConsent
                      ? ConsentState.granted
                      : ConsentState.denied,
                  ConsentType.adStorage: marketingConsent
                      ? ConsentState.granted
                      : ConsentState.denied,
                  ConsentType.adUserData: marketingConsent
                      ? ConsentState.granted
                      : ConsentState.denied,
                  ConsentType.adPersonalization: marketingConsent
                      ? ConsentState.granted
                      : ConsentState.denied,
                };

                // Update consent in ConsentManager
                _analyticsService.consentManager.updateAllConsent(consent);

                // Update UI state
                _handleConsentChanged(consent);
              },
              onCompleted: () {
                setState(() {
                  _showConsentUI = false;
                });
              },
            ),
          ),
        ),
      ),
    );
  }
}

// Add track screen view functionality
void trackScreenView(String screenName) {
  final analyticsService = AnalyticsService();
  analyticsService.logEvent(
    name: 'screen_view',
    parameters: {'screen_name': screenName},
  );
}
