import 'dart:async';
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final uiState = StateProvider<String>((ref) => "");

// this will be used as notification channel id
const notificationChannelId = 'my_foreground';

// this will be used for notification id, So you can update your custom notification with this id.
const notificationId = 888;

final class ForeGroundService {
  static final ForeGroundService instance = ForeGroundService._();

  const ForeGroundService._();

  FlutterBackgroundService get service => FlutterBackgroundService();

  Future init() async {
    debugPrint("service init");

    const channel = AndroidNotificationChannel(
      notificationChannelId,
      'MY FOREGROUND SERVICE',
      description: 'This channel is used for important notifications.',
      importance: Importance.defaultImportance,
    );

    await FlutterLocalNotificationsPlugin()
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    await FlutterLocalNotificationsPlugin()
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    await service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: onStart,
        autoStart: false,
        autoStartOnBoot: false,
        isForegroundMode: true,
        notificationChannelId: notificationChannelId,
        // this must match with notification channel you created above.
        initialNotificationTitle: 'Foreground SERVICE',
        initialNotificationContent: 'Initializing',
        foregroundServiceNotificationId: notificationId,
      ),
      iosConfiguration: IosConfiguration(),
    );
  }

  Future<bool> startBackgroundService() {
    debugPrint("service start");

    return service.startService();
  }

  void stopBackgroundService() {
    debugPrint("service stop");

    return service.invoke("stop");
  }
}

@pragma('vm:entry-point')
Future<void> onStart(ServiceInstance service) async {
  debugPrint("service onStart");
  // Only available for flutter 3.0.0 and later
  DartPluginRegistrant.ensureInitialized();

  // bring to foreground
  final timer = Timer.periodic(const Duration(seconds: 1), (timer) {
    debugPrint("service update");
    service.invoke(
      'event',
      {
        "current_date": DateTime.now().toIso8601String(),
      },
    );
  });

  service.on("stop").listen((value) {
    debugPrint("service stop");

    timer.cancel();
    service.stopSelf();
  });
}
