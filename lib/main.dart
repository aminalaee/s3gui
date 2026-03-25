import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:s3gui/const.dart';
import 'package:s3gui/pages/settings.dart';
import 'package:s3gui/pages/home.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  const storage = FlutterSecureStorage();
  final s3AccessKey = await storage.read(key: s3AccessKeyTag);
  final isReady = s3AccessKey != null && s3AccessKey.isNotEmpty;
  runApp(App(isReady: isReady));
}

class App extends StatelessWidget {
  const App({super.key, required this.isReady});

  final bool isReady;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'S3 GUI',
      theme: ThemeData(
        fontFamily: 'Balsamiq',
        appBarTheme: AppBarTheme(color: Colors.blueGrey[600]),
        colorScheme: ColorScheme.fromSwatch(primarySwatch: Colors.blueGrey),
      ),
      debugShowCheckedModeBanner: false,
      home: isReady ? const HomePage() : const SettingsPage(),
    );
  }
}
