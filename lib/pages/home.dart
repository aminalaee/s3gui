import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:s3gui/pages/settings.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:s3gui/pages/objects.dart';
import 'package:s3gui/client.dart';
import 'package:s3gui/s3.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.sharedPreferences});

  final SharedPreferences sharedPreferences;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _s3 = S3();

  @override
  void initState() {
    Client().init(widget.sharedPreferences);
    _s3.listBuckets();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Buckets'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Settings',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      SettingsPage(sharedPreferences: widget.sharedPreferences),
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Observer(
              builder: (_) => buildTable(),
            )
          ],
        ),
      ),
    );
  }

  Widget buildTable() {
    return DataTable(
      columns: const [
        DataColumn(
          label: Expanded(
            child: Text(
              'Name',
              style: TextStyle(fontSize: 16),
            ),
          ),
        ),
      ],
      rows: List<DataRow>.generate(
          _s3.buckets.length, (index) => buildBucketRow(index)),
    );
  }

  DataRow buildBucketRow(int index) {
    return DataRow(
      cells: [
        DataCell(
          ListTile(
            leading: Icon(Icons.storage, color: Colors.blue[400]),
            title: Text(
              _s3.buckets[index].name,
              style: const TextStyle(fontSize: 16),
            ),
          ),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ObjectsPage(
                  bucket: _s3.buckets[index].name,
                  prefix: '',
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
