import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:s3gui/client.dart';
import 'package:s3gui/const.dart';
import 'package:s3gui/pages/settings.dart';
import 'package:s3gui/pages/home.dart';
import 'package:s3gui/pages/objects.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  const storage = FlutterSecureStorage();
  final s3AccessKey = await storage.read(key: s3AccessKeyTag);
  final s3Bucket = await storage.read(key: s3BucketTag);
  final isReady = s3AccessKey != null && s3AccessKey.isNotEmpty;
  if (isReady) {
    await Client().init();
  }
  runApp(App(isReady: isReady, defaultBucket: s3Bucket));
}

class App extends StatefulWidget {
  const App({super.key, required this.isReady, this.defaultBucket});

  final bool isReady;
  final String? defaultBucket;

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  ThemeMode _themeMode = ThemeMode.light;

  void toggleTheme() {
    setState(() {
      _themeMode =
          _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    });
  }

  @override
  Widget build(BuildContext context) {
    final lightScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF1A73E8),
      brightness: Brightness.light,
    );
    final darkScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF1A73E8),
      brightness: Brightness.dark,
    );

    Widget home;
    if (!widget.isReady) {
      home = SettingsPage(onToggleTheme: toggleTheme);
    } else if (widget.defaultBucket != null &&
        widget.defaultBucket!.isNotEmpty) {
      home = ObjectsPage(
        bucket: widget.defaultBucket!,
        prefix: '',
        onToggleTheme: toggleTheme,
      );
    } else {
      home = HomePage(onToggleTheme: toggleTheme);
    }

    return MaterialApp(
      title: 'S3 GUI',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: lightScheme,
        fontFamily: 'Balsamiq',
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: darkScheme,
        fontFamily: 'Balsamiq',
      ),
      themeMode: _themeMode,
      debugShowCheckedModeBanner: false,
      home: home,
    );
  }
}
