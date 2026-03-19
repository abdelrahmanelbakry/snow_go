import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'aws_http_client_service.dart';

class AWSNotificationService {
  static final AWSNotificationService _instance = AWSNotificationService._internal();
  factory AWSNotificationService() => _instance;
  AWSNotificationService._internal();

  final AWSHttpClientService _httpClient = AWSHttpClientService();
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  String? _currentUserId;
  String? _deviceToken;

  // Notification channels
  static const String _jobChannelId = 'snow_go_jobs';
  static const String _jobChannelName = 'Snow Go Jobs';
  static const String _jobChannelDescription = 'Notifications about job status updates';

  // Initialize the notification service
  Future<void> initialize() async {
    // Initialize local notifications
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Create notification channels for Android
    if (Platform.isAndroid) {
      const androidChannel = AndroidNotificationChannel(
        _jobChannelId,
        _jobChannelName,
        description: _jobChannelDescription,
        importance: Importance.high,
        enableVibration: true,
        playSound: true,
      );

      await _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(androidChannel);
    }

    // Request notification permissions
    await _requestPermissions();

    // Load saved user ID
    await _loadUserId();

    // Initialize device token registration
    await _initializeDeviceToken();
  }

  // Request notification permissions
  Future<bool> _requestPermissions() async {
    if (Platform.isIOS) {
      final iosPlugin = _localNotifications.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      final result = await iosPlugin?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      return result ?? false;
    } else if (Platform.isAndroid) {
      final androidPlugin = _localNotifications.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      final result = await androidPlugin?.requestNotificationsPermission();
      return result ?? false;
    }
    return true;
  }

