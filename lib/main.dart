import 'package:flutter/material.dart';
import 'package:s3gui/client.dart';
import 'package:s3gui/pages/home.dart';

void main() {
  Client().init();
  runApp(const App());
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'S3 GUI',
      theme: ThemeData(
        fontFamily: 'Balsamiq',
      ),
      debugShowCheckedModeBanner: false,
      home: const HomePage(),
    );
  }
}
