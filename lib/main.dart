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
  WidgetsFlutterBinding.ensureInitialized();  // Enable edge-to-edge mode without setting deprecated color properties
  SystemChrome.setEnabledSystemUIMode(
    SystemUiMode.edgeToEdge,
  );

  // Initialize Firebase
  try {
    await Firebase.initializeApp();
    debugPrint('Firebase initialized successfully');
  } catch (e) {
    debugPrint('Firebase initialization error: $e');
  }

  // Initialize Logger Service
  try {
    await LoggerService().init();
    LoggerService().log('App started');
  } catch (e) {
    debugPrint('Logger initialization error: $e');
  }

  // Initialize Analytics Service (which initializes consent manager)
  final analyticsService = AnalyticsService();
  await analyticsService.initialize(); 

  // Initialize Review Request Service
  try {
    await ReviewRequestService.initialize();
    debugPrint('Review request service initialized');
  } catch (e) {
    debugPrint('Review request service initialization error: $e');
  }

  // Initialize timezones and notifications
  try {
    // Initialize notifications service
    await NotificationService().initNotification();
    debugPrint('Notification service initialized');

    // Schedule daily notifications based on user preferences
    await NotificationService().scheduleDailyNotifications();
    debugPrint('Daily notifications scheduled');
  } catch (e) {
    debugPrint('Notification initialization error: $e');
  }

  // Comment out or remove Google Mobile Ads SDK initialization
  // try {
  //   await MobileAds.instance.initialize();
  //   debugPrint('Google Mobile Ads SDK initialized successfully');
  // } catch (e) {
  //   debugPrint('Google Mobile Ads SDK initialization error: $e');
  // }

  // Request permissions
  try {
    await requestPermissions();
    debugPrint('Permissions requested');
  } catch (e) {
    debugPrint('Permission request error: $e');
  }

  // Run the app
  runApp(const MyApp());
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

  @override
  void initState() {
    super.initState();
    _checkConsentStatus();
  }

  Future<void> _checkConsentStatus() async {
    final analyticsConsent = _analyticsService.consentManager.getConsentState(
      ConsentType.analytics,
    );

    if (analyticsConsent == ConsentState.notSet) {
      setState(() {
        _showConsentUI = true;
      });
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
    return MaterialApp(
      title: 'AA Daily Prayers & Readings',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) =>
            _showConsentUI ? _buildConsentScreen() : const ReadingsScreen(),
        '/settings/consent': (context) => const ConsentSettingsScreen(),
        '/about': (context) => const AboutPage(),
      },
    );
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