  // Load user ID from shared preferences
  Future<void> _loadUserId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _currentUserId = prefs.getString('user_id');
    } catch (e) {
      debugPrint('Error loading user ID: $e');
    }
  }

  // Set current user ID
  Future<void> setUserId(String userId) async {
    _currentUserId = userId;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_id', userId);
      
      // Register device token with new user ID
      if (_deviceToken != null) {
        await _registerDeviceToken();
      }
    } catch (e) {
      debugPrint('Error saving user ID: $e');
    }
  }

  // Initialize device token (platform-specific implementation)
  Future<void> _initializeDeviceToken() async {
    if (Platform.isAndroid) {
      // For Android, you would integrate with Firebase Cloud Messaging
      // or use a custom push notification service
      // This is a placeholder implementation
      _deviceToken = 'android-device-token-placeholder';
    } else if (Platform.isIOS) {
      // For iOS, you would integrate with APNs
      // This is a placeholder implementation
      _deviceToken = 'ios-device-token-placeholder';
    }

    if (_deviceToken != null && _currentUserId != null) {
      await _registerDeviceToken();
    }
  }

  // Register device token with AWS backend
  Future<void> _registerDeviceToken() async {
    if (_deviceToken == null || _currentUserId == null) {
      return;
    }

    try {
      final platform = Platform.isAndroid ? 'android' : 'ios';
      final result = await _httpClient.registerDeviceToken(
        userId: _currentUserId!,
        token: _deviceToken!,
        platform: platform,
      );

      if (result.isSuccess) {
        debugPrint('Device token registered successfully');
      } else {
        debugPrint('Failed to register device token: ${result.error}');
      }
    } catch (e) {
      debugPrint('Error registering device token: $e');
    }
  }

  // Handle notification tap
  void _onNotificationTapped(NotificationResponse response) {
    final payload = response.payload;
    if (payload != null) {
      // Handle navigation based on notification payload
      _handleNotificationNavigation(payload);
    }
  }

  // Handle navigation based on notification payload
  void _handleNotificationNavigation(String payload) {
    try {
      // Parse the notification data
      final data = Uri.splitQueryString(payload);
      
      if (data.containsKey('job_id')) {
        // Navigate to job details
        // This would typically use a navigation service
        debugPrint('Navigate to job: ${data['job_id']}');
      }
      
      if (data.containsKey('type')) {
        switch (data['type']) {
          case 'job_accepted':
            debugPrint('Job accepted notification');
            break;
          case 'job_started':
            debugPrint('Job started notification');
            break;
          case 'job_completed':
            debugPrint('Job completed notification');
            break;
          case 'counter_offer':
            debugPrint('Counter offer notification');
            break;
        }
      }
    } catch (e) {
      debugPrint('Error handling notification navigation: $e');
    }
  }

  // Show local notification
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
    String type = 'general',
  }) async {
    const androidDetails = AndroidNotificationDetails(
      _jobChannelId,
      _jobChannelName,
      channelDescription: _jobChannelDescription,
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      enableVibration: true,
      playSound: true,
      icon: '@mipmap/ic_launcher',
      color: Color(0xFF2196F3),
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      badgeNumber: 1,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      id,
      title,
      body,
      details,
      payload: payload,
    );
  }

  // Handle incoming push notification (placeholder for actual implementation)
  Future<void> handlePushNotification(Map<String, dynamic> message) async {
    try {
      final title = message['title'] ?? 'Snow Go';
      final body = message['body'] ?? 'New notification';
      final type = message['type'] ?? 'general';
      final data = message['data'] as Map<String, dynamic>?;
      
      // Create payload for navigation
      String payload = '';
      if (data != null) {
        final uriData = data.map((key, value) => MapEntry(key, value.toString()));
        payload = Uri(queryParameters: uriData).query;
      }

      // Show local notification
      await showNotification(
        id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
        title: title,
        body: body,
        payload: payload,
        type: type,
      );

      // Store notification in backend
      if (_currentUserId != null) {
        await _storeNotification(_currentUserId!, title, body, type, data);
      }
    } catch (e) {
      debugPrint('Error handling push notification: $e');
    }
  }

  // Store notification in backend
  Future<void> _storeNotification(
    String userId,
    String title,
    String body,
    String type,
    Map<String, dynamic>? data,
  ) async {
    try {
      // This would call the backend to store the notification
      // For now, we'll just log it
      debugPrint('Storing notification: $title - $body');
    } catch (e) {
      debugPrint('Error storing notification: $e');
    }
  }

  // Get notification history from backend
  Future<List<Map<String, dynamic>>> getNotificationHistory({
    String? type,
    bool? isRead,
    int limit = 50,
    int offset = 0,
  }) async {
    if (_currentUserId == null) {
      return [];
    }

    try {
      final result = await _httpClient.getNotifications(
        userId: _currentUserId!,
        type: type,
        isRead: isRead,
        limit: limit,
        offset: offset,
      );

      if (result.isSuccess && result.data != null) {
        final notifications = result.data!['notifications'] as List<dynamic>;
        return notifications.cast<Map<String, dynamic>>();
      }
      
      return [];
    } catch (e) {
      debugPrint('Error getting notification history: $e');
      return [];
    }
  }

  // Mark notification as read
  Future<void> markNotificationAsRead(String notificationId) async {
    try {
      final result = await _httpClient.markNotificationRead(notificationId);
      if (!result.isSuccess) {
        debugPrint('Failed to mark notification as read: ${result.error}');
      }
    } catch (e) {
      debugPrint('Error marking notification as read: $e');
    }
  }

  // Get unread notification count
  Future<int> getUnreadCount() async {
    if (_currentUserId == null) {
      return 0;
    }

    try {
      final result = await _httpClient.getNotifications(
        userId: _currentUserId!,
        isRead: false,
        limit: 1,
      );

      if (result.isSuccess && result.data != null) {
        return result.data!['unreadCount'] as int? ?? 0;
      }
      
      return 0;
    } catch (e) {
      debugPrint('Error getting unread count: $e');
      return 0;
    }
  }

  // Clear all notifications
  Future<void> clearAllNotifications() async {
    await _localNotifications.cancelAll();
  }

  // Clear specific notification
  Future<void> clearNotification(int id) async {
    await _localNotifications.cancel(id);
  }

  // Dispose the service
  void dispose() {
    _localNotifications.dispose();
  }
}
