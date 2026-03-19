import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_performance/firebase_performance.dart';
import 'package:flutter/foundation.dart';

class AnalyticsService {
  static final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;
  static final FirebaseCrashlytics _crashlytics = FirebaseCrashlytics.instance;
  static final FirebasePerformance _performance = FirebasePerformance.instance;

  // User Events
  static Future<void> trackUserRegistration(String method, String userRole) async {
    await _analytics.logSignUp(signUpMethod: method);
    await _analytics.logEvent(
      name: 'user_registration',
      parameters: {
        'method': method,
        'user_role': userRole,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      },
    );
  }

  static Future<void> trackUserLogin(String method, String userRole) async {
    await _analytics.logLogin(loginMethod: method);
    await _analytics.logEvent(
      name: 'user_login',
      parameters: {
        'method': method,
        'user_role': userRole,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      },
    );
  }

  static Future<void> trackRoleSwitch(String fromRole, String toRole) async {
    await _analytics.logEvent(
      name: 'role_switch',
      parameters: {
        'from_role': fromRole,
        'to_role': toRole,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      },
    );
  }

  // Job Events
  static Future<void> trackJobCreation(String serviceType, double price, String schedulingType) async {
    await _analytics.logEvent(
      name: 'job_created',
      parameters: {
        'service_type': serviceType,
        'price': price,
        'scheduling_type': schedulingType,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      },
    );
  }

  static Future<void> trackJobAcceptance(String jobId, String providerId, double price) async {
    await _analytics.logEvent(
      name: 'job_accepted',
      parameters: {
        'job_id': jobId,
        'provider_id': providerId,
        'price': price,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      },
    );
  }

  static Future<void> trackJobCompletion(String jobId, String serviceType, double price, int durationMinutes) async {
    await _analytics.logEvent(
      name: 'job_completed',
      parameters: {
        'job_id': jobId,
        'service_type': serviceType,
        'price': price,
        'duration_minutes': durationMinutes,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      },
    );
  }

  static Future<void> trackJobCancellation(String jobId, String reason, String cancelledBy) async {
    await _analytics.logEvent(
      name: 'job_cancelled',
      parameters: {
        'job_id': jobId,
        'reason': reason,
        'cancelled_by': cancelledBy,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      },
    );
  }

  // Map and Location Events
  static Future<void> trackMapInteraction(String action, String context) async {
    await _analytics.logEvent(
      name: 'map_interaction',
      parameters: {
        'action': action, // 'zoom', 'pan', 'marker_tap', 'search'
        'context': context, // 'booking', 'home', 'tracking'
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      },
    );
  }

  static Future<void> trackLocationPermission(String status) async {
    await _analytics.logEvent(
      name: 'location_permission',
      parameters: {
        'status': status, // 'granted', 'denied', 'restricted'
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      },
    );
  }

  // Business Metrics
  static Future<void> trackRevenue(double amount, String currency, String jobId) async {
    await _analytics.logPurchase(
      currency: currency,
      value: amount,
      parameters: {
        'job_id': jobId,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      },
    );
  }

  static Future<void> trackUserRetention(int daysSinceRegistration) async {
    await _analytics.logEvent(
      name: 'user_retention',
      parameters: {
        'days_since_registration': daysSinceRegistration,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      },
    );
  }

  // Screen Tracking
  static Future<void> trackScreenView(String screenName, String screenClass) async {
    await _analytics.logScreenView(
      screenName: screenName,
      screenClass: screenClass,
    );
  }

  // Performance Monitoring
  static Trace startTrace(String traceName) {
    return _performance.newTrace(traceName);
  }

  static Future<void> trackApiCall(String endpoint, int responseTime, bool success) async {
    await _analytics.logEvent(
      name: 'api_call',
      parameters: {
        'endpoint': endpoint,
        'response_time_ms': responseTime,
        'success': success,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      },
    );
  }

  // Error Tracking
  static Future<void> recordError(dynamic error, StackTrace? stackTrace, {
    Map<String, dynamic>? customData,
    bool fatal = false,
  }) async {
    await _crashlytics.recordError(
      error,
      stackTrace,
      fatal: fatal,
      information: customData?.entries.map((e) => DiagnosticsProperty(e.key, e.value)).toList() ?? [],
    );
  }

  static Future<void> recordFlutterError(FlutterErrorDetails errorDetails) async {
    await _crashlytics.recordFlutterFatalError(errorDetails);
  }

  static Future<void> setUserIdentifier(String userId, String userRole) async {
    await _crashlytics.setUserIdentifier(userId);
    await _analytics.setUserId(id: userId);
    await _analytics.setUserProperty(name: 'user_role', value: userRole);
  }

  static Future<void> logCustomEvent(String eventName, Map<String, dynamic> parameters) async {
    await _analytics.logEvent(name: eventName, parameters: parameters);
  }

  // App Lifecycle Events
  static Future<void> trackAppOpen() async {
    await _analytics.logAppOpen();
  }

  static Future<void> trackAppBackground() async {
    await _analytics.logEvent(
      name: 'app_background',
      parameters: {
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      },
    );
  }

  // Notification Events
  static Future<void> trackNotificationReceived(String type, String jobId) async {
    await _analytics.logEvent(
      name: 'notification_received',
      parameters: {
        'type': type,
        'job_id': jobId,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      },
    );
  }

  static Future<void> trackNotificationTapped(String type, String jobId) async {
    await _analytics.logEvent(
      name: 'notification_tapped',
      parameters: {
        'type': type,
        'job_id': jobId,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      },
    );
  }
}
