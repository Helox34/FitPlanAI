import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter/foundation.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() => _instance;

  NotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _notificationsEnabled = false;
  bool _initialized = false;
  
  bool get isInitialized => _initialized;
  bool get areNotificationsEnabled => _notificationsEnabled;

  Future<void> initialize() async {
    try {
      debugPrint('🔔 Initializing NotificationService...');
      
      // 1. Initialize Timezone
      await _configureLocalTimeZone();
      debugPrint('✅ Timezone configured');

      // 2. Android Initialization Settings
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      // 3. iOS/macOS Initialization Settings
      const DarwinInitializationSettings initializationSettingsDarwin =
          DarwinInitializationSettings(
        requestSoundPermission: false,
        requestBadgePermission: false,
        requestAlertPermission: false,
      );

      // 4. General Initialization Settings
      const InitializationSettings initializationSettings = InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: initializationSettingsDarwin,
        macOS: initializationSettingsDarwin,
      );

      final result = await flutterLocalNotificationsPlugin.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: (NotificationResponse details) {
          debugPrint('🔔 NOTIFICATION CLICKED: ${details.payload}');
        },
      );
      
      _initialized = result ?? false;
      
      if (_initialized) {
        debugPrint('✅ NotificationService initialized successfully');
      } else {
        debugPrint('⚠️ NotificationService initialization returned false');
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Error initializing NotificationService: $e');
      debugPrint('Stack trace: $stackTrace');
      _initialized = false;
    }
  }

  Future<void> _configureLocalTimeZone() async {
    tz.initializeTimeZones();
    final String timeZoneName = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(timeZoneName));
  }

  Future<void> requestPermissions() async {
    try {
      debugPrint('🔔 Requesting notification permissions...');
      
      // Android 13+
      final bool? androidGranted = await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
      
      debugPrint('Android permission: ${androidGranted ?? "N/A (not Android 13+)"}');
      
      // iOS
      final bool? iosGranted = await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );
      
      debugPrint('iOS permission: ${iosGranted ?? "N/A (not iOS)"}');

      _notificationsEnabled = (androidGranted ?? false) || (iosGranted ?? false);
      
      debugPrint('✅ Notifications enabled: $_notificationsEnabled');
    } catch (e, stackTrace) {
      debugPrint('❌ Error requesting notification permissions: $e');
      debugPrint('Stack trace: $stackTrace');
      _notificationsEnabled = false;
    }
  }

  // ===========================================================================
  // TRAINING REMINDERS via User Settings
  // ===========================================================================
  
  /// ID: 100
  Future<void> scheduleTrainingReminder(bool enable) async {
    if (!enable) {
      await flutterLocalNotificationsPlugin.cancel(100);
      return;
    }

    await _scheduleDaily(
      id: 100,
      title: 'Czas na trening! 💪',
      body: 'Nie odpuszczaj! Twoja wymarzona sylwetka czeka.',
      hour: 18,
      minute: 0,
    );
  }

  // ===========================================================================
  // WATER REMINDERS via User Settings
  // ===========================================================================
  
  /// IDs: 201, 202, 203, 204
  Future<void> scheduleWaterReminders(bool enable) async {
    if (!enable) {
      await flutterLocalNotificationsPlugin.cancel(201);
      await flutterLocalNotificationsPlugin.cancel(202);
      await flutterLocalNotificationsPlugin.cancel(203);
      await flutterLocalNotificationsPlugin.cancel(204);
      return;
    }

    await _scheduleDaily(
      id: 201, 
      title: 'Pij wodę! 💧', 
      body: 'Nawodnienie to podstawa zdrowia i formy.', 
      hour: 10, minute: 0
    );
    
    await _scheduleDaily(
      id: 202, 
      title: 'Pora na szklankę wody 💧', 
      body: 'Twój organizm Ci podziękuje!', 
      hour: 14, minute: 0
    );
    
    await _scheduleDaily(
      id: 203, 
      title: 'Uzupełnij płyny 💧', 
      body: 'Pamiętaj o wodzie po treningu i przed snem.', 
      hour: 18, minute: 30
    );
    
    await _scheduleDaily(
      id: 204, 
      title: 'Ostatnia szklanka wody 💧', 
      body: 'Napij się przed snem dla lepszej regeneracji.', 
      hour: 20, minute: 0
    );
  }

  // ===========================================================================
  // DIET REMINDERS via User Settings
  // ===========================================================================

  /// IDs: 301, 302, 303
  Future<void> scheduleDietReminders(bool enable) async {
    if (!enable) {
      await flutterLocalNotificationsPlugin.cancel(301);
      await flutterLocalNotificationsPlugin.cancel(302);
      await flutterLocalNotificationsPlugin.cancel(303);
      return;
    }

    await _scheduleDaily(
      id: 301, 
      title: 'Pora na śniadanie 🍳', 
      body: 'Zacznij dzień od zdrowego posiłku!', 
      hour: 8, minute: 0
    );

    await _scheduleDaily(
      id: 302, 
      title: 'Czas na obiad 🥗', 
      body: 'Paliwo dla Twoich mięśni jest gotowe?', 
      hour: 13, minute: 0
    );

    await _scheduleDaily(
      id: 303, 
      title: 'Kolacja czeka 🥑', 
      body: 'Zjedz coś lekkiego na zakończenie dnia.', 
      hour: 19, minute: 0
    );
  }

  // ===========================================================================
  // HELPER MOTHODS
  // ===========================================================================

  /// Show Rest Finished Notification
  Future<void> showRestFinishedNotification() async {
    await flutterLocalNotificationsPlugin.show(
      999, // Rest Timer ID
      'Koniec odpoczynku! ⏱️', 
      'Czas wracać do ćwiczeń. Następna seria czeka!', 
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'fitplan_rest_timer',
          'Licznik Odpoczynku',
          channelDescription: 'Powiadomienia o końcu przerwy',
          importance: Importance.max,
          priority: Priority.high,
          playSound: true,
          enableVibration: true,
        ),
        iOS: DarwinNotificationDetails(
          presentSound: true,
          presentAlert: true,
          presentBanner: true,
        ),
      ),
    );
  }

  /// Show an instant notification for testing purposes
  Future<void> showTestNotification() async {
    try {
      if (!_initialized) {
        debugPrint('⚠️ Cannot show test notification: Service not initialized');
        throw 'Serwis powiadomień nie został zainicjalizowany. Uruchom aplikację ponownie.';
      }
      
      debugPrint('🔔 Showing test notification...');
      
      await flutterLocalNotificationsPlugin.show(
        888, // Arbitrary ID
        'Test Powiadomienia 🔔', 
        'To jest testowe powiadomienie z FitPlan AI. Wszystko działa!', 
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'fitplan_test',
            'Test Powiadomień',
            channelDescription: 'Kanał testowy powiadomień FitPlan AI',
            importance: Importance.max,
            priority: Priority.high,
            playSound: true,
            enableVibration: true,
          ),
          iOS: DarwinNotificationDetails(
            presentSound: true,
            presentAlert: true,
            presentBanner: true,
          ),
        ),
      );
      
      debugPrint('✅ Test notification sent successfully');
    } catch (e, stackTrace) {
      debugPrint('❌ Error showing test notification: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

  Future<void> _scheduleDaily({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
  }) async {
    await flutterLocalNotificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      _nextInstanceOfTime(hour, minute),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'fitplan_reminders',
          'Przypomnienia',
          channelDescription: 'Kanał powiadomień FitPlan AI',
          importance: Importance.max,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time, // Repeat daily at same time
    );
  }

  tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }
  
  // Future<void> cancelAll() async {
  //   await flutterLocalNotificationsPlugin.cancelAll();
  // }
}
