import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:foreground_service/foreground_service.dart';
import 'package:permission_handler/permission_handler.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await ForeGroundService.instance.init();

  runApp(ProviderScope(child: const MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Foreground Service",
      home: HomeScreen(),
    );
  }
}

final isRunning = StreamProvider((ref) async* {
  while (true) {
    bool data = await FlutterBackgroundService().isRunning();
    yield data;
    await Future.delayed(Duration(seconds: 2));
  }
});

final eventProvider = StreamProvider((ref) => FlutterBackgroundService().on('event'));

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Foreground Service"),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () async {
                await Permission.notification.request().then((value) async {
                  if (PermissionStatus.granted == value) {
                    await ForeGroundService.instance.startBackgroundService();
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text("Permission $value"),
                    ));
                  }
                });
              },
              child: Text("Start Service"),
            ),
            const SizedBox(
              height: 64,
            ),
            ElevatedButton(
              onPressed: () => ForeGroundService.instance.stopBackgroundService(),
              child: Text("Stop Service"),
            ),
            const SizedBox(
              height: 64,
            ),
            Consumer(
              builder: (context, ref, child) {
                return ref.watch(isRunning).when(
                      data: (data) {
                        if (data) {
                          return _Body();
                        } else {
                          return Text("No Service");
                        }
                      },
                      error: (error, stack) => Text("Error $error"),
                      loading: () => Text("Check Service"),
                    );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _Body extends ConsumerWidget {
  const _Body({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref.watch(eventProvider).when(
          data: (data) => Text(DateTime.tryParse(data!["current_date"])?.toString() ?? 'Nothing'),
          error: (error, stack) => Text("Event error: ${error.toString()}"),
          loading: () => Text("Loading"),
        );
  }
}
