import 'package:flutter/material.dart';
import 'package:s3gui/const.dart';
import 'package:s3gui/pages/settings.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:s3gui/pages/home.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final sharedPreferences = await SharedPreferences.getInstance();
  runApp(App(sharedPreferences: sharedPreferences));
}

class App extends StatelessWidget {
  const App({super.key, required this.sharedPreferences});

  final SharedPreferences sharedPreferences;

  @override
  Widget build(BuildContext context) {
    final s3AccessKey = sharedPreferences.getString(s3AccessKeyTag);
    final isReady = s3AccessKey != null && s3AccessKey.isNotEmpty;
    return MaterialApp(
      title: 'S3 GUI',
      theme: ThemeData(
        fontFamily: 'Balsamiq',
        appBarTheme: AppBarTheme(color: Colors.blueGrey[600]),
        colorScheme: ColorScheme.fromSwatch(primarySwatch: Colors.blueGrey),
      ),
      debugShowCheckedModeBanner: false,
      home: isReady!
          ? HomePage(sharedPreferences: sharedPreferences)
          : SettingsPage(sharedPreferences: sharedPreferences),
    );
  }
}
